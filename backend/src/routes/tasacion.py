"""
Tasacion (Appraisal) Router.

Flujo de coordinacion de cita (4 estados):
  pending   -> El comprador aun no ha propuesto fecha.
  proposed  -> Comprador propone fecha/hora. Vendedor debe aceptar o rechazar.
  rejected  -> Vendedor rechaza y propone fecha alternativa. Comprador decide.
  accepted  -> Ambas partes acordaron la fecha. Vendedor confirma visita fisica.
  completed -> Vendedor confirma que el tasador visito la vivienda. FEIN desbloqueada.

Endpoints:
  GET  /tasacion/{offer_id}/status         Estado completo
  POST /tasacion/{offer_id}/schedule       Comprador propone fecha (tambien re-propone tras rechazo)
  POST /tasacion/{offer_id}/accept         Vendedor acepta la propuesta del comprador
  POST /tasacion/{offer_id}/reject         Vendedor rechaza y propone fecha alternativa
  POST /tasacion/{offer_id}/confirm-visit  Vendedor confirma que la visita ocurrio (gate: accepted)

Gate FEIN: TASACION_APPOINTMENT debe estar COMPLETED.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified

from backend.src.config.database import get_db
from backend.src.utils.security import get_current_active_user
from backend.src.models.users import User
from backend.src.models.offers import PropertyOffer
from backend.src.models.timeline import TransactionStep, StepStatus

router = APIRouter(prefix="/tasacion", tags=["Tasacion"])

_STEP_KEY = "TASACION_APPOINTMENT"

# Sub-estados almacenados en metadata_json["appointment_status"]
_S_PENDING   = "pending"
_S_PROPOSED  = "proposed"
_S_REJECTED  = "rejected"
_S_ACCEPTED  = "accepted"
_S_COMPLETED = "completed"


# ─── Internal helpers ─────────────────────────────────────────────────────────

def _get_offer_or_404(offer_id: int, db: Session) -> PropertyOffer:
    offer = db.query(PropertyOffer).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Oferta no encontrada.")
    return offer


def _require_participant(offer: PropertyOffer, user: User) -> None:
    if offer.buyer_id != user.id and offer.property.owner_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo las partes de la oferta pueden acceder.",
        )


def _require_buyer(offer: PropertyOffer, user: User) -> None:
    if offer.buyer_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el comprador puede realizar esta accion.",
        )


def _require_seller(offer: PropertyOffer, user: User) -> None:
    if offer.property.owner_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el vendedor puede realizar esta accion.",
        )


def _get_step(offer_id: int, db: Session) -> TransactionStep | None:
    return (
        db.query(TransactionStep)
        .filter(
            TransactionStep.offer_id == offer_id,
            TransactionStep.step_key == _STEP_KEY,
        )
        .first()
    )


def _get_or_create_step(offer_id: int, db: Session) -> TransactionStep:
    """Devuelve el step, creandolo si no existe (cubre ofertas antiguas)."""
    step = _get_step(offer_id, db)
    if step is not None:
        return step
    step = TransactionStep(
        offer_id=offer_id,
        step_order=5,
        step_key=_STEP_KEY,
        label="Tasacion de la Vivienda",
        description="El tasador visita la vivienda y emite el informe de valor de mercado.",
        required_role="BOTH",
        status=StepStatus.PENDING,
        metadata_json={"appointment_status": _S_PENDING},
    )
    db.add(step)
    db.commit()
    db.refresh(step)
    return step


def _appt_status(step: TransactionStep) -> str:
    meta = dict(step.metadata_json or {})
    return meta.get("appointment_status", _S_PENDING)


# ─── Schemas ──────────────────────────────────────────────────────────────────

class ScheduleRequest(BaseModel):
    appointment_date: str = Field(..., description="Fecha ISO: YYYY-MM-DD")
    appointment_time: str = Field(..., description="Hora: HH:MM")
    notes: Optional[str] = Field(None, max_length=500)


class RejectRequest(BaseModel):
    proposed_date: str = Field(..., description="Fecha alternativa del vendedor: YYYY-MM-DD")
    proposed_time: str = Field(..., description="Hora alternativa: HH:MM")
    notes: Optional[str] = Field(None, max_length=500)


class TasacionStatusResponse(BaseModel):
    offer_id: int
    appointment_status: str           # pending | proposed | rejected | accepted | completed
    appointment_date: Optional[str]   # fecha propuesta por el comprador
    appointment_time: Optional[str]
    notes: Optional[str]
    seller_proposed_date: Optional[str]   # contraoferta del vendedor (cuando rejected)
    seller_proposed_time: Optional[str]
    seller_rejection_notes: Optional[str]
    buyer_proposed_at: Optional[str]
    seller_responded_at: Optional[str]
    seller_confirmed_at: Optional[str]


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.get("/{offer_id}/status", response_model=TasacionStatusResponse)
async def get_tasacion_status(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Estado actual de la tasacion. RBAC: comprador o vendedor."""
    offer = _get_offer_or_404(offer_id, db)
    _require_participant(offer, current_user)

    step = _get_step(offer_id, db)
    if step is None:
        return TasacionStatusResponse(
            offer_id=offer_id,
            appointment_status=_S_PENDING,
            appointment_date=None,
            appointment_time=None,
            notes=None,
            seller_proposed_date=None,
            seller_proposed_time=None,
            seller_rejection_notes=None,
            buyer_proposed_at=None,
            seller_responded_at=None,
            seller_confirmed_at=None,
        )

    meta = dict(step.metadata_json or {})
    return TasacionStatusResponse(
        offer_id=offer_id,
        appointment_status=meta.get("appointment_status", _S_PENDING),
        appointment_date=meta.get("appointment_date"),
        appointment_time=meta.get("appointment_time"),
        notes=meta.get("notes"),
        seller_proposed_date=meta.get("seller_proposed_date"),
        seller_proposed_time=meta.get("seller_proposed_time"),
        seller_rejection_notes=meta.get("seller_rejection_notes"),
        buyer_proposed_at=(
            step.buyer_confirmed_at.isoformat() if step.buyer_confirmed_at else None
        ),
        seller_responded_at=meta.get("seller_responded_at"),
        seller_confirmed_at=(
            step.seller_confirmed_at.isoformat() if step.seller_confirmed_at else None
        ),
    )


@router.post("/{offer_id}/schedule")
async def schedule_appointment(
    offer_id: int,
    body: ScheduleRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Comprador propone una fecha/hora para la visita del tasador.
    Valido en estado pending o rejected (re-propuesta tras rechazo del vendedor).
    """
    offer = _get_offer_or_404(offer_id, db)
    _require_buyer(offer, current_user)

    step = _get_or_create_step(offer_id, db)
    appt_s = _appt_status(step)

    if appt_s not in (_S_PENDING, _S_REJECTED):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"No se puede proponer una fecha en estado '{appt_s}'.",
        )

    now = datetime.now(timezone.utc)
    meta = dict(step.metadata_json or {})
    meta.update({
        "appointment_status": _S_PROPOSED,
        "appointment_date": body.appointment_date,
        "appointment_time": body.appointment_time,
        "notes": body.notes or "",
        "scheduled_by": current_user.id,
        "scheduled_at": now.isoformat(),
        # Limpiar contraoferta previa del vendedor al re-proponer
        "seller_proposed_date": None,
        "seller_proposed_time": None,
        "seller_rejection_notes": None,
        "seller_responded_at": None,
    })

    step.metadata_json = meta
    flag_modified(step, "metadata_json")
    step.buyer_confirmed_at = now
    step.status = StepStatus.PENDING  # aun no aceptado por vendedor

    db.commit()
    db.refresh(step)

    return {
        "offer_id": offer_id,
        "appointment_status": _S_PROPOSED,
        "appointment_date": body.appointment_date,
        "appointment_time": body.appointment_time,
    }


@router.post("/{offer_id}/accept")
async def accept_appointment(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Vendedor acepta la fecha propuesta por el comprador.
    Gate: appointment_status debe ser 'proposed'.
    """
    offer = _get_offer_or_404(offer_id, db)
    _require_seller(offer, current_user)

    step = _get_or_create_step(offer_id, db)
    appt_s = _appt_status(step)

    if appt_s != _S_PROPOSED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"No hay propuesta pendiente de aceptar (estado actual: '{appt_s}').",
        )

    now = datetime.now(timezone.utc)
    meta = dict(step.metadata_json or {})
    meta["appointment_status"] = _S_ACCEPTED
    meta["seller_responded_at"] = now.isoformat()
    meta["accepted_by"] = current_user.id

    step.metadata_json = meta
    flag_modified(step, "metadata_json")
    step.seller_confirmed_at = None  # se usara solo para confirmar la visita fisica
    step.status = StepStatus.PARTIALLY_COMPLETED  # cita acordada, falta la visita

    db.commit()
    db.refresh(step)

    return {"offer_id": offer_id, "appointment_status": _S_ACCEPTED}


@router.post("/{offer_id}/reject")
async def reject_appointment(
    offer_id: int,
    body: RejectRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Vendedor rechaza la fecha propuesta y ofrece una alternativa.
    Gate: appointment_status debe ser 'proposed'.
    """
    offer = _get_offer_or_404(offer_id, db)
    _require_seller(offer, current_user)

    step = _get_or_create_step(offer_id, db)
    appt_s = _appt_status(step)

    if appt_s != _S_PROPOSED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"No hay propuesta pendiente de rechazar (estado actual: '{appt_s}').",
        )

    now = datetime.now(timezone.utc)
    meta = dict(step.metadata_json or {})
    meta.update({
        "appointment_status": _S_REJECTED,
        "seller_proposed_date": body.proposed_date,
        "seller_proposed_time": body.proposed_time,
        "seller_rejection_notes": body.notes or "",
        "seller_responded_at": now.isoformat(),
        "rejected_by": current_user.id,
    })

    step.metadata_json = meta
    flag_modified(step, "metadata_json")
    step.status = StepStatus.PENDING  # vuelve a pending hasta que comprador re-proponga

    db.commit()
    db.refresh(step)

    return {
        "offer_id": offer_id,
        "appointment_status": _S_REJECTED,
        "seller_proposed_date": body.proposed_date,
        "seller_proposed_time": body.proposed_time,
    }


@router.post("/{offer_id}/accept-counter")
async def accept_counter_proposal(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Comprador acepta la contraoferta de fecha del vendedor.
    Gate: appointment_status debe ser 'rejected' (vendedor propuso fecha alternativa).
    Transiciona directamente a 'accepted' sin requerir confirmacion adicional del vendedor.
    """
    offer = _get_offer_or_404(offer_id, db)
    _require_buyer(offer, current_user)

    step = _get_or_create_step(offer_id, db)
    appt_s = _appt_status(step)

    if appt_s != _S_REJECTED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"No hay contraoferta pendiente de aceptar (estado actual: '{appt_s}').",
        )

    meta = dict(step.metadata_json or {})
    seller_date = meta.get("seller_proposed_date")
    seller_time = meta.get("seller_proposed_time")

    if not seller_date or not seller_time:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se encontro la fecha alternativa del vendedor.",
        )

    now = datetime.now(timezone.utc)
    # Promocionar la fecha del vendedor como la fecha acordada
    meta["appointment_date"] = seller_date
    meta["appointment_time"] = seller_time
    meta["appointment_status"] = _S_ACCEPTED
    meta["accepted_by"] = current_user.id
    meta["accepted_at"] = now.isoformat()
    meta["seller_proposed_date"] = None
    meta["seller_proposed_time"] = None

    step.metadata_json = meta
    flag_modified(step, "metadata_json")
    step.buyer_confirmed_at = now
    step.status = StepStatus.PARTIALLY_COMPLETED  # cita acordada, falta la visita fisica

    db.commit()
    db.refresh(step)

    return {
        "offer_id": offer_id,
        "appointment_status": _S_ACCEPTED,
        "appointment_date": seller_date,
        "appointment_time": seller_time,
    }


@router.post("/{offer_id}/confirm-visit")
async def confirm_visit(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Vendedor confirma que el tasador ha visitado la vivienda.
    Gate: appointment_status debe ser 'accepted' (ambas partes acordaron la cita).
    """
    offer = _get_offer_or_404(offer_id, db)
    _require_seller(offer, current_user)

    step = _get_or_create_step(offer_id, db)
    appt_s = _appt_status(step)

    if appt_s == _S_COMPLETED:
        return {"offer_id": offer_id, "appointment_status": _S_COMPLETED}

    if appt_s != _S_ACCEPTED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La cita debe estar aceptada por ambas partes antes de confirmar la visita.",
        )

    now = datetime.now(timezone.utc)
    meta = dict(step.metadata_json or {})
    meta["appointment_status"] = _S_COMPLETED
    meta["visit_confirmed_by"] = current_user.id
    meta["visit_confirmed_at"] = now.isoformat()

    step.metadata_json = meta
    flag_modified(step, "metadata_json")
    step.seller_confirmed_at = now
    step.status = StepStatus.COMPLETED

    db.commit()
    db.refresh(step)

    return {"offer_id": offer_id, "appointment_status": _S_COMPLETED}

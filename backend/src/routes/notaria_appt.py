"""
Notaria Appointment — firma de escrituras en notaria.

Flujo:
  pending    -> Ninguna parte ha propuesto cita.
  scheduled  -> Comprador ha propuesto ciudad/fecha/hora. Pendiente de confirmacion.
  completed  -> Ambas partes confirman que la firma se ha realizado.

Step key: NOTARIA_APPOINTMENT (step_order=6)

Endpoints:
  GET  /notaria-appt/{offer_id}/status        Estado actual
  POST /notaria-appt/{offer_id}/schedule      Comprador propone ciudad+fecha+hora
  POST /notaria-appt/{offer_id}/confirm       Comprador o vendedor confirma la firma
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

router = APIRouter(prefix="/notaria-appt", tags=["Notaria Appointment"])

_STEP_KEY = "NOTARIA_APPOINTMENT"
_S_PENDING    = "pending"
_S_SCHEDULED  = "scheduled"
_S_COMPLETED  = "completed"


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
            detail="Solo el comprador puede proponer la cita de notaria.",
        )


def _get_or_create_step(offer_id: int, db: Session) -> TransactionStep:
    step = (
        db.query(TransactionStep)
        .filter(
            TransactionStep.offer_id == offer_id,
            TransactionStep.step_key == _STEP_KEY,
        )
        .first()
    )
    if step is not None:
        return step
    step = TransactionStep(
        offer_id=offer_id,
        step_order=6,
        step_key=_STEP_KEY,
        label="Firma en Notaria",
        description="Ambas partes firman las escrituras ante notario.",
        required_role="BOTH",
        status=StepStatus.PENDING,
        metadata_json={"appointment_status": _S_PENDING},
    )
    db.add(step)
    db.commit()
    db.refresh(step)
    return step


# ─── Schemas ──────────────────────────────────────────────────────────────────

class ScheduleRequest(BaseModel):
    city: str = Field(..., max_length=100, description="Ciudad/notaria propuesta")
    appointment_date: str = Field(..., description="Fecha ISO: YYYY-MM-DD")
    appointment_time: str = Field(..., description="Hora: HH:MM")
    notes: Optional[str] = Field(None, max_length=500)


class NotariaStatusResponse(BaseModel):
    offer_id: int
    appointment_status: str
    city: Optional[str]
    appointment_date: Optional[str]
    appointment_time: Optional[str]
    notes: Optional[str]
    buyer_confirmed: bool
    seller_confirmed: bool
    scheduled_at: Optional[str]
    buyer_confirmed_at: Optional[str]
    seller_confirmed_at: Optional[str]


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.get("/{offer_id}/status", response_model=NotariaStatusResponse)
async def get_notaria_status(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    offer = _get_offer_or_404(offer_id, db)
    _require_participant(offer, current_user)

    step = (
        db.query(TransactionStep)
        .filter(
            TransactionStep.offer_id == offer_id,
            TransactionStep.step_key == _STEP_KEY,
        )
        .first()
    )
    if step is None:
        return NotariaStatusResponse(
            offer_id=offer_id,
            appointment_status=_S_PENDING,
            city=None,
            appointment_date=None,
            appointment_time=None,
            notes=None,
            buyer_confirmed=False,
            seller_confirmed=False,
            scheduled_at=None,
            buyer_confirmed_at=None,
            seller_confirmed_at=None,
        )

    meta = step.metadata_json or {}
    return NotariaStatusResponse(
        offer_id=offer_id,
        appointment_status=meta.get("appointment_status", _S_PENDING),
        city=meta.get("city"),
        appointment_date=meta.get("appointment_date"),
        appointment_time=meta.get("appointment_time"),
        notes=meta.get("notes"),
        buyer_confirmed=step.buyer_confirmed_at is not None,
        seller_confirmed=step.seller_confirmed_at is not None,
        scheduled_at=meta.get("scheduled_at"),
        buyer_confirmed_at=(
            step.buyer_confirmed_at.isoformat() if step.buyer_confirmed_at else None
        ),
        seller_confirmed_at=(
            step.seller_confirmed_at.isoformat() if step.seller_confirmed_at else None
        ),
    )


@router.post("/{offer_id}/schedule")
async def schedule_notaria(
    offer_id: int,
    body: ScheduleRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Comprador propone ciudad, fecha y hora para la firma en notaria."""
    offer = _get_offer_or_404(offer_id, db)
    _require_buyer(offer, current_user)

    step = _get_or_create_step(offer_id, db)
    now = datetime.now(timezone.utc)
    meta = dict(step.metadata_json or {})
    meta.update({
        "appointment_status": _S_SCHEDULED,
        "city": body.city,
        "appointment_date": body.appointment_date,
        "appointment_time": body.appointment_time,
        "notes": body.notes or "",
        "scheduled_by": current_user.id,
        "scheduled_at": now.isoformat(),
    })
    step.metadata_json = meta
    flag_modified(step, "metadata_json")
    step.status = StepStatus.PARTIALLY_COMPLETED
    db.commit()
    db.refresh(step)

    return {
        "offer_id": offer_id,
        "appointment_status": _S_SCHEDULED,
        "city": body.city,
        "appointment_date": body.appointment_date,
        "appointment_time": body.appointment_time,
    }


@router.post("/{offer_id}/confirm")
async def confirm_notaria_signing(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Comprador o vendedor confirma que la firma de escrituras se ha realizado.
    Cuando ambos confirman -> NOTARIA_APPOINTMENT COMPLETED.
    """
    offer = _get_offer_or_404(offer_id, db)
    _require_participant(offer, current_user)

    step = _get_or_create_step(offer_id, db)
    now = datetime.now(timezone.utc)
    meta = dict(step.metadata_json or {})

    is_buyer = offer.buyer_id == current_user.id
    if is_buyer:
        step.buyer_confirmed_at = now
        meta["buyer_confirmed_at"] = now.isoformat()
    else:
        step.seller_confirmed_at = now
        meta["seller_confirmed_at"] = now.isoformat()

    # Ambos confirmaron -> COMPLETED
    if step.buyer_confirmed_at and step.seller_confirmed_at:
        meta["appointment_status"] = _S_COMPLETED
        step.status = StepStatus.COMPLETED
    else:
        step.status = StepStatus.PARTIALLY_COMPLETED

    step.metadata_json = meta
    flag_modified(step, "metadata_json")
    db.commit()
    db.refresh(step)

    return {
        "offer_id": offer_id,
        "appointment_status": meta.get("appointment_status"),
        "buyer_confirmed": step.buyer_confirmed_at is not None,
        "seller_confirmed": step.seller_confirmed_at is not None,
    }

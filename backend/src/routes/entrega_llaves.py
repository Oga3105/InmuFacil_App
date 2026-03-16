"""
Entrega de Llaves — hito final de la transaccion.

Flujo:
  pending   -> Ninguna parte ha confirmado la entrega.
  partial   -> Una parte ha confirmado.
  completed -> Ambas partes confirman -> offer.status = 'completed'.

Step key: KEY_HANDOVER (step_order=7)

Endpoints:
  GET  /entrega-llaves/{offer_id}/status   Estado actual
  POST /entrega-llaves/{offer_id}/confirm  Comprador o vendedor confirma entrega
"""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified

from backend.src.config.database import get_db
from backend.src.utils.security import get_current_active_user
from backend.src.models.users import User
from backend.src.models.offers import PropertyOffer
from backend.src.models.timeline import TransactionStep, StepStatus
from backend.src.models.enums import OfferStatus

router = APIRouter(prefix="/entrega-llaves", tags=["Entrega de Llaves"])

_STEP_KEY = "KEY_HANDOVER"
_S_PENDING   = "pending"
_S_PARTIAL   = "partial"
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
        step_order=7,
        step_key=_STEP_KEY,
        label="Entrega de Llaves",
        description="Entrega fisica de las llaves y firma del acta de entrega.",
        required_role="BOTH",
        status=StepStatus.PENDING,
        metadata_json={"handover_status": _S_PENDING},
    )
    db.add(step)
    db.commit()
    db.refresh(step)
    return step


# ─── Schemas ──────────────────────────────────────────────────────────────────

class EntregaLlavesStatusResponse(BaseModel):
    offer_id: int
    handover_status: str
    buyer_confirmed: bool
    seller_confirmed: bool
    buyer_confirmed_at: str | None
    seller_confirmed_at: str | None


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.get("/{offer_id}/status", response_model=EntregaLlavesStatusResponse)
async def get_entrega_llaves_status(
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
        return EntregaLlavesStatusResponse(
            offer_id=offer_id,
            handover_status=_S_PENDING,
            buyer_confirmed=False,
            seller_confirmed=False,
            buyer_confirmed_at=None,
            seller_confirmed_at=None,
        )

    meta = step.metadata_json or {}
    return EntregaLlavesStatusResponse(
        offer_id=offer_id,
        handover_status=meta.get("handover_status", _S_PENDING),
        buyer_confirmed=step.buyer_confirmed_at is not None,
        seller_confirmed=step.seller_confirmed_at is not None,
        buyer_confirmed_at=(
            step.buyer_confirmed_at.isoformat() if step.buyer_confirmed_at else None
        ),
        seller_confirmed_at=(
            step.seller_confirmed_at.isoformat() if step.seller_confirmed_at else None
        ),
    )


@router.post("/{offer_id}/confirm")
async def confirm_entrega_llaves(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Comprador o vendedor confirma la entrega de llaves.
    Cuando ambos confirman:
      - KEY_HANDOVER step -> COMPLETED
      - offer.status -> 'completed'
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

    both_confirmed = step.buyer_confirmed_at and step.seller_confirmed_at

    if both_confirmed:
        meta["handover_status"] = _S_COMPLETED
        meta["completed_at"] = now.isoformat()
        step.status = StepStatus.COMPLETED
        # Avanzar la oferta a 'completed'
        offer.status = OfferStatus.COMPLETED
    else:
        meta["handover_status"] = _S_PARTIAL
        step.status = StepStatus.PARTIALLY_COMPLETED

    step.metadata_json = meta
    flag_modified(step, "metadata_json")
    db.commit()
    db.refresh(step)

    return {
        "offer_id": offer_id,
        "handover_status": meta["handover_status"],
        "buyer_confirmed": step.buyer_confirmed_at is not None,
        "seller_confirmed": step.seller_confirmed_at is not None,
        "offer_completed": bool(both_confirmed),
    }

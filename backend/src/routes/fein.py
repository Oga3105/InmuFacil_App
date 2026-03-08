"""
FEIN (Ficha Europea de Informacion Normalizada) confirmation endpoint.
@Shield: RBAC — buyer or seller of the offer only.
@Jules: Gate — accessible only when TASACION_APPOINTMENT step is COMPLETED.
"""
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from backend.src.config.database import get_db
from backend.src.utils.security import get_current_active_user
from backend.src.models.users import User
from backend.src.models.offers import PropertyOffer
from backend.src.models.timeline import TransactionStep, StepStatus

router = APIRouter(prefix="/fein", tags=["FEIN"])


# ─── Internal helpers ─────────────────────────────────────────────────────────

def _get_tasacion_step_status(offer_id: int, db: Session) -> StepStatus:
    """Returns status of the TASACION_APPOINTMENT step for the offer."""
    step = (
        db.query(TransactionStep)
        .filter(
            TransactionStep.offer_id == offer_id,
            TransactionStep.step_key == "TASACION_APPOINTMENT",
        )
        .first()
    )
    if step is None:
        # If step doesn't exist (old data), fall back to MORTGAGE_APPROVAL
        step = (
            db.query(TransactionStep)
            .filter(
                TransactionStep.offer_id == offer_id,
                TransactionStep.step_key == "MORTGAGE_APPROVAL",
            )
            .first()
        )
    return step.status if step else StepStatus.PENDING


def _require_tasacion_completed(offer_id: int, db: Session) -> None:
    """Raises 403 if TASACION_APPOINTMENT step is not COMPLETED."""
    step_status = _get_tasacion_step_status(offer_id, db)
    if step_status != StepStatus.COMPLETED:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="La formalizacion bancaria (FEIN) requiere que la tasacion "
                   "este completada previamente.",
        )


def _get_offer_or_404(offer_id: int, db: Session) -> PropertyOffer:
    offer = db.query(PropertyOffer).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Oferta no encontrada.")
    return offer


def _require_participant(offer: PropertyOffer, user: User) -> None:
    is_buyer  = offer.buyer_id == user.id
    is_seller = offer.property.owner_id == user.id
    if not (is_buyer or is_seller):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo las partes de la oferta pueden acceder.",
        )


def _confirm_fein_step(offer_id: int, user_id: int, role: str, notes: str, db: Session) -> dict:
    """
    Confirms the FEIN step for the given role.
    Uses MORTGAGE_APPROVAL or FEIN_CONFIRMATION step key.
    """
    step = (
        db.query(TransactionStep)
        .filter(
            TransactionStep.offer_id == offer_id,
            TransactionStep.step_key.in_(["FEIN_CONFIRMATION", "MORTGAGE_APPROVAL"]),
        )
        .first()
    )

    if not step:
        return {"offer_id": offer_id, "fein_status": "step_not_initialized"}

    if step.status == StepStatus.COMPLETED:
        return {"offer_id": offer_id, "fein_status": "already_completed"}

    now = datetime.now(timezone.utc)
    metadata = step.metadata_json or {}

    if role.upper() == "BUYER":
        step.buyer_confirmed_at = now
        metadata["buyer_fein_log"] = {"user_id": user_id, "notes": notes, "at": str(now)}
    elif role.upper() == "SELLER":
        step.seller_confirmed_at = now
        metadata["seller_fein_log"] = {"user_id": user_id, "notes": notes, "at": str(now)}

    step.metadata_json = metadata

    if step.buyer_confirmed_at and step.seller_confirmed_at:
        step.status = StepStatus.COMPLETED
    elif step.buyer_confirmed_at or step.seller_confirmed_at:
        step.status = StepStatus.PARTIALLY_COMPLETED

    db.commit()
    db.refresh(step)

    return {
        "offer_id": offer_id,
        "fein_status": step.status.value,
        "step_id": step.id,
    }


# ─── Schemas ──────────────────────────────────────────────────────────────────

class FeinConfirmRequest(BaseModel):
    role: str  # BUYER or SELLER
    notes: Optional[str] = None


class FeinStatusResponse(BaseModel):
    offer_id: int
    tasacion_completed: bool
    fein_status: str
    buyer_confirmed: bool
    seller_confirmed: bool


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.get("/{offer_id}/status", response_model=FeinStatusResponse)
async def get_fein_status(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Get the current FEIN confirmation status for an offer.
    Gate: TASACION_APPOINTMENT must be COMPLETED.
    """
    _require_tasacion_completed(offer_id, db)
    offer = _get_offer_or_404(offer_id, db)
    _require_participant(offer, current_user)

    fein_step = (
        db.query(TransactionStep)
        .filter(
            TransactionStep.offer_id == offer_id,
            TransactionStep.step_key.in_(["FEIN_CONFIRMATION", "MORTGAGE_APPROVAL"]),
        )
        .first()
    )

    return FeinStatusResponse(
        offer_id=offer_id,
        tasacion_completed=True,
        fein_status=fein_step.status.value if fein_step else "not_initialized",
        buyer_confirmed=fein_step.buyer_confirmed_at is not None if fein_step else False,
        seller_confirmed=fein_step.seller_confirmed_at is not None if fein_step else False,
    )


@router.post("/{offer_id}/confirm")
async def confirm_fein(
    offer_id: int,
    body: FeinConfirmRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Confirm FEIN receipt/acknowledgment for buyer or seller.
    Gate: TASACION_APPOINTMENT must be COMPLETED.
    RBAC: Only buyer or seller of the offer.
    """
    _require_tasacion_completed(offer_id, db)
    offer = _get_offer_or_404(offer_id, db)
    _require_participant(offer, current_user)

    if body.role.upper() not in ("BUYER", "SELLER"):
        raise HTTPException(status_code=422, detail="Rol invalido. Use BUYER o SELLER.")

    return _confirm_fein_step(offer_id, current_user.id, body.role, body.notes or "", db)

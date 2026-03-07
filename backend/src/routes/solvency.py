"""
Solvency Router — Pasaporte de Solvencia Consciente
Handles buyer self-qualification and anonymised seller passport views.

Endpoints:
  GET  /solvency/me                       Buyer: fetch own passport
  POST /solvency/me                       Buyer: create/update passport (wizard)
  GET  /solvency/offer/{offer_id}/buyer   Seller: anonymised buyer passport for an offer
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field, ConfigDict
from sqlalchemy.orm import Session

from backend.src.config.database import get_db
from backend.src.models import User, PropertyOffer, Property, BuyerSolvency
from backend.src.models.enums import PaymentMethod, StressIndex, SolvencyLevel
from backend.src.utils.crypto import encrypt_data, decrypt_data
from backend.src.utils.security import get_current_active_user

router = APIRouter(prefix="/solvency", tags=["Solvency"])

_TERMS_VERSION = "v1.0"
_DOCUMENT_TTL_DAYS = 90


# ============================================================================
# Schemas
# ============================================================================

class SolvencySubmit(BaseModel):
    """Payload from the wizard (buyer submits all answers at once)."""
    terms_accepted: bool = Field(..., description="Buyer accepted the civil-liability disclaimer")
    knows_extra_costs: bool
    debt_ratio: float = Field(..., ge=0.0, le=1.0, description="Monthly debt / net income ratio")
    has_emergency_fund: bool
    payment_method: PaymentMethod
    has_initial_savings: bool
    has_pre_approval: bool
    pre_approval_pdf_url: Optional[str] = None


class SolvencyPassport(BaseModel):
    """Full passport visible to the buyer themselves."""
    model_config = ConfigDict(from_attributes=True)

    id: int
    buyer_id: int
    terms_accepted_at: Optional[datetime]
    terms_version_id: Optional[str]
    knows_extra_costs: Optional[bool]
    debt_ratio: Optional[float]
    has_emergency_fund: Optional[bool]
    payment_method: Optional[str]
    has_initial_savings: Optional[bool]
    has_pre_approval: Optional[bool]
    stress_index: Optional[str]
    solvency_level: Optional[str]
    created_at: Optional[datetime]
    expires_at: Optional[datetime]
    # pre_approval_pdf_url is decrypted and returned only here
    pre_approval_pdf_url: Optional[str] = None


class AnonymisedPassport(BaseModel):
    """Anonymised view for the seller — no salary or private data."""
    solvency_level: Optional[str]
    stress_index: Optional[str]
    knows_extra_costs: bool
    has_initial_savings: bool
    has_pre_approval: bool
    payment_method: Optional[str]
    expires_at: Optional[datetime]
    buyer_id: int


# ============================================================================
# Score computation
# ============================================================================

def _compute_solvency(data: SolvencySubmit) -> tuple[StressIndex, SolvencyLevel]:
    score = 0

    if data.knows_extra_costs:
        score += 1
    if data.debt_ratio < 0.35:
        score += 1
    if data.has_emergency_fund:
        score += 1
    if data.has_initial_savings:
        score += 1
    if data.payment_method in (PaymentMethod.CASH, PaymentMethod.MORTGAGE_APPROVED):
        score += 2
    elif data.payment_method == PaymentMethod.MORTGAGE_PENDING:
        score += 1
    if data.has_pre_approval:
        score += 1

    if data.debt_ratio > 0.38:
        stress = StressIndex.HIGH_RISK
    elif data.debt_ratio > 0.35:
        stress = StressIndex.MEDIUM_RISK
    else:
        stress = StressIndex.LOW_RISK

    if score >= 6:
        level = SolvencyLevel.GOLD
    elif score >= 4:
        level = SolvencyLevel.SILVER
    else:
        level = SolvencyLevel.BRONZE

    return stress, level


# ============================================================================
# Endpoints
# ============================================================================

@router.get("/me", response_model=SolvencyPassport)
async def get_my_solvency(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Buyer retrieves their own solvency passport."""
    record = db.query(BuyerSolvency).filter(
        BuyerSolvency.buyer_id == current_user.id
    ).first()
    if not record:
        raise HTTPException(status_code=404, detail="Passport not found. Complete the wizard first.")

    pdf_url = None
    if record.pre_approval_pdf_url_encrypted:
        try:
            pdf_url = decrypt_data(record.pre_approval_pdf_url_encrypted)
        except Exception:
            pdf_url = None

    return SolvencyPassport(
        id=record.id,
        buyer_id=record.buyer_id,
        terms_accepted_at=record.terms_accepted_at,
        terms_version_id=record.terms_version_id,
        knows_extra_costs=record.knows_extra_costs,
        debt_ratio=record.debt_ratio,
        has_emergency_fund=record.has_emergency_fund,
        payment_method=record.payment_method.value if record.payment_method else None,
        has_initial_savings=record.has_initial_savings,
        has_pre_approval=record.has_pre_approval,
        stress_index=record.stress_index.value if record.stress_index else None,
        solvency_level=record.solvency_level.value if record.solvency_level else None,
        created_at=record.created_at,
        expires_at=record.expires_at,
        pre_approval_pdf_url=pdf_url,
    )


@router.post("/me", response_model=SolvencyPassport, status_code=status.HTTP_201_CREATED)
async def submit_solvency(
    body: SolvencySubmit,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Buyer submits (or re-submits) the solvency wizard.
    Creates or fully replaces the existing record (UPSERT).
    """
    if not body.terms_accepted:
        raise HTTPException(
            status_code=400,
            detail="Debes aceptar los terminos de responsabilidad antes de continuar.",
        )

    stress, level = _compute_solvency(body)

    encrypted_pdf: Optional[str] = None
    if body.pre_approval_pdf_url:
        encrypted_pdf = encrypt_data(body.pre_approval_pdf_url)

    now = datetime.now(timezone.utc)
    expires = now + timedelta(days=_DOCUMENT_TTL_DAYS)

    record = db.query(BuyerSolvency).filter(
        BuyerSolvency.buyer_id == current_user.id
    ).first()

    if record:
        record.terms_accepted_at = now
        record.terms_version_id = _TERMS_VERSION
        record.knows_extra_costs = body.knows_extra_costs
        record.debt_ratio = body.debt_ratio
        record.has_emergency_fund = body.has_emergency_fund
        record.payment_method = body.payment_method
        record.has_initial_savings = body.has_initial_savings
        record.has_pre_approval = body.has_pre_approval
        record.pre_approval_pdf_url_encrypted = encrypted_pdf
        record.stress_index = stress
        record.solvency_level = level
        record.expires_at = expires
    else:
        record = BuyerSolvency(
            buyer_id=current_user.id,
            terms_accepted_at=now,
            terms_version_id=_TERMS_VERSION,
            knows_extra_costs=body.knows_extra_costs,
            debt_ratio=body.debt_ratio,
            has_emergency_fund=body.has_emergency_fund,
            payment_method=body.payment_method,
            has_initial_savings=body.has_initial_savings,
            has_pre_approval=body.has_pre_approval,
            pre_approval_pdf_url_encrypted=encrypted_pdf,
            stress_index=stress,
            solvency_level=level,
            expires_at=expires,
        )
        db.add(record)

    db.commit()
    db.refresh(record)

    pdf_url = None
    if record.pre_approval_pdf_url_encrypted:
        try:
            pdf_url = decrypt_data(record.pre_approval_pdf_url_encrypted)
        except Exception:
            pdf_url = None

    return SolvencyPassport(
        id=record.id,
        buyer_id=record.buyer_id,
        terms_accepted_at=record.terms_accepted_at,
        terms_version_id=record.terms_version_id,
        knows_extra_costs=record.knows_extra_costs,
        debt_ratio=record.debt_ratio,
        has_emergency_fund=record.has_emergency_fund,
        payment_method=record.payment_method.value if record.payment_method else None,
        has_initial_savings=record.has_initial_savings,
        has_pre_approval=record.has_pre_approval,
        stress_index=record.stress_index.value if record.stress_index else None,
        solvency_level=record.solvency_level.value if record.solvency_level else None,
        created_at=record.created_at,
        expires_at=record.expires_at,
        pre_approval_pdf_url=pdf_url,
    )


@router.get("/offer/{offer_id}/buyer", response_model=AnonymisedPassport)
async def get_buyer_passport_for_offer(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Seller retrieves the anonymised solvency passport of the buyer for a
    specific offer. Only the seller (property owner) may call this.
    Returns 404 if the buyer has not submitted a passport.
    """
    offer = (
        db.query(PropertyOffer)
        .join(Property)
        .filter(PropertyOffer.id == offer_id)
        .first()
    )
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")

    is_seller = offer.property.owner_id == current_user.id
    if not is_seller:
        raise HTTPException(status_code=403, detail="Solo el vendedor puede ver este pasaporte")

    record = db.query(BuyerSolvency).filter(
        BuyerSolvency.buyer_id == offer.buyer_id
    ).first()
    if not record:
        raise HTTPException(
            status_code=404,
            detail="El comprador no ha completado su Pasaporte de Solvencia todavia.",
        )

    return AnonymisedPassport(
        solvency_level=record.solvency_level.value if record.solvency_level else None,
        stress_index=record.stress_index.value if record.stress_index else None,
        knows_extra_costs=bool(record.knows_extra_costs),
        has_initial_savings=bool(record.has_initial_savings),
        has_pre_approval=bool(record.has_pre_approval),
        payment_method=record.payment_method.value if record.payment_method else None,
        expires_at=record.expires_at,
        buyer_id=record.buyer_id,
    )

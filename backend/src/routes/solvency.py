"""
Solvency Router — Pasaporte de Solvencia Consciente
Handles buyer self-qualification and anonymised seller passport views.

Endpoints:
  GET  /solvency/me                          Buyer: fetch own passport
  POST /solvency/me                          Buyer: create/update passport (wizard)
  GET  /solvency/viability/{property_id}     Buyer: property-specific viability calculation
  POST /solvency/offer/{offer_id}/accept     Seller: accept buyer solvency to unlock timeline
  GET  /solvency/offer/{offer_id}/buyer      Seller: anonymised buyer passport for an offer
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
    # ADN Financiero (Sprint V9) — quantitative fields, optional for backward compat
    # For multi-buyer purchases these values represent the TOTAL of all buyers combined.
    net_monthly_income: Optional[int] = Field(None, ge=0, description="EUR net monthly income (total of all buyers)")
    total_savings: Optional[int] = Field(None, ge=0, description="EUR total liquid savings (total of all buyers)")
    total_monthly_debt: Optional[int] = Field(None, ge=0, description="EUR existing monthly debt obligations (total)")
    # Multi-buyer flag (Sprint V10)
    is_multi_buyer: bool = Field(False, description="True when two or more buyers purchase jointly")


class PropertyViability(BaseModel):
    """Buyer-specific viability result for a given property. Never sent to seller."""
    property_id: int
    property_price: int
    # Entry cost = price * 1.12 (10% taxes ITP/IVA + 2% notary/registry)
    entry_cost_estimate: int
    # Viability verdict
    verdict: str          # "green" | "amber" | "red" | "insufficient_data"
    verdict_label: str    # Human-readable Spanish label
    # Breakdown (shown to buyer only)
    savings_coverage_pct: Optional[float] = None   # savings / entry_cost * 100
    dti_ratio: Optional[float] = None              # total_monthly_payment / net_income
    monthly_mortgage_estimate: Optional[int] = None
    # Privacy flag: quantitative data available
    has_financial_dna: bool


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
    # Multi-buyer (Sprint V10)
    is_multi_buyer: bool = False
    # Derived: True when a second identity verification is required in the timeline
    needs_second_identity_verification: bool = False


_PAYMENT_METHOD_LABELS: dict[str, str] = {
    "cash": "Pago al contado",
    "mortgage_pending": "Hipoteca en tramitacion",
    "mortgage_approved": "Hipoteca aprobada",
    "house_to_sell": "Venta de vivienda actual",
    "savings_plus_mortgage": "Ahorros + hipoteca",
    "bridge_mortgage": "Hipoteca puente",
}


class AnonymisedPassport(BaseModel):
    """Anonymised view for the seller — no salary or private data."""
    solvency_level: Optional[str]
    stress_index: Optional[str]
    knows_extra_costs: bool
    has_initial_savings: bool
    has_pre_approval: bool
    payment_method: Optional[str]
    payment_method_label: Optional[str] = None   # Human-readable label (Sprint V12)
    expires_at: Optional[datetime]
    buyer_id: int
    is_multi_buyer: bool = False                  # Sprint V12


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
    elif data.payment_method in (PaymentMethod.MORTGAGE_PENDING, PaymentMethod.SAVINGS_PLUS_MORTGAGE):
        score += 1
    # HOUSE_TO_SELL and BRIDGE_MORTGAGE score 0 (highest uncertainty)
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

    is_multi = bool(record.is_multi_buyer)
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
        is_multi_buyer=is_multi,
        needs_second_identity_verification=is_multi,
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

    # Encrypt ADN Financiero fields (Sprint V9)
    enc_income = encrypt_data(str(body.net_monthly_income)) if body.net_monthly_income is not None else None
    enc_savings = encrypt_data(str(body.total_savings)) if body.total_savings is not None else None
    enc_debt = encrypt_data(str(body.total_monthly_debt)) if body.total_monthly_debt is not None else None

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
        record.net_monthly_income_enc = enc_income
        record.total_savings_enc = enc_savings
        record.total_monthly_debt_enc = enc_debt
        record.is_multi_buyer = body.is_multi_buyer
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
            net_monthly_income_enc=enc_income,
            total_savings_enc=enc_savings,
            total_monthly_debt_enc=enc_debt,
            is_multi_buyer=body.is_multi_buyer,
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

    is_multi = bool(record.is_multi_buyer)
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
        is_multi_buyer=is_multi,
        needs_second_identity_verification=is_multi,
    )


# ── Mortgage payment formula (30 years, 3% annual rate) ──────────────────────
_ANNUAL_RATE = 0.03
_MONTHS = 360


def _monthly_mortgage(principal: float) -> int:
    """Calculates monthly payment using standard amortization formula."""
    r = _ANNUAL_RATE / 12
    payment = principal * r * (1 + r) ** _MONTHS / ((1 + r) ** _MONTHS - 1)
    return int(payment)


def _decrypt_int(enc: Optional[str]) -> Optional[int]:
    if not enc:
        return None
    try:
        return int(decrypt_data(enc))
    except Exception:
        return None


@router.get("/viability/{property_id}", response_model=PropertyViability)
async def get_property_viability(
    property_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Buyer-only: calculates property-specific financial viability.
    Privacy: this result is NEVER shared with the seller.
    Formula:
      entry_cost = price * 1.12  (10% taxes + 2% notary/registry)
      mortgage   = price * 0.80  (80% LTV)
      monthly_mortgage = amortization(mortgage, 30yr, 3%)
      dti = (monthly_mortgage + total_monthly_debt) / net_monthly_income
      verdict = green if savings >= entry_cost*0.20 AND dti <= 0.35
                amber  if savings >= entry_cost*0.15 AND dti <= 0.40
                red    otherwise
    """
    prop = db.query(Property).filter(Property.id == property_id).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")

    passport = db.query(BuyerSolvency).filter(
        BuyerSolvency.buyer_id == current_user.id
    ).first()

    price = int(prop.price)
    entry_cost = int(price * 1.12)

    if not passport:
        return PropertyViability(
            property_id=property_id,
            property_price=price,
            entry_cost_estimate=entry_cost,
            verdict="insufficient_data",
            verdict_label="Completa tu Pasaporte de Solvencia para ver tu viabilidad",
            has_financial_dna=False,
        )

    income = _decrypt_int(passport.net_monthly_income_enc)
    savings = _decrypt_int(passport.total_savings_enc)
    debt = _decrypt_int(passport.total_monthly_debt_enc) or 0

    if income is None or savings is None:
        # Qualitative passport exists but no quantitative ADN Financiero
        return PropertyViability(
            property_id=property_id,
            property_price=price,
            entry_cost_estimate=entry_cost,
            verdict="insufficient_data",
            verdict_label="Actualiza tu pasaporte con tus datos financieros para ver la viabilidad exacta",
            has_financial_dna=False,
        )

    mortgage_principal = price * 0.80
    monthly_mortgage = _monthly_mortgage(mortgage_principal)
    total_monthly_payment = monthly_mortgage + debt
    dti = total_monthly_payment / income if income > 0 else 999.0
    savings_pct = savings / entry_cost * 100 if entry_cost > 0 else 0.0

    # Verdict logic
    savings_ok = savings >= entry_cost * 0.20  # Covers at least 20% entry
    savings_min = savings >= entry_cost * 0.15  # Covers at least 15% entry
    if savings_ok and dti <= 0.35:
        verdict = "green"
        verdict_label = "Viabilidad alta — cumples los criterios bancarios estandar"
    elif savings_min and dti <= 0.40:
        verdict = "amber"
        verdict_label = "Viabilidad media — posible con buen historial crediticio"
    else:
        verdict = "red"
        verdict_label = "Viabilidad baja — cuota o ahorros por debajo del umbral recomendado"

    return PropertyViability(
        property_id=property_id,
        property_price=price,
        entry_cost_estimate=entry_cost,
        verdict=verdict,
        verdict_label=verdict_label,
        savings_coverage_pct=round(savings_pct, 1),
        dti_ratio=round(dti, 3),
        monthly_mortgage_estimate=monthly_mortgage,
        has_financial_dna=True,
    )


@router.post("/offer/{offer_id}/accept", status_code=status.HTTP_200_OK)
async def seller_accept_solvency(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Seller accepts the buyer solvency passport to allow the timeline to advance.
    Only the property owner (seller) may call this endpoint.
    """
    offer = (
        db.query(PropertyOffer)
        .join(Property)
        .filter(PropertyOffer.id == offer_id)
        .first()
    )
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")

    if offer.property.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Solo el vendedor puede aceptar la solvencia")

    buyer_passport = db.query(BuyerSolvency).filter(
        BuyerSolvency.buyer_id == offer.buyer_id
    ).first()
    if not buyer_passport:
        raise HTTPException(
            status_code=404,
            detail="El comprador no ha completado su Pasaporte de Solvencia todavia.",
        )

    from backend.src.models.offers import PropertyOffer as _Offer
    offer.seller_solvency_accepted = True
    offer.seller_solvency_accepted_at = datetime.now(timezone.utc)
    db.commit()

    return {
        "status": "accepted",
        "offer_id": offer_id,
        "accepted_at": offer.seller_solvency_accepted_at.isoformat(),
    }


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

    pm_value = record.payment_method.value if record.payment_method else None
    return AnonymisedPassport(
        solvency_level=record.solvency_level.value if record.solvency_level else None,
        stress_index=record.stress_index.value if record.stress_index else None,
        knows_extra_costs=bool(record.knows_extra_costs),
        has_initial_savings=bool(record.has_initial_savings),
        has_pre_approval=bool(record.has_pre_approval),
        payment_method=pm_value,
        payment_method_label=_PAYMENT_METHOD_LABELS.get(pm_value) if pm_value else None,
        expires_at=record.expires_at,
        buyer_id=record.buyer_id,
        is_multi_buyer=bool(record.is_multi_buyer),
    )

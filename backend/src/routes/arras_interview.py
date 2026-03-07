"""
ArrasInterview Router — Entrevista dinamica para el Contrato de Arras Penitenciales.

Endpoints:
  GET  /arras/{offer_id}            Obtener entrevista actual (buyer o seller)
  POST /arras/{offer_id}            Guardar respuestas parciales (buyer o seller)
  POST /arras/{offer_id}/confirm    Confirmar entrevista (buyer o seller)
  GET  /arras/{offer_id}/pdf        Descargar borrador PDF (solo si ambos confirmaron)
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
import io

from backend.src.config.database import get_db
from backend.src.models import User, PropertyOffer, Property
from backend.src.models.arras_interview import ArrasInterview
from backend.src.utils.security import get_current_active_user

router = APIRouter(prefix="/arras", tags=["Arras Interview"])


# ============================================================================
# Schemas
# ============================================================================

class ArrasAnswers(BaseModel):
    deposit_percentage: Optional[int] = Field(None, ge=1, le=30)
    deadline_days: Optional[int] = Field(None, ge=15, le=180)
    additional_conditions: Optional[str] = None
    payment_method: Optional[str] = None
    notary_city: Optional[str] = None
    extra_answers_json: Optional[dict] = None


class ArrasInterviewResponse(BaseModel):
    id: int
    offer_id: int
    deposit_percentage: Optional[int]
    deposit_amount: Optional[int]
    deadline_days: Optional[int]
    additional_conditions: Optional[str]
    payment_method: Optional[str]
    notary_city: Optional[str]
    buyer_confirmed: bool
    buyer_confirmed_at: Optional[datetime]
    seller_confirmed: bool
    seller_confirmed_at: Optional[datetime]
    draft_pdf_path: Optional[str]
    is_complete: bool

    class Config:
        from_attributes = True


def _compute_deposit(offer_amount: int, percentage: Optional[int]) -> Optional[int]:
    if percentage is None:
        return None
    return int(offer_amount * percentage / 100)


def _serialize(record: ArrasInterview) -> ArrasInterviewResponse:
    return ArrasInterviewResponse(
        id=record.id,
        offer_id=record.offer_id,
        deposit_percentage=record.deposit_percentage,
        deposit_amount=record.deposit_amount,
        deadline_days=record.deadline_days,
        additional_conditions=record.additional_conditions,
        payment_method=record.payment_method,
        notary_city=record.notary_city,
        buyer_confirmed=bool(record.buyer_confirmed),
        buyer_confirmed_at=record.buyer_confirmed_at,
        seller_confirmed=bool(record.seller_confirmed),
        seller_confirmed_at=record.seller_confirmed_at,
        draft_pdf_path=record.draft_pdf_path,
        is_complete=bool(record.buyer_confirmed and record.seller_confirmed),
    )


def _get_offer_and_role(offer_id: int, current_user: User, db: Session):
    """Fetch offer and determine caller role. Raises 403/404 as needed."""
    offer = (
        db.query(PropertyOffer)
        .filter(PropertyOffer.id == offer_id)
        .first()
    )
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")

    if current_user.id == offer.buyer_id:
        return offer, "BUYER"
    if offer.property and offer.property.owner_id == current_user.id:
        return offer, "SELLER"

    raise HTTPException(status_code=403, detail="No autorizado para esta entrevista")


# ============================================================================
# Endpoints
# ============================================================================

@router.get("/{offer_id}", response_model=ArrasInterviewResponse)
async def get_interview(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Retrieve the current state of the arras interview for an offer."""
    offer, _ = _get_offer_and_role(offer_id, current_user, db)

    record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()
    if not record:
        # Return an empty interview so the UI can start filling answers
        return ArrasInterviewResponse(
            id=0,
            offer_id=offer_id,
            deposit_percentage=None,
            deposit_amount=None,
            deadline_days=None,
            additional_conditions=None,
            payment_method=None,
            notary_city=None,
            buyer_confirmed=False,
            buyer_confirmed_at=None,
            seller_confirmed=False,
            seller_confirmed_at=None,
            draft_pdf_path=None,
            is_complete=False,
        )

    return _serialize(record)


@router.post("/{offer_id}", response_model=ArrasInterviewResponse)
async def save_answers(
    offer_id: int,
    body: ArrasAnswers,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Save (partial) interview answers. Either party can save answers before confirming.
    Saving resets their confirmation flag — must re-confirm after any edit.
    """
    offer, role = _get_offer_and_role(offer_id, current_user, db)

    record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()

    if not record:
        record = ArrasInterview(offer_id=offer_id)
        db.add(record)

    # Apply answers
    if body.deposit_percentage is not None:
        record.deposit_percentage = body.deposit_percentage
        record.deposit_amount = _compute_deposit(int(offer.amount), body.deposit_percentage)
    if body.deadline_days is not None:
        record.deadline_days = body.deadline_days
    if body.additional_conditions is not None:
        record.additional_conditions = body.additional_conditions
    if body.payment_method is not None:
        record.payment_method = body.payment_method
    if body.notary_city is not None:
        record.notary_city = body.notary_city
    if body.extra_answers_json is not None:
        record.extra_answers_json = body.extra_answers_json

    # Reset confirmation for the role that just edited
    if role == "BUYER":
        record.buyer_confirmed = False
        record.buyer_confirmed_at = None
    else:
        record.seller_confirmed = False
        record.seller_confirmed_at = None

    db.commit()
    db.refresh(record)
    return _serialize(record)


@router.post("/{offer_id}/confirm", response_model=ArrasInterviewResponse)
async def confirm_interview(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Confirm the interview. When both parties confirm, the draft PDF is generated.
    Minimum required fields: deposit_percentage and deadline_days.
    """
    offer, role = _get_offer_and_role(offer_id, current_user, db)

    record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()
    if not record:
        raise HTTPException(status_code=400, detail="Debes guardar las respuestas antes de confirmar")

    if record.deposit_percentage is None or record.deadline_days is None:
        raise HTTPException(
            status_code=400,
            detail="Debes completar al menos el porcentaje de arras y el plazo antes de confirmar",
        )

    now = datetime.now(timezone.utc)

    if role == "BUYER":
        record.buyer_confirmed = True
        record.buyer_confirmed_at = now
    else:
        record.seller_confirmed = True
        record.seller_confirmed_at = now

    # If both confirmed, generate PDF draft
    if record.buyer_confirmed and record.seller_confirmed:
        record.draft_pdf_path = _generate_draft_pdf(offer, record)

    db.commit()
    db.refresh(record)
    return _serialize(record)


@router.get("/{offer_id}/pdf")
async def download_draft_pdf(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Download the agreed arras draft PDF. Requires both parties to have confirmed."""
    offer, _ = _get_offer_and_role(offer_id, current_user, db)

    record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()
    if not record or not (record.buyer_confirmed and record.seller_confirmed):
        raise HTTPException(
            status_code=400,
            detail="El PDF solo esta disponible cuando ambas partes han confirmado la entrevista",
        )

    pdf_bytes = _generate_pdf_bytes(offer, record)

    return StreamingResponse(
        io.BytesIO(pdf_bytes),
        media_type="application/pdf",
        headers={
            "Content-Disposition": f"attachment; filename=arras_borrador_{offer_id}.pdf"
        },
    )


# ============================================================================
# PDF Generation (simple text-based draft — extend with reportlab/weasyprint)
# ============================================================================

def _generate_draft_pdf(offer: PropertyOffer, record: ArrasInterview) -> str:
    """
    Generate PDF and persist to disk. Returns the file path.
    Uses ContractGenerator if available; falls back to a plain text stub.
    """
    import os
    from datetime import timedelta

    try:
        from backend.src.services.contract_service import ContractGenerator
        buyer = offer.buyer
        prop = offer.property
        seller = prop.owner if prop else None

        limit_date = datetime.now() + timedelta(days=record.deadline_days or 60)

        pdf_bytes = ContractGenerator.generate_arras_draft(
            buyer_name=buyer.full_name if buyer else "Comprador",
            buyer_dni="",
            seller_name=seller.full_name if seller else "Vendedor",
            seller_dni="",
            property_address=prop.location if prop else "",
            property_registry_ref="",
            price_total=float(offer.amount),
            deposit_amount=float(record.deposit_amount or 0),
            limit_date=limit_date,
            contract_data={
                "additional_conditions": record.additional_conditions or "",
                "notary_city": record.notary_city or "",
            },
        )
    except Exception:
        # Stub fallback
        content = (
            f"BORRADOR CONTRATO DE ARRAS PENITENCIALES\n"
            f"Oferta: {offer.id}\n"
            f"Importe: {offer.amount} EUR\n"
            f"Arras: {record.deposit_amount} EUR ({record.deposit_percentage}%)\n"
            f"Plazo: {record.deadline_days} dias\n"
        )
        pdf_bytes = content.encode("utf-8")

    upload_dir = "uploads/arras"
    os.makedirs(upload_dir, exist_ok=True)
    path = f"{upload_dir}/arras_borrador_{offer.id}.pdf"
    with open(path, "wb") as f:
        f.write(pdf_bytes)

    return path


def _generate_pdf_bytes(offer: PropertyOffer, record: ArrasInterview) -> bytes:
    """Return PDF bytes for streaming download."""
    import os
    if record.draft_pdf_path and os.path.exists(record.draft_pdf_path):
        with open(record.draft_pdf_path, "rb") as f:
            return f.read()
    # Regenerate on the fly if file missing
    _generate_draft_pdf(offer, record)
    if record.draft_pdf_path and os.path.exists(record.draft_pdf_path):
        with open(record.draft_pdf_path, "rb") as f:
            return f.read()
    return b""

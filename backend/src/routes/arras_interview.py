"""
ArrasInterview Router — Entrevista dual comprador/vendedor + contrato IA.

Endpoints:
  GET  /arras/{offer_id}                  Estado completo de la entrevista
  POST /arras/{offer_id}                  Guardar respuestas genericas (legacy)
  POST /arras/{offer_id}/buyer            Guardar entrevista del comprador
  POST /arras/{offer_id}/seller           Guardar entrevista del vendedor
  POST /arras/{offer_id}/buyer/confirm    Comprador confirma su entrevista
  POST /arras/{offer_id}/seller/confirm   Vendedor confirma su entrevista
  POST /arras/{offer_id}/contract/accept  Aceptar el contrato generado por IA
  POST /arras/{offer_id}/contract/reject  Rechazar contrato y pedir cambios
  POST /arras/{offer_id}/contract/regenerate  Forzar regeneracion del contrato
  GET  /arras/{offer_id}/equity           Analisis de equidad por rol (cached)
  GET  /arras/{offer_id}/pdf              Descargar borrador PDF
"""
from __future__ import annotations

import json
import logging
import os
from datetime import datetime, timezone
from typing import Optional, List

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
import io

from backend.src.config.database import get_db, SessionLocal
from backend.src.models import User, PropertyOffer, Property
from backend.src.models.arras_interview import ArrasInterview
from backend.src.utils.crypto import encrypt_data, decrypt_data
from backend.src.utils.security import get_current_active_user

router = APIRouter(prefix="/arras", tags=["Arras Interview"])
logger = logging.getLogger(__name__)


# ============================================================================
# Schemas
# ============================================================================

class ArrasAnswers(BaseModel):
    """Legacy shared answers — kept for backward compat."""
    deposit_percentage: Optional[int] = Field(None, ge=1, le=30)
    deadline_days: Optional[int] = Field(None, ge=15, le=180)
    additional_conditions: Optional[str] = None
    payment_method: Optional[str] = None
    notary_city: Optional[str] = None
    extra_answers_json: Optional[dict] = None


class BuyerArrasAnswers(BaseModel):
    deposit_percentage: int = Field(10, ge=5, le=20)
    deadline_days: int = Field(60, ge=15, le=180)
    notary_preference: Optional[str] = None
    max_signing_date: Optional[str] = None
    subject_to_mortgage: bool = False
    extension_allowed: bool = False
    extension_reasons: Optional[List[str]] = None
    ibi_proration_by_days: bool = True
    retain_pending_ibi: bool = False
    hidden_defects_accepted: bool = False
    community_debt_retention: bool = False
    payment_method: Optional[str] = None
    additional_clauses: Optional[str] = None


class SellerArrasAnswers(BaseModel):
    property_free_of_tenants: bool = True
    utilities_active: bool = True
    utilities_maintenance_commitment: bool = True
    has_approved_levies: bool = False
    levy_details: Optional[str] = None
    zero_debt_certificate: bool = True
    has_mortgage_to_cancel: bool = False
    mortgage_amount: Optional[int] = None
    plusvalia_assumed: bool = True
    ibi_retention_accepted: bool = True
    iban: Optional[str] = None
    additional_clauses: Optional[str] = None


class ContractRejectBody(BaseModel):
    notes: str = Field(..., min_length=5, max_length=2000)


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
    # V2 fields
    buyer_interview_confirmed: bool = False
    seller_interview_confirmed: bool = False
    buyer_answers_json: Optional[dict] = None
    seller_answers_json: Optional[dict] = None
    contract_text: Optional[str] = None
    contract_status: Optional[str] = None
    generation_count: int = 0
    buyer_contract_accepted: bool = False
    seller_contract_accepted: bool = False
    buyer_rejection_notes: Optional[str] = None
    seller_rejection_notes: Optional[str] = None
    # Computed helper for the timeline
    arras_status: str = "none"

    class Config:
        from_attributes = True


def _compute_deposit(offer_amount: int, percentage: Optional[int]) -> Optional[int]:
    if percentage is None:
        return None
    return int(offer_amount * percentage / 100)


def _compute_arras_status(record: ArrasInterview) -> str:
    """Compute a single arras_status string for the timeline."""
    cs = record.contract_status or ""
    if cs == "fully_accepted":
        return "accepted"
    if cs in ("ready", "buyer_accepted", "seller_accepted"):
        return "contract_ready"
    if cs == "generating":
        return "generating"
    if cs == "error":
        return "error"
    b = bool(record.buyer_interview_confirmed)
    s = bool(record.seller_interview_confirmed)
    if b and s:
        return "both_done"
    if b:
        return "buyer_done"
    if s:
        return "seller_done"
    return "none"


def _serialize(record: ArrasInterview, offer_amount: int = 0) -> ArrasInterviewResponse:
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
        buyer_interview_confirmed=bool(record.buyer_interview_confirmed),
        seller_interview_confirmed=bool(record.seller_interview_confirmed),
        buyer_answers_json=record.buyer_answers_json,
        seller_answers_json=record.seller_answers_json,
        contract_text=record.contract_text,
        contract_status=record.contract_status,
        generation_count=record.generation_count or 0,
        buyer_contract_accepted=bool(record.buyer_contract_accepted),
        seller_contract_accepted=bool(record.seller_contract_accepted),
        buyer_rejection_notes=record.buyer_rejection_notes,
        seller_rejection_notes=record.seller_rejection_notes,
        arras_status=_compute_arras_status(record),
    )


def _empty_response(offer_id: int) -> ArrasInterviewResponse:
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
        arras_status="none",
    )


def _get_offer_and_role(offer_id: int, current_user: User, db: Session):
    offer = db.query(PropertyOffer).filter(PropertyOffer.id == offer_id).first()
    if not offer:
        raise HTTPException(status_code=404, detail="Oferta no encontrada")
    if current_user.id == offer.buyer_id:
        return offer, "BUYER"
    if offer.property and offer.property.owner_id == current_user.id:
        return offer, "SELLER"
    raise HTTPException(status_code=403, detail="No autorizado para esta entrevista")


# ============================================================================
# Gemini Contract Generation (BackgroundTask)
# ============================================================================

def _generate_arras_contract_gemini(offer_id: int) -> None:
    """
    Background task: generates the Arras Penitenciales contract text using Gemini.
    Triggered when both buyer and seller confirm their interviews.
    """
    api_key = os.getenv("GEMINI_API_KEY", "")
    db: Session = SessionLocal()
    try:
        record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()
        if not record:
            logger.error("Arras contract generation: no record for offer_id=%s", offer_id)
            return

        offer = db.query(PropertyOffer).filter(PropertyOffer.id == offer_id).first()
        if not offer:
            logger.error("Arras contract generation: offer not found offer_id=%s", offer_id)
            return

        buyer = offer.buyer
        prop = offer.property
        seller = prop.owner if prop else None

        buyer_name = buyer.full_name if buyer else "Comprador"
        seller_name = seller.full_name if seller else "Vendedor"
        property_address = prop.location if prop else "Inmueble objeto de la compraventa"
        offer_amount = int(offer.amount)

        ba = record.buyer_answers_json or {}
        sa = record.seller_answers_json or {}

        deposit_pct = ba.get("deposit_percentage", record.deposit_percentage or 10)
        deposit_amount = offer_amount * deposit_pct // 100
        deadline_days = ba.get("deadline_days", record.deadline_days or 60)

        # Decrypt IBAN for contract (only included as masked placeholder)
        iban_display = "ES** **** **** **** **** ****"
        if record.seller_iban_enc:
            try:
                raw_iban = decrypt_data(record.seller_iban_enc)
                if len(raw_iban) > 8:
                    iban_display = raw_iban[:4] + " **** **** **** " + raw_iban[-4:]
            except Exception:
                pass

        buyer_clauses = ba.get("additional_clauses", "")
        seller_clauses = sa.get("additional_clauses", "")

        def yn(val): return "Si" if val else "No"

        buyer_summary = f"""
- Porcentaje de arras: {deposit_pct}%
- Plazo maximo para escritura: {deadline_days} dias
- Notaria preferida: {ba.get('notary_preference', 'A determinar')}
- Fecha maxima firma: {ba.get('max_signing_date', 'Segun plazo pactado')}
- Sujeto a hipoteca: {yn(ba.get('subject_to_mortgage', False))}
- Prorrogas automaticas: {yn(ba.get('extension_allowed', False))}
- Causas de prorroga: {', '.join(ba.get('extension_reasons', [])) if ba.get('extension_reasons') else 'N/A'}
- Prorrateo IBI por dias: {yn(ba.get('ibi_proration_by_days', True))}
- Retencion IBI no emitido: {yn(ba.get('retain_pending_ibi', False))}
- Acepta clausula vicios ocultos (art. 1484 CC): {yn(ba.get('hidden_defects_accepted', False))}
- Retencion por deudas comunidad: {yn(ba.get('community_debt_retention', False))}
- Metodo de financiacion: {ba.get('payment_method', 'Por determinar')}
- Clausulas adicionales comprador: {buyer_clauses if buyer_clauses else 'Ninguna'}"""

        seller_summary = f"""
- Vivienda libre de arrendatarios: {yn(sa.get('property_free_of_tenants', True))}
- Suministros activos: {yn(sa.get('utilities_active', True))}
- Compromiso mantenimiento suministros: {yn(sa.get('utilities_maintenance_commitment', True))}
- Derramas aprobadas: {yn(sa.get('has_approved_levies', False))}
- Detalle derramas: {sa.get('levy_details', 'N/A')}
- Certificado cero deudas comunidad: {yn(sa.get('zero_debt_certificate', True))}
- Hipoteca a cancelar en firma: {yn(sa.get('has_mortgage_to_cancel', False))}
- Importe hipoteca pendiente: {sa.get('mortgage_amount', 0)} EUR
- Asume plusvalia municipal: {yn(sa.get('plusvalia_assumed', True))}
- Acepta retencion IBI: {yn(sa.get('ibi_retention_accepted', True))}
- IBAN para ingreso arras: {iban_display}
- Clausulas adicionales vendedor: {seller_clauses if seller_clauses else 'Ninguna'}"""

        prompt = f"""Eres un abogado especialista en derecho inmobiliario espanol. Genera un CONTRATO DE ARRAS PENITENCIALES completo y formal en espanol basado en los siguientes datos. El contrato debe ser riguroso, profesional y listo para revisar por las partes. No uses placeholders como "[X]" — usa los datos proporcionados.

DATOS DE LA OPERACION:
- Comprador: {buyer_name}
- Vendedor: {seller_name}
- Inmueble: {property_address}
- Precio de compraventa: {offer_amount:,} EUR
- Importe de arras ({deposit_pct}%): {deposit_amount:,} EUR
- Plazo maximo escritura: {deadline_days} dias desde la firma de arras

DECLARACIONES DEL COMPRADOR:{buyer_summary}

DECLARACIONES DEL VENDEDOR:{seller_summary}

Estructura el contrato con las siguientes secciones:
1. REUNIDOS (identificacion de partes)
2. EXPONEN
3. ESTIPULAN:
   - Primera: Objeto del contrato
   - Segunda: Precio de compraventa
   - Tercera: Arras penitenciales (importe, condiciones, penalizaciones)
   - Cuarta: Plazo y condiciones de la compraventa
   - Quinta: Condiciones suspensivas (hipoteca si aplica)
   - Sexta: Prorrogas (si aplica)
   - Septima: Gastos e impuestos (ITP/IVA, plusvalia, notaria, registro)
   - Octava: IBI y gastos de comunidad
   - Novena: Estado de la vivienda y suministros
   - Decima: Vicios ocultos
   - Undecima: Clausulas adicionales de las partes
   - Duodecima: Jurisdiccion
4. FIRMAS

Fecha del contrato: {datetime.now(timezone.utc).strftime('%d de %B de %Y')}
"""

        if not api_key:
            logger.warning("GEMINI_API_KEY not set — cannot generate arras contract for offer_id=%s", offer_id)
            record.contract_text = (
                "[CONTRATO NO GENERADO: API key de Gemini no configurada. "
                "Contacta con el administrador del sistema.]"
            )
            record.contract_status = "ready"
            record.generation_count = (record.generation_count or 0) + 1
            db.commit()
            return

        from google import genai as google_genai
        client = google_genai.Client(api_key=api_key)
        model_id = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
        response = client.models.generate_content(
            model=model_id,
            contents=prompt,
        )
        contract_text = response.text

        record.contract_text = contract_text
        record.contract_status = "ready"
        record.generation_count = (record.generation_count or 0) + 1
        record.buyer_contract_accepted = False
        record.seller_contract_accepted = False
        db.commit()
        logger.info("Arras contract generated for offer_id=%s (iteration %s)", offer_id, record.generation_count)

    except Exception as exc:
        logger.exception("Arras contract generation failed for offer_id=%s: %s", offer_id, exc)
        err_str = str(exc)
        if "429" in err_str or "RESOURCE_EXHAUSTED" in err_str or "quota" in err_str.lower():
            user_msg = (
                "El servicio de IA ha superado su cuota de uso. "
                "Puedes reintentar en unos minutos o contactar con el soporte."
            )
        elif "API_KEY" in err_str.upper() or "invalid" in err_str.lower():
            user_msg = "La clave de API de Gemini no es valida. Contacta con el administrador."
        else:
            user_msg = "Error al generar el contrato. Puedes reintentar."
        try:
            record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()
            if record:
                record.contract_status = "error"
                record.contract_text = user_msg
                db.commit()
        except Exception:
            pass
    finally:
        db.close()


def _maybe_trigger_generation(record: ArrasInterview, background_tasks: BackgroundTasks) -> None:
    """Triggers Gemini generation if both parties have confirmed and no contract exists yet."""
    if bool(record.buyer_interview_confirmed) and bool(record.seller_interview_confirmed):
        if record.contract_status not in ("generating", "ready", "buyer_accepted", "seller_accepted", "fully_accepted",):
            record.contract_status = "generating"
            background_tasks.add_task(_generate_arras_contract_gemini, offer_id=record.offer_id)
            logger.info("Arras contract generation triggered for offer_id=%s", record.offer_id)


# ============================================================================
# Endpoints
# ============================================================================

@router.get("/{offer_id}", response_model=ArrasInterviewResponse)
async def get_interview(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    offer, _ = _get_offer_and_role(offer_id, current_user, db)
    record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()
    if not record:
        return _empty_response(offer_id)
    return _serialize(record, int(offer.amount))


@router.post("/{offer_id}", response_model=ArrasInterviewResponse)
async def save_answers(
    offer_id: int,
    body: ArrasAnswers,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Legacy shared answers endpoint — kept for backward compat."""
    offer, role = _get_offer_and_role(offer_id, current_user, db)
    record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()
    if not record:
        record = ArrasInterview(offer_id=offer_id)
        db.add(record)

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

    if role == "BUYER":
        record.buyer_confirmed = False
        record.buyer_confirmed_at = None
    else:
        record.seller_confirmed = False
        record.seller_confirmed_at = None

    db.commit()
    db.refresh(record)
    return _serialize(record, int(offer.amount))


@router.post("/{offer_id}/buyer", response_model=ArrasInterviewResponse)
async def save_buyer_answers(
    offer_id: int,
    body: BuyerArrasAnswers,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Buyer saves their interview answers. Resets buyer confirmation."""
    offer, role = _get_offer_and_role(offer_id, current_user, db)
    if role != "BUYER":
        raise HTTPException(status_code=403, detail="Solo el comprador puede guardar esta entrevista")

    record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()
    if not record:
        record = ArrasInterview(offer_id=offer_id)
        db.add(record)

    record.buyer_answers_json = body.model_dump()
    # Sync shared fields for legacy compat
    record.deposit_percentage = body.deposit_percentage
    record.deposit_amount = _compute_deposit(int(offer.amount), body.deposit_percentage)
    record.deadline_days = body.deadline_days
    record.payment_method = body.payment_method
    record.notary_city = body.notary_preference
    record.buyer_interview_confirmed = False
    record.buyer_confirmed = False
    record.buyer_confirmed_at = None

    db.commit()
    db.refresh(record)
    return _serialize(record, int(offer.amount))


@router.post("/{offer_id}/seller", response_model=ArrasInterviewResponse)
async def save_seller_answers(
    offer_id: int,
    body: SellerArrasAnswers,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Seller saves their interview answers. IBAN is encrypted. Resets seller confirmation."""
    offer, role = _get_offer_and_role(offer_id, current_user, db)
    if role != "SELLER":
        raise HTTPException(status_code=403, detail="Solo el vendedor puede guardar esta entrevista")

    record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()
    if not record:
        record = ArrasInterview(offer_id=offer_id)
        db.add(record)

    # Encrypt IBAN before storing
    answers = body.model_dump()
    iban_raw = answers.pop("iban", None)
    record.seller_answers_json = answers
    if iban_raw:
        record.seller_iban_enc = encrypt_data(iban_raw)

    record.seller_interview_confirmed = False
    record.seller_confirmed = False
    record.seller_confirmed_at = None

    db.commit()
    db.refresh(record)
    return _serialize(record, int(offer.amount))


@router.post("/{offer_id}/buyer/confirm", response_model=ArrasInterviewResponse)
async def confirm_buyer_interview(
    offer_id: int,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Buyer confirms their interview. Triggers Gemini generation if both confirmed."""
    offer, role = _get_offer_and_role(offer_id, current_user, db)
    if role != "BUYER":
        raise HTTPException(status_code=403, detail="Solo el comprador puede confirmar esta entrevista")

    record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()
    if not record or not record.buyer_answers_json:
        raise HTTPException(status_code=400, detail="Debes completar tu entrevista antes de confirmar")

    now = datetime.now(timezone.utc)
    record.buyer_interview_confirmed = True
    record.buyer_confirmed = True
    record.buyer_confirmed_at = now

    _maybe_trigger_generation(record, background_tasks)
    db.commit()
    db.refresh(record)
    return _serialize(record, int(offer.amount))


@router.post("/{offer_id}/seller/confirm", response_model=ArrasInterviewResponse)
async def confirm_seller_interview(
    offer_id: int,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Seller confirms their interview. Triggers Gemini generation if both confirmed."""
    offer, role = _get_offer_and_role(offer_id, current_user, db)
    if role != "SELLER":
        raise HTTPException(status_code=403, detail="Solo el vendedor puede confirmar esta entrevista")

    record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()
    if not record or not record.seller_answers_json:
        raise HTTPException(status_code=400, detail="Debes completar tu entrevista antes de confirmar")

    now = datetime.now(timezone.utc)
    record.seller_interview_confirmed = True
    record.seller_confirmed = True
    record.seller_confirmed_at = now

    _maybe_trigger_generation(record, background_tasks)
    db.commit()
    db.refresh(record)
    return _serialize(record, int(offer.amount))


@router.post("/{offer_id}/contract/accept", response_model=ArrasInterviewResponse)
async def accept_contract(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Buyer or seller accepts the AI-generated contract."""
    offer, role = _get_offer_and_role(offer_id, current_user, db)

    record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()
    if not record or record.contract_status not in ("ready", "buyer_accepted", "seller_accepted"):
        raise HTTPException(status_code=400, detail="No hay contrato disponible para aceptar")

    now = datetime.now(timezone.utc)
    if role == "BUYER":
        record.buyer_contract_accepted = True
        record.buyer_contract_accepted_at = now
    else:
        record.seller_contract_accepted = True
        record.seller_contract_accepted_at = now

    if bool(record.buyer_contract_accepted) and bool(record.seller_contract_accepted):
        record.contract_status = "fully_accepted"
        # Advance offer to SIGNED
        from sqlalchemy import cast, String, func as sa_func
        if sa_func.upper(cast(offer.status, String)) != "SIGNED":
            from backend.src.models.enums import OfferStatus
            offer.status = OfferStatus.SIGNED
        logger.info("Arras contract fully accepted for offer_id=%s — offer advanced to SIGNED", offer_id)
    elif role == "BUYER":
        record.contract_status = "buyer_accepted"
    else:
        record.contract_status = "seller_accepted"

    db.commit()
    db.refresh(record)
    return _serialize(record, int(offer.amount))


@router.post("/{offer_id}/contract/reject", response_model=ArrasInterviewResponse)
async def reject_contract(
    offer_id: int,
    body: ContractRejectBody,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Buyer or seller rejects the contract and provides change notes.
    Resets both confirmations so both parties must re-confirm their interviews.
    """
    offer, role = _get_offer_and_role(offer_id, current_user, db)

    record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Entrevista no encontrada")

    if role == "BUYER":
        record.buyer_rejection_notes = body.notes
    else:
        record.seller_rejection_notes = body.notes

    # Reset so both can add clauses and reconfirm
    record.buyer_interview_confirmed = False
    record.buyer_confirmed = False
    record.buyer_confirmed_at = None
    record.seller_interview_confirmed = False
    record.seller_confirmed = False
    record.seller_confirmed_at = None
    record.buyer_contract_accepted = False
    record.buyer_contract_accepted_at = None
    record.seller_contract_accepted = False
    record.seller_contract_accepted_at = None
    record.contract_status = None
    record.contract_text = None
    # Clear equity cache so analysis reflects the new contract when regenerated
    record.buyer_equity_json = None
    record.seller_equity_json = None

    db.commit()
    db.refresh(record)
    return _serialize(record, int(offer.amount))


@router.post("/{offer_id}/contract/regenerate", response_model=ArrasInterviewResponse)
async def regenerate_contract(
    offer_id: int,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Re-triggers Gemini contract generation.
    Allowed when contract_status is 'error' and both interviews are confirmed.
    """
    offer, _ = _get_offer_and_role(offer_id, current_user, db)
    record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Entrevista no encontrada")
    if not (record.buyer_interview_confirmed and record.seller_interview_confirmed):
        raise HTTPException(
            status_code=400,
            detail="Ambas partes deben confirmar su entrevista antes de regenerar el contrato",
        )
    if record.contract_status == "fully_accepted":
        raise HTTPException(status_code=400, detail="El contrato ya fue aceptado por ambas partes")

    record.contract_status = "generating"
    record.contract_text = None
    # Clear equity cache so it is regenerated against the new contract
    record.buyer_equity_json = None
    record.seller_equity_json = None
    db.commit()
    background_tasks.add_task(_generate_arras_contract_gemini, offer_id=offer_id)
    logger.info("Contract regeneration triggered for offer_id=%s by user=%s", offer_id, current_user.id)
    db.refresh(record)
    return _serialize(record, int(offer.amount))


@router.get("/{offer_id}/equity")
async def get_equity_analysis(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Returns the AI equity analysis for the requesting party (buyer or seller).
    Generates and caches the analysis on first call using the current contract text.
    Response: { "score": int, "items": [ { "key", "label", "status", "description" } ] }
    """
    offer, role = _get_offer_and_role(offer_id, current_user, db)
    record = db.query(ArrasInterview).filter(ArrasInterview.offer_id == offer_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Entrevista no encontrada")
    if not record.contract_text or record.contract_status not in (
        "ready", "buyer_accepted", "seller_accepted", "fully_accepted"
    ):
        raise HTTPException(
            status_code=400,
            detail="El analisis solo esta disponible cuando el contrato ha sido generado",
        )

    # Return cached analysis if available for this role
    if role == "BUYER" and record.buyer_equity_json:
        return record.buyer_equity_json
    if role == "SELLER" and record.seller_equity_json:
        return record.seller_equity_json

    # --- Generate equity analysis via Gemini ---
    api_key = os.getenv("GEMINI_API_KEY", "")
    if not api_key:
        raise HTTPException(
            status_code=503,
            detail="El servicio de IA no esta configurado. Contacta con el administrador.",
        )

    ba = record.buyer_answers_json or {}
    sa = record.seller_answers_json or {}

    def yn(val): return "Si" if val else "No"

    buyer_context = (
        f"- Sujeto a hipoteca: {yn(ba.get('subject_to_mortgage', False))}\n"
        f"- Penalizacion comprador (pierde arras): Si el comprador desiste, pierde el importe de arras\n"
        f"- Prorrateo IBI por dias: {yn(ba.get('ibi_proration_by_days', True))}\n"
        f"- Retencion IBI no emitido: {yn(ba.get('retain_pending_ibi', False))}\n"
        f"- Acepta clausula vicios ocultos art. 1484 CC: {yn(ba.get('hidden_defects_accepted', False))}\n"
        f"- Retencion por deudas de comunidad: {yn(ba.get('community_debt_retention', False))}\n"
        f"- Plazo maximo para escritura: {ba.get('deadline_days', record.deadline_days or 60)} dias\n"
        f"- Porcentaje arras: {ba.get('deposit_percentage', record.deposit_percentage or 10)}%\n"
        f"- Notaria preferida: {ba.get('notary_preference', 'A determinar')}"
    )
    seller_context = (
        f"- Vivienda libre de arrendatarios: {yn(sa.get('property_free_of_tenants', True))}\n"
        f"- Suministros activos: {yn(sa.get('utilities_active', True))}\n"
        f"- Compromiso mantenimiento suministros: {yn(sa.get('utilities_maintenance_commitment', True))}\n"
        f"- Derramas aprobadas no comunicadas: {yn(sa.get('has_approved_levies', False))}\n"
        f"- Certificado cero deudas comunidad: {yn(sa.get('zero_debt_certificate', True))}\n"
        f"- Hipoteca pendiente de cancelar: {yn(sa.get('has_mortgage_to_cancel', False))}\n"
        f"- Importe hipoteca: {sa.get('mortgage_amount', 0)} EUR\n"
        f"- Asume plusvalia municipal: {yn(sa.get('plusvalia_assumed', True))}\n"
        f"- Acepta retencion IBI: {yn(sa.get('ibi_retention_accepted', True))}"
    )

    prompt = f"""Eres un asesor juridico inmobiliario espanol experto en contratos de arras penitenciales.
Analiza el siguiente contrato y las condiciones pactadas desde la perspectiva de cada parte.
Devuelve UNICAMENTE un JSON valido con el siguiente formato exacto. Sin texto adicional, sin markdown, sin comentarios.

FORMATO REQUERIDO:
{{
  "buyer": {{
    "score": <entero 0-100 que indica cuan favorable es el contrato para el comprador>,
    "items": [
      {{
        "key": "<identificador_snake_case>",
        "label": "<Titulo del aspecto en espanol>",
        "status": "<favorable|neutral|alerta|critico>",
        "description": "<Explicacion concisa de 1-2 frases en espanol>"
      }}
    ]
  }},
  "seller": {{
    "score": <entero 0-100 que indica cuan favorable es el contrato para el vendedor>,
    "items": [...]
  }}
}}

CRITERIOS DE STATUS:
- favorable: el termino beneficia claramente a esta parte (verde)
- neutral: clausula estandar, ni beneficia ni perjudica especialmente (azul)
- alerta: condicion que requiere atencion o tiene cierto riesgo (naranja)
- critico: condicion desfavorable o con alto riesgo para esta parte (rojo)

ITEMS OBLIGATORIOS PARA EL COMPRADOR (usa exactamente estas keys):
1. hipoteca — condicion suspensiva de financiacion hipotecaria
2. notaria — gastos notariales y quien los asume
3. plazo — plazo de firma de escritura y si es suficiente
4. ibi — prorrateo del IBI y proteccion frente a IBI no emitido
5. vicios_ocultos — clausula de vicios ocultos articulo 1484 del Codigo Civil
6. penalizacion_arras — consecuencias economicas de desistimiento del comprador
7. deudas_comunidad — proteccion frente a deudas de comunidad del vendedor

ITEMS OBLIGATORIOS PARA EL VENDEDOR (usa exactamente estas keys):
1. compromiso_entrega — estado de la vivienda y libre de arrendatarios
2. suministros — situacion de los suministros y compromisos de mantenimiento
3. plusvalia — quien asume la plusvalia municipal
4. hipoteca_vendedor — cancelacion de hipoteca existente y riesgo para el plazo
5. penalizacion_arras — consecuencias economicas de desistimiento del vendedor (devolver doble)
6. plazo_liberacion — suficiencia del plazo para preparar la documentacion y la venta
7. ibi_retencion — retencion o prorrateo del IBI y impacto economico para el vendedor

CONDICIONES DECLARADAS POR EL COMPRADOR:
{buyer_context}

CONDICIONES DECLARADAS POR EL VENDEDOR:
{seller_context}

TEXTO DEL CONTRATO (primeras 3000 palabras):
{record.contract_text[:3000] if record.contract_text else ""}
"""

    try:
        from google import genai as google_genai
        client = google_genai.Client(api_key=api_key)
        model_id = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
        response = client.models.generate_content(
            model=model_id,
            contents=prompt,
        )
        raw = response.text.strip()
        # Strip markdown code fences if present
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]
        equity_data = json.loads(raw)
    except json.JSONDecodeError as exc:
        logger.error("Equity analysis JSON parse error for offer_id=%s: %s", offer_id, exc)
        raise HTTPException(
            status_code=502,
            detail="El servicio de IA devolvio una respuesta invalida. Intentalo de nuevo.",
        )
    except Exception as exc:
        err_str = str(exc)
        logger.exception("Equity analysis failed for offer_id=%s: %s", offer_id, exc)
        if "429" in err_str or "RESOURCE_EXHAUSTED" in err_str or "quota" in err_str.lower():
            raise HTTPException(
                status_code=429,
                detail="El servicio de IA ha superado su cuota. Intenta de nuevo en unos minutos.",
            )
        raise HTTPException(status_code=502, detail="Error al generar el analisis de equidad.")

    buyer_analysis = equity_data.get("buyer", {})
    seller_analysis = equity_data.get("seller", {})

    # Cache both analyses
    record.buyer_equity_json = buyer_analysis
    record.seller_equity_json = seller_analysis
    db.commit()
    logger.info("Equity analysis cached for offer_id=%s", offer_id)

    return buyer_analysis if role == "BUYER" else seller_analysis


@router.post("/{offer_id}/confirm", response_model=ArrasInterviewResponse)
async def confirm_interview(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Legacy confirm endpoint — kept for backward compat."""
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

    if record.buyer_confirmed and record.seller_confirmed:
        record.draft_pdf_path = _generate_draft_pdf(offer, record)

    db.commit()
    db.refresh(record)
    return _serialize(record, int(offer.amount))


@router.get("/{offer_id}/pdf")
async def download_draft_pdf(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
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
        headers={"Content-Disposition": f"attachment; filename=arras_borrador_{offer_id}.pdf"},
    )


# ============================================================================
# PDF Generation (stub — replaced by Gemini contract text in V2 flow)
# ============================================================================

def _generate_draft_pdf(offer, record: ArrasInterview) -> str:
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
        content = (
            f"BORRADOR CONTRATO DE ARRAS PENITENCIALES\n"
            f"Oferta: {offer.id}\n"
            f"Importe: {offer.amount} EUR\n"
            f"Arras: {record.deposit_amount} EUR ({record.deposit_percentage}%)\n"
            f"Plazo: {record.deadline_days} dias\n"
        )
        if record.contract_text:
            content = record.contract_text
        pdf_bytes = content.encode("utf-8")

    upload_dir = "uploads/arras"
    os.makedirs(upload_dir, exist_ok=True)
    path = f"{upload_dir}/arras_borrador_{offer.id}.pdf"
    with open(path, "wb") as f:
        f.write(pdf_bytes)
    return path


def _generate_pdf_bytes(offer, record: ArrasInterview) -> bytes:
    import os
    if record.draft_pdf_path and os.path.exists(record.draft_pdf_path):
        with open(record.draft_pdf_path, "rb") as f:
            return f.read()
    _generate_draft_pdf(offer, record)
    if record.draft_pdf_path and os.path.exists(record.draft_pdf_path):
        with open(record.draft_pdf_path, "rb") as f:
            return f.read()
    return b""

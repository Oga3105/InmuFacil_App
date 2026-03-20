"""
@Shield - AI Consent Routes (GDPR Art. 6.1.a / LOPDGDD Art. 7)

POST /ai-consent        — Registra un consentimiento explícito del usuario.
GET  /ai-consent/me     — Devuelve el historial de consentimientos del usuario.

Cada registro es inmutable: representa un consentimiento puntual y trazable.
"""
import json
import logging
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from backend.src.config.database import get_db
from backend.src.models import User
from backend.src.models.ai_consent import AIConsentLog
from backend.src.utils.security import get_current_active_user

logger = logging.getLogger(__name__)
router = APIRouter(tags=["AI Consent"])


# ─── Schemas ──────────────────────────────────────────────────────────────────

class AIConsentCreate(BaseModel):
    action_type: str = Field(..., max_length=100)
    action_label: str = Field(..., max_length=255)
    data_categories: List[str] = Field(..., min_length=1)
    purpose: str
    ai_provider: str = Field(..., max_length=255)
    consent_text_version: str = Field(default="v1.0", max_length=50)
    property_id: Optional[str] = Field(default=None, max_length=50)


class AIConsentResponse(BaseModel):
    id: int
    action_type: str
    action_label: str
    data_categories: List[str]
    purpose: str
    ai_provider: str
    consent_text_version: str
    consented_at: datetime
    ip_address: Optional[str]
    property_id: Optional[str]

    class Config:
        from_attributes = True


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _get_client_ip(request: Request) -> Optional[str]:
    """
    Extrae la IP real del cliente respetando cabeceras de proxy/CDN.
    Cloudflare: CF-Connecting-IP. Nginx: X-Real-IP. Fallback: X-Forwarded-For.
    """
    for header in ("cf-connecting-ip", "x-real-ip", "x-forwarded-for"):
        value = request.headers.get(header)
        if value:
            return value.split(",")[0].strip()
    return request.client.host if request.client else None


def _parse_consent_log(log: AIConsentLog) -> AIConsentResponse:
    try:
        categories = json.loads(log.data_categories)
    except (json.JSONDecodeError, TypeError):
        categories = [log.data_categories]
    return AIConsentResponse(
        id=log.id,
        action_type=log.action_type,
        action_label=log.action_label,
        data_categories=categories,
        purpose=log.purpose,
        ai_provider=log.ai_provider,
        consent_text_version=log.consent_text_version,
        consented_at=log.consented_at,
        ip_address=log.ip_address,
        property_id=log.property_id,
    )


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.post(
    "/ai-consent",
    response_model=AIConsentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar consentimiento explícito para uso de IA (RGPD Art. 6.1.a)",
)
async def record_ai_consent(
    payload: AIConsentCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Crea un registro inmutable de consentimiento.
    Debe llamarse ANTES de ejecutar la accion de IA asociada.
    Si este endpoint falla, el cliente NO debe proceder con la accion.
    """
    log = AIConsentLog(
        user_id=current_user.id,
        action_type=payload.action_type,
        action_label=payload.action_label,
        data_categories=json.dumps(payload.data_categories, ensure_ascii=False),
        purpose=payload.purpose,
        ai_provider=payload.ai_provider,
        consent_text_version=payload.consent_text_version,
        ip_address=_get_client_ip(request),
        user_agent=request.headers.get("user-agent", "")[:512],
        property_id=payload.property_id,
    )
    db.add(log)
    db.commit()
    db.refresh(log)

    logger.info(
        f"[AI_CONSENT] user={current_user.id} action={payload.action_type} "
        f"provider={payload.ai_provider} ip={log.ip_address}"
    )

    return _parse_consent_log(log)


@router.get(
    "/ai-consent/me",
    response_model=List[AIConsentResponse],
    summary="Historial de consentimientos IA del usuario autenticado (RGPD Art. 15)",
)
async def get_my_ai_consents(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Devuelve todos los consentimientos registrados para el usuario.
    Derecho de acceso RGPD Art. 15 — el usuario puede ver qué autorizó.
    """
    logs = (
        db.query(AIConsentLog)
        .filter(AIConsentLog.user_id == current_user.id)
        .order_by(AIConsentLog.consented_at.desc())
        .all()
    )
    return [_parse_consent_log(log) for log in logs]

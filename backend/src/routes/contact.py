"""
Contact Message Endpoint

Allows authenticated users to send a contact message to the InmuFacil
support team. Protected by JWT authentication and per-user rate limiting
(max 3 messages per 24-hour window) to prevent abuse.
"""

import logging
from collections import defaultdict
from datetime import datetime, timedelta
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from backend.src.models import User
from backend.src.utils.security import get_current_active_user
from backend.src.services.email_service import _send_email

logger = logging.getLogger("inmufacil.contact")

router = APIRouter(prefix="/contact", tags=["Contact"])

# ── In-memory rate limiter ─────────────────────────────────────────────────────
# {user_id: [datetime, ...]}  — keeps timestamps of recent sends
_rate_limit_store: dict[int, List[datetime]] = defaultdict(list)

RATE_LIMIT_MAX = 3
RATE_LIMIT_WINDOW_HOURS = 24

SUPPORT_EMAIL = "soporte@inmufacil.com"


def _check_rate_limit(user_id: int) -> None:
    """Raise 429 if user has sent >= RATE_LIMIT_MAX messages in the past 24h."""
    now = datetime.utcnow()
    cutoff = now - timedelta(hours=RATE_LIMIT_WINDOW_HOURS)

    # Purge old timestamps
    _rate_limit_store[user_id] = [
        ts for ts in _rate_limit_store[user_id] if ts > cutoff
    ]

    if len(_rate_limit_store[user_id]) >= RATE_LIMIT_MAX:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=(
                f"Has alcanzado el limite de {RATE_LIMIT_MAX} mensajes "
                f"en {RATE_LIMIT_WINDOW_HOURS} horas. Intentalo mas tarde."
            ),
        )


# ── Schemas ───────────────────────────────────────────────────────────────────

class ContactMessageRequest(BaseModel):
    subject: str = Field(..., min_length=3, max_length=100)
    message: str = Field(..., min_length=10, max_length=2000)


class ContactMessageResponse(BaseModel):
    ok: bool
    detail: str


# ── Endpoint ──────────────────────────────────────────────────────────────────

@router.post(
    "/message",
    response_model=ContactMessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Send a contact message to InmuFacil support",
)
async def send_contact_message(
    body: ContactMessageRequest,
    current_user: User = Depends(get_current_active_user),
) -> ContactMessageResponse:
    """
    Sends an email to the InmuFacil support inbox on behalf of the
    authenticated user. Requires a valid JWT Bearer token.

    Rate limited: max 3 messages per user per 24 hours.
    """
    _check_rate_limit(current_user.id)

    sender_name = current_user.full_name or "Usuario"
    sender_email = current_user.email

    html_body = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #135BEC; border-bottom: 2px solid #135BEC; padding-bottom: 8px;">
        Nuevo mensaje de contacto — InmuFacil
      </h2>
      <table style="width:100%; border-collapse:collapse;">
        <tr>
          <td style="padding:6px 0; font-weight:bold; color:#555; width:120px;">De:</td>
          <td style="padding:6px 0;">{sender_name} &lt;{sender_email}&gt;</td>
        </tr>
        <tr>
          <td style="padding:6px 0; font-weight:bold; color:#555;">Asunto:</td>
          <td style="padding:6px 0;">{body.subject}</td>
        </tr>
      </table>
      <hr style="border:none; border-top:1px solid #eee; margin:16px 0;">
      <p style="white-space: pre-wrap; color: #333; line-height: 1.6;">{body.message}</p>
      <hr style="border:none; border-top:1px solid #eee; margin:16px 0;">
      <p style="color:#999; font-size:12px;">
        Mensaje enviado desde la plataforma InmuFacil (usuario ID: {current_user.id}).
      </p>
    </div>
    """

    subject_line = f"[Contacto] {body.subject} — {sender_name}"

    sent = await _send_email(
        to=SUPPORT_EMAIL,
        subject=subject_line,
        html_body=html_body,
    )

    if not sent:
        logger.error(
            "[contact] SMTP failed for user_id=%s subject=%r",
            current_user.id,
            body.subject,
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No se pudo enviar el mensaje. Intentalo de nuevo en unos minutos.",
        )

    # Record successful send in rate limiter
    _rate_limit_store[current_user.id].append(datetime.utcnow())

    logger.info(
        "[contact] Message sent user_id=%s to=%s subject=%r",
        current_user.id,
        SUPPORT_EMAIL,
        body.subject,
    )

    return ContactMessageResponse(ok=True, detail="Mensaje enviado correctamente.")

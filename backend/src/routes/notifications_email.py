"""
Email Notification Router

@Shield: Admin-only endpoint. Requires valid JWT + admin role check.
         SMTP credentials read from environment variables — never hardcoded.
         Graceful degradation when SMTP is not configured (dev/test environments).
@Watcher: Logs all send attempts (success, skip, error) without logging email content.
"""

import os
import smtplib
import logging
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Any, Dict

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr

from backend.src.models.users import User
from backend.src.utils.security import get_current_admin_user
from backend.src.services.email_templates import (
    password_reset_template,
    offer_received_template,
    offer_accepted_template,
    welcome_template,
)

logger = logging.getLogger("inmufacil.notifications_email")

router = APIRouter(prefix="/notifications", tags=["Notifications", "Admin"])


# ============================================================================
# Request / Response Schemas
# ============================================================================


class SendEmailRequest(BaseModel):
    """Request body for the send-email endpoint."""

    to: EmailStr
    template_name: str
    template_data: Dict[str, Any]


class SendEmailResponse(BaseModel):
    """Response body for the send-email endpoint."""

    status: str
    reason: str = ""


# ============================================================================
# SMTP helpers
# ============================================================================

_SUPPORTED_TEMPLATES = {
    "password_reset",
    "offer_received",
    "offer_accepted",
    "welcome",
}


def _smtp_configured() -> bool:
    """Return True only when all required SMTP environment variables are present."""
    required = ("SMTP_HOST", "SMTP_PORT", "SMTP_USER", "SMTP_PASS", "SMTP_FROM")
    return all(os.getenv(k) for k in required)


def _render_template(template_name: str, template_data: Dict[str, Any]) -> tuple[str, str]:
    """
    Render a named HTML template with the provided data.

    Returns:
        Tuple of (subject, html_body).

    Raises:
        HTTPException 400 if template_name is unknown or required fields are missing.
    """
    try:
        if template_name == "password_reset":
            reset_url = template_data["reset_url"]
            expires_hours = int(template_data.get("expires_hours", 1))
            html = password_reset_template(reset_url, expires_hours)
            subject = "Restablecer contrasena - InmuFacil"

        elif template_name == "offer_received":
            html = offer_received_template(
                seller_name=template_data["seller_name"],
                property_address=template_data["property_address"],
                offer_amount=int(template_data["offer_amount"]),
                buyer_name=template_data["buyer_name"],
            )
            subject = "Nueva oferta recibida - InmuFacil"

        elif template_name == "offer_accepted":
            html = offer_accepted_template(
                buyer_name=template_data["buyer_name"],
                property_address=template_data["property_address"],
                offer_amount=int(template_data["offer_amount"]),
            )
            subject = "Oferta aceptada - InmuFacil"

        elif template_name == "welcome":
            html = welcome_template(user_name=template_data["user_name"])
            subject = "Bienvenido a InmuFacil"

        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Plantilla '{template_name}' no reconocida. "
                    f"Plantillas disponibles: {sorted(_SUPPORTED_TEMPLATES)}"
                ),
            )
    except KeyError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Campo requerido ausente en template_data: {exc}",
        ) from exc

    return subject, html


def _send_smtp(to: str, subject: str, html_body: str) -> None:
    """
    Send an HTML email via SMTP using environment-variable credentials.

    Raises:
        RuntimeError if the SMTP session fails.
    """
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER")
    smtp_pass = os.getenv("SMTP_PASS")
    smtp_from = os.getenv("SMTP_FROM")

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = smtp_from
    msg["To"] = to
    msg.attach(MIMEText(html_body, "html", "utf-8"))

    with smtplib.SMTP(smtp_host, smtp_port, timeout=15) as server:
        server.ehlo()
        server.starttls()
        server.login(smtp_user, smtp_pass)
        server.sendmail(smtp_from, [to], msg.as_string())


# ============================================================================
# Endpoint
# ============================================================================


@router.post(
    "/send-email",
    response_model=SendEmailResponse,
    status_code=status.HTTP_200_OK,
    summary="Enviar email usando una plantilla corporativa (solo admin)",
)
def send_email(
    request: SendEmailRequest,
    current_admin: User = Depends(get_current_admin_user),
) -> SendEmailResponse:
    """
    Send a transactional email using one of the corporate HTML templates.

    - Requires a valid JWT token belonging to an admin user.
    - If SMTP environment variables are not configured, returns a skipped status
      instead of raising an error (graceful degradation for dev/test environments).

    Supported template names:
    - `password_reset`  — fields: reset_url, expires_hours (optional, default 1)
    - `offer_received`  — fields: seller_name, property_address, offer_amount, buyer_name
    - `offer_accepted`  — fields: buyer_name, property_address, offer_amount
    - `welcome`         — fields: user_name
    """
    if not _smtp_configured():
        logger.warning(
            "[EMAIL] SMTP no configurado. Envio omitido. "
            "Define SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS y SMTP_FROM en .env."
        )
        return SendEmailResponse(
            status="skipped",
            reason="SMTP not configured",
        )

    subject, html_body = _render_template(request.template_name, request.template_data)

    try:
        _send_smtp(to=str(request.to), subject=subject, html_body=html_body)
        logger.info(
            "[EMAIL] Enviado correctamente. template=%s recipient_domain=%s",
            request.template_name,
            str(request.to).split("@")[-1],
        )
        return SendEmailResponse(status="sent")
    except Exception as exc:
        logger.error("[EMAIL] Error al enviar email. template=%s error=%r", request.template_name, exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Error al enviar el email: {repr(exc)}",
        ) from exc

"""
Moderation Alert Service -- Admin Notification via SMTP (IONOS)

Sends structured email alerts to the platform administrator when:
- A user accumulates >= 3 reports from distinct users.
- An OSINT investigation yields a critical risk score (> 90).
- A registration attempt is blocked by the anti-agency filter (Layer 1).

Integrates with the Active Intelligence Shield 2.0 and Community Shield
reporting system.

Sender: "Asistente IA InmuFacil <asistenteia@inmufacil.com>"
Recipient: ADMIN_EMAIL environment variable.
"""

import os
import logging
from typing import List, Dict, Any
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import aiosmtplib

logger = logging.getLogger("inmufacil.moderation_alerts")

# SMTP Configuration (shared with email_service.py)
MAIL_USERNAME = os.getenv("MAIL_USERNAME", "admin@inmufacil.com")
MAIL_PASSWORD = os.getenv("MAIL_PASSWORD", "")
MAIL_SERVER = os.getenv("MAIL_SERVER", "smtp.ionos.es")
MAIL_PORT = int(os.getenv("MAIL_PORT", "587"))

# Moderation-specific configuration
MODERATION_FROM = os.getenv(
    "MODERATION_FROM", "asistenteia@inmufacil.com"
)
MODERATION_FROM_NAME = "Asistente IA InmuFacil"
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "")

ADMIN_PANEL_URL = os.getenv(
    "ADMIN_PANEL_URL", "https://www.inmufacil.com/admin/users"
)


async def _send_email(to: str, subject: str, html_body: str) -> bool:
    """
    Send an HTML email via SMTP IONOS with STARTTLS.

    Args:
        to: Recipient email address.
        subject: Email subject line.
        html_body: HTML content of the email.

    Returns:
        True if sent successfully, False otherwise.
    """
    if not MAIL_PASSWORD:
        logger.error("[SMTP] MAIL_PASSWORD not configured. Alert not sent.")
        return False

    if not to:
        logger.error("[SMTP] No recipient address. Alert not sent.")
        return False

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = f"{MODERATION_FROM_NAME} <{MODERATION_FROM}>"
    msg["To"] = to
    msg.attach(MIMEText(html_body, "html", "utf-8"))

    try:
        await aiosmtplib.send(
            msg,
            hostname=MAIL_SERVER,
            port=MAIL_PORT,
            username=MAIL_USERNAME,
            password=MAIL_PASSWORD,
            start_tls=True,
        )
        logger.info(
            "[SMTP] Moderation alert sent to %s -- subject: %r",
            to, subject,
        )
        return True
    except aiosmtplib.SMTPException as exc:
        logger.error("[SMTP] Failed to send moderation alert to %s: %s", to, exc)
        return False
    except Exception as exc:
        logger.error(
            "[SMTP] Unexpected error sending moderation alert to %s: %s",
            to, exc,
        )
        return False


def _build_moderation_html(
    reported_user_name: str,
    reported_user_email: str,
    reported_user_phone: str,
    report_count: int,
    ai_score: int,
    reports_summary: List[Dict[str, Any]],
) -> str:
    """
    Build the HTML body for the admin moderation alert email.

    Args:
        reported_user_name: Name of the suspected user.
        reported_user_email: Email of the suspected user.
        reported_user_phone: Phone of the suspected user (may be empty).
        report_count: Total number of community reports.
        ai_score: OSINT investigation risk score.
        reports_summary: List of dicts with reporter and category info.

    Returns:
        HTML string for the email body.
    """
    severity = "CRITICAL" if ai_score > 90 else "HIGH" if ai_score >= 80 else "MEDIUM"

    reports_rows = ""
    for i, report in enumerate(reports_summary, 1):
        reporter = report.get("reporter", "N/A")
        category = report.get("category", "N/A")
        reports_rows += f"""
        <tr>
            <td style="padding:8px 12px;border-bottom:1px solid #E2E8F0;">{i}</td>
            <td style="padding:8px 12px;border-bottom:1px solid #E2E8F0;">{reporter}</td>
            <td style="padding:8px 12px;border-bottom:1px solid #E2E8F0;">{category}</td>
        </tr>"""

    if not reports_rows:
        reports_rows = """
        <tr>
            <td colspan="3" style="padding:8px 12px;text-align:center;color:#94A3B8;">
                Sin denuncias de la comunidad (deteccion automatica por IA)
            </td>
        </tr>"""

    return f"""
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Alerta de Moderacion - InmuFacil</title>
</head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0"
               style="background:#ffffff;border-radius:16px;overflow:hidden;
                      box-shadow:0 4px 24px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background:#DC2626;padding:24px 40px;text-align:center;">
              <h1 style="margin:0;color:#ffffff;font-size:20px;font-weight:800;">
                [SHIELD] Alerta de Moderacion -- {severity}
              </h1>
              <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:13px;">
                Active Intelligence Shield 2.0
              </p>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:32px 40px;">
              <h2 style="margin:0 0 16px;color:#1E293B;font-size:18px;">
                Usuario sospechoso detectado
              </h2>

              <table width="100%" style="margin-bottom:24px;">
                <tr>
                  <td style="padding:4px 0;color:#64748B;width:140px;">Nombre:</td>
                  <td style="padding:4px 0;color:#1E293B;font-weight:600;">
                    {reported_user_name}
                  </td>
                </tr>
                <tr>
                  <td style="padding:4px 0;color:#64748B;">Email:</td>
                  <td style="padding:4px 0;color:#1E293B;">{reported_user_email}</td>
                </tr>
                <tr>
                  <td style="padding:4px 0;color:#64748B;">Telefono:</td>
                  <td style="padding:4px 0;color:#1E293B;">
                    {reported_user_phone or 'No disponible'}
                  </td>
                </tr>
                <tr>
                  <td style="padding:4px 0;color:#64748B;">Score IA:</td>
                  <td style="padding:4px 0;color:#DC2626;font-weight:700;font-size:18px;">
                    {ai_score} / 100
                  </td>
                </tr>
                <tr>
                  <td style="padding:4px 0;color:#64748B;">Denuncias:</td>
                  <td style="padding:4px 0;color:#1E293B;font-weight:600;">
                    {report_count}
                  </td>
                </tr>
              </table>

              <!-- Reports Table -->
              <h3 style="margin:0 0 8px;color:#1E293B;font-size:14px;">
                Denuncias de la comunidad:
              </h3>
              <table width="100%" style="border-collapse:collapse;margin-bottom:24px;">
                <thead>
                  <tr style="background:#F8FAFC;">
                    <th style="padding:8px 12px;text-align:left;color:#64748B;font-size:12px;">#</th>
                    <th style="padding:8px 12px;text-align:left;color:#64748B;font-size:12px;">Reportero</th>
                    <th style="padding:8px 12px;text-align:left;color:#64748B;font-size:12px;">Categoria</th>
                  </tr>
                </thead>
                <tbody>
                  {reports_rows}
                </tbody>
              </table>

              <!-- Action Button -->
              <div style="text-align:center;margin:24px 0;">
                <a href="{ADMIN_PANEL_URL}"
                   style="display:inline-block;background:#DC2626;color:#ffffff;
                          text-decoration:none;padding:14px 32px;border-radius:8px;
                          font-weight:700;font-size:14px;">
                  Revisar en Panel de Admin
                </a>
              </div>

              <p style="color:#94A3B8;font-size:11px;text-align:center;margin-top:24px;">
                Este email fue generado automaticamente por el Active Intelligence Shield 2.0
                de InmuFacil. No responder a este correo.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>"""


async def send_admin_moderation_alert(
    reported_user_name: str,
    reported_user_email: str,
    reported_user_phone: str,
    report_count: int,
    ai_score: int,
    reports_summary: List[Dict[str, Any]],
) -> bool:
    """
    Send a moderation alert email to the platform administrator.

    Called when:
    - A user accumulates >= 3 community reports (Community Shield trigger).
    - An OSINT investigation yields score > 90 (Critical AI trigger).

    Args:
        reported_user_name: Name of the suspected professional.
        reported_user_email: Email of the suspected professional.
        reported_user_phone: Phone (may be empty if encrypted).
        report_count: Number of community reports.
        ai_score: Risk score from OSINT investigation.
        reports_summary: List of report details for the email body.

    Returns:
        True if email was sent successfully, False otherwise.
    """
    recipient = ADMIN_EMAIL
    if not recipient:
        logger.warning(
            "[MODERATION] ADMIN_EMAIL not configured. Alert not sent."
        )
        return False

    severity = "CRITICAL" if ai_score > 90 else "HIGH" if ai_score >= 80 else "MEDIUM"
    subject = (
        f"[InmuFacil Shield] {severity}: Score {ai_score} -- "
        f"{reported_user_name} ({report_count} denuncias)"
    )

    html_body = _build_moderation_html(
        reported_user_name=reported_user_name,
        reported_user_email=reported_user_email,
        reported_user_phone=reported_user_phone,
        report_count=report_count,
        ai_score=ai_score,
        reports_summary=reports_summary,
    )

    logger.info(
        "[MODERATION] Sending alert: severity=%s score=%d reports=%d user=%s",
        severity, ai_score, report_count, reported_user_email,
    )

    return await _send_email(
        to=recipient,
        subject=subject,
        html_body=html_body,
    )


# ============================================================================
# Blocked Registration Alert (Layer 1 — Static Filter)
# ============================================================================


def _build_blocked_registration_html(
    email: str,
    full_name: str,
    reason: str,
    ip_address: str,
    auth_method: str,
) -> str:
    """Build HTML body for blocked registration alert."""
    from datetime import datetime

    timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")

    return f"""
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Registro Bloqueado - InmuFacil</title>
</head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0"
               style="background:#ffffff;border-radius:16px;overflow:hidden;
                      box-shadow:0 4px 24px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background:#F59E0B;padding:24px 40px;text-align:center;">
              <h1 style="margin:0;color:#ffffff;font-size:20px;font-weight:800;">
                [SHIELD] Registro Bloqueado -- Escudo Anti-Agencia
              </h1>
              <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:13px;">
                Layer 1: Filtro Estatico
              </p>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:32px 40px;">
              <h2 style="margin:0 0 16px;color:#1E293B;font-size:18px;">
                Intento de registro rechazado
              </h2>

              <table width="100%" style="margin-bottom:24px;">
                <tr>
                  <td style="padding:8px 0;color:#64748B;width:140px;">Email:</td>
                  <td style="padding:8px 0;color:#1E293B;font-weight:600;">
                    {email}
                  </td>
                </tr>
                <tr>
                  <td style="padding:8px 0;color:#64748B;">Nombre:</td>
                  <td style="padding:8px 0;color:#1E293B;">{full_name}</td>
                </tr>
                <tr>
                  <td style="padding:8px 0;color:#64748B;">Metodo:</td>
                  <td style="padding:8px 0;color:#1E293B;">{auth_method}</td>
                </tr>
                <tr>
                  <td style="padding:8px 0;color:#64748B;">IP:</td>
                  <td style="padding:8px 0;color:#1E293B;">{ip_address}</td>
                </tr>
                <tr>
                  <td style="padding:8px 0;color:#64748B;">Fecha:</td>
                  <td style="padding:8px 0;color:#1E293B;">{timestamp}</td>
                </tr>
              </table>

              <!-- Reason box -->
              <div style="background:#FEF3C7;border:1px solid #F59E0B;border-radius:8px;
                          padding:16px;margin-bottom:24px;">
                <p style="margin:0;color:#92400E;font-weight:700;font-size:13px;">
                  Motivo del bloqueo:
                </p>
                <p style="margin:8px 0 0;color:#78350F;font-size:14px;">
                  {reason}
                </p>
              </div>

              <!-- Action Button -->
              <div style="text-align:center;margin:24px 0;">
                <a href="{ADMIN_PANEL_URL}"
                   style="display:inline-block;background:#F59E0B;color:#ffffff;
                          text-decoration:none;padding:14px 32px;border-radius:8px;
                          font-weight:700;font-size:14px;">
                  Revisar en Panel de Admin
                </a>
              </div>

              <p style="color:#94A3B8;font-size:11px;text-align:center;margin-top:24px;">
                Este email fue generado automaticamente por el Escudo Anti-Agencia
                de InmuFacil. No responder a este correo.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>"""


async def send_blocked_registration_alert(
    email: str,
    full_name: str,
    reason: str,
    ip_address: str = "unknown",
    auth_method: str = "email",
) -> bool:
    """
    Send an alert when the anti-agency filter blocks a registration attempt.

    Called from auth.py when validate_user_is_not_agency() returns False.

    Args:
        email: Email that attempted to register.
        full_name: Name provided during registration.
        reason: Human-readable reason for the block.
        ip_address: Client IP address.
        auth_method: 'email' or 'google'.

    Returns:
        True if email was sent successfully, False otherwise.
    """
    recipient = ADMIN_EMAIL
    if not recipient:
        logger.warning(
            "[MODERATION] ADMIN_EMAIL not configured. "
            "Blocked registration alert not sent."
        )
        return False

    subject = (
        f"[InmuFacil Shield] Registro bloqueado: "
        f"{email} ({auth_method})"
    )

    html_body = _build_blocked_registration_html(
        email=email,
        full_name=full_name,
        reason=reason,
        ip_address=ip_address,
        auth_method=auth_method,
    )

    logger.info(
        "[MODERATION] Sending blocked registration alert: email=%s reason=%s",
        email, reason,
    )

    return await _send_email(
        to=recipient,
        subject=subject,
        html_body=html_body,
    )

"""
@Shield - Email Service

Generacion de tokens MFA, validacion y envio SMTP real via IONOS (aiosmtplib).
"""

import os
import secrets
import string
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Tuple
import logging

import aiosmtplib

logger = logging.getLogger("inmufacil.email")

# ── Configuracion SMTP desde variables de entorno ─────────────────────────────

MAIL_USERNAME  = os.getenv("MAIL_USERNAME",  "admin@inmufacil.com")
MAIL_PASSWORD  = os.getenv("MAIL_PASSWORD",  "")
MAIL_FROM      = os.getenv("MAIL_FROM",      "no-reply@inmufacil.com")
MAIL_FROM_NAME = os.getenv("MAIL_FROM_NAME", "InmuFacil")
MAIL_SERVER    = os.getenv("MAIL_SERVER",    "smtp.ionos.es")
MAIL_PORT      = int(os.getenv("MAIL_PORT",  "587"))

FRONTEND_BASE_URL = os.getenv("API_BASE_URL", "https://www.inmufacil.com").replace("/api/v1", "")


# ============================================================================
# Token Generation & Validation
# ============================================================================

def generate_verification_token() -> str:
    """Codigo de 6 digitos criptograficamente seguro."""
    token = ''.join(secrets.choice(string.digits) for _ in range(6))
    logger.info("[AUTH] Token MFA generado")
    return token


def get_token_expiration() -> datetime:
    """Expiracion: 15 minutos desde ahora (UTC)."""
    return datetime.utcnow() + timedelta(minutes=15)


def verify_token(
    provided_token: str,
    stored_token: str,
    expiration: datetime,
) -> Tuple[bool, str]:
    """Valida token con comparacion en tiempo constante y chequeo de expiracion."""
    if datetime.utcnow() > expiration:
        logger.warning("[AUTH] Token expirado")
        return False, "El codigo ha expirado. Solicita uno nuevo."

    if not secrets.compare_digest(provided_token, stored_token):
        logger.warning("[AUTH] Token invalido")
        return False, "Codigo incorrecto. Revisa el email e intentalo de nuevo."

    logger.info("[AUTH] Token verificado correctamente")
    return True, ""


# ── Rate limiting en memoria (sustituir por Redis en produccion) ───────────────

_token_request_tracker: dict[str, list[datetime]] = {}


def can_request_token(
    email: str,
    max_requests: int = 5,
    window_minutes: int = 60,
) -> Tuple[bool, str]:
    """Limita a 5 peticiones por hora por email."""
    now = datetime.utcnow()
    cutoff = now - timedelta(minutes=window_minutes)

    _token_request_tracker.setdefault(email, [])
    _token_request_tracker[email] = [
        t for t in _token_request_tracker[email] if t > cutoff
    ]

    if len(_token_request_tracker[email]) >= max_requests:
        logger.warning(f"[RATE-LIMIT] {email} supero el limite de tokens")
        return False, f"Demasiados intentos. Espera {window_minutes} minutos."

    _token_request_tracker[email].append(now)
    return True, ""


# ============================================================================
# SMTP — Envio real via IONOS (aiosmtplib)
# ============================================================================

def _build_password_reset_html(token: str) -> str:
    return f"""
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Recuperar contrasena - InmuFacil</title>
</head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="560" cellpadding="0" cellspacing="0"
               style="background:#ffffff;border-radius:16px;overflow:hidden;
                      box-shadow:0 4px 24px rgba(0,0,0,0.08);">

          <!-- Cabecera azul -->
          <tr>
            <td style="background:#135BEC;padding:32px 40px;text-align:center;">
              <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:800;
                         letter-spacing:-0.5px;">InmuFacil</h1>
              <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:13px;">
                Plataforma inmobiliaria entre particulares
              </p>
            </td>
          </tr>

          <!-- Cuerpo -->
          <tr>
            <td style="padding:40px 40px 32px;">
              <h2 style="margin:0 0 12px;color:#0F172A;font-size:20px;font-weight:700;">
                Recupera tu contrasena
              </h2>
              <p style="margin:0 0 28px;color:#475569;font-size:15px;line-height:1.6;">
                Hemos recibido una solicitud para restablecer la contrasena de tu cuenta.
                Introduce el siguiente codigo de verificacion en la aplicacion:
              </p>

              <!-- Codigo -->
              <div style="background:#EFF6FF;border:2px dashed #93C5FD;border-radius:12px;
                          padding:28px;text-align:center;margin-bottom:28px;">
                <p style="margin:0 0 6px;color:#3B82F6;font-size:12px;font-weight:700;
                           letter-spacing:2px;text-transform:uppercase;">
                  Codigo de verificacion
                </p>
                <p style="margin:0;color:#1E3A8A;font-size:42px;font-weight:900;
                           letter-spacing:12px;font-family:monospace;">
                  {token}
                </p>
                <p style="margin:10px 0 0;color:#64748B;font-size:12px;">
                  Valido durante <strong>15 minutos</strong>
                </p>
              </div>

              <p style="margin:0;color:#64748B;font-size:13px;line-height:1.6;">
                Si no solicitaste este cambio, puedes ignorar este mensaje.
                Tu contrasena actual seguira siendo la misma.
              </p>
            </td>
          </tr>

          <!-- Pie -->
          <tr>
            <td style="background:#F8FAFC;border-top:1px solid #E2E8F0;
                       padding:24px 40px;text-align:center;">
              <p style="margin:0;color:#94A3B8;font-size:12px;">
                InmuFacil &copy; 2025 &middot; Compraventa inmobiliaria entre particulares<br>
                Este es un mensaje automatico. No respondas a este correo.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
"""


def _build_welcome_html(token: str) -> str:
    return f"""
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Verifica tu cuenta - InmuFacil</title>
</head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="560" cellpadding="0" cellspacing="0"
               style="background:#ffffff;border-radius:16px;overflow:hidden;
                      box-shadow:0 4px 24px rgba(0,0,0,0.08);">

          <!-- Cabecera -->
          <tr>
            <td style="background:#135BEC;padding:32px 40px;text-align:center;">
              <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:800;">InmuFacil</h1>
              <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:13px;">
                Bienvenido a la plataforma inmobiliaria entre particulares
              </p>
            </td>
          </tr>

          <!-- Cuerpo -->
          <tr>
            <td style="padding:40px 40px 32px;">
              <h2 style="margin:0 0 12px;color:#0F172A;font-size:20px;font-weight:700;">
                Verifica tu direccion de correo
              </h2>
              <p style="margin:0 0 28px;color:#475569;font-size:15px;line-height:1.6;">
                Para activar tu cuenta introduce el siguiente codigo en la aplicacion:
              </p>

              <!-- Codigo -->
              <div style="background:#F0FDF4;border:2px dashed #86EFAC;border-radius:12px;
                          padding:28px;text-align:center;margin-bottom:28px;">
                <p style="margin:0 0 6px;color:#16A34A;font-size:12px;font-weight:700;
                           letter-spacing:2px;text-transform:uppercase;">
                  Codigo de verificacion
                </p>
                <p style="margin:0;color:#14532D;font-size:42px;font-weight:900;
                           letter-spacing:12px;font-family:monospace;">
                  {token}
                </p>
                <p style="margin:10px 0 0;color:#64748B;font-size:12px;">
                  Valido durante <strong>15 minutos</strong>
                </p>
              </div>

              <p style="margin:0;color:#64748B;font-size:13px;line-height:1.6;">
                Si no has creado esta cuenta, ignora este mensaje.
              </p>
            </td>
          </tr>

          <!-- Pie -->
          <tr>
            <td style="background:#F8FAFC;border-top:1px solid #E2E8F0;
                       padding:24px 40px;text-align:center;">
              <p style="margin:0;color:#94A3B8;font-size:12px;">
                InmuFacil &copy; 2025 &middot; Este es un mensaje automatico.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
"""


async def _send_email(to: str, subject: str, html_body: str) -> bool:
    """Envia un email HTML via SMTP IONOS con STARTTLS."""
    if not MAIL_PASSWORD:
        logger.error("[SMTP] MAIL_PASSWORD no configurado en .env")
        return False

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"]    = f"{MAIL_FROM_NAME} <{MAIL_FROM}>"
    msg["To"]      = to
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
        logger.info(f"[SMTP] Email enviado a {to} — asunto: {subject!r}")
        return True
    except aiosmtplib.SMTPException as exc:
        logger.error(f"[SMTP] Error al enviar a {to}: {exc}")
        return False
    except Exception as exc:
        logger.error(f"[SMTP] Error inesperado al enviar a {to}: {exc}")
        return False


async def send_verification_email(email: str, token: str) -> bool:
    """Envia el email de verificacion de cuenta (registro)."""
    html = _build_welcome_html(token)
    return await _send_email(
        to=email,
        subject="Verifica tu cuenta en InmuFacil",
        html_body=html,
    )


async def send_password_reset_email(email: str, token: str) -> bool:
    """Envia el email de recuperacion de contrasena."""
    html = _build_password_reset_html(token)
    return await _send_email(
        to=email,
        subject="Recupera tu contrasena en InmuFacil",
        html_body=html,
    )


def _build_comfort_request_html(seller_name: str, property_title: str, buyer_name: str) -> str:
    property_link = f"{FRONTEND_BASE_URL}/dashboard/my-properties"
    return f"""
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Solicitud de informe de confort - InmuFacil</title>
</head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="560" cellpadding="0" cellspacing="0"
               style="background:#ffffff;border-radius:16px;overflow:hidden;
                      box-shadow:0 4px 24px rgba(0,0,0,0.08);">

          <!-- Cabecera -->
          <tr>
            <td style="background:#135BEC;padding:32px 40px;text-align:center;">
              <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:800;">InmuFacil</h1>
              <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:13px;">
                Plataforma inmobiliaria entre particulares
              </p>
            </td>
          </tr>

          <!-- Cuerpo -->
          <tr>
            <td style="padding:40px 40px 32px;">
              <h2 style="margin:0 0 12px;color:#0F172A;font-size:20px;font-weight:700;">
                Un comprador solicita el Indice de Confort de tu propiedad
              </h2>
              <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
                Hola <strong>{seller_name}</strong>,
              </p>
              <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
                <strong>{buyer_name}</strong> esta interesado en tu propiedad
                <strong>"{property_title}"</strong> y ha solicitado que actives el
                <strong>Indice de Confort con IA</strong>.
              </p>
              <p style="margin:0 0 28px;color:#475569;font-size:15px;line-height:1.6;">
                Este informe analiza factores como ruido, luz natural, calidad del aire,
                conectividad y confort termico de la zona, y puede aumentar el interes
                de los compradores en tu propiedad.
              </p>

              <!-- CTA -->
              <div style="text-align:center;margin-bottom:28px;">
                <a href="{property_link}"
                   style="display:inline-block;background:#135BEC;color:#ffffff;
                          text-decoration:none;padding:14px 32px;border-radius:10px;
                          font-size:15px;font-weight:700;">
                  Activar Indice de Confort
                </a>
              </div>

              <p style="margin:0;color:#64748B;font-size:13px;line-height:1.6;">
                Para activarlo, entra en tu anuncio, edita la propiedad y activa la opcion
                <em>"Generar informe de confort con IA"</em> en el paso 1 del formulario.
              </p>
            </td>
          </tr>

          <!-- Pie -->
          <tr>
            <td style="background:#F8FAFC;border-top:1px solid #E2E8F0;
                       padding:24px 40px;text-align:center;">
              <p style="margin:0;color:#94A3B8;font-size:12px;">
                InmuFacil &copy; 2025 &middot; Este es un mensaje automatico. No respondas a este correo.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
"""


async def send_comfort_request_email(
    seller_email: str,
    seller_name: str,
    property_title: str,
    buyer_name: str,
) -> bool:
    """Notifica al vendedor que un comprador solicita el Indice de Confort."""
    html = _build_comfort_request_html(seller_name, property_title, buyer_name)
    return await _send_email(
        to=seller_email,
        subject=f"Un comprador solicita el Indice de Confort de '{property_title}'",
        html_body=html,
    )

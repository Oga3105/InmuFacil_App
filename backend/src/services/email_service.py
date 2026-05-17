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


# ============================================================================
# AI Abuse Alert
# ============================================================================

_ALERT_DESTINATION = "alerta@inmufacil.com"

_ALERT_TYPE_LABELS: dict[str, str] = {
    "feature_limit": "Limite de feature alcanzado",
    "global_limit":  "Limite diario global alcanzado",
    "burst":         "Patron de llamadas rapidas detectado (posible bot/ataque)",
}

_ALERT_TYPE_COLORS: dict[str, str] = {
    "feature_limit": "#F59E0B",  # amber
    "global_limit":  "#EF4444",  # red
    "burst":         "#7C3AED",  # purple
}


def _build_ai_abuse_alert_html(
    user_id: int,
    feature: str,
    count: int,
    limit: int,
    ip: str,
    alert_type: str,
    timestamp: str,
) -> str:
    label = _ALERT_TYPE_LABELS.get(alert_type, alert_type)
    color = _ALERT_TYPE_COLORS.get(alert_type, "#EF4444")
    return f"""
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Alerta de uso de IA - InmuFacil</title>
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
            <td style="background:{color};padding:28px 40px;text-align:center;">
              <h1 style="margin:0;color:#ffffff;font-size:20px;font-weight:800;">
                ALERTA DE USO DE IA
              </h1>
              <p style="margin:6px 0 0;color:rgba(255,255,255,0.9);font-size:13px;">
                InmuFacil — Sistema de Seguridad
              </p>
            </td>
          </tr>

          <!-- Tipo de alerta -->
          <tr>
            <td style="padding:28px 40px 0;">
              <div style="background:#FEF3C7;border-left:4px solid {color};
                          border-radius:8px;padding:16px 20px;margin-bottom:24px;">
                <p style="margin:0;font-size:15px;font-weight:700;color:#92400E;">
                  {label}
                </p>
              </div>
            </td>
          </tr>

          <!-- Detalles del evento -->
          <tr>
            <td style="padding:0 40px 28px;">
              <table width="100%" cellpadding="0" cellspacing="0"
                     style="border:1px solid #E2E8F0;border-radius:10px;overflow:hidden;">
                <tr style="background:#F8FAFC;">
                  <td style="padding:10px 16px;font-size:12px;font-weight:700;
                             color:#64748B;text-transform:uppercase;width:40%;">
                    Campo
                  </td>
                  <td style="padding:10px 16px;font-size:12px;font-weight:700;
                             color:#64748B;text-transform:uppercase;">
                    Valor
                  </td>
                </tr>
                <tr style="border-top:1px solid #E2E8F0;">
                  <td style="padding:12px 16px;color:#475569;font-size:14px;">User ID</td>
                  <td style="padding:12px 16px;color:#0F172A;font-size:14px;
                             font-weight:600;font-family:monospace;">{user_id}</td>
                </tr>
                <tr style="background:#F8FAFC;border-top:1px solid #E2E8F0;">
                  <td style="padding:12px 16px;color:#475569;font-size:14px;">Feature</td>
                  <td style="padding:12px 16px;color:#0F172A;font-size:14px;
                             font-weight:600;font-family:monospace;">{feature}</td>
                </tr>
                <tr style="border-top:1px solid #E2E8F0;">
                  <td style="padding:12px 16px;color:#475569;font-size:14px;">Llamadas</td>
                  <td style="padding:12px 16px;color:#DC2626;font-size:14px;
                             font-weight:700;">{count} / {limit}</td>
                </tr>
                <tr style="background:#F8FAFC;border-top:1px solid #E2E8F0;">
                  <td style="padding:12px 16px;color:#475569;font-size:14px;">IP</td>
                  <td style="padding:12px 16px;color:#0F172A;font-size:14px;
                             font-family:monospace;">{ip}</td>
                </tr>
                <tr style="border-top:1px solid #E2E8F0;">
                  <td style="padding:12px 16px;color:#475569;font-size:14px;">Timestamp</td>
                  <td style="padding:12px 16px;color:#0F172A;font-size:14px;">{timestamp}</td>
                </tr>
                <tr style="background:#F8FAFC;border-top:1px solid #E2E8F0;">
                  <td style="padding:12px 16px;color:#475569;font-size:14px;">Tipo</td>
                  <td style="padding:12px 16px;font-size:14px;">
                    <span style="background:{color};color:#fff;border-radius:6px;
                                 padding:3px 10px;font-size:12px;font-weight:700;">
                      {alert_type.upper()}
                    </span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Acciones recomendadas -->
          <tr>
            <td style="padding:0 40px 28px;">
              <p style="margin:0 0 10px;color:#475569;font-size:13px;font-weight:700;">
                Acciones recomendadas:
              </p>
              <ul style="margin:0;padding-left:20px;color:#64748B;font-size:13px;line-height:1.8;">
                <li>Verificar en la BD si el usuario tiene patron de abuso sistematico</li>
                <li>Revisar logs de uvicorn para este user_id y rango horario</li>
                <li>Considerar suspension temporal si el patron persiste</li>
              </ul>
            </td>
          </tr>

          <!-- Pie -->
          <tr>
            <td style="background:#F8FAFC;border-top:1px solid #E2E8F0;
                       padding:20px 40px;text-align:center;">
              <p style="margin:0;color:#94A3B8;font-size:11px;">
                InmuFacil &copy; 2025 &middot; Sistema de Alertas de Seguridad IA<br>
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


# ============================================================================
# Action Confirmation Emails — sent to the ACTOR (always, regardless of prefs)
# and Notification Emails — sent to the OTHER PARTY (only if notifications ON)
# ============================================================================

def _build_comfort_request_confirmation_html(
    buyer_name: str, seller_name: str, property_title: str
) -> str:
    dashboard_link = f"{FRONTEND_BASE_URL}/profile"
    return f"""
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Solicitud enviada - InmuFacil</title>
</head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 0;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:16px;overflow:hidden;
                    box-shadow:0 4px 24px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:#135BEC;padding:32px 40px;text-align:center;">
            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:800;">InmuFacil</h1>
            <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:13px;">
              Plataforma inmobiliaria entre particulares
            </p>
          </td>
        </tr>
        <tr>
          <td style="padding:40px 40px 32px;">
            <h2 style="margin:0 0 12px;color:#0F172A;font-size:20px;font-weight:700;">
              Tu solicitud ha sido enviada
            </h2>
            <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
              Hola <strong>{buyer_name}</strong>,
            </p>
            <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
              Has solicitado el <strong>Indice de Confort con IA</strong> para la propiedad
              <strong>"{property_title}"</strong>.
            </p>
            <div style="background:#EFF6FF;border-left:4px solid #135BEC;border-radius:8px;
                        padding:16px 20px;margin-bottom:24px;">
              <p style="margin:0;font-size:14px;color:#1E40AF;">
                <strong>Accion realizada:</strong> Solicitud de Indice de Confort<br>
                <strong>Propiedad:</strong> {property_title}<br>
                <strong>Vendedor notificado:</strong> {seller_name}
              </p>
            </div>
            <p style="margin:0 0 20px;color:#475569;font-size:14px;line-height:1.6;">
              Hemos notificado al vendedor. Si activa el analisis, el informe de confort
              aparecera en el detalle de la propiedad automaticamente.
            </p>
            <div style="text-align:center;margin-bottom:28px;">
              <a href="{dashboard_link}"
                 style="display:inline-block;background:#135BEC;color:#ffffff;
                        text-decoration:none;padding:14px 32px;border-radius:10px;
                        font-size:15px;font-weight:700;">
                Ver mis ofertas
              </a>
            </div>
          </td>
        </tr>
        <tr>
          <td style="background:#F8FAFC;border-top:1px solid #E2E8F0;
                     padding:24px 40px;text-align:center;">
            <p style="margin:0;color:#94A3B8;font-size:12px;">
              InmuFacil &copy; 2025 &middot; Este es un mensaje automatico. No respondas a este correo.
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
"""


async def send_comfort_request_confirmation_email(
    buyer_email: str,
    buyer_name: str,
    seller_name: str,
    property_title: str,
) -> bool:
    """Confirmacion al COMPRADOR de que su solicitud de Indice de Confort fue enviada."""
    html = _build_comfort_request_confirmation_html(buyer_name, seller_name, property_title)
    return await _send_email(
        to=buyer_email,
        subject=f"Has solicitado el Indice de Confort de '{property_title}'",
        html_body=html,
    )


def _build_offer_received_html(
    seller_name: str,
    buyer_name: str,
    property_title: str,
    property_address: str,
    amount: int,
    valid_until: str,
) -> str:
    formatted_amount = f"{amount:,}".replace(",", ".")
    offers_link = f"{FRONTEND_BASE_URL}/profile"
    return f"""
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Nueva oferta recibida - InmuFacil</title>
</head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 0;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:16px;overflow:hidden;
                    box-shadow:0 4px 24px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:#135BEC;padding:32px 40px;text-align:center;">
            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:800;">InmuFacil</h1>
            <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:13px;">
              Plataforma inmobiliaria entre particulares
            </p>
          </td>
        </tr>
        <tr>
          <td style="padding:40px 40px 32px;">
            <h2 style="margin:0 0 12px;color:#0F172A;font-size:20px;font-weight:700;">
              Has recibido una nueva oferta
            </h2>
            <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
              Hola <strong>{seller_name}</strong>,
            </p>
            <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
              <strong>{buyer_name}</strong> ha presentado una oferta por tu propiedad en InmuFacil.
            </p>
            <div style="background:#EFF6FF;border-left:4px solid #135BEC;border-radius:8px;
                        padding:16px 20px;margin-bottom:24px;">
              <p style="margin:0;font-size:14px;color:#1E40AF;">
                <strong>Propiedad:</strong> {property_title}<br>
                <strong>Direccion:</strong> {property_address}<br>
                <strong>Oferta recibida:</strong> {formatted_amount} EUR<br>
                <strong>Comprador:</strong> {buyer_name}<br>
                <strong>Valida hasta:</strong> {valid_until}
              </p>
            </div>
            <p style="margin:0 0 20px;color:#475569;font-size:14px;line-height:1.6;">
              Tienes <strong>48 horas</strong> para aceptar, rechazar o realizar una contraoferta.
              Si no respondes en ese plazo, la oferta expirara automaticamente.
            </p>
            <div style="text-align:center;margin-bottom:28px;">
              <a href="{offers_link}"
                 style="display:inline-block;background:#135BEC;color:#ffffff;
                        text-decoration:none;padding:14px 32px;border-radius:10px;
                        font-size:15px;font-weight:700;">
                Ver oferta en InmuFacil
              </a>
            </div>
          </td>
        </tr>
        <tr>
          <td style="background:#F8FAFC;border-top:1px solid #E2E8F0;
                     padding:24px 40px;text-align:center;">
            <p style="margin:0;color:#94A3B8;font-size:12px;">
              InmuFacil &copy; 2025 &middot; Este es un mensaje automatico. No respondas a este correo.
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
"""


async def send_offer_received_email(
    seller_email: str,
    seller_name: str,
    buyer_name: str,
    property_title: str,
    property_address: str,
    amount: int,
    valid_until: str,
) -> bool:
    """Notificacion al VENDEDOR de que ha recibido una nueva oferta."""
    formatted_amount = f"{amount:,}".replace(",", ".")
    html = _build_offer_received_html(
        seller_name, buyer_name, property_title, property_address, amount, valid_until
    )
    return await _send_email(
        to=seller_email,
        subject=f"Has recibido una oferta de {formatted_amount} EUR por '{property_title}'",
        html_body=html,
    )


def _build_offer_sent_confirmation_html(
    buyer_name: str,
    property_title: str,
    property_address: str,
    amount: int,
    seller_name: str,
    valid_until: str,
) -> str:
    formatted_amount = f"{amount:,}".replace(",", ".")
    offers_link = f"{FRONTEND_BASE_URL}/profile"
    return f"""
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Oferta enviada - InmuFacil</title>
</head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 0;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:16px;overflow:hidden;
                    box-shadow:0 4px 24px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:#135BEC;padding:32px 40px;text-align:center;">
            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:800;">InmuFacil</h1>
            <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:13px;">
              Plataforma inmobiliaria entre particulares
            </p>
          </td>
        </tr>
        <tr>
          <td style="padding:40px 40px 32px;">
            <h2 style="margin:0 0 12px;color:#0F172A;font-size:20px;font-weight:700;">
              Tu oferta ha sido enviada
            </h2>
            <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
              Hola <strong>{buyer_name}</strong>,
            </p>
            <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
              Tu oferta ha sido enviada correctamente al vendedor. Te avisaremos cuando responda.
            </p>
            <div style="background:#EFF6FF;border-left:4px solid #135BEC;border-radius:8px;
                        padding:16px 20px;margin-bottom:24px;">
              <p style="margin:0;font-size:14px;color:#1E40AF;">
                <strong>Accion realizada:</strong> Oferta enviada<br>
                <strong>Propiedad:</strong> {property_title}<br>
                <strong>Direccion:</strong> {property_address}<br>
                <strong>Importe ofertado:</strong> {formatted_amount} EUR<br>
                <strong>Vendedor:</strong> {seller_name}<br>
                <strong>Oferta valida hasta:</strong> {valid_until}
              </p>
            </div>
            <p style="margin:0 0 20px;color:#475569;font-size:14px;line-height:1.6;">
              El vendedor tiene 48 horas para aceptar, rechazar o realizar una contraoferta.
              Puedes seguir el estado desde tu perfil en InmuFacil.
            </p>
            <div style="text-align:center;margin-bottom:28px;">
              <a href="{offers_link}"
                 style="display:inline-block;background:#135BEC;color:#ffffff;
                        text-decoration:none;padding:14px 32px;border-radius:10px;
                        font-size:15px;font-weight:700;">
                Ver mis ofertas
              </a>
            </div>
          </td>
        </tr>
        <tr>
          <td style="background:#F8FAFC;border-top:1px solid #E2E8F0;
                     padding:24px 40px;text-align:center;">
            <p style="margin:0;color:#94A3B8;font-size:12px;">
              InmuFacil &copy; 2025 &middot; Este es un mensaje automatico. No respondas a este correo.
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
"""


async def send_offer_sent_confirmation_email(
    buyer_email: str,
    buyer_name: str,
    property_title: str,
    property_address: str,
    amount: int,
    seller_name: str,
    valid_until: str,
) -> bool:
    """Confirmacion al COMPRADOR de que su oferta fue enviada correctamente."""
    formatted_amount = f"{amount:,}".replace(",", ".")
    html = _build_offer_sent_confirmation_html(
        buyer_name, property_title, property_address, amount, seller_name, valid_until
    )
    return await _send_email(
        to=buyer_email,
        subject=f"Tu oferta de {formatted_amount} EUR ha sido enviada",
        html_body=html,
    )


def _build_offer_accepted_notification_html(
    buyer_name: str,
    property_title: str,
    property_address: str,
    amount: int,
) -> str:
    formatted_amount = f"{amount:,}".replace(",", ".")
    offers_link = f"{FRONTEND_BASE_URL}/profile"
    return f"""
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Oferta aceptada - InmuFacil</title>
</head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 0;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:16px;overflow:hidden;
                    box-shadow:0 4px 24px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:#16A34A;padding:32px 40px;text-align:center;">
            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:800;">InmuFacil</h1>
            <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:13px;">
              Plataforma inmobiliaria entre particulares
            </p>
          </td>
        </tr>
        <tr>
          <td style="padding:40px 40px 32px;">
            <h2 style="margin:0 0 12px;color:#0F172A;font-size:20px;font-weight:700;">
              Tu oferta ha sido aceptada
            </h2>
            <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
              Hola <strong>{buyer_name}</strong>,
            </p>
            <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
              Excelente noticia: el propietario ha aceptado tu oferta.
            </p>
            <div style="background:#F0FDF4;border-left:4px solid #16A34A;border-radius:8px;
                        padding:16px 20px;margin-bottom:24px;">
              <p style="margin:0;font-size:14px;color:#14532D;">
                <strong>Propiedad:</strong> {property_title}<br>
                <strong>Direccion:</strong> {property_address}<br>
                <strong>Importe acordado:</strong> {formatted_amount} EUR
              </p>
            </div>
            <p style="margin:0 0 20px;color:#475569;font-size:14px;line-height:1.6;">
              El siguiente paso es iniciar el proceso de arras y formalizacion de la compraventa.
              Accede a tu perfil para revisar los proximos pasos: firma del contrato de arras,
              obtencion de financiacion y cita en notaria.
            </p>
            <div style="text-align:center;margin-bottom:28px;">
              <a href="{offers_link}"
                 style="display:inline-block;background:#16A34A;color:#ffffff;
                        text-decoration:none;padding:14px 32px;border-radius:10px;
                        font-size:15px;font-weight:700;">
                Continuar el proceso
              </a>
            </div>
          </td>
        </tr>
        <tr>
          <td style="background:#F8FAFC;border-top:1px solid #E2E8F0;
                     padding:24px 40px;text-align:center;">
            <p style="margin:0;color:#94A3B8;font-size:12px;">
              InmuFacil &copy; 2025 &middot; Este es un mensaje automatico. No respondas a este correo.
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
"""


async def send_offer_accepted_notification_email(
    buyer_email: str,
    buyer_name: str,
    property_title: str,
    property_address: str,
    amount: int,
) -> bool:
    """Notificacion al COMPRADOR de que su oferta ha sido aceptada."""
    formatted_amount = f"{amount:,}".replace(",", ".")
    html = _build_offer_accepted_notification_html(
        buyer_name, property_title, property_address, amount
    )
    return await _send_email(
        to=buyer_email,
        subject=f"Tu oferta de {formatted_amount} EUR ha sido aceptada",
        html_body=html,
    )


def _build_offer_accepted_confirmation_html(
    seller_name: str,
    buyer_name: str,
    property_title: str,
    property_address: str,
    amount: int,
) -> str:
    formatted_amount = f"{amount:,}".replace(",", ".")
    offers_link = f"{FRONTEND_BASE_URL}/profile"
    return f"""
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Oferta aceptada - InmuFacil</title>
</head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 0;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:16px;overflow:hidden;
                    box-shadow:0 4px 24px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:#16A34A;padding:32px 40px;text-align:center;">
            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:800;">InmuFacil</h1>
            <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:13px;">
              Plataforma inmobiliaria entre particulares
            </p>
          </td>
        </tr>
        <tr>
          <td style="padding:40px 40px 32px;">
            <h2 style="margin:0 0 12px;color:#0F172A;font-size:20px;font-weight:700;">
              Has aceptado la oferta
            </h2>
            <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
              Hola <strong>{seller_name}</strong>,
            </p>
            <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
              Has aceptado la oferta de <strong>{buyer_name}</strong>. El comprador ha sido
              notificado y comenzara el proceso de formalizacion de la compraventa.
            </p>
            <div style="background:#F0FDF4;border-left:4px solid #16A34A;border-radius:8px;
                        padding:16px 20px;margin-bottom:24px;">
              <p style="margin:0;font-size:14px;color:#14532D;">
                <strong>Accion realizada:</strong> Oferta aceptada<br>
                <strong>Propiedad:</strong> {property_title}<br>
                <strong>Direccion:</strong> {property_address}<br>
                <strong>Importe acordado:</strong> {formatted_amount} EUR<br>
                <strong>Comprador:</strong> {buyer_name}
              </p>
            </div>
            <p style="margin:0 0 20px;color:#475569;font-size:14px;line-height:1.6;">
              Espera el contacto del comprador para coordinar los proximos pasos:
              contrato de arras y cita en notaria.
            </p>
            <div style="text-align:center;margin-bottom:28px;">
              <a href="{offers_link}"
                 style="display:inline-block;background:#16A34A;color:#ffffff;
                        text-decoration:none;padding:14px 32px;border-radius:10px;
                        font-size:15px;font-weight:700;">
                Ver mis ofertas recibidas
              </a>
            </div>
          </td>
        </tr>
        <tr>
          <td style="background:#F8FAFC;border-top:1px solid #E2E8F0;
                     padding:24px 40px;text-align:center;">
            <p style="margin:0;color:#94A3B8;font-size:12px;">
              InmuFacil &copy; 2025 &middot; Este es un mensaje automatico. No respondas a este correo.
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
"""


async def send_offer_accepted_confirmation_email(
    seller_email: str,
    seller_name: str,
    buyer_name: str,
    property_title: str,
    property_address: str,
    amount: int,
) -> bool:
    """Confirmacion al VENDEDOR de que acepto la oferta."""
    formatted_amount = f"{amount:,}".replace(",", ".")
    html = _build_offer_accepted_confirmation_html(
        seller_name, buyer_name, property_title, property_address, amount
    )
    return await _send_email(
        to=seller_email,
        subject=f"Has aceptado la oferta de {buyer_name} por '{property_title}'",
        html_body=html,
    )


def _build_counter_offer_html(
    recipient_name: str,
    actor_name: str,
    property_title: str,
    new_amount: int,
    is_confirmation: bool,
) -> str:
    """Reutilizado para notificacion al destinatario Y confirmacion al actor."""
    formatted_amount = f"{new_amount:,}".replace(",", ".")
    offers_link = f"{FRONTEND_BASE_URL}/profile"
    if is_confirmation:
        heading = "Tu contraoferta ha sido enviada"
        intro = f"Has enviado una contraoferta de <strong>{formatted_amount} EUR</strong> " \
                f"por la propiedad <strong>\"{property_title}\"</strong>."
        action_label = "Accion realizada: Contraoferta enviada"
        other_label = f"Destinatario notificado: {actor_name}"
        cta_text = "Ver mis ofertas"
    else:
        heading = "Has recibido una contraoferta"
        intro = f"<strong>{actor_name}</strong> ha enviado una contraoferta de " \
                f"<strong>{formatted_amount} EUR</strong> por la propiedad " \
                f"<strong>\"{property_title}\"</strong>."
        action_label = "Tipo de accion: Contraoferta recibida"
        other_label = f"Realizada por: {actor_name}"
        cta_text = "Responder en InmuFacil"

    return f"""
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{heading} - InmuFacil</title>
</head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 0;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:16px;overflow:hidden;
                    box-shadow:0 4px 24px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:#7C3AED;padding:32px 40px;text-align:center;">
            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:800;">InmuFacil</h1>
            <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:13px;">
              Plataforma inmobiliaria entre particulares
            </p>
          </td>
        </tr>
        <tr>
          <td style="padding:40px 40px 32px;">
            <h2 style="margin:0 0 12px;color:#0F172A;font-size:20px;font-weight:700;">
              {heading}
            </h2>
            <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
              Hola <strong>{recipient_name}</strong>,
            </p>
            <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
              {intro}
            </p>
            <div style="background:#F5F3FF;border-left:4px solid #7C3AED;border-radius:8px;
                        padding:16px 20px;margin-bottom:24px;">
              <p style="margin:0;font-size:14px;color:#4C1D95;">
                <strong>{action_label}</strong><br>
                <strong>Propiedad:</strong> {property_title}<br>
                <strong>Nuevo importe:</strong> {formatted_amount} EUR<br>
                <strong>{other_label}</strong>
              </p>
            </div>
            <p style="margin:0 0 20px;color:#475569;font-size:14px;line-height:1.6;">
              Accede a tu perfil para ver los detalles y responder.
            </p>
            <div style="text-align:center;margin-bottom:28px;">
              <a href="{offers_link}"
                 style="display:inline-block;background:#7C3AED;color:#ffffff;
                        text-decoration:none;padding:14px 32px;border-radius:10px;
                        font-size:15px;font-weight:700;">
                {cta_text}
              </a>
            </div>
          </td>
        </tr>
        <tr>
          <td style="background:#F8FAFC;border-top:1px solid #E2E8F0;
                     padding:24px 40px;text-align:center;">
            <p style="margin:0;color:#94A3B8;font-size:12px;">
              InmuFacil &copy; 2025 &middot; Este es un mensaje automatico. No respondas a este correo.
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
"""


async def send_counter_offer_notification_email(
    recipient_email: str,
    recipient_name: str,
    actor_name: str,
    property_title: str,
    new_amount: int,
) -> bool:
    """Notificacion al OTRO PARTICIPANTE de que ha recibido una contraoferta."""
    formatted_amount = f"{new_amount:,}".replace(",", ".")
    html = _build_counter_offer_html(
        recipient_name, actor_name, property_title, new_amount, is_confirmation=False
    )
    return await _send_email(
        to=recipient_email,
        subject=f"Nueva contraoferta de {formatted_amount} EUR por '{property_title}'",
        html_body=html,
    )


async def send_counter_offer_confirmation_email(
    actor_email: str,
    actor_name: str,
    property_title: str,
    new_amount: int,
) -> bool:
    """Confirmacion al ACTOR de que su contraoferta ha sido enviada."""
    formatted_amount = f"{new_amount:,}".replace(",", ".")
    html = _build_counter_offer_html(
        actor_name, actor_name, property_title, new_amount, is_confirmation=True
    )
    return await _send_email(
        to=actor_email,
        subject=f"Tu contraoferta de {formatted_amount} EUR ha sido enviada",
        html_body=html,
    )


# ============================================================================
# Visit Request Email (when seller has no availability windows)
# ============================================================================

def _build_visit_request_html(
    seller_name: str,
    buyer_name: str,
    property_title: str,
    buyer_message: str,
) -> str:
    property_link = f"{FRONTEND_BASE_URL}/dashboard/my-properties"
    message_block = ""
    if buyer_message:
        message_block = f"""
              <div style="background:#F8FAFC;border-left:4px solid #94A3B8;border-radius:8px;
                          padding:16px 20px;margin-bottom:24px;">
                <p style="margin:0 0 6px;font-size:12px;font-weight:700;color:#64748B;
                          text-transform:uppercase;">Mensaje del comprador:</p>
                <p style="margin:0;font-size:14px;color:#1E293B;line-height:1.6;
                          font-style:italic;">"{buyer_message}"</p>
              </div>"""
    return f"""
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Solicitud de visita - InmuFacil</title>
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
                Un comprador quiere visitar tu propiedad
              </h2>
              <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
                Hola <strong>{seller_name}</strong>,
              </p>
              <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
                <strong>{buyer_name}</strong> esta interesado en visitar tu propiedad
                <strong>"{property_title}"</strong>, pero aun no has configurado
                horarios de disponibilidad.
              </p>
              {message_block}
              <p style="margin:0 0 28px;color:#475569;font-size:15px;line-height:1.6;">
                Para que los compradores puedan reservar una visita, necesitas abrir
                ventanas de disponibilidad desde tu panel de propiedades.
              </p>

              <!-- CTA -->
              <div style="text-align:center;margin-bottom:28px;">
                <a href="{property_link}"
                   style="display:inline-block;background:#135BEC;color:#ffffff;
                          text-decoration:none;padding:14px 32px;border-radius:10px;
                          font-size:15px;font-weight:700;">
                  Configurar horarios de visita
                </a>
              </div>

              <p style="margin:0;color:#64748B;font-size:13px;line-height:1.6;">
                Puedes definir los dias y horas que mejor te convengan. Los compradores
                interesados podran reservar automaticamente.
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


async def send_visit_request_email(
    seller_email: str,
    seller_name: str,
    buyer_name: str,
    property_title: str,
    buyer_message: str = "",
) -> bool:
    """Notifica al vendedor que un comprador quiere visitar su propiedad."""
    html = _build_visit_request_html(seller_name, buyer_name, property_title, buyer_message)
    return await _send_email(
        to=seller_email,
        subject=f"{buyer_name} quiere visitar tu propiedad '{property_title}'",
        html_body=html,
    )


# ============================================================================
# AI Abuse Alert (internal — kept below the user-facing emails)
# ============================================================================

async def send_ai_abuse_alert_email(
    user_id: int,
    feature: str,
    count: int,
    limit: int,
    ip: str,
    alert_type: str,
) -> bool:
    """
    Envia alerta de abuso/limite de IA a alerta@inmufacil.com.

    Parametros:
        user_id:    ID del usuario que provoco el evento.
        feature:    Clave de la feature afectada (ej. 'market_price').
        count:      Numero de llamadas realizadas.
        limit:      Limite configurado que fue igualado o superado.
        ip:         IP de la ultima request del usuario.
        alert_type: 'feature_limit' | 'global_limit' | 'burst'
    """
    from datetime import datetime, timezone
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    label = _ALERT_TYPE_LABELS.get(alert_type, alert_type)
    html = _build_ai_abuse_alert_html(
        user_id=user_id,
        feature=feature,
        count=count,
        limit=limit,
        ip=ip,
        alert_type=alert_type,
        timestamp=timestamp,
    )
    return await _send_email(
        to=_ALERT_DESTINATION,
        subject=f"[InmuFacil ALERTA IA] {label} — user_id={user_id} feature={feature}",
        html_body=html,
    )


# ---------------------------------------------------------------------------
# CEE Pending — Offer saved but property lacks valid energy certificate
# ---------------------------------------------------------------------------

def _build_cee_pending_offer_html(
    seller_name: str,
    buyer_name: str,
    property_title: str,
    property_address: str,
    amount: int,
) -> str:
    formatted_amount = f"{amount:,}".replace(",", ".")
    dashboard_link = f"{FRONTEND_BASE_URL}/profile"
    return f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Oferta pendiente - certificado energetico requerido</title>
</head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 0;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:16px;overflow:hidden;
                    box-shadow:0 4px 24px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:#D97706;padding:32px 40px;text-align:center;">
            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:800;">InmuFacil</h1>
            <p style="margin:6px 0 0;color:rgba(255,255,255,0.85);font-size:13px;">
              Plataforma inmobiliaria entre particulares
            </p>
          </td>
        </tr>
        <tr>
          <td style="padding:40px 40px 32px;">
            <h2 style="margin:0 0 12px;color:#0F172A;font-size:20px;font-weight:700;">
              Tienes una oferta pendiente
            </h2>
            <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
              Hola <strong>{seller_name}</strong>,
            </p>
            <p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.6;">
              <strong>{buyer_name}</strong> ha realizado una oferta por tu propiedad, pero
              <strong>no puedes recibirla hasta que anadas el certificado energetico</strong>.
            </p>
            <div style="background:#FFFBEB;border-left:4px solid #D97706;border-radius:8px;
                        padding:16px 20px;margin-bottom:24px;">
              <p style="margin:0;font-size:14px;color:#92400E;">
                <strong>Propiedad:</strong> {property_title}<br>
                <strong>Direccion:</strong> {property_address}<br>
                <strong>Oferta recibida:</strong> {formatted_amount} EUR<br>
                <strong>Comprador:</strong> {buyer_name}
              </p>
            </div>
            <div style="background:#FEF3C7;border-radius:8px;padding:16px 20px;margin-bottom:24px;">
              <p style="margin:0;font-size:14px;color:#78350F;line-height:1.6;">
                Para que el comprador pueda ver su oferta y continuar el proceso,
                accede a tu propiedad en InmuFacil y anade la clasificacion del
                certificado energetico (A, B, C, D, E, F o G).
                En cuanto lo hagas, la oferta se activara automaticamente.
              </p>
            </div>
            <div style="text-align:center;margin-bottom:28px;">
              <a href="{dashboard_link}"
                 style="display:inline-block;background:#D97706;color:#ffffff;
                        text-decoration:none;padding:14px 32px;border-radius:10px;
                        font-size:15px;font-weight:700;">
                Anadir certificado energetico
              </a>
            </div>
          </td>
        </tr>
        <tr>
          <td style="background:#F8FAFC;border-top:1px solid #E2E8F0;
                     padding:24px 40px;text-align:center;">
            <p style="margin:0;color:#94A3B8;font-size:12px;">
              InmuFacil &copy; 2025 &middot; Este es un mensaje automatico. No respondas a este correo.
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>"""


async def send_cee_pending_offer_email(
    seller_email: str,
    seller_name: str,
    buyer_name: str,
    property_title: str,
    property_address: str,
    amount: int,
) -> bool:
    """Notifica al VENDEDOR que tiene una oferta pendiente por falta de certificado energetico."""
    formatted_amount = f"{amount:,}".replace(",", ".")
    html = _build_cee_pending_offer_html(
        seller_name, buyer_name, property_title, property_address, amount
    )
    return await _send_email(
        to=seller_email,
        subject=f"Oferta pendiente en '{property_title}' — Anade el certificado energetico",
        html_body=html,
    )

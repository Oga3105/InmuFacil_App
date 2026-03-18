"""
Email Templates Service

@Shield: Corporate HTML email templates for InmuFacil platform.
         No PII logged, no secrets hardcoded.
@FrontendProxy: Templates match user-facing communication flows.

All templates return complete, standards-compliant HTML strings.
"""


def _base_layout(title: str, content: str) -> str:
    """
    Wrap content in the shared corporate HTML layout.
    Max width 600px, InmuFacil brand color #2563EB.
    """
    return f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>{title}</title>
  <style>
    body {{
      margin: 0;
      padding: 0;
      background-color: #f3f4f6;
      font-family: Arial, Helvetica, sans-serif;
      color: #111827;
    }}
    .wrapper {{
      width: 100%;
      background-color: #f3f4f6;
      padding: 32px 0;
    }}
    .container {{
      max-width: 600px;
      margin: 0 auto;
      background-color: #ffffff;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }}
    .header {{
      background-color: #2563EB;
      padding: 28px 32px;
    }}
    .header h1 {{
      margin: 0;
      font-size: 22px;
      font-weight: 700;
      color: #ffffff;
      letter-spacing: -0.3px;
    }}
    .header p {{
      margin: 4px 0 0;
      font-size: 13px;
      color: #bfdbfe;
    }}
    .body {{
      padding: 32px;
    }}
    .body h2 {{
      margin: 0 0 16px;
      font-size: 18px;
      font-weight: 600;
      color: #111827;
    }}
    .body p {{
      margin: 0 0 16px;
      font-size: 14px;
      line-height: 1.6;
      color: #374151;
    }}
    .button-wrap {{
      text-align: center;
      margin: 28px 0;
    }}
    .button {{
      display: inline-block;
      padding: 14px 28px;
      background-color: #2563EB;
      color: #ffffff;
      text-decoration: none;
      border-radius: 6px;
      font-size: 15px;
      font-weight: 600;
    }}
    .info-box {{
      background-color: #eff6ff;
      border-left: 4px solid #2563EB;
      border-radius: 4px;
      padding: 14px 18px;
      margin: 20px 0;
      font-size: 14px;
      color: #1e40af;
    }}
    .divider {{
      border: none;
      border-top: 1px solid #e5e7eb;
      margin: 24px 0;
    }}
    .footer {{
      background-color: #f9fafb;
      border-top: 1px solid #e5e7eb;
      padding: 20px 32px;
      text-align: center;
    }}
    .footer p {{
      margin: 0;
      font-size: 12px;
      color: #6b7280;
      line-height: 1.6;
    }}
    .footer a {{
      color: #2563EB;
      text-decoration: none;
    }}
  </style>
</head>
<body>
  <div class="wrapper">
    <table class="container" width="100%" cellpadding="0" cellspacing="0" role="presentation">
      <tr>
        <td>
          <div class="header">
            <h1>InmuFacil</h1>
            <p>Plataforma de compraventa inmobiliaria</p>
          </div>
          <div class="body">
            {content}
          </div>
          <div class="footer">
            <p>
              InmuFacil - Plataforma de compraventa inmobiliaria<br />
              Este mensaje ha sido enviado de forma automatica. Por favor, no respondas a este correo.<br />
              Si tienes dudas, contacta con nuestro equipo de soporte.
            </p>
            <p style="margin-top:8px;">
              <a href="#">Politica de privacidad</a> &nbsp;|&nbsp; <a href="#">Terminos de uso</a>
            </p>
          </div>
        </td>
      </tr>
    </table>
  </div>
</body>
</html>"""


def password_reset_template(reset_url: str, expires_hours: int = 1) -> str:
    """
    HTML email template for password reset requests.

    Args:
        reset_url: The unique URL the user must visit to reset their password.
        expires_hours: Number of hours before the reset link expires (default 1).

    Returns:
        Complete HTML string ready to send as email body.
    """
    hours_label = "1 hora" if expires_hours == 1 else f"{expires_hours} horas"

    content = f"""
      <h2>Restablecer contrasena</h2>
      <p>Hemos recibido una solicitud para restablecer la contrasena de tu cuenta en InmuFacil.</p>
      <p>Haz clic en el boton siguiente para crear una nueva contrasena. Si no realizaste esta solicitud,
         puedes ignorar este mensaje de forma segura.</p>
      <div class="button-wrap">
        <a href="{reset_url}" class="button">Restablecer contrasena</a>
      </div>
      <div class="info-box">
        Este enlace es valido durante <strong>{hours_label}</strong> a partir del momento en que
        fue enviado. Pasado ese tiempo tendras que solicitar un nuevo enlace.
      </div>
      <hr class="divider" />
      <p style="font-size:13px; color:#6b7280;">
        Si el boton no funciona, copia y pega la siguiente URL en tu navegador:<br />
        <span style="word-break:break-all; color:#2563EB;">{reset_url}</span>
      </p>
      <p style="font-size:13px; color:#6b7280;">
        Por motivos de seguridad, nunca compartas este enlace con nadie.
        InmuFacil jamas te pedira tu contrasena por correo electronico.
      </p>
    """
    return _base_layout("Restablecer contrasena - InmuFacil", content)


def offer_received_template(
    seller_name: str,
    property_address: str,
    offer_amount: int,
    buyer_name: str,
) -> str:
    """
    HTML email template notifying a seller that a new offer has been received.

    Args:
        seller_name: Full name of the property seller.
        property_address: Human-readable address of the listed property.
        offer_amount: Offer amount in euros (integer, no decimals).
        buyer_name: Full name of the buyer who submitted the offer.

    Returns:
        Complete HTML string ready to send as email body.
    """
    formatted_amount = f"{offer_amount:,}".replace(",", ".")

    content = f"""
      <h2>Has recibido una nueva oferta</h2>
      <p>Hola <strong>{seller_name}</strong>,</p>
      <p>Un comprador interesado ha presentado una oferta para tu inmueble en InmuFacil.
         Accede a la plataforma para revisarla y responder.</p>
      <div class="info-box">
        <strong>Inmueble:</strong> {property_address}<br />
        <strong>Oferta recibida:</strong> {formatted_amount} EUR<br />
        <strong>Comprador:</strong> {buyer_name}
      </div>
      <div class="button-wrap">
        <a href="#" class="button">Ver oferta en InmuFacil</a>
      </div>
      <p>Tienes 48 horas para aceptar, rechazar o realizar una contraoferta.
         Si no respondes en ese plazo, la oferta expirara automaticamente.</p>
      <p>Recuerda que en InmuFacil operas directamente con el comprador, sin intermediarios
         y sin comisiones de agencia.</p>
    """
    return _base_layout("Nueva oferta recibida - InmuFacil", content)


def offer_accepted_template(
    buyer_name: str,
    property_address: str,
    offer_amount: int,
) -> str:
    """
    HTML email template notifying a buyer that their offer has been accepted.

    Args:
        buyer_name: Full name of the buyer whose offer was accepted.
        property_address: Human-readable address of the property.
        offer_amount: Accepted offer amount in euros (integer, no decimals).

    Returns:
        Complete HTML string ready to send as email body.
    """
    formatted_amount = f"{offer_amount:,}".replace(",", ".")

    content = f"""
      <h2>Tu oferta ha sido aceptada</h2>
      <p>Hola <strong>{buyer_name}</strong>,</p>
      <p>Excelente noticia: el propietario ha aceptado tu oferta. El siguiente paso es
         iniciar el proceso de arras y formalizacion de la compraventa a traves de InmuFacil.</p>
      <div class="info-box">
        <strong>Inmueble:</strong> {property_address}<br />
        <strong>Importe acordado:</strong> {formatted_amount} EUR
      </div>
      <div class="button-wrap">
        <a href="#" class="button">Continuar el proceso en InmuFacil</a>
      </div>
      <p>Accede a la plataforma para revisar los proximos pasos: firma del contrato de
         arras, obtencion de financiacion y cita en notaria.</p>
      <p>Si tienes alguna duda durante el proceso, nuestro equipo de soporte esta disponible
         para ayudarte.</p>
    """
    return _base_layout("Oferta aceptada - InmuFacil", content)


def welcome_template(user_name: str) -> str:
    """
    HTML welcome email template for newly registered users.

    Args:
        user_name: Full name or display name of the new user.

    Returns:
        Complete HTML string ready to send as email body.
    """
    content = f"""
      <h2>Bienvenido a InmuFacil</h2>
      <p>Hola <strong>{user_name}</strong>,</p>
      <p>Tu cuenta ha sido creada con exito. Gracias por unirte a InmuFacil, la plataforma
         de compraventa inmobiliaria directa entre particulares, sin intermediarios y sin
         comisiones de agencia.</p>
      <div class="info-box">
        <strong>Que puedes hacer en InmuFacil:</strong><br />
        - Publicar tu inmueble y recibir ofertas directas de compradores.<br />
        - Buscar propiedades y negociar directamente con el propietario.<br />
        - Gestionar todo el proceso de compraventa desde la plataforma.
      </div>
      <div class="button-wrap">
        <a href="#" class="button">Empezar ahora</a>
      </div>
      <p>Antes de operar, te recomendamos completar tu perfil y verificar tu identidad
         para generar mayor confianza con la otra parte.</p>
      <p>Ante cualquier duda, nuestro equipo de soporte esta a tu disposicion.</p>
    """
    return _base_layout("Bienvenido a InmuFacil", content)

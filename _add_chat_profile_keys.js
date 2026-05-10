const fs = require('fs');
const path = require('path');

const chatKeys = {
  "chat": {
    "title": "Mensajes",
    "search_hint": "Buscar chats...",
    "no_conversations": "No hay conversaciones",
    "no_conversations_desc": "Cuando contactes con un vendedor o recibas una oferta, aparecerán aquí.",
    "encrypted_badge": "CIFRADO DE EXTREMO A EXTREMO",
    "trust_gold": "ORO",
    "trust_silver": "PLATA",
    "trust_bronze": "BRONCE",
    "yesterday": "Ayer",
    "secure_conv_title": "Conversaciones Seguras",
    "secure_conv_desc": "En InmuFácil, tus datos están protegidos. Negocia con tranquilidad.",
    "feature_p2p": "P2P SEGURO",
    "feature_legal": "MARCO LEGAL",
    "feature_kyc": "PERFIL KYC",
    "error_loading": "Error al cargar mensajes",
    "retry": "Reintentar",
    "send_error": "Error al enviar mensaje",
    "visit_time_help": "Selecciona la hora de la visita",
    "offer_proposal_title": "Propuesta de Oferta",
    "error_amount_required": "Debes indicar un importe",
    "error_amount_invalid": "Importe no válido",
    "send_button": "Enviar",
    "start_conversation": "Escribe el primer mensaje para empezar",
    "online": "En línea",
    "offline": "Desconectado",
    "active_offer": "Oferta activa",
    "today": "HOY",
    "yesterday_caps": "AYER",
    "respond_error": "Error al responder",
    "cancel_error": "Error al cancelar",
    "action_visit_request": "Solicitud de Visita",
    "action_visit_accepted": "Visita Confirmada",
    "action_visit_rejected": "Visita Rechazada",
    "action_offer_proposal": "Propuesta de Oferta",
    "action_docs_request": "Solicitud de Documentos",
    "action_visit_cancelled": "Visita Cancelada",
    "action_generic": "Acción",
    "reject": "Rechazar",
    "accept": "Aceptar",
    "reschedule": "Reprogramar",
    "cancel": "Anular",
    "quick_visit": "Visita",
    "quick_offer": "Oferta",
    "encryption_note": "Tus mensajes están protegidos por cifrado de extremo a extremo.",
    "message_hint": "Escribe un mensaje...",
    "solvency_not_completed": "El comprador aún no ha completado su pasaporte de solvencia.",
    "qualified_candidate": "Candidato Calificado: {level}",
    "level_gold": "Nivel Oro",
    "level_silver": "Nivel Plata",
    "level_bronze": "Nivel Bronce",
    "tap_for_details": "Toca para ver detalles financieros",
    "solvency_draft_wip": "Próximamente: Borrador de contrato basado en solvencia",
    "accept_solvency_btn": "Aceptar Solvencia y Reservar",
    "reference": "REFERENCIA: {title}"
  },
  "profile": {
    "tab_my_profile": "Mi Perfil",
    "tab_properties": "Mis Propiedades",
    "tab_offers": "Mis Ofertas",
    "tab_visits": "Mis Visitas",
    "tab_messages": "Mensajes",
    "default_username": "Usuario",
    "member_since": "Miembro desde {year}",
    "status_verified": "VERIFICADO",
    "personal_info_title": "Información Personal",
    "security_title": "Seguridad",
    "password_label": "Contraseña",
    "password_update_hint": "Actualiza tu contraseña regularmente",
    "change_password": "Cambiar Contraseña",
    "suspend_account": "Suspender Cuenta",
    "suspend_hint": "Tu cuenta dejará de ser visible temporalmente.",
    "suspend_button": "Suspender",
    "reactivate": "Reactivar",
    "delete_account": "Eliminar Cuenta",
    "delete_hint": "Acción permanente. Perderás todos tus datos.",
    "notifications_title": "Notificaciones",
    "email_notifications_label": "Notificaciones por Email",
    "email_notifications_on": "Recibirás avisos en tu correo",
    "email_notifications_off": "No recibirás avisos por email",
    "promo_title": "¿Vendes tu casa?",
    "promo_body": "Publícala en InmuFácil y gestiona todo el proceso sin comisiones.",
    "promo_button": "Publicar Propiedad",
    "see_drafts": "Ver mis borradores",
    "my_properties_title": "Mis Propiedades",
    "my_properties_subtitle": "Gestiona tus anuncios y borradores",
    "properties_error": "Error al cargar propiedades: {error}",
    "delete_photo_title": "Eliminar foto",
    "delete_photo_confirm": "¿Estás seguro de que quieres eliminar tu foto de perfil?",
    "delete_photo_success": "Foto eliminada",
    "delete_photo_error": "Error al eliminar foto",
    "security": {
        "suspension_not_available": "La suspensión de cuenta no está disponible todavía."
    },
    "personal_info": {
        "full_name": "Nombre completo",
        "phone": "Teléfono",
        "email_readonly": "Email (No editable)",
        "save_btn": "Guardar cambios",
        "edit_btn": "Editar perfil",
        "save_success": "Perfil actualizado correctamente"
    },
    "solvency": {
        "passport_title": "PASAPORTE SOLVENCIA",
        "passport_desc": "Aumenta tus posibilidades de éxito en un 80%.",
        "level": "Nivel {level}",
        "gold": "Oro",
        "silver": "Plata",
        "bronze": "Bronce"
    },
    "solvency_buyers_only": "SOLO COMPRADORES",
    "trust_level_button": "Mi Nivel de Confianza",
    "lifestyle_button": "Mi Estilo de Vida",
    "trust": {
        "dashboard_desc": "Ver cómo te ven los vendedores"
    },
    "lifestyle": {
        "button_desc": "Personaliza tus recomendaciones"
    },
    "my_properties": {
        "filter_all": "Todas",
        "filter_published": "Publicadas",
        "filter_drafts": "Borradores",
        "filter_unpublished": "Retiradas",
        "sort_oldest": "Más antiguas"
    }
  },
  "notifications": {
      "settings": {
          "section_offers": "Actividad de Ofertas",
          "offer_received": "Oferta Recibida",
          "offer_received_desc": "Avisar cuando reciba una nueva oferta por mi propiedad.",
          "offer_accepted": "Oferta Aceptada",
          "offer_accepted_desc": "Avisar cuando el vendedor acepte mi oferta.",
          "offer_countered": "Contraoferta Recibida",
          "offer_countered_desc": "Avisar cuando reciba una contraoferta.",
          "section_messages": "Mensajes y Chat",
          "new_message": "Nuevo Mensaje",
          "new_message_desc": "Avisar cuando reciba un mensaje en el chat.",
          "section_property": "Mi Propiedad",
          "property_status_change": "Cambio de Estado",
          "property_status_change_desc": "Avisar cuando cambie el estado de mi publicación.",
          "section_marketing": "Novedades e Información",
          "marketing_emails": "Emails de Marketing",
          "marketing_emails_desc": "Recibir noticias sobre nuevas funciones y ofertas."
      }
  }
};

const translationsDir = path.join(__dirname, 'frontend/assets/translations');
const langs = ["es-ES", "ca-ES", "va-ES", "en-US", "fr-FR", "eu-ES", "gl-ES"];

for (const lang of langs) {
  const filePath = path.join(translationsDir, `${lang}.json`);
  if (!fs.existsSync(filePath)) continue;

  let fileContent = fs.readFileSync(filePath, 'utf8');
  if (fileContent.charCodeAt(0) === 0xFEFF) fileContent = fileContent.slice(1);
  const data = JSON.parse(fileContent);

  // Deep merge helper
  function merge(target, source) {
    for (const key of Object.keys(source)) {
      if (source[key] instanceof Object && key in target) {
        Object.assign(source[key], merge(target[key], source[key]));
      }
    }
    Object.assign(target || {}, source);
    return target;
  }

  if (!data["chat"]) data["chat"] = {};
  merge(data["chat"], chatKeys["chat"]);
  
  if (!data["profile"]) data["profile"] = {};
  merge(data["profile"], chatKeys["profile"]);

  if (!data["notifications"]) data["notifications"] = {};
  merge(data["notifications"], chatKeys["notifications"]);

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

console.log("Chat/Profile/Notification keys injected.");

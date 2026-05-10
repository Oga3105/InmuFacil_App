const fs = require('fs');
const path = require('path');

const visitsKeys = {
  "visits": {
    "create_new_window": "Nueva Ventana de Disponibilidad",
    "define_block_desc": "Define un bloque de tiempo para que los interesados puedan reservar citas de {duration} minutos.",
    "start_time": "Hora inicio",
    "end_time": "Hora fin",
    "slot_duration": "Duración cita",
    "visit_duration_title": "Duración de la visita",
    "minutes": "{min} minutos",
    "preview_creating": "Se crearán {count} huecos de {duration} min entre las {start} y las {end}.",
    "error_end_after_start": "La hora de fin debe ser posterior a la de inicio.",
    "success_created": "Ventana de disponibilidad creada con éxito.",
    "error_overlap": "Este horario se solapa con una ventana existente.",
    "configured_windows": "VENTANAS CONFIGURADAS",
    "error_loading_windows": "Error al cargar las ventanas de disponibilidad.",
    "no_windows_configured": "No tienes ventanas de disponibilidad configuradas para esta propiedad.",
    "slots_duration_text": "Citas de {duration} min",
    "past": "PASADO",
    "active": "ACTIVA",
    "no_slots_available": "No hay huecos disponibles actualmente.",
    "already_scheduled_title": "Ya tienes una visita programada",
    "status_label": "Estado: {status}",
    "status_pending_confirm": "Pendiente de confirmar",
    "status_confirmed": "Confirmada",
    "view_my_visits": "Ver mis visitas",
    "success_requested": "Visita solicitada con éxito. El vendedor recibirá tu propuesta.",
    "error_booking": "Error al solicitar la visita.",
    "no_slots_email_title": "Sin disponibilidad inmediata",
    "no_slots_email_desc": "El vendedor no tiene huecos configurados. Puedes enviarle un mensaje para proponerle una fecha.",
    "email_message_label": "Mensaje opcional para el vendedor...",
    "request_visit_email_btn": "Proponer visita por email",
    "email_request_success": "Propuesta enviada correctamente.",
    "email_request_error": "Error al enviar la propuesta.",
    "select_date_time": "Selecciona día y hora",
    "available_hours": "HORARIOS DISPONIBLES",
    "free_slots": "{count} libres",
    "select_day_hint": "Selecciona un día en el calendario\npara ver los horarios disponibles.",
    "notes_label": "Notas para el vendedor (opcional)",
    "notes_hint": "Ej: ¿Es posible ver el trastero? / Somos una pareja...",
    "protected_visit_title": "Visita Protegida por InmuFácil",
    "protected_visit_desc": "Tus datos personales no se comparten hasta que la visita es confirmada. La comunicación es segura.",
    "visit_summary": "RESUMEN DE LA VISITA",
    "visit_summary_text": "Día {day} de {month} a las {time}",
    "confirm_request": "Confirmar Solicitud",
    "no_seller_windows": "Vendedor sin calendario activo",
    "no_seller_windows_desc": "Este vendedor aún no ha configurado sus ventanas de disponibilidad para visitas automáticas.",
    "create_window_btn": "Crear ventana de disponibilidad"
  },
  "time": {
    "months": {
      "1": "Enero", "2": "Febrero", "3": "Marzo", "4": "Abril", "5": "Mayo", "6": "Junio",
      "7": "Julio", "8": "Agosto", "9": "Septiembre", "10": "Octubre", "11": "Noviembre", "12": "Diciembre"
    },
    "short_months": {
      "1": "Ene", "2": "Feb", "3": "Mar", "4": "Abr", "5": "May", "6": "Jun",
      "7": "Jul", "8": "Ago", "9": "Sep", "10": "Oct", "11": "Nov", "12": "Dic"
    },
    "weekdays_short": {
      "1": "LU", "2": "MA", "3": "MI", "4": "JU", "5": "VI", "6": "SA", "7": "DO"
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

  if (!data["visits"]) data["visits"] = {};
  for (const [k, v] of Object.entries(visitsKeys["visits"])) {
    data["visits"][k] = v;
  }

  if (!data["time"]) data["time"] = {};
  if (!data["time"]["months"]) data["time"]["months"] = {};
  for (const [k, v] of Object.entries(visitsKeys["time"]["months"])) {
    data["time"]["months"][k] = v;
  }
  if (!data["time"]["short_months"]) data["time"]["short_months"] = {};
  for (const [k, v] of Object.entries(visitsKeys["time"]["short_months"])) {
    data["time"]["short_months"][k] = v;
  }
  if (!data["time"]["weekdays_short"]) data["time"]["weekdays_short"] = {};
  for (const [k, v] of Object.entries(visitsKeys["time"]["weekdays_short"])) {
    data["time"]["weekdays_short"][k] = v;
  }

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

console.log("Visits keys (numeric) injected.");

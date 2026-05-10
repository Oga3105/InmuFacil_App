const fs = require('fs');
const path = require('path');

const tasacionKeys = {
  "transaction": {
    "tasacion_app_bar_title": "Tasación de la Vivienda",
    "tasacion_info_title": "Proceso de Tasación",
    "tasacion_info_body": "La tasación es un paso crítico para que el banco apruebe la hipoteca del comprador. Debe ser realizada por una entidad homologada por el Banco de España.",
    "tasacion_checklist_seller": "Preparación para el Vendedor",
    "tasacion_checklist_buyer": "Preparación para el Comprador",
    "tasacion_checklist_1": "Asegúrate de tener las llaves disponibles",
    "tasacion_checklist_2": "La vivienda debe estar accesible",
    "tasacion_checklist_3": "Ten a mano la escritura o nota simple",
    "tasacion_checklist_4": "El proceso suele durar entre 30 y 60 minutos",
    "tasacion_snack_proposed": "Propuesta enviada al vendedor",
    "tasacion_snack_accepted": "Cita confirmada correctamente",
    "tasacion_snack_rejected": "Contraoferta enviada al comprador",
    "tasacion_snack_counter_accepted": "Nueva fecha aceptada correctamente",
    "tasacion_schedule_title": "Agendar Cita",
    "tasacion_schedule_subtitle": "Propón una fecha y hora para que el tasador visite la vivienda",
    "tasacion_date_label": "Fecha de visita",
    "tasacion_time_label": "Hora aproximada",
    "tasacion_select": "Seleccionar",
    "tasacion_notes_label": "Notas adicionales (portal, timbre...)",
    "tasacion_send_proposal": "Enviar propuesta de cita",
    "tasacion_waiting_title": "Esperando al comprador",
    "tasacion_waiting_body": "El comprador debe proponer una fecha para la visita del tasador. Te avisaremos en cuanto lo haga.",
    "tasacion_proposed_badge": "Cita Propuesta",
    "tasacion_your_proposal": "Tu propuesta",
    "tasacion_proposed_hint": "Esperando que el vendedor confirme o proponga otra hora.",
    "tasacion_buyer_proposes": "El comprador propone una cita",
    "tasacion_proposed_date": "Fecha propuesta",
    "tasacion_accept_date": "Aceptar fecha y hora",
    "tasacion_cancel_label": "Cancelar",
    "tasacion_reject_propose": "Rechazar y proponer otra",
    "tasacion_alt_title": "Tu contrapropuesta",
    "tasacion_alt_date": "Nueva fecha sugerida",
    "tasacion_alt_time": "Nueva hora sugerida",
    "tasacion_alt_notes": "Motivo del cambio / notas",
    "tasacion_send_counter": "Enviar contrapropuesta",
    "tasacion_seller_counter_title": "El vendedor propone otra fecha",
    "tasacion_seller_counter_body": "El vendedor no puede en la fecha solicitada y sugiere el siguiente horario:",
    "tasacion_seller_proposal": "Propuesta del vendedor",
    "tasacion_propose_other": "Proponer otra fecha distinta",
    "tasacion_waiting_new_title": "Esperando respuesta",
    "tasacion_waiting_new_body": "Has enviado una contrapropuesta. El comprador debe aceptarla o proponer una nueva.",
    "tasacion_confirmed": "¡Cita Confirmada!",
    "tasacion_confirmed_at": "La visita será el {date} a las {time}",
    "tasacion_seller_confirm_hint": "Por favor, asegúrate de estar presente o facilitar el acceso.",
    "tasacion_buyer_confirm_hint": "El tasador acudirá en la fecha acordada.",
    "tasacion_confirm_visit_title": "Confirmar Realización",
    "tasacion_confirm_visit_body": "Una vez que el tasador haya visitado la vivienda, por favor confírmalo para avanzar al siguiente paso (FEIN).",
    "tasacion_visit_done": "Confirmar que la visita se ha realizado",
    "tasacion_completed": "Tasación Realizada",
    "tasacion_completed_seller": "La visita del tasador se ha completado correctamente.",
    "tasacion_completed_buyer": "La visita se ha completado. El siguiente paso es la emisión del FEIN por parte del banco.",
    "tasacion_goto_fein": "Ir al paso del FEIN",
    "tasacion_appointment_format": "{day}/{month}/{year}  ·  {time}"
  },
  "common": {
    "error_title": "Error",
    "home_btn": "Inicio"
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

  if (!data["transaction"]) data["transaction"] = {};
  for (const [k, v] of Object.entries(tasacionKeys["transaction"])) {
    data["transaction"][k] = v;
  }

  if (!data["common"]) data["common"] = {};
  for (const [k, v] of Object.entries(tasacionKeys["common"])) {
    data["common"][k] = v;
  }

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

console.log("Tasacion keys injected.");

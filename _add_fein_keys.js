const fs = require('fs');
const path = require('path');

const feinKeys = {
  "transaction": {
    "fein_title": "Formalización Bancaria (FEIN)",
    "fein_buyer_banner": "Confirma que has recibido la FEIN (Ficha Europea de Información Normalizada) de tu entidad bancaria.",
    "fein_seller_banner": "El comprador está gestionando la formalización bancaria. Este proceso es obligatorio antes de acudir a notaría.",
    "fein_what_is": "¿Qué es la FEIN?",
    "fein_faq1_title": "Obligatorio",
    "fein_faq1_body": "Es el documento que detalla las condiciones definitivas de tu hipoteca.",
    "fein_faq2_title": "Plazo",
    "fein_faq2_body": "Debes tenerla al menos 10 días antes de la firma en notaría.",
    "fein_faq3_title": "Siguiente",
    "fein_faq3_body": "Tras confirmarla, coordinaremos la cita con el notario.",
    "fein_process_title": "Pasos hasta la Notaría",
    "fein_step1_title": "Tasación Completada",
    "fein_step1_body": "La vivienda ya ha sido valorada por el banco.",
    "fein_step2_title": "Oferta Vinculante",
    "fein_step2_body": "El banco emite la FEIN y el borrador del contrato.",
    "fein_step3_title": "Confirmación en App",
    "fein_step3_body": "Indicas que tienes la documentación necesaria.",
    "fein_step4_title": "Acta Previa",
    "fein_step4_body": "Visita al notario para resolver dudas.",
    "fein_step5_title": "Firma Escritura",
    "fein_step5_body": "Firma final y entrega de llaves.",
    "fein_form_title": "Confirmar Recepción",
    "fein_check1": "He recibido la FEIN y el FIPER de mi banco.",
    "fein_check2": "He leído y comprendido las condiciones del préstamo.",
    "fein_form_warn": "Esta confirmación indica que estás listo para pasar a la fase de notaría. No es un contrato legal, pero avanza el proceso en InmuFácil.",
    "fein_seller_wait_title": "Esperando Formalización",
    "fein_seller_wait_body": "El comprador debe confirmar que ya dispone de la FEIN. Te avisaremos cuando ocurra.",
    "fein_success_title": "¡Formalización Confirmada!",
    "fein_success_buyer": "Has confirmado la recepción de la FEIN. Ahora podemos proceder a la elección de notaría.",
    "fein_success_seller": "El comprador ha confirmado la formalización bancaria. Estamos listos para coordinar la notaría.",
    "fein_success_warn": "Recuerda que deben pasar al menos 10 días desde la emisión de la FEIN hasta la firma.",
    "fein_goto_notary": "Ir a Notaría",
    "fein_back_timeline": "Volver a la línea de tiempo",
    "fein_notes_confirm": "Confirmación de FEIN desde la app."
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
  for (const [k, v] of Object.entries(feinKeys["transaction"])) {
    data["transaction"][k] = v;
  }

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

console.log("FEIN keys injected.");

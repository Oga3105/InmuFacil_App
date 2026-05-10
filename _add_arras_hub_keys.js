const fs = require('fs');
const path = require('path');

const arrasKeys = {
  "arras_interview": {
    "hub_buyer_title": "Comprador",
    "hub_seller_title": "Vendedor",
    "hub_completed": "Completado",
    "hub_pending": "Pendiente",
    "hub_view_edit": "Ver / Editar",
    "hub_start": "Empezar",
    "hub_info_box": "Cuando ambas partes completen y confirmen sus entrevistas, la inteligencia artificial redactará el Contrato de Arras Penitenciales con todas las condiciones acordadas. Podrás revisarlo y proponer cambios antes de firmarlo digitalmente.",
    "hub_status_accepted": "Contrato aceptado y listo para firma",
    "hub_status_ready": "Contrato disponible para revisión",
    "hub_status_generating_ai": "La IA está redactando el contrato...",
    "hub_status_generating_draft": "Ambas entrevistas listas. Generando borrador...",
    "hub_status_buyer_done_buyer": "Tu entrevista completada — esperando al vendedor",
    "hub_status_buyer_done_seller": "Comprador listo — completa tu entrevista",
    "hub_status_seller_done_seller": "Tu entrevista completada — esperando al comprador",
    "hub_status_seller_done_buyer": "Vendedor listo — completa tu entrevista",
    "hub_status_default": "Completa las entrevistas para generar el contrato",
    "hub_hero_title": "Contrato de Arras",
    "hub_hero_subtitle": "Penitenciales",
    "hub_hero_arras_pct": "{pct}% Arras",
    "hub_hero_deadline": "{days} días plazo",
    "hub_hero_buyer": "Comprador",
    "hub_hero_seller": "Vendedor",
    "hub_role_you": "TÚ",
    "hub_btn_view": "Ver",
    "hub_btn_start": "Empezar",
    "hub_contract_accepted_title": "Contrato Aceptado",
    "hub_contract_accepted_desc": "Ambas partes han validado las condiciones",
    "hub_contract_generating_title": "Generando contrato...",
    "hub_contract_generating_desc": "La IA está redactando el contrato",
    "hub_contract_ready_title": "Contrato listo para revisión",
    "hub_contract_ready_desc": "Ambas partes deben leer y aceptar el contrato",
    "hub_contract_pending_title": "Generando contrato...",
    "hub_contract_pending_desc": "Espera mientras se prepara el borrador",
    "hub_contract_view_btn": "Revisar Contrato",
    "shared_back": "Atrás",
    "shared_continue": "Continuar"
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

  if (!data["arras_interview"]) data["arras_interview"] = {};
  for (const [k, v] of Object.entries(arrasKeys["arras_interview"])) {
    data["arras_interview"][k] = v;
  }

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

console.log("Arras interview keys injected.");

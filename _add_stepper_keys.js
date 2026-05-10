const fs = require('fs');
const path = require('path');

const stepperKeys = {
  "arras_interview": {
    "step1_title": "Logística y Notaría",
    "step1_subtitle": "Paso 1 de 3 — Plazos, depósito y notaría",
    "step2_title": "Seguridad y Flexibilidad",
    "step2_subtitle": "Paso 2 de 3 — Condiciones y contingencias",
    "step3_title": "Impuestos y Cargas",
    "step3_subtitle": "Paso 3 de 3 — Fiscalidad y financiación",
    "reason_work": "Motivos laborales",
    "reason_mortgage": "Retraso en hipoteca",
    "reason_family": "Motivos familiares",
    "reason_legal": "Procedimiento legal",
    "reason_other": "Otras causas",
    "mortgage_subject_title": "Sujeto a concesión de hipoteca",
    "mortgage_subject_sub": "El contrato queda condicionado a la aprobación del préstamo",
    "extension_allowed_title": "Permite prórroga del plazo",
    "extension_allowed_sub": "Se puede ampliar el plazo por causas justificadas",
    "hidden_defects_title": "Acepta cláusula de vicios ocultos",
    "hidden_defects_sub": "Art. 1484 CC — El vendedor responde por defectos ocultos",
    "community_debt_title": "Retención por deudas de comunidad",
    "community_debt_sub": "Se retiene parte del precio si el vendedor tiene deudas pendientes",
    "ibi_proration_title": "Prorrateo de IBI por días",
    "ibi_proration_sub": "El IBI del año se reparte proporcionalmente entre comprador y vendedor",
    "method_cash": "Pago al contado",
    "method_mortgage_approved": "Hipoteca aprobada",
    "method_mortgage_pending": "Hipoteca en tramitación",
    "method_savings_plus_mortgage": "Ahorros + hipoteca",
    "method_house_to_sell": "Venta de vivienda actual"
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
  for (const [k, v] of Object.entries(stepperKeys["arras_interview"])) {
    data["arras_interview"][k] = v;
  }

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

console.log("Stepper keys injected.");

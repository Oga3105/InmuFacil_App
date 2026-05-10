const fs = require('fs');
const path = require('path');

const equityKeys = {
  "arras_interview": {
    "equity_no_data": "El análisis no está disponible. Asegúrate de que el contrato ha sido generado.",
    "equity_aspects_title": "Aspectos del contrato",
    "equity_label_favorable": "Favorable",
    "equity_label_balanced": "Equilibrado",
    "equity_label_alerts": "Con alertas",
    "equity_label_unfavorable": "Desfavorable",
    "equity_buyer_pos": "Tu posición como Comprador",
    "equity_seller_pos": "Tu posición como Vendedor",
    "equity_status_favorable": "Favorable",
    "equity_status_neutral": "Neutral",
    "equity_status_alert": "Alerta",
    "equity_status_critical": "Crítico",
    "equity_not_available": "Análisis no disponible",
    "equity_disclaimer": "Este análisis es orientativo y ha sido generado por inteligencia artificial. No constituye asesoramiento jurídico. Consulta con un abogado antes de firmar."
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
  for (const [k, v] of Object.entries(equityKeys["arras_interview"])) {
    data["arras_interview"][k] = v;
  }

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

console.log("Equity analysis keys injected.");

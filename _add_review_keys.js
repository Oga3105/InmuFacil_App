const fs = require('fs');
const path = require('path');

const reviewKeys = {
  "arras_interview": {
    "rejection_sent_snack": "Rechazo enviado. Ambas partes deben volver a confirmar sus entrevistas.",
    "no_interview_info": "No hay información de la entrevista",
    "error_generating": "Error desconocido al generar el contrato"
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
  for (const [k, v] of Object.entries(reviewKeys["arras_interview"])) {
    data["arras_interview"][k] = v;
  }

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

console.log("Review keys injected.");

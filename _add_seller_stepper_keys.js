const fs = require('fs');
const path = require('path');

const sellerKeys = {
  "arras_interview": {
    "bank_name_title": "Entidad bancaria",
    "additional_clauses_title": "Cláusulas adicionales (opcional)",
    "additional_clauses_desc": "Cualquier condición especial que quieras incluir en el contrato"
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
  for (const [k, v] of Object.entries(sellerKeys["arras_interview"])) {
    data["arras_interview"][k] = v;
  }

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

console.log("Seller stepper keys injected.");

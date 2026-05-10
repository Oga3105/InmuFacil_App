const fs = require('fs');
const path = require('path');

const notaryKeys = {
  "transaction": {
    "notary_close_title": "Cierre en Notaría",
    "notary_buyer_desc": "Confirma que se ha firmado la escritura pública de compraventa y se han recibido las llaves.",
    "notary_seller_desc": "Confirma que se ha firmado la escritura y se han entregado las llaves al nuevo propietario.",
    "notary_status_title": "Estado de las Confirmaciones",
    "notary_your_confirm_buyer": "Tu confirmación (Comprador)",
    "notary_your_confirm_seller": "Tu confirmación (Vendedor)",
    "notary_other_confirm_seller": "Confirmación del Vendedor",
    "notary_other_confirm_buyer": "Confirmación del Comprador",
    "notary_declare_title": "Declaración Jurada",
    "notary_declare_signed": "Declaro que la firma ante notario se ha realizado correctamente.",
    "notary_declare_keys_buyer": "He recibido todas las llaves de la vivienda.",
    "notary_declare_keys_seller": "He entregado todas las llaves al comprador.",
    "notary_declare_warning": "Esta acción es irreversible y marca el fin de la fase de compraventa en InmuFácil.",
    "notary_confirm_btn": "Confirmar Firma y Entrega",
    "notary_success_title": "¡Enhorabuena!",
    "notary_success_buyer": "La compra se ha completado oficialmente. Ya puedes acceder a la gestión post-venta.",
    "notary_success_seller": "La venta se ha completado oficialmente. Gracias por confiar en InmuFácil.",
    "notary_go_post_venta": "Ir a Post-Venta",
    "notary_pending": "Pendiente",
    "notary_confirmed": "Confirmado"
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
  for (const [k, v] of Object.entries(notaryKeys["transaction"])) {
    data["transaction"][k] = v;
  }

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

console.log("Notary keys injected.");

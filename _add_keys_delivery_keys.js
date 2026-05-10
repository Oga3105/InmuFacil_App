const fs = require('fs');
const path = require('path');

const keysDeliveryKeys = {
  "transaction": {
    "keys_confirm_wait_snack": "Confirmación registrada. Esperando la confirmación de la otra parte.",
    "keys_confirm_error": "Error al confirmar la entrega de llaves.",
    "keys_completed_title": "¡Transacción Finalizada!",
    "keys_completed_desc": "Ambas partes han confirmado la entrega de llaves. La compraventa en InmuFácil se ha completado con éxito.",
    "keys_accept": "Entendido",
    "keys_seller": "Vendedor",
    "keys_buyer": "Comprador",
    "keys_delivered_title": "Entrega de Llaves",
    "keys_pending_title": "Entrega Pendiente",
    "keys_delivered_desc": "La posesión de la vivienda ha sido transferida formalmente.",
    "keys_pending_desc": "Ambas partes deben confirmar la entrega de llaves tras la firma en notaría.",
    "keys_confirmed": "Entrega confirmada",
    "keys_confirm_prompt": "Por favor, confirma que has realizado la entrega.",
    "keys_waiting_confirm": "Esperando confirmación",
    "keys_confirm_btn": "Confirmar Entrega",
    "keys_docs_delivery": "Documentación a entregar",
    "keys_doc1": "Juego completo de llaves (vivienda, buzón, trastero)",
    "keys_doc2": "Certificado de Eficiencia Energética (original)",
    "keys_doc3": "Cédula de Habitabilidad (si aplica)",
    "keys_doc4": "Últimos recibos de IBI y suministros pagados",
    "keys_doc5": "Certificado de estar al corriente con la comunidad",
    "keys_doc6": "Manuales y garantías de electrodomésticos",
    "keys_tips_title": "Consejos finales",
    "keys_tip1": "Haz fotos del estado de los contadores (luz, agua, gas).",
    "keys_tip2": "Realiza el cambio de titularidad de suministros cuanto antes.",
    "keys_tip3": "Cambia el bombín de la cerradura principal por seguridad.",
    "keys_tip4": "Comunica la venta a tu entidad bancaria y seguro de hogar."
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
  for (const [k, v] of Object.entries(keysDeliveryKeys["transaction"])) {
    data["transaction"][k] = v;
  }

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

console.log("Keys Delivery keys injected.");

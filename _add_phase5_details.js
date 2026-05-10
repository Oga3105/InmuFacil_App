const fs = require('fs');
const path = require('path');

const newKeys = {
  "pre_offer_tax": {
    "notarial_disclaimer": "Los gastos de notaría y registro son estimaciones basadas en los aranceles oficiales vigentes.",
    "offer_amount_label": "TU OFERTA ECONÓMICA",
    "offer_subtitle": "Importe propuesto para la compra del inmueble",
    "header": "Estimación de Gastos e Impuestos",
    "itp_label": "Impuesto Transmisiones (ITP {rate})",
    "notary_label": "Notaría (Est.)",
    "notary_sublabel": "Escritura pública de compraventa",
    "registry_label": "Registro (Est.)",
    "registry_sublabel": "Inscripción en el Registro de la Propiedad",
    "agency_label": "Gestoría (Opcional)",
    "agency_sublabel": "Tramitación y liquidación de impuestos",
    "optional_badge": "OPCIONAL",
    "total_label": "TOTAL GASTOS ESTIMADOS",
    "total_sublabel": "Sin incluir el precio del inmueble",
    "confirm_button": "Confirmar y enviar oferta",
    "back_button": "Volver a la oferta",
    "foral_clause": "En los regímenes forales o especiales (País Vasco, Navarra, Canarias), el ITP y otros gastos pueden variar significativamente. Te recomendamos consultar con un asesor fiscal local.",
    "disclaimer": "Este cálculo es puramente informativo y se basa en tipos impositivos estándar. La liquidación final dependerá de las circunstancias personales y la normativa vigente en el momento de la firma."
  },
  "smart_bid_risk": {
    "label_low": "Riesgo Bajo",
    "label_low_detail": "Tu oferta es igual o superior al precio de venta. Es muy probable que sea aceptada si no hay otras ofertas competitivas.",
    "label_medium": "Riesgo Medio",
    "label_medium_detail": "Tu oferta está ligeramente por debajo del precio. El vendedor podría aceptarla o enviarte una contraoferta.",
    "label_medium_high": "Riesgo Moderado",
    "label_medium_high_detail": "Hay una diferencia considerable. Necesitarás argumentos sólidos o que el inmueble lleve tiempo en el mercado.",
    "label_high": "Riesgo Alto",
    "label_high_detail": "La oferta está muy por debajo del precio de salida. Existe un alto riesgo de rechazo inmediato.",
    "extreme_low_offer": "Oferta muy agresiva",
    "gauge_title": "Probabilidad de Aceptación",
    "scale_low": "BAJA",
    "scale_high": "ALTA",
    "no_historical_data": "Sin datos históricos suficientes en esta zona para una predicción exacta.",
    "statistical_disclaimer": "El nivel de riesgo es una estimación estadística basada en el mercado actual, no una predicción del comportamiento humano del vendedor.",
    "understood_button": "Entendido, continuar",
    "your_offer_label": "TU OFERTA",
    "asking_price_label": "PRECIO SALIDA"
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

  for (const [sectionName, keys] of Object.entries(newKeys)) {
    if (!data[sectionName]) data[sectionName] = {};
    for (const [k, v] of Object.entries(keys)) {
      data[sectionName][k] = v; // Basic Spanish fallback for now, will improve later
    }
  }

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

console.log("Phase 5 detailed keys injected.");

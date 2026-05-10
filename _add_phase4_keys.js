const fs = require('fs');
const path = require('path');

const translations = {
  "es-ES": {
    "title_ai_hint": "La descripción comercial se genera con IA en el siguiente paso.",
    "market_ref": "Referencia de mercado: ",
    "market_ref_detail": "({} EUR/m², {})",
    "cee_hint": "Indica la calificación energética de la propiedad.",
    "cee_pending": "En trámite",
    "cee_pending_selected": "Certificado en trámite seleccionado",
    "cee_rating_selected": "Calificación {} seleccionada"
  },
  "ca-ES": {
    "title_ai_hint": "La descripció comercial es genera amb IA en el següent pas.",
    "market_ref": "Referència de mercat: ",
    "market_ref_detail": "({} EUR/m², {})",
    "cee_hint": "Indica la qualificació energètica de la propietat.",
    "cee_pending": "En tràmit",
    "cee_pending_selected": "Certificat en tràmit seleccionat",
    "cee_rating_selected": "Qualificació {} seleccionada"
  },
  "va-ES": {
    "title_ai_hint": "La descripció comercial es genera amb IA en el següent pas.",
    "market_ref": "Referència de mercat: ",
    "market_ref_detail": "({} EUR/m², {})",
    "cee_hint": "Indica la qualificació energètica de la propietat.",
    "cee_pending": "En tràmit",
    "cee_pending_selected": "Certificat en tràmit seleccionat",
    "cee_rating_selected": "Qualificació {} seleccionada"
  },
  "en-US": {
    "title_ai_hint": "The commercial description is generated with AI in the next step.",
    "market_ref": "Market reference: ",
    "market_ref_detail": "({} EUR/m², {})",
    "cee_hint": "Indicate the energy rating of the property.",
    "cee_pending": "In progress",
    "cee_pending_selected": "Certificate in progress selected",
    "cee_rating_selected": "Rating {} selected"
  },
  "en-CA": {
    "title_ai_hint": "The commercial description is generated with AI in the next step.",
    "market_ref": "Market reference: ",
    "market_ref_detail": "({} EUR/m², {})",
    "cee_hint": "Indicate the energy rating of the property.",
    "cee_pending": "In progress",
    "cee_pending_selected": "Certificate in progress selected",
    "cee_rating_selected": "Rating {} selected"
  },
  "en-GB": {
    "title_ai_hint": "The commercial description is generated with AI in the next step.",
    "market_ref": "Market reference: ",
    "market_ref_detail": "({} EUR/m², {})",
    "cee_hint": "Indicate the energy rating of the property.",
    "cee_pending": "In progress",
    "cee_pending_selected": "Certificate in progress selected",
    "cee_rating_selected": "Rating {} selected"
  },
  "fr-FR": {
    "title_ai_hint": "La description commerciale est générée par l'IA à l'étape suivante.",
    "market_ref": "Référence du marché : ",
    "market_ref_detail": "({} EUR/m², {})",
    "cee_hint": "Indiquez la classe énergétique de la propriété.",
    "cee_pending": "En cours",
    "cee_pending_selected": "Certificat en cours sélectionné",
    "cee_rating_selected": "Classe {} sélectionnée"
  },
  "fr-CA": {
    "title_ai_hint": "La description commerciale est générée par l'IA à l'étape suivante.",
    "market_ref": "Référence du marché : ",
    "market_ref_detail": "({} EUR/m², {})",
    "cee_hint": "Indiquez la classe énergétique de la propriété.",
    "cee_pending": "En cours",
    "cee_pending_selected": "Certificat en cours sélectionné",
    "cee_rating_selected": "Classe {} sélectionnée"
  },
  "eu-ES": {
    "title_ai_hint": "Deskribapen komertziala hurrengo urratsean sortuko da IArekin.",
    "market_ref": "Merkatuko erreferentzia: ",
    "market_ref_detail": "({} EUR/m², {})",
    "cee_hint": "Adierazi jabetzaren kalifikazio energetikoa.",
    "cee_pending": "Tramitean",
    "cee_pending_selected": "Tramitean dagoen ziurtagiria hautatua",
    "cee_rating_selected": "{} kalifikazioa hautatua"
  },
  "gl-ES": {
    "title_ai_hint": "A descrición comercial xérase con IA no seguinte paso.",
    "market_ref": "Referencia de mercado: ",
    "market_ref_detail": "({} EUR/m², {})",
    "cee_hint": "Indica a cualificación enerxética da propiedade.",
    "cee_pending": "En trámite",
    "cee_pending_selected": "Certificado en trámite seleccionado",
    "cee_rating_selected": "Cualificación {} seleccionada"
  }
};

const translationsDir = path.join(__dirname, 'frontend/assets/translations');

for (const [lang, keys] of Object.entries(translations)) {
  const filePath = path.join(translationsDir, `${lang}.json`);
  if (!fs.existsSync(filePath)) {
    console.log(`File not found: ${filePath}`);
    continue;
  }

  let fileContent = fs.readFileSync(filePath, 'utf8');
  // Remove BOM if present
  if (fileContent.charCodeAt(0) === 0xFEFF) {
    fileContent = fileContent.slice(1);
  }
  
  const data = JSON.parse(fileContent);

  if (!data.property_wizard) {
    data.property_wizard = {};
  }

  for (const [k, v] of Object.entries(keys)) {
    data.property_wizard[k] = v;
  }

  // Write back as UTF-8 (without BOM)
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
  console.log(`[${lang}] Updated Phase 4 keys.`);
}

console.log("Phase 4 keys injected successfully in all 10 languages.");

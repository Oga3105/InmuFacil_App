const fs = require('fs');
const path = require('path');

const newKeys = {
  "transaction": {
    "timeline_title": "Estado de la Transacción",
    "timeline_subtitle": "Sigue el progreso de tu venta en tiempo real",
    "property_fallback": "Propiedad",
    "counterparty_fallback": "Contraparte"
  },
  "chat": {
    "level_gold": "Oro",
    "level_silver": "Plata",
    "level_bronze": "Bronce"
  },
  "solvency": {
    "low_risk": "Bajo riesgo",
    "medium_risk": "Riesgo medio",
    "high_risk": "Alto riesgo",
    "cash": "Pago al contado",
    "mortgage_approved": "Hipoteca aprobada",
    "mortgage_pending": "Hipoteca en trámite",
    "house_to_sell": "Venta de vivienda",
    "unspecified_payment": "No especificado",
    "pre_approval": "Preaprobación bancaria",
    "knows_costs": "Conoce los gastos",
    "has_savings": "Tiene ahorros iniciales"
  }
};

const translations = {
  "es-ES": newKeys,
  "ca-ES": {
    "transaction": {
      "timeline_title": "Estat de la Transacció",
      "timeline_subtitle": "Segueix el progrés de la teva venda en temps real",
      "property_fallback": "Propietat",
      "counterparty_fallback": "Contrapart"
    },
    "chat": { "level_gold": "Or", "level_silver": "Plata", "level_bronze": "Bronze" },
    "solvency": {
      "low_risk": "Baix risc", "medium_risk": "Risc mitjà", "high_risk": "Alt risc",
      "cash": "Pagament al comptat", "mortgage_approved": "Hipoteca aprovada",
      "mortgage_pending": "Hipoteca en tràmit", "house_to_sell": "Venda d'habitatge",
      "unspecified_payment": "No especificat", "pre_approval": "Preaprovació bancària",
      "knows_costs": "Coneix les despeses", "has_savings": "Té estalvis inicials"
    }
  },
  "va-ES": {
    "transaction": {
      "timeline_title": "Estat de la Transacció",
      "timeline_subtitle": "Segueix el progrés de la teua venda en temps real",
      "property_fallback": "Propietat",
      "counterparty_fallback": "Contrapart"
    },
    "chat": { "level_gold": "Or", "level_silver": "Plata", "level_bronze": "Bronze" },
    "solvency": {
      "low_risk": "Baix risc", "medium_risk": "Risc mitjà", "high_risk": "Alt risc",
      "cash": "Pagament al comptat", "mortgage_approved": "Hipoteca aprovada",
      "mortgage_pending": "Hipoteca en tràmit", "house_to_sell": "Venda d'habitatge",
      "unspecified_payment": "No especificat", "pre_approval": "Preaprovació bancària",
      "knows_costs": "Coneix les despeses", "has_savings": "Té estalvis inicials"
    }
  },
  "en-US": {
    "transaction": {
      "timeline_title": "Transaction Status",
      "timeline_subtitle": "Track the progress of your sale in real time",
      "property_fallback": "Property",
      "counterparty_fallback": "Counterparty"
    },
    "chat": { "level_gold": "Gold", "level_silver": "Silver", "level_bronze": "Bronze" },
    "solvency": {
      "low_risk": "Low risk", "medium_risk": "Medium risk", "high_risk": "High risk",
      "cash": "Cash payment", "mortgage_approved": "Mortgage approved",
      "mortgage_pending": "Mortgage pending", "house_to_sell": "House to sell",
      "unspecified_payment": "Unspecified", "pre_approval": "Bank pre-approval",
      "knows_costs": "Knows expenses", "has_savings": "Has initial savings"
    }
  },
  "fr-FR": {
    "transaction": {
      "timeline_title": "État de la Transaction",
      "timeline_subtitle": "Suivez le progrès de votre vente en temps réel",
      "property_fallback": "Propriété",
      "counterparty_fallback": "Contrepartie"
    },
    "chat": { "level_gold": "Or", "level_silver": "Argent", "level_bronze": "Bronze" },
    "solvency": {
      "low_risk": "Faible risque", "medium_risk": "Risque moyen", "high_risk": "Risque élevé",
      "cash": "Paiement au comptant", "mortgage_approved": "Hypothèque approuvée",
      "mortgage_pending": "Hypothèque en cours", "house_to_sell": "Maison à vendre",
      "unspecified_payment": "Non spécifié", "pre_approval": "Pré-approbation bancaire",
      "knows_costs": "Connaît les frais", "has_savings": "A des économies initiales"
    }
  },
  "eu-ES": {
    "transaction": {
      "timeline_title": "Transakzioaren Egoera",
      "timeline_subtitle": "Jarraitu zure salmentaren aurrerapena denbora errealean",
      "property_fallback": "Jabetza",
      "counterparty_fallback": "Kontrapartea"
    },
    "chat": { "level_gold": "Urrezkoa", "level_silver": "Zilarrezkoa", "level_bronze": "Brontzezkoa" },
    "solvency": {
      "low_risk": "Arrisku txikia", "medium_risk": "Arrisku ertaina", "high_risk": "Arrisku handia",
      "cash": "Eskura ordaintzea", "mortgage_approved": "Hipoteka onartua",
      "mortgage_pending": "Hipoteka tramitean", "house_to_sell": "Etxebizitza saltzeko",
      "unspecified_payment": "Zehaztu gabe", "pre_approval": "Bankuaren aurretiko onarpena",
      "knows_costs": "Gastuak ezagutzen ditu", "has_savings": "Hasierako aurrezkiak ditu"
    }
  },
  "gl-ES": {
    "transaction": {
      "timeline_title": "Estado da Transacción",
      "timeline_subtitle": "Segue o progreso da túa venda en tempo real",
      "property_fallback": "Propiedade",
      "counterparty_fallback": "Contraparte"
    },
    "chat": { "level_gold": "Ouro", "level_silver": "Prata", "level_bronze": "Bronce" },
    "solvency": {
      "low_risk": "Baixo risco", "medium_risk": "Risco medio", "high_risk": "Alto risco",
      "cash": "Pago ao contado", "mortgage_approved": "Hipoteca aprobada",
      "mortgage_pending": "Hipoteca en trámite", "house_to_sell": "Venda de vivenda",
      "unspecified_payment": "Non especificado", "pre_approval": "Preaprobación bancaria",
      "knows_costs": "Coñece os gastos", "has_savings": "Ten aforros iniciais"
    }
  }
};

// Also copy en-US to en-CA and en-GB, fr-FR to fr-CA
translations["en-CA"] = translations["en-US"];
translations["en-GB"] = translations["en-US"];
translations["fr-CA"] = translations["fr-FR"];

const translationsDir = path.join(__dirname, 'frontend/assets/translations');

for (const [lang, sections] of Object.entries(translations)) {
  const filePath = path.join(translationsDir, `${lang}.json`);
  if (!fs.existsSync(filePath)) continue;

  let fileContent = fs.readFileSync(filePath, 'utf8');
  if (fileContent.charCodeAt(0) === 0xFEFF) fileContent = fileContent.slice(1);
  const data = JSON.parse(fileContent);

  for (const [sectionName, keys] of Object.entries(sections)) {
    if (!data[sectionName]) data[sectionName] = {};
    for (const [k, v] of Object.entries(keys)) {
      data[sectionName][k] = v;
    }
  }

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
  console.log(`[${lang}] Finalized Phase 5 keys.`);
}

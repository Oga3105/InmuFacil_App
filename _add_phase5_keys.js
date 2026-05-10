const fs = require('fs');
const path = require('path');

const translations = {
  "es-ES": {
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
  },
  "ca-ES": {
    "chat": {
      "level_gold": "Or",
      "level_silver": "Plata",
      "level_bronze": "Bronze"
    },
    "solvency": {
      "low_risk": "Baix risc",
      "medium_risk": "Risc mitjà",
      "high_risk": "Alt risc",
      "cash": "Pagament al comptat",
      "mortgage_approved": "Hipoteca aprovada",
      "mortgage_pending": "Hipoteca en tràmit",
      "house_to_sell": "Venda d'habitatge",
      "unspecified_payment": "No especificat",
      "pre_approval": "Preaprovació bancària",
      "knows_costs": "Coneix les despeses",
      "has_savings": "Té estalvis inicials"
    }
  },
  "va-ES": {
    "chat": {
      "level_gold": "Or",
      "level_silver": "Plata",
      "level_bronze": "Bronze"
    },
    "solvency": {
      "low_risk": "Baix risc",
      "medium_risk": "Risc mitjà",
      "high_risk": "Alt risc",
      "cash": "Pagament al comptat",
      "mortgage_approved": "Hipoteca aprovada",
      "mortgage_pending": "Hipoteca en tràmit",
      "house_to_sell": "Venda d'habitatge",
      "unspecified_payment": "No especificat",
      "pre_approval": "Preaprovació bancària",
      "knows_costs": "Coneix les despeses",
      "has_savings": "Té estalvis inicials"
    }
  },
  "en-US": {
    "chat": {
      "level_gold": "Gold",
      "level_silver": "Silver",
      "level_bronze": "Bronze"
    },
    "solvency": {
      "low_risk": "Low risk",
      "medium_risk": "Medium risk",
      "high_risk": "High risk",
      "cash": "Cash payment",
      "mortgage_approved": "Mortgage approved",
      "mortgage_pending": "Mortgage pending",
      "house_to_sell": "House to sell",
      "unspecified_payment": "Unspecified",
      "pre_approval": "Bank pre-approval",
      "knows_costs": "Knows expenses",
      "has_savings": "Has initial savings"
    }
  },
  "en-CA": {
    "chat": {
      "level_gold": "Gold",
      "level_silver": "Silver",
      "level_bronze": "Bronze"
    },
    "solvency": {
      "low_risk": "Low risk",
      "medium_risk": "Medium risk",
      "high_risk": "High risk",
      "cash": "Cash payment",
      "mortgage_approved": "Mortgage approved",
      "mortgage_pending": "Mortgage pending",
      "house_to_sell": "House to sell",
      "unspecified_payment": "Unspecified",
      "pre_approval": "Bank pre-approval",
      "knows_costs": "Knows expenses",
      "has_savings": "Has initial savings"
    }
  },
  "en-GB": {
    "chat": {
      "level_gold": "Gold",
      "level_silver": "Silver",
      "level_bronze": "Bronze"
    },
    "solvency": {
      "low_risk": "Low risk",
      "medium_risk": "Medium risk",
      "high_risk": "High risk",
      "cash": "Cash payment",
      "mortgage_approved": "Mortgage approved",
      "mortgage_pending": "Mortgage pending",
      "house_to_sell": "House to sell",
      "unspecified_payment": "Unspecified",
      "pre_approval": "Bank pre-approval",
      "knows_costs": "Knows expenses",
      "has_savings": "Has initial savings"
    }
  },
  "fr-FR": {
    "chat": {
      "level_gold": "Or",
      "level_silver": "Argent",
      "level_bronze": "Bronze"
    },
    "solvency": {
      "low_risk": "Faible risque",
      "medium_risk": "Risque moyen",
      "high_risk": "Risque élevé",
      "cash": "Paiement au comptant",
      "mortgage_approved": "Hypothèque approuvée",
      "mortgage_pending": "Hypothèque en cours",
      "house_to_sell": "Maison à vendre",
      "unspecified_payment": "Non spécifié",
      "pre_approval": "Pré-approbation bancaire",
      "knows_costs": "Connaît les frais",
      "has_savings": "A des économies initiales"
    }
  },
  "fr-CA": {
    "chat": {
      "level_gold": "Or",
      "level_silver": "Argent",
      "level_bronze": "Bronze"
    },
    "solvency": {
      "low_risk": "Faible risque",
      "medium_risk": "Risque moyen",
      "high_risk": "Risque élevé",
      "cash": "Paiement au comptant",
      "mortgage_approved": "Hypothèque approuvée",
      "mortgage_pending": "Hypothèque en cours",
      "house_to_sell": "Maison à vendre",
      "unspecified_payment": "Non spécifié",
      "pre_approval": "Pré-approbation bancaire",
      "knows_costs": "Connaît les frais",
      "has_savings": "A des économies initiales"
    }
  },
  "eu-ES": {
    "chat": {
      "level_gold": "Urrezkoa",
      "level_silver": "Zilarrezkoa",
      "level_bronze": "Brontzezkoa"
    },
    "solvency": {
      "low_risk": "Arrisku txikia",
      "medium_risk": "Arrisku ertaina",
      "high_risk": "Arrisku handia",
      "cash": "Eskura ordaintzea",
      "mortgage_approved": "Hipoteka onartua",
      "mortgage_pending": "Hipoteka tramitean",
      "house_to_sell": "Etxebizitza saltzeko",
      "unspecified_payment": "Zehaztu gabe",
      "pre_approval": "Bankuaren aurretiko onarpena",
      "knows_costs": "Gastuak ezagutzen ditu",
      "has_savings": "Hasierako aurrezkiak ditu"
    }
  },
  "gl-ES": {
    "chat": {
      "level_gold": "Ouro",
      "level_silver": "Prata",
      "level_bronze": "Bronce"
    },
    "solvency": {
      "low_risk": "Baixo risco",
      "medium_risk": "Risco medio",
      "high_risk": "Alto risco",
      "cash": "Pago ao contado",
      "mortgage_approved": "Hipoteca aprobada",
      "mortgage_pending": "Hipoteca en trámite",
      "house_to_sell": "Venda de vivenda",
      "unspecified_payment": "Non especificado",
      "pre_approval": "Preaprobación bancaria",
      "knows_costs": "Coñece os gastos",
      "has_savings": "Ten aforros iniciais"
    }
  }
};

const translationsDir = path.join(__dirname, 'frontend/assets/translations');

for (const [lang, sections] of Object.entries(translations)) {
  const filePath = path.join(translationsDir, `${lang}.json`);
  if (!fs.existsSync(filePath)) {
    console.log(`File not found: ${filePath}`);
    continue;
  }

  let fileContent = fs.readFileSync(filePath, 'utf8');
  if (fileContent.charCodeAt(0) === 0xFEFF) {
    fileContent = fileContent.slice(1);
  }
  
  const data = JSON.parse(fileContent);

  for (const [sectionName, keys] of Object.entries(sections)) {
    if (!data[sectionName]) {
      data[sectionName] = {};
    }
    for (const [k, v] of Object.entries(keys)) {
      data[sectionName][k] = v;
    }
  }

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
  console.log(`[${lang}] Updated Phase 5 keys.`);
}

console.log("Phase 5 keys injected successfully.");

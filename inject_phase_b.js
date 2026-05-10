const fs = require('fs');
const base = 'C:/Users/Os/.gemini/antigravity/scratch/InmuFacil_Project/frontend/assets/translations/';

// ccaa names: geographic names stay in Spanish (official Spanish names)
// Decision: keep Spanish names in all languages (they are proper nouns)
const ccaa = {
  andalucia: "Andalucía", aragon: "Aragón", asturias: "Principado de Asturias",
  baleares: "Islas Baleares", canarias: "Canarias", cantabria: "Cantabria",
  castillaLaMancha: "Castilla-La Mancha", castillaYLeon: "Castilla y León",
  cataluna: "Cataluña", extremadura: "Extremadura", galicia: "Galicia",
  larioja: "La Rioja", madrid: "Comunidad de Madrid", murcia: "Región de Murcia",
  navarra: "Comunidad Foral de Navarra", paisVasco: "País Vasco",
  cValenciana: "Comunidad Valenciana", ceuta: "Ceuta", melilla: "Melilla",
  desconocida: "Comunidad no identificada"
};

// savings_table translations per language
const savings_table = {
  'en-GB': { concept: "Concept", seller: "Seller", buyer: "Buyer", percentage: "Percentage",
    percentage_seller: "5%\n(range 3%–7%)", percentage_buyer: "3%\n(range 0%–5%)",
    fixed_min: "Fixed minimum", fixed_min_seller: "£6,200 – £7,700", fixed_min_buyer: "£2,600 – £3,900",
    online_fee: "Online fee", online_fee_seller: "£3,400 – £6,900", online_fee_buyer: "Variable",
    financial: "Financial", financial_seller: "N/A", financial_buyer: "£2,600 – £5,200" },
  'en-CA': { concept: "Concept", seller: "Seller", buyer: "Buyer", percentage: "Percentage",
    percentage_seller: "5%\n(range 3%–7%)", percentage_buyer: "3%\n(range 0%–5%)",
    fixed_min: "Fixed minimum", fixed_min_seller: "€7,260 – €9,000", fixed_min_buyer: "€3,000 – €4,500",
    online_fee: "Online fee", online_fee_seller: "€4,000 – €8,000", online_fee_buyer: "Variable",
    financial: "Financial", financial_seller: "N/A", financial_buyer: "€3,000 – €6,000" },
  'fr-FR': { concept: "Concept", seller: "Vendeur", buyer: "Acheteur", percentage: "Pourcentage",
    percentage_seller: "5%\n(fourchette 3%–7%)", percentage_buyer: "3%\n(fourchette 0%–5%)",
    fixed_min: "Montant fixe minimum", fixed_min_seller: "7.260€ – 9.000€", fixed_min_buyer: "3.000€ – 4.500€",
    online_fee: "Frais en ligne", online_fee_seller: "4.000€ – 8.000€", online_fee_buyer: "Variable",
    financial: "Financier", financial_seller: "N/A", financial_buyer: "3.000€ – 6.000€" },
  'fr-CA': { concept: "Concept", seller: "Vendeur", buyer: "Acheteur", percentage: "Pourcentage",
    percentage_seller: "5%\n(fourchette 3%–7%)", percentage_buyer: "3%\n(fourchette 0%–5%)",
    fixed_min: "Montant fixe minimum", fixed_min_seller: "7.260€ – 9.000€", fixed_min_buyer: "3.000€ – 4.500€",
    online_fee: "Frais en ligne", online_fee_seller: "4.000€ – 8.000€", online_fee_buyer: "Variable",
    financial: "Financier", financial_seller: "N/A", financial_buyer: "3.000€ – 6.000€" }
};

// arras_contract legal refs (keep original Spanish legal references)
const legalRefs = {
  legal_ref_cataluna: "Art. 621-8 del Código Civil de Cataluña",
  legal_ref_general: "Art. 1454 del Código Civil"
};

// Apply ccaa to: en-GB, en-CA, fr-FR, fr-CA, ca-ES, eu-ES, gl-ES (they keep Spanish official names)
const ccaaLangs = ['en-GB', 'en-CA', 'fr-FR', 'fr-CA', 'ca-ES', 'eu-ES', 'gl-ES'];
ccaaLangs.forEach(lang => {
  const filePath = base + lang + '.json';
  const json = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  json.ccaa = Object.assign({}, ccaa);
  fs.writeFileSync(filePath, JSON.stringify(json, null, 2), 'utf8');
  console.log(lang + ' ccaa: done');
});

// Apply savings_table to fr-FR and fr-CA (en-GB, en-CA already have it from prior audit)
['fr-FR', 'fr-CA', 'en-GB', 'en-CA'].forEach(lang => {
  if (!savings_table[lang]) return;
  const filePath = base + lang + '.json';
  const json = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  if (!json.info) json.info = {};
  if (!json.info.what_is) json.info.what_is = {};
  json.info.what_is.savings_table = savings_table[lang];
  fs.writeFileSync(filePath, JSON.stringify(json, null, 2), 'utf8');
  console.log(lang + ' savings_table: done');
});

// Apply arras legal refs to fr-FR and fr-CA (keep Spanish refs as they are legal citations)
['fr-FR', 'fr-CA'].forEach(lang => {
  const filePath = base + lang + '.json';
  const json = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  if (!json.arras_contract) json.arras_contract = {};
  Object.assign(json.arras_contract, legalRefs);
  fs.writeFileSync(filePath, JSON.stringify(json, null, 2), 'utf8');
  console.log(lang + ' arras_contract legal refs: done');
});

// Verify key counts
const langs = ['es-ES','en-US','en-GB','en-CA','fr-FR','fr-CA','ca-ES','va-ES','eu-ES','gl-ES'];
function flatten(obj, p='') {
  let r={};
  for(let k in obj){let key=p?p+'.'+k:k;if(typeof obj[k]==='object'&&obj[k]!==null)Object.assign(r,flatten(obj[k],key));else r[key]=obj[k];}
  return r;
}
const baseKeys = Object.keys(flatten(JSON.parse(fs.readFileSync(base + 'es-ES.json','utf8'))));
console.log('\n=== Phase B complete — key counts ===');
langs.forEach(l => {
  const keys = Object.keys(flatten(JSON.parse(fs.readFileSync(base + l + '.json','utf8'))));
  const missing = baseKeys.filter(k => !keys.includes(k));
  console.log(l + ': ' + keys.length + ' keys, missing vs es-ES: ' + missing.length);
});

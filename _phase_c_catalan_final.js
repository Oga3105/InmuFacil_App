'use strict';
// Final targeted fixes for ca-ES / va-ES: ccaa names + ai_consent + a few genuine diffs
const fs = require('fs');
const path = require('path');

const TRANS_DIR = path.join(__dirname, 'frontend', 'assets', 'translations');

function readJson(locale) {
  return JSON.parse(fs.readFileSync(path.join(TRANS_DIR, locale + '.json'), 'utf8'));
}
function writeJson(locale, data) {
  fs.writeFileSync(path.join(TRANS_DIR, locale + '.json'), JSON.stringify(data, null, 2) + '\n', 'utf8');
}
function setVal(obj, dotPath, value) {
  const parts = dotPath.split('.');
  let cur = obj;
  for (let i = 0; i < parts.length - 1; i++) {
    if (typeof cur[parts[i]] !== 'object' || cur[parts[i]] === null) cur[parts[i]] = {};
    cur = cur[parts[i]];
  }
  cur[parts[parts.length - 1]] = value;
}
function applyDict(locale, dict) {
  const data = readJson(locale);
  for (const [key, val] of Object.entries(dict)) setVal(data, key, val);
  writeJson(locale, data);
  console.log('Updated', locale, '(' + Object.keys(dict).length + ' keys)');
}

const caDict = {
  // ccaa names that differ in Catalan
  'ccaa.andalucia': 'Andalusia',
  'ccaa.aragon': 'Aragó',
  'ccaa.asturias': "Principat d'Astúries",
  'ccaa.baleares': 'Illes Balears',
  'ccaa.canarias': 'Illes Canàries',
  'ccaa.cantabria': 'Cantàbria',
  'ccaa.castillaLaMancha': 'Castella-La Manxa',
  'ccaa.castillaYLeon': 'Castella i Lleó',
  'ccaa.cataluna': 'Catalunya',
  'ccaa.extremadura': 'Extremadura',
  'ccaa.galicia': 'Galícia',
  'ccaa.larioja': 'La Rioja',
  'ccaa.madrid': 'Comunitat de Madrid',
  'ccaa.murcia': 'Regió de Múrcia',
  'ccaa.navarra': 'Comunitat Foral de Navarra',
  'ccaa.paisVasco': 'País Basc',
  'ccaa.cValenciana': 'Comunitat Valenciana',
  'ccaa.ceuta': 'Ceuta',
  'ccaa.melilla': 'Melilla',
  'ccaa.desconocida': 'Comunitat no identificada',
  // ai_consent genuinely untranslated
  'ai_consent.data_sent_label': "Dades que s'envien",
  'ai_consent.ai_provider_label': "Proveïdor d'IA",
  'ai_consent.error_generic': "No s'ha pogut registrar el consentiment. Torna-ho a intentar.",
  'ai_consent.cancel_btn': "Cancel·lar",
  'ai_consent.accept_btn': 'Accepto i continuar',
  // info section that differs
  'info.what_is.savings_table.buyer': 'Comprador',
  'info.contact.email_action': 'Enviar correu',
  'info.legal.privacy.title': 'Política de Privacitat',
  'info.legal.legal_notice.title': 'Avís Legal',
  // property genuinely different
  'property.contact_private': 'Contactar Particular',
  'property.visit_confirmed': 'Visita confirmada',
  'property.compare.add': 'Comparar',
  'property.comparison.row.floor': 'Planta',
  'property.comparison.needs_renovation': 'Reforma',
  // transaction - a few that should differ
  'transaction.tasacion_snack_rejected': "Contraoferta enviada al comprador",
  'transaction.notaria_detail_notary': 'Notaria',
  'transaction.notaria_other_buyer': 'el comprador',
  'transaction.keys_buyer': 'Comprador',
  // solvency
  'solvency.individual_purchase': 'Compra individual',
  'solvency.co_titular': 'CO-TITULAR',
  // lifestyle
  'lifestyle.profile_investor': 'Inversor/a',
  'lifestyle.ready_slider_end': 'Potencial de reforma',
};

applyDict('ca-ES', caDict);
applyDict('va-ES', caDict);

console.log('Done: _phase_c_catalan_final');

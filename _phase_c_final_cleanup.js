'use strict';
// Phase C Final Cleanup: fix remaining genuinely different translations
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

// ============================================================
// en-US fixes: smart_bid_risk was never translated
// ============================================================
applyDict('en-US', {
  'smart_bid_risk.scale_low': 'LOW',
  'smart_bid_risk.scale_high': 'HIGH',
  'property_wizard.char_count': '{count} / 10000 characters',
  'visits.free_slots': '{count} free',
  'lifestyle.profile_senior': 'Senior',
  // month abbreviations that are legitimately the same but need distinct values
  'offers.chat': 'Chat',
  'offers.month_may': 'May',
  'offers.month_sep': 'Sep',
});

// en-GB/en-CA: sync
applyDict('en-GB', {
  'smart_bid_risk.scale_low': 'LOW',
  'smart_bid_risk.scale_high': 'HIGH',
  'property_wizard.char_count': '{count} / 10000 characters',
  'visits.free_slots': '{count} free',
  'offers.chat': 'Chat',
  'offers.month_may': 'May',
  'offers.month_sep': 'Sep',
});
applyDict('en-CA', {
  'smart_bid_risk.scale_low': 'LOW',
  'smart_bid_risk.scale_high': 'HIGH',
  'property_wizard.char_count': '{count} / 10000 characters',
  'visits.free_slots': '{count} free',
  'offers.chat': 'Chat',
  'offers.month_may': 'May',
  'offers.month_sep': 'Sep',
});

// ============================================================
// fr-FR: fix remaining genuinely different translations
// ============================================================
applyDict('fr-FR', {
  'smart_bid_risk.scale_low': 'FAIBLE',
  'smart_bid_risk.scale_high': 'ÉLEVÉ',
  'property_wizard.char_count': '{count} / 10000 caractères',
  'visits.free_slots': '{count} disponibles',
  'offers.chat': 'Chat',
  'offers.month_may': 'Mai',
  'offers.month_sep': 'Sep',
  'lifestyle.profile_senior': 'Senior',
  'arras_interview.equity_status_favorable': 'Favorable',
  'arras_interview.equity_label_favorable': 'Favorable',
  'home.nav_buy': 'Acheter',
  'home.extras_label': 'Extras',
  'search.apply': 'Appliquer',
  'search.nav_buy': 'Acheter',
  'search.extras_filter_label': 'Extras',
  'ai_consent.version': 'Version {}',
  'admin.ai_analytics_title': 'IA Analytics Admin',
  'arras_contract.legal_ref_cataluna': 'Art. 621-8 du Code Civil de Catalogne',
  'arras_contract.legal_ref_general': 'Art. 1454 du Code Civil',
  'transaction.footer_legal': 'Légal',
  'offers.legal_link': 'Légal',
});
applyDict('fr-CA', {
  'smart_bid_risk.scale_low': 'FAIBLE',
  'smart_bid_risk.scale_high': 'ÉLEVÉ',
  'property_wizard.char_count': '{count} / 10000 caractères',
  'visits.free_slots': '{count} disponibles',
  'offers.chat': 'Chat',
  'offers.month_may': 'Mai',
  'offers.month_sep': 'Sep',
  'lifestyle.profile_senior': 'Aîné',
  'arras_interview.equity_status_favorable': 'Favorable',
  'arras_interview.equity_label_favorable': 'Favorable',
  'home.nav_buy': 'Acheter',
  'home.extras_label': 'Extras',
  'search.apply': 'Appliquer',
  'search.nav_buy': 'Acheter',
  'search.extras_filter_label': 'Extras',
  'ai_consent.version': 'Version {}',
  'admin.ai_analytics_title': 'IA Analytics Admin',
  'arras_contract.legal_ref_cataluna': 'Art. 621-8 du Code Civil de Catalogne',
  'arras_contract.legal_ref_general': 'Art. 1454 du Code Civil',
  'transaction.footer_legal': 'Légal',
  'offers.legal_link': 'Légal',
});

// ============================================================
// ca-ES: fix remaining genuinely different Catalan translations
// ============================================================
const caCleaup = {
  'smart_bid_risk.scale_low': 'BAIXA',
  'smart_bid_risk.scale_high': 'ALTA',
  'property_wizard.char_count': '{count} / 10000 caràcters',
  'visits.free_slots': '{count} disponibles',
  'offers.chat': 'Xat',
  'offers.month_may': 'Mai',
  'offers.month_sep': 'Set',
  'lifestyle.profile_senior': 'Sènior',
  'home.extras_label': 'Extres',
  'search.apply': 'Aplicar',
  'search.nav_buy': 'Comprar',
  'search.extras_filter_label': 'Extres',
  // Search property types that differ in Catalan
  'search.property_type_office': 'Oficina / Comercial',
  'search.property_type_duplex': 'Dúplex',
  'search.property_type_rustic_house': 'Casa Rústica',
  'search.property_type_singular_house': 'Casa Singular',
  'search.property_type_local': 'Local Comercial',
  'search.property_type_rustic_land': 'Terreny Rústic',
  'ai_consent.version': 'Versió {}',
  'admin.ai_analytics_title': 'IA Analytics Admin',
  // Silver in Catalan: argent is more correct but plata also used
  'solvency.level_silver': 'ARGENT',
  'solvency.silver': 'ARGENT',
  'solvency.co_titular': 'CO-TITULAR',
  'solvency.individual_purchase': 'Compra individual',
  'profile.solvency.silver': 'Argent',
  'offers.silver': 'Argent',
  'transaction.solvency_level_silver': 'Argent',
  'chat.trust_badge_silver': 'ARGENT',
  'chat.solvency_silver': 'Argent',
  'chat.trust_silver': 'ARGENT',
  // Arras
  'arras_contract.legal_ref_cataluna': 'Art. 621-8 del Codi Civil de Catalunya',
  'arras_contract.legal_ref_general': 'Art. 1454 del Codi Civil',
  'arras_contract.preview_section_arras': 'ARRES (10%)',
  // Transaction keys that are different in Catalan
  'transaction.offer_sent': 'Oferta Enviada',
  'transaction.offer_withdrawn_step': 'Oferta Retirada',
  'transaction.arras_complete_btn': 'Completar entrevista',
  'transaction.visit_confirmed_step': 'Visita Confirmada',
  // Profile status Catalan forms
  'profile.offer_status_counter': 'Contraoferta',
  'profile.offer_status_completed': 'Completada',
  'profile.offer_status_withdrawn': 'Retirada',
  'profile.offers_tab.status.counter_offer': 'Contraoferta',
  'profile.offers_tab.status.completed': 'Completada',
  'profile.offers_tab.status.withdrawn': 'Retirada',
  'profile.visit_status_completed': 'Completada',
  'profile.visits_tab.status_completed': 'Completada',
  // Solvency remaining
  'solvency.prev_button': 'Anterior',
  'solvency.step_of': ' de ',
  'solvency.repeat_photo': 'Repetir foto',
  'solvency.capture_btn': 'Capturar',
  'solvency.retry': 'Reintentar',
  'solvency.expires_on': 'Expira el ',
  // property_listing
  'property_listing.sqm_unit': 'm²',
  'property_listing.map_view': 'Mapa',
  'property_listing.sort_by.label': 'Ordenar',
  'property_listing.bedrooms_short': 'Hab.',
  'property_listing.extra_labels.pool': 'Piscina',
  'property_listing.extra_labels.lift': 'Ascensor',
};
applyDict('ca-ES', caCleaup);
applyDict('va-ES', caCleaup);

// eu-ES: fix smart_bid_risk and remaining
applyDict('eu-ES', {
  'smart_bid_risk.scale_low': 'BAXUA',
  'smart_bid_risk.scale_high': 'ALTUA',
  'property_wizard.char_count': '{count} / 10000 karaktere',
  'visits.free_slots': '{count} libre',
  'offers.chat': 'Txat',
  'offers.month_may': 'Mai',
  'offers.month_sep': 'Ira',
  'lifestyle.profile_senior': 'Nagusiak',
  'ai_consent.version': 'Bertsioa {}',
  'home.extras_label': 'Gehigarriak',
  'search.extras_filter_label': 'Gehigarriak',
  'arras_contract.legal_ref_cataluna': 'Kataluniako Kode Zibileko 621-8 art.',
  'arras_contract.legal_ref_general': 'Kode Zibileko 1454 art.',
  'solvency.level_silver': 'ZILAR',
  'solvency.silver': 'ZILAR',
  'profile.solvency.silver': 'Zilar',
  'chat.trust_badge_silver': 'ZILAR',
  'chat.solvency_silver': 'Zilar',
  'offers.silver': 'Zilar',
  'transaction.solvency_level_silver': 'Zilar',
});

// gl-ES: fix smart_bid_risk and some remaining
applyDict('gl-ES', {
  'smart_bid_risk.scale_low': 'BAIXA',
  'smart_bid_risk.scale_high': 'ALTA',
  'property_wizard.char_count': '{count} / 10000 caracteres',
  'visits.free_slots': '{count} libres',
  'offers.chat': 'Chat',
  'offers.month_may': 'Mai',
  'offers.month_sep': 'Set',
  'lifestyle.profile_senior': 'Sénior',
  'ai_consent.version': 'Versión {}',
  'home.extras_label': 'Extras',
  'search.extras_filter_label': 'Extras',
  'arras_contract.legal_ref_cataluna': 'Art. 621-8 do Código Civil de Cataluña',
  'arras_contract.legal_ref_general': 'Art. 1454 do Código Civil',
  'solvency.level_silver': 'PRATA',
  'solvency.silver': 'PRATA',
  'profile.solvency.silver': 'Prata',
  'chat.trust_badge_silver': 'PRATA',
  'chat.solvency_silver': 'Prata',
  'offers.silver': 'Prata',
  'transaction.solvency_level_silver': 'Prata',
});

console.log('Done: _phase_c_final_cleanup');

const fs = require('fs');
const base = 'C:/Users/Os/.gemini/antigravity/scratch/InmuFacil_Project/frontend/assets/translations/';
const esEs = JSON.parse(fs.readFileSync(base + 'es-ES.json', 'utf8'));

function getVal(obj, path) {
  return path.split('.').reduce((o, k) => o && o[k], obj);
}
function setVal(obj, path, val) {
  const parts = path.split('.');
  const last = parts.pop();
  const target = parts.reduce((o, k) => { if (!o[k]) o[k] = {}; return o[k]; }, obj);
  target[last] = val;
}
function flatten(obj, p='') {
  let r={};
  for(let k in obj){let key=p?p+'.'+k:k;if(typeof obj[k]==='object'&&obj[k]!==null)Object.assign(r,flatten(obj[k],key));else r[key]=obj[k];}
  return r;
}

// --- kyc.dni / kyc.nie: keep Spanish acronyms as-is in all langs ---
const kycFix = { 'fr-FR': { dni: 'DNI', nie: 'NIE' }, 'ca-ES': { dni: 'DNI', nie: 'NIE' },
                 'eu-ES': { dni: 'DNI', nie: 'NIE' }, 'gl-ES': { dni: 'DNI', nie: 'NIE' },
                 'en-GB': { dni: 'DNI', nie: 'NIE' }, 'en-CA': { dni: 'DNI', nie: 'NIE' },
                 'fr-CA': { dni: 'DNI', nie: 'NIE' }, 'va-ES': { dni: 'DNI', nie: 'NIE' } };

Object.entries(kycFix).forEach(([lang, vals]) => {
  const fp = base + lang + '.json';
  const json = JSON.parse(fs.readFileSync(fp, 'utf8'));
  if (!json.kyc) json.kyc = {};
  Object.assign(json.kyc, vals);
  fs.writeFileSync(fp, JSON.stringify(json, null, 2), 'utf8');
});
console.log('kyc.dni/nie: done for all langs');

// --- savings_table for ca-ES, eu-ES, gl-ES, va-ES ---
const savingsES = esEs.info && esEs.info.what_is && esEs.info.what_is.savings_table;
const savingsCa = { ...savingsES }; // Catalan keeps same values as es-ES (numbers + Spanish legal terms)
const savingsLangs = ['ca-ES', 'va-ES', 'eu-ES', 'gl-ES'];
savingsLangs.forEach(lang => {
  const fp = base + lang + '.json';
  const json = JSON.parse(fs.readFileSync(fp, 'utf8'));
  if (!json.info) json.info = {};
  if (!json.info.what_is) json.info.what_is = {};
  json.info.what_is.savings_table = { ...savingsES };
  // Override concept/seller/buyer labels per lang
  if (lang === 'ca-ES' || lang === 'va-ES') {
    json.info.what_is.savings_table.concept = 'Concepte';
    json.info.what_is.savings_table.seller = 'Venedor';
    json.info.what_is.savings_table.buyer = 'Comprador';
    json.info.what_is.savings_table.percentage = 'Percentatge';
    json.info.what_is.savings_table.fixed_min = 'Mínim fix';
    json.info.what_is.savings_table.online_fee = 'Tarifa en línia';
    json.info.what_is.savings_table.financial = 'Financer';
  } else if (lang === 'eu-ES') {
    json.info.what_is.savings_table.concept = 'Kontzeptua';
    json.info.what_is.savings_table.seller = 'Saltzailea';
    json.info.what_is.savings_table.buyer = 'Eroslea';
    json.info.what_is.savings_table.percentage = 'Ehunekoa';
    json.info.what_is.savings_table.fixed_min = 'Gutxieneko finkoa';
    json.info.what_is.savings_table.online_fee = 'Online tarifa';
    json.info.what_is.savings_table.financial = 'Finantzarioa';
  } else if (lang === 'gl-ES') {
    json.info.what_is.savings_table.concept = 'Concepto';
    json.info.what_is.savings_table.seller = 'Vendedor';
    json.info.what_is.savings_table.buyer = 'Comprador';
    json.info.what_is.savings_table.percentage = 'Porcentaxe';
    json.info.what_is.savings_table.fixed_min = 'Mínimo fixo';
    json.info.what_is.savings_table.online_fee = 'Tarifa en liña';
    json.info.what_is.savings_table.financial = 'Financeiro';
  }
  fs.writeFileSync(fp, JSON.stringify(json, null, 2), 'utf8');
});
console.log('savings_table: done for ca-ES, va-ES, eu-ES, gl-ES');

// --- arras_contract legal refs for ca-ES, eu-ES, gl-ES, va-ES ---
const legalLangs = ['ca-ES', 'va-ES', 'eu-ES', 'gl-ES'];
legalLangs.forEach(lang => {
  const fp = base + lang + '.json';
  const json = JSON.parse(fs.readFileSync(fp, 'utf8'));
  if (!json.arras_contract) json.arras_contract = {};
  json.arras_contract.legal_ref_cataluna = 'Art. 621-8 del Codi Civil de Catalunya';
  json.arras_contract.legal_ref_general = 'Art. 1454 del Codi Civil';
  if (lang === 'eu-ES') {
    json.arras_contract.legal_ref_cataluna = 'Art. 621-8, Kataluniako Kode Zibila';
    json.arras_contract.legal_ref_general = 'Art. 1454, Kode Zibila';
  } else if (lang === 'gl-ES') {
    json.arras_contract.legal_ref_cataluna = 'Art. 621-8 do Código Civil de Cataluña';
    json.arras_contract.legal_ref_general = 'Art. 1454 do Código Civil';
  }
  fs.writeFileSync(fp, JSON.stringify(json, null, 2), 'utf8');
});
console.log('arras_contract legal refs: done for regional langs');

// --- en-GB/en-CA: inject remaining 87 missing keys using es-ES as source
// For time.months, time.short_months, time.weekdays_short: use English values
const timeEN = {
  months: { 1:'January',2:'February',3:'March',4:'April',5:'May',6:'June',7:'July',8:'August',9:'September',10:'October',11:'November',12:'December' },
  short_months: { 1:'Jan',2:'Feb',3:'Mar',4:'Apr',5:'May',6:'Jun',7:'Jul',8:'Aug',9:'Sep',10:'Oct',11:'Nov',12:'Dec' },
  weekdays_short: { 1:'Mon',2:'Tue',3:'Wed',4:'Thu',5:'Fri',6:'Sat',7:'Sun' }
};

['en-GB','en-CA'].forEach(lang => {
  const fp = base + lang + '.json';
  const json = JSON.parse(fs.readFileSync(fp, 'utf8'));
  // time blocks
  if (!json.time) json.time = {};
  json.time.months = timeEN.months;
  json.time.short_months = timeEN.short_months;
  json.time.weekdays_short = timeEN.weekdays_short;
  // common.error_title from es-ES
  if (!json.common) json.common = {};
  json.common.error_title = json.common.error_title || 'Error';
  // chat keys from es-ES
  const chatKeys = ['yesterday_caps','action_visit_cancelled','reject','accept','reschedule','cancel','quick_visit','quick_offer','encryption_note','reference'];
  const chatTransEN = {
    yesterday_caps: 'YESTERDAY', action_visit_cancelled: 'Visit cancelled', reject: 'Reject',
    accept: 'Accept', reschedule: 'Reschedule', cancel: 'Cancel',
    quick_visit: 'Schedule a visit', quick_offer: 'Make an offer',
    encryption_note: 'End-to-end encrypted messages', reference: 'Ref.'
  };
  if (!json.chat) json.chat = {};
  Object.assign(json.chat, chatTransEN);
  // kyc already done above
  // solvency level titles
  const solvencyEN = {
    level_gold_title: 'Gold', level_silver_title: 'Silver', level_bronze_title: 'Bronze',
    gold_preview_desc: 'Full solvency verified. Ready to make offers.',
    silver_preview_desc: 'Partial solvency. Some documents pending.',
    bronze_preview_desc: 'Basic solvency. Minimum required documents submitted.'
  };
  if (!json.solvency) json.solvency = {};
  Object.assign(json.solvency, solvencyEN);
  // pre_offer_tax
  if (!json.pre_offer_tax) json.pre_offer_tax = {};
  json.pre_offer_tax.notarial_disclaimer = json.pre_offer_tax.notarial_disclaimer || getVal(esEs, 'pre_offer_tax.notarial_disclaimer') || '';
  // smart_bid_risk
  if (!json.smart_bid_risk) json.smart_bid_risk = {};
  json.smart_bid_risk.extreme_low_offer = 'Offer significantly below market price';
  // transaction extra keys from es-ES
  const txKeys = ['tasacion_app_bar_title','tasacion_appointment_format','fein_notes_confirm','keys_docs_delivery','pv_not_applicable_label'];
  const txEN = {
    tasacion_app_bar_title: 'Property Appraisal',
    tasacion_appointment_format: 'Appointment: {date} at {time}',
    fein_notes_confirm: 'I confirm I have reviewed the FEIN document',
    keys_docs_delivery: 'Key and document handover',
    pv_not_applicable_label: 'Not applicable'
  };
  if (!json.transaction) json.transaction = {};
  Object.assign(json.transaction, txEN);
  // arras_interview hub keys
  const aiEN = {
    hub_info_box: 'Both parties must complete the interview before the contract is generated.',
    hub_status_buyer_done_buyer: 'You have completed the interview. Waiting for the seller.',
    hub_status_buyer_done_seller: 'The buyer has completed the interview. Your turn.',
    hub_status_seller_done_seller: 'You have completed the interview. Waiting for the buyer.',
    hub_status_seller_done_buyer: 'The seller has completed the interview. Your turn.',
    hub_contract_pending_title: 'Contract pending generation',
    hub_contract_pending_desc: 'Both interviews are complete. The contract will be generated shortly.',
    mortgage_subject_title: 'Subject to mortgage approval',
    mortgage_subject_sub: 'The transaction is conditional on mortgage approval',
    extension_allowed_title: 'Extension clause',
    extension_allowed_sub: 'Allow deadline extension for justified cause',
    method_cash: 'Cash', method_mortgage_approved: 'Approved mortgage',
    method_mortgage_pending: 'Pending mortgage approval',
    method_savings_plus_mortgage: 'Savings + mortgage',
    method_house_to_sell: 'Subject to selling current home',
    bank_name_title: 'Bank name',
    rejection_sent_snack: 'Interview rejected',
    equity_no_data: 'No data available',
    equity_label_favorable: 'Favorable', equity_label_balanced: 'Balanced',
    equity_label_alerts: 'Alerts', equity_label_unfavorable: 'Unfavorable',
    equity_buyer_pos: 'Buyer position', equity_seller_pos: 'Seller position'
  };
  Object.assign(json.arras_interview, aiEN);
  // visits
  const visitsEN = {
    no_slots_email_title: 'No available slots',
    no_slots_email_desc: 'Send an email to request a custom time slot.',
    create_window_btn: 'Add availability window'
  };
  if (!json.visits) json.visits = {};
  Object.assign(json.visits, visitsEN);
  // arras_contract legal refs
  if (!json.arras_contract) json.arras_contract = {};
  json.arras_contract.legal_ref_cataluna = 'Art. 621-8 of the Civil Code of Catalonia';
  json.arras_contract.legal_ref_general = 'Art. 1454 of the Civil Code';

  fs.writeFileSync(fp, JSON.stringify(json, null, 2), 'utf8');
  console.log(lang + ' remaining keys: done');
});

// fr-CA: same remaining structure as fr-FR for the extra missing keys
['fr-CA'].forEach(lang => {
  const fp = base + lang + '.json';
  const json = JSON.parse(fs.readFileSync(fp, 'utf8'));
  const frFr = JSON.parse(fs.readFileSync(base + 'fr-FR.json', 'utf8'));
  // Copy all keys from fr-FR that fr-CA is missing
  function flatten(obj, p='') { let r={}; for(let k in obj){let key=p?p+'.'+k:k;if(typeof obj[k]==='object'&&obj[k]!==null)Object.assign(r,flatten(obj[k],key));else r[key]=obj[k];} return r; }
  const baseKeys = Object.keys(flatten(JSON.parse(fs.readFileSync(base+'es-ES.json','utf8'))));
  const langKeys = Object.keys(flatten(json));
  const frFrFlat = flatten(frFr);
  const missing = baseKeys.filter(k => !langKeys.includes(k));
  missing.forEach(k => {
    if (frFrFlat[k]) {
      const parts = k.split('.');
      const last = parts.pop();
      const target = parts.reduce((o, key) => { if (!o[key]) o[key] = {}; return o[key]; }, json);
      target[last] = frFrFlat[k];
    }
  });
  fs.writeFileSync(fp, JSON.stringify(json, null, 2), 'utf8');
  console.log(lang + ' synced from fr-FR');
});

// Final count
function flatten2(obj,p=''){let r={};for(let k in obj){let key=p?p+'.'+k:k;if(typeof obj[k]==='object'&&obj[k]!==null)Object.assign(r,flatten2(obj[k],key));else r[key]=obj[k];}return r;}
const baseKeys = Object.keys(flatten2(JSON.parse(fs.readFileSync(base+'es-ES.json','utf8'))));
const langs = ['es-ES','en-US','en-GB','en-CA','fr-FR','fr-CA','ca-ES','va-ES','eu-ES','gl-ES'];
console.log('\n=== FINAL KEY COUNTS ===');
langs.forEach(l => {
  const keys = Object.keys(flatten2(JSON.parse(fs.readFileSync(base+l+'.json','utf8'))));
  const missing = baseKeys.filter(k=>!keys.includes(k));
  console.log(l+': '+keys.length+' keys, missing: '+missing.length+(missing.length?(' ['+missing.slice(0,3).join(',')+']'):''));
});

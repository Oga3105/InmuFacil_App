'use strict';
// Phase C Regional C: urgency + report + visit_cancel + common + chat + home + offers + transaction + misc
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
function flatten(obj, prefix) {
  prefix = prefix || '';
  return Object.entries(obj).reduce(function(acc, entry) {
    const k = entry[0], v = entry[1];
    const key = prefix ? prefix + '.' + k : k;
    if (typeof v === 'object' && v !== null && !Array.isArray(v)) {
      Object.assign(acc, flatten(v, key));
    } else {
      acc[key] = v;
    }
    return acc;
  }, {});
}

// ============================================================
// URGENCY
// ============================================================
const urgencyCa = {
  'urgency.complete_solvency': 'Completar Passaport de Solvència',
  'urgency.review_post_sale_buyer': 'Revisar documents de post-venda',
  'urgency.review_post_sale_seller': 'Gestionar documents de post-venda',
  'urgency.confirm_signing_keys': 'Confirmar signatura i lliurament de claus',
  'urgency.coordinate_notary': 'Coordinar cita a la notaria',
  'urgency.waiting_notary_appt': "A l'espera de cita a la notaria",
  'urgency.go_to_fein': 'Anar a la Formalització Bancària (FEIN)',
  'urgency.appraiser_appt_confirmed': 'Cita del taxador confirmada',
  'urgency.waiting_seller_confirmation': 'Esperant confirmació del venedor',
  'urgency.answer_appraiser_counter': 'Respondre contraoferta del taxador',
  'urgency.schedule_appraiser_visit': 'Programar visita del taxador',
  'urgency.review_buyer_solvency': 'Revisar solvència del comprador',
  'urgency.confirm_appraiser_appt': 'Confirmar cita del taxador',
  'urgency.confirm_appraiser_visit': 'Confirmar visita del taxador',
};

const urgencyEu = {
  'urgency.complete_solvency': 'Solventzia Pasaportea Osatu',
  'urgency.review_post_sale_buyer': 'Post-salmenta dokumentuak berrikusi',
  'urgency.review_post_sale_seller': 'Post-salmenta dokumentuak kudeatu',
  'urgency.confirm_signing_keys': 'Sinadura eta gakoen entrega berretsi',
  'urgency.coordinate_notary': 'Notarioaren hitzordua koordinatu',
  'urgency.waiting_notary_appt': 'Notarioaren hitzordua zain',
  'urgency.go_to_fein': 'Joan Banku Formalizaziora (FEIN)',
  'urgency.appraiser_appt_confirmed': 'Tasatzailearen hitzordua berretsia',
  'urgency.waiting_seller_confirmation': 'Saltzailearen berrespena zain',
  'urgency.answer_appraiser_counter': 'Tasatzailearen kontraeskaintza erantzun',
  'urgency.schedule_appraiser_visit': 'Tasatzailearen bisitaldia programatu',
  'urgency.review_buyer_solvency': 'Eroslearen solventzia berrikusi',
  'urgency.confirm_appraiser_appt': 'Tasatzailearen hitzordua berretsi',
  'urgency.confirm_appraiser_visit': 'Tasatzailearen bisitaldia berretsi',
};

const urgencyGl = {
  'urgency.complete_solvency': 'Completar Pasaporte de Solvencia',
  'urgency.review_post_sale_buyer': 'Revisar documentos de post-venda',
  'urgency.review_post_sale_seller': 'Xestionar documentos de post-venda',
  'urgency.confirm_signing_keys': 'Confirmar sinatura e entrega de chaves',
  'urgency.coordinate_notary': 'Coordinar cita na notaría',
  'urgency.waiting_notary_appt': 'Á espera de cita na notaría',
  'urgency.go_to_fein': 'Ir á Formalización Bancaria (FEIN)',
  'urgency.appraiser_appt_confirmed': 'Cita do taxador confirmada',
  'urgency.waiting_seller_confirmation': 'Esperando confirmación do vendedor',
  'urgency.answer_appraiser_counter': 'Responder contraoferta do taxador',
  'urgency.schedule_appraiser_visit': 'Programar visita do taxador',
  'urgency.review_buyer_solvency': 'Revisar solvencia do comprador',
  'urgency.confirm_appraiser_appt': 'Confirmar cita do taxador',
  'urgency.confirm_appraiser_visit': 'Confirmar visita do taxador',
};

const urgencyFr = {
  'urgency.complete_solvency': 'Compléter le Passeport de Solvabilité',
  'urgency.review_post_sale_buyer': "Examiner les documents d'après-vente",
  'urgency.review_post_sale_seller': "Gérer les documents d'après-vente",
  'urgency.confirm_signing_keys': 'Confirmer la signature et la remise des clés',
  'urgency.coordinate_notary': 'Coordonner le rendez-vous chez le notaire',
  'urgency.waiting_notary_appt': "En attente d'un rendez-vous chez le notaire",
  'urgency.go_to_fein': 'Aller à la Formalisation Bancaire (FEIN)',
  'urgency.appraiser_appt_confirmed': "Rendez-vous de l'expert confirmé",
  'urgency.waiting_seller_confirmation': 'En attente de confirmation du vendeur',
  'urgency.answer_appraiser_counter': "Répondre à la contre-proposition de l'expert",
  'urgency.schedule_appraiser_visit': "Planifier la visite de l'expert",
  'urgency.review_buyer_solvency': "Examiner la solvabilité de l'acheteur",
  'urgency.confirm_appraiser_appt': "Confirmer le rendez-vous de l'expert",
  'urgency.confirm_appraiser_visit': "Confirmer la visite de l'expert",
};

// ============================================================
// REPORT
// ============================================================
const reportCa = {
  'report.button_tooltip': 'Reportar usuari',
  'report.modal_title': 'Reportar usuari sospitós',
  'report.modal_subtitle': 'Selecciona el motiu de la teva denúncia. Les denúncies falses poden ser sancionades.',
  'report.category_professional': 'Professional camuflat',
  'report.category_commission': 'Demana comissió',
  'report.category_inaccurate': 'Dades inexactes',
  'report.description_label': 'Descripció (opcional)',
  'report.description_hint': 'Descriu el comportament sospitós...',
  'report.submit': 'Enviar denúncia',
  'report.success': 'Denúncia enviada correctament',
  'report.error': "Error en enviar la denúncia",
};
const reportEu = {
  'report.button_tooltip': 'Erabiltzailea salatu',
  'report.modal_title': 'Erabiltzaile susmagarria salatu',
  'report.modal_subtitle': 'Hautatu zure salaketa arrazoia. Salaketa faltsuak zigortuta egon daitezke.',
  'report.category_professional': 'Profesional mozorrotua',
  'report.category_commission': 'Komisioa eskatzen du',
  'report.category_inaccurate': 'Datu inexaktuak',
  'report.description_label': 'Deskripzioa (aukerakoa)',
  'report.description_hint': 'Deskribatu portaera susmagarria...',
  'report.submit': 'Salaketa bidali',
  'report.success': 'Salaketa behar bezala bidali da',
  'report.error': 'Errorea salaketa bidaltzean',
};
const reportGl = {
  'report.button_tooltip': 'Reportar usuario',
  'report.modal_title': 'Reportar usuario sospeitoso',
  'report.modal_subtitle': 'Selecciona o motivo da túa denuncia. As denuncias falsas poden ser sancionadas.',
  'report.category_professional': 'Profesional camuflado',
  'report.category_commission': 'Pide comisión',
  'report.category_inaccurate': 'Datos inexactos',
  'report.description_label': 'Descrición (opcional)',
  'report.description_hint': 'Describe o comportamento sospeitoso...',
  'report.submit': 'Enviar denuncia',
  'report.success': 'Denuncia enviada correctamente',
  'report.error': 'Erro ao enviar a denuncia',
};
const reportFr = {
  'report.button_tooltip': "Signaler l'utilisateur",
  'report.modal_title': 'Signaler un utilisateur suspect',
  'report.modal_subtitle': 'Sélectionnez le motif de votre signalement. Les faux signalements peuvent être sanctionnés.',
  'report.category_professional': 'Professionnel déguisé',
  'report.category_commission': 'Demande une commission',
  'report.category_inaccurate': 'Données inexactes',
  'report.description_label': 'Description (optionnel)',
  'report.description_hint': 'Décrivez le comportement suspect...',
  'report.submit': 'Envoyer le signalement',
  'report.success': 'Signalement envoyé avec succès',
  'report.error': "Erreur lors de l'envoi du signalement",
};

// ============================================================
// VISIT_CANCEL
// ============================================================
const visitCancelCa = {
  'visit_cancel.title_part1': "Anul·lar",
  'visit_cancel.title_part2': 'visita',
  'visit_cancel.reason_prompt': "Si us plau, indica el motiu de l'anul·lació:",
  'visit_cancel.reason_withdraw': 'Retirar oferta',
  'visit_cancel.reason_other_label': 'Especifica el motiu',
  'visit_cancel.reason_other_required': 'El motiu és obligatori.',
  'visit_cancel.back_btn': 'Tornar',
  'visit_cancel.confirm_btn': "Anul·lar Visita",
  'visit_cancel.reason_withdraw_offer': 'Retirar oferta',
};
const visitCancelEu = {
  'visit_cancel.title_part1': 'Bisitaldia',
  'visit_cancel.title_part2': 'bertan behera utzi',
  'visit_cancel.reason_prompt': 'Mesedez, adierazi bertan behera uzteko arrazoia:',
  'visit_cancel.reason_withdraw': 'Eskaintza erretiratu',
  'visit_cancel.reason_other_label': 'Zehaztu arrazoia',
  'visit_cancel.reason_other_required': 'Arrazoia nahitaezkoa da.',
  'visit_cancel.back_btn': 'Itzuli',
  'visit_cancel.confirm_btn': 'Bisitaldia Bertan Behera Utzi',
  'visit_cancel.reason_withdraw_offer': 'Eskaintza erretiratu',
};
const visitCancelGl = {
  'visit_cancel.title_part1': 'Anular',
  'visit_cancel.title_part2': 'visita',
  'visit_cancel.reason_prompt': 'Por favor, indica o motivo da anulación:',
  'visit_cancel.reason_withdraw': 'Retirar oferta',
  'visit_cancel.reason_other_label': 'Especifica o motivo',
  'visit_cancel.reason_other_required': 'O motivo é obrigatorio.',
  'visit_cancel.back_btn': 'Volver',
  'visit_cancel.confirm_btn': 'Anular Visita',
  'visit_cancel.reason_withdraw_offer': 'Retirar oferta',
};
const visitCancelFr = {
  'visit_cancel.title_part1': 'Annuler',
  'visit_cancel.title_part2': 'visite',
  'visit_cancel.reason_prompt': "Veuillez indiquer le motif de l'annulation :",
  'visit_cancel.reason_withdraw': "Retirer l'offre",
  'visit_cancel.reason_other_label': 'Précisez le motif',
  'visit_cancel.reason_other_required': 'Le motif est obligatoire.',
  'visit_cancel.back_btn': 'Retour',
  'visit_cancel.confirm_btn': 'Annuler la Visite',
  'visit_cancel.reason_withdraw_offer': "Retirer l'offre",
};

// ============================================================
// COMMON remaining
// ============================================================
const commonCa = {
  'common.delete': 'Eliminar',
  'common.edit': 'Editar',
  'common.error': 'Error',
  'common.confirm': 'Confirmar',
  'common.filter': 'Filtrar',
  'common.sort': 'Ordenar',
  'common.send': 'Enviar',
  'common.withdraw': 'Retirar',
  'common.yes': 'Sí',
  'common.no': 'No',
  'common.language': 'Idioma',
  'common.previous': 'Anterior',
  'common.continue_btn': 'Continua',
  'common.activate': 'Activar',
  'common.retry': 'Reintentar',
  'common.error_title': 'Error',
};
const commonEu = {
  'common.delete': 'Ezabatu',
  'common.edit': 'Editatu',
  'common.error': 'Errorea',
  'common.confirm': 'Berretsi',
  'common.filter': 'Iragazkia',
  'common.sort': 'Ordenatu',
  'common.send': 'Bidali',
  'common.withdraw': 'Erretiratu',
  'common.yes': 'Bai',
  'common.no': 'Ez',
  'common.language': 'Hizkuntza',
  'common.previous': 'Aurrekoa',
  'common.continue_btn': 'Jarraitu',
  'common.activate': 'Aktibatu',
  'common.retry': 'Berriro saiatu',
  'common.error_title': 'Errorea',
};
const commonGl = {
  'common.delete': 'Eliminar',
  'common.edit': 'Editar',
  'common.error': 'Erro',
  'common.confirm': 'Confirmar',
  'common.filter': 'Filtrar',
  'common.sort': 'Ordenar',
  'common.send': 'Enviar',
  'common.withdraw': 'Retirar',
  'common.yes': 'Si',
  'common.no': 'Non',
  'common.language': 'Idioma',
  'common.previous': 'Anterior',
  'common.continue_btn': 'Continuar',
  'common.activate': 'Activar',
  'common.retry': 'Reintentar',
  'common.error_title': 'Erro',
};
const commonFr = {
  'common.delete': 'Supprimer',
  'common.edit': 'Modifier',
  'common.error': 'Erreur',
  'common.confirm': 'Confirmer',
  'common.filter': 'Filtrer',
  'common.sort': 'Trier',
  'common.send': 'Envoyer',
  'common.withdraw': 'Retirer',
  'common.yes': 'Oui',
  'common.no': 'Non',
  'common.language': 'Langue',
  'common.previous': 'Précédent',
  'common.continue_btn': 'Continuer',
  'common.activate': 'Activer',
  'common.retry': 'Réessayer',
  'common.error_title': 'Erreur',
};

// ============================================================
// CHAT remaining
// ============================================================
const chatCa = {
  'chat.retry': 'Reintentar',
  'chat.active_offer': 'Oferta activa',
  'chat.trust_badge_silver': 'PLATA',
  'chat.send_button': 'Enviar',
  'chat.action_visit_accepted': 'Visita Confirmada',
  'chat.solvency_silver': 'Plata',
  'chat.feature_kyc': 'PERFIL KYC',
  'chat.trust_silver': 'PLATA',
  'chat.reschedule': 'Reprogramar',
  'chat.quick_visit': 'Visita',
  'chat.quick_offer': 'Oferta',
};
const chatEu = {
  'chat.retry': 'Berriro saiatu',
  'chat.active_offer': 'Eskaintza aktibo',
  'chat.trust_badge_silver': 'ZILAR',
  'chat.send_button': 'Bidali',
  'chat.action_visit_accepted': 'Bisitaldia Berretsia',
  'chat.solvency_silver': 'Zilar',
  'chat.feature_kyc': 'KYC PROFILA',
  'chat.trust_silver': 'ZILAR',
  'chat.reschedule': 'Berreprogramatu',
  'chat.quick_visit': 'Bisitaldia',
  'chat.quick_offer': 'Eskaintza',
};
const chatGl = {
  'chat.retry': 'Reintentar',
  'chat.active_offer': 'Oferta activa',
  'chat.trust_badge_silver': 'PRATA',
  'chat.send_button': 'Enviar',
  'chat.action_visit_accepted': 'Visita Confirmada',
  'chat.solvency_silver': 'Prata',
  'chat.feature_kyc': 'PERFIL KYC',
  'chat.trust_silver': 'PRATA',
  'chat.reschedule': 'Reprogramar',
  'chat.quick_visit': 'Visita',
  'chat.quick_offer': 'Oferta',
};
const chatFr = {
  'chat.retry': 'Réessayer',
  'chat.active_offer': 'Offre active',
  'chat.trust_badge_silver': 'ARGENT',
  'chat.send_button': 'Envoyer',
  'chat.action_visit_accepted': 'Visite Confirmée',
  'chat.solvency_silver': 'Argent',
  'chat.feature_kyc': 'PROFIL KYC',
  'chat.trust_silver': 'ARGENT',
  'chat.reschedule': 'Reprogrammer',
  'chat.quick_visit': 'Visite',
  'chat.quick_offer': 'Offre',
};

// ============================================================
// HOME remaining
// ============================================================
const homeCa = {
  'home.apply': 'Aplicar',
  'home.nav_buy': 'Comprar',
  'home.property_type_apartment': 'Pisos',
  'home.property_type_duplex': 'Dúplex',
};
const homeEu = {
  'home.apply': 'Aplikatu',
  'home.nav_buy': 'Erosi',
  'home.property_type_apartment': 'Pisua',
  'home.property_type_duplex': 'Duplexak',
};
const homeGl = {
  'home.apply': 'Aplicar',
  'home.nav_buy': 'Comprar',
  'home.property_type_apartment': 'Pisos',
  'home.property_type_duplex': 'Dúplex',
};
const homeFr = {
  'home.apply': 'Appliquer',
  'home.nav_buy': 'Acheter',
  'home.property_type_apartment': 'Appartements',
  'home.property_type_duplex': 'Duplex',
};

// ============================================================
// OFFERS remaining
// ============================================================
const offersCa = {
  'offers.date_placeholder': 'dd/mm/aaaa',
  'offers.total_label': 'OFERTA TOTAL',
  'offers.send_offer': 'Enviar Oferta Formal',
  'offers.available_status': 'DISPONIBLE',
  'offers.retry': 'Reintentar',
  'offers.buyer_fallback': 'Comprador',
  'offers.counter_title_prefix': 'Contra',
  'offers.counter_btn': 'Contraofertar',
  'offers.status_counter': 'CONTRAOFERTA ENVIADA',
  'offers.status_signing': 'EN SIGNATURA',
  'offers.status_signed': 'SIGNADA',
  'offers.status_completed': 'COMPLETADA',
  'offers.status_withdrawn': 'RETIRADA',
  'offers.silver': 'Plata',
  'offers.joint_purchase': 'Compra conjunta',
  'offers.legal_link': 'Legal',
  'offers.month_feb': 'Feb',
  'offers.month_mar': 'Mar',
  'offers.month_apr': 'Abr',
  'offers.month_jun': 'Jun',
  'offers.month_jul': 'Jul',
  'offers.month_aug': 'Ago',
  'offers.month_oct': 'Oct',
  'offers.month_nov': 'Nov',
};
const offersEu = {
  'offers.date_placeholder': 'ee/hh/uuuu',
  'offers.total_label': 'ESKAINTZA OSOA',
  'offers.send_offer': 'Eskaintza Formala Bidali',
  'offers.available_status': 'ESKURAGARRI',
  'offers.retry': 'Berriro saiatu',
  'offers.buyer_fallback': 'Erosleak',
  'offers.counter_title_prefix': 'Kontra',
  'offers.counter_btn': 'Kontraeskaintza',
  'offers.status_counter': 'KONTRAESKAINTZA BIDALITA',
  'offers.status_signing': 'SINATZEKO',
  'offers.status_signed': 'SINATUTA',
  'offers.status_completed': 'OSATUTA',
  'offers.status_withdrawn': 'ERRETIRATU',
  'offers.silver': 'Zilar',
  'offers.joint_purchase': 'Erosketa bateratua',
  'offers.legal_link': 'Legala',
  'offers.month_feb': 'Ots',
  'offers.month_mar': 'Mar',
  'offers.month_apr': 'Api',
  'offers.month_jun': 'Eka',
  'offers.month_jul': 'Uzt',
  'offers.month_aug': 'Abu',
  'offers.month_oct': 'Urr',
  'offers.month_nov': 'Aza',
};
const offersGl = {
  'offers.date_placeholder': 'dd/mm/aaaa',
  'offers.total_label': 'OFERTA TOTAL',
  'offers.send_offer': 'Enviar Oferta Formal',
  'offers.available_status': 'DISPOÑIBLE',
  'offers.retry': 'Reintentar',
  'offers.buyer_fallback': 'Comprador',
  'offers.counter_title_prefix': 'Contra',
  'offers.counter_btn': 'Contraofertar',
  'offers.status_counter': 'CONTRAOFERTA ENVIADA',
  'offers.status_signing': 'EN SINATURA',
  'offers.status_signed': 'ASINADA',
  'offers.status_completed': 'COMPLETADA',
  'offers.status_withdrawn': 'RETIRADA',
  'offers.silver': 'Prata',
  'offers.joint_purchase': 'Compra conxunta',
  'offers.legal_link': 'Legal',
  'offers.month_feb': 'Feb',
  'offers.month_mar': 'Mar',
  'offers.month_apr': 'Abr',
  'offers.month_jun': 'Xuñ',
  'offers.month_jul': 'Xul',
  'offers.month_aug': 'Ago',
  'offers.month_oct': 'Out',
  'offers.month_nov': 'Nov',
};
const offersFr = {
  'offers.date_placeholder': 'jj/mm/aaaa',
  'offers.total_label': 'OFFRE TOTALE',
  'offers.send_offer': 'Envoyer une Offre Formelle',
  'offers.available_status': 'DISPONIBLE',
  'offers.retry': 'Réessayer',
  'offers.buyer_fallback': 'Acheteur',
  'offers.counter_title_prefix': 'Contre',
  'offers.counter_btn': 'Contre-offre',
  'offers.status_counter': 'CONTRE-OFFRE ENVOYÉE',
  'offers.status_signing': 'EN SIGNATURE',
  'offers.status_signed': 'SIGNÉE',
  'offers.status_completed': 'COMPLÉTÉE',
  'offers.status_withdrawn': 'RETIRÉE',
  'offers.silver': 'Argent',
  'offers.joint_purchase': 'Achat conjoint',
  'offers.legal_link': 'Légal',
  'offers.month_feb': 'Fév',
  'offers.month_mar': 'Mar',
  'offers.month_apr': 'Avr',
  'offers.month_jun': 'Juin',
  'offers.month_jul': 'Juil',
  'offers.month_aug': 'Août',
  'offers.month_oct': 'Oct',
  'offers.month_nov': 'Nov',
};

// ============================================================
// TRANSACTION remaining
// ============================================================
const transactionCa = {
  'transaction.buyer_header_label': 'COMPRADOR',
  'transaction.offer_sent': 'Oferta Enviada',
  'transaction.offer_withdrawn_step': 'Oferta Retirada',
  'transaction.arras_complete_btn': 'Completar entrevista',
  'transaction.visit_confirmed_step': 'Visita Confirmada',
  'transaction.visit_date_confirmed': 'Cita acordada: {date}',
  'transaction.withdraw_dialog_title': 'Retirar oferta',
  'transaction.withdraw_btn': 'Retirar',
  'transaction.solvency_level_silver': 'Plata',
  'transaction.solvency_joint_purchase': 'Compra conjunta',
  'transaction.withdraw_offer_btn': 'Retirar Oferta',
  'transaction.footer_legal': 'Legal',
  'transaction.tasacion_time_label': 'Hora aproximada',
  'transaction.tasacion_select': 'Seleccionar',
  'transaction.tasacion_snack_rejected': 'Contraoferta enviada al comprador',
  'transaction.notaria_time_label': 'Hora',
  'transaction.notaria_select_time': 'Seleccionar hora',
  'transaction.notaria_scheduled': 'Cita programada',
  'transaction.notaria_buyer_label': 'Comprador',
  'transaction.notaria_detail_notary': 'Notaria',
  'transaction.notaria_other_buyer': 'el comprador',
  'transaction.notaria_doc_buyer_1': 'DNI / NIE en vigor (original)',
  'transaction.notaria_doc_seller_2': 'DNI / NIE en vigor (original)',
  'transaction.pv_not_applicable_btn': 'No aplica',
  'transaction.pv_not_applicable_badge': 'No aplica',
  'transaction.pv_gas_label': 'Gas',
  'transaction.pv_gas_sub': 'Última factura (si és aplicable)',
  'transaction.pv_ibi_label': 'IBI',
  'transaction.keys_buyer': 'Comprador',
  'transaction.tasacion_appointment_format': '{day}/{month}/{year}  ·  {time}',
  'transaction.pv_not_applicable_label': 'No aplica',
  'transaction.role_buyer': 'COMPRADOR',
  'transaction.step_offer': 'Oferta Enviada',
  'transaction.fein_cta_review': 'Revisar FEIN',
  'transaction.fein_cta_default': 'Gestionar FEIN',
  'transaction.notary_cta_confirm': 'Confirmar cita',
  'transaction.dialog_withdraw_title': 'Retirar oferta',
  'transaction.dialog_withdraw_confirm': 'Retirar oferta',
  'transaction.dialog_new_offer_confirm': 'Enviar oferta',
  'transaction.solvency_none': 'No verificada',
};
const transactionEu = {
  'transaction.buyer_header_label': 'EROSLEAK',
  'transaction.offer_sent': 'Eskaintza Bidalita',
  'transaction.offer_withdrawn_step': 'Eskaintza Erretiratua',
  'transaction.arras_complete_btn': 'Elkarrizketa osatu',
  'transaction.visit_confirmed_step': 'Bisitaldia Berretsia',
  'transaction.visit_date_confirmed': 'Hitzordua adostua: {date}',
  'transaction.withdraw_dialog_title': 'Eskaintza erretiratu',
  'transaction.withdraw_btn': 'Erretiratu',
  'transaction.solvency_level_silver': 'Zilar',
  'transaction.solvency_joint_purchase': 'Erosketa bateratua',
  'transaction.withdraw_offer_btn': 'Eskaintza Erretiratu',
  'transaction.footer_legal': 'Legala',
  'transaction.tasacion_time_label': 'Gutxi gorabeherako ordua',
  'transaction.tasacion_select': 'Hautatu',
  'transaction.tasacion_snack_rejected': 'Kontraeskaintza erosleari bidalita',
  'transaction.notaria_time_label': 'Ordua',
  'transaction.notaria_select_time': 'Ordua hautatu',
  'transaction.notaria_scheduled': 'Hitzordua programatuta',
  'transaction.notaria_buyer_label': 'Erosleak',
  'transaction.notaria_detail_notary': 'Notarioa',
  'transaction.notaria_other_buyer': 'erosleak',
  'transaction.notaria_doc_buyer_1': 'Indarreko DNI / NIE (jatorrizkoa)',
  'transaction.notaria_doc_seller_2': 'Indarreko DNI / NIE (jatorrizkoa)',
  'transaction.pv_not_applicable_btn': 'Ez aplikagarri',
  'transaction.pv_not_applicable_badge': 'Ez aplikagarri',
  'transaction.pv_gas_label': 'Gasa',
  'transaction.pv_gas_sub': 'Azken faktura (aplikagarri bada)',
  'transaction.pv_ibi_label': 'IBI',
  'transaction.keys_buyer': 'Erosleak',
  'transaction.tasacion_appointment_format': '{day}/{month}/{year}  ·  {time}',
  'transaction.pv_not_applicable_label': 'Ez aplikagarri',
  'transaction.role_buyer': 'EROSLEAK',
  'transaction.step_offer': 'Eskaintza Bidalita',
  'transaction.fein_cta_review': 'FEIN Berrikusi',
  'transaction.fein_cta_default': 'FEIN Kudeatu',
  'transaction.notary_cta_confirm': 'Hitzordua berretsi',
  'transaction.dialog_withdraw_title': 'Eskaintza erretiratu',
  'transaction.dialog_withdraw_confirm': 'Eskaintza erretiratu',
  'transaction.dialog_new_offer_confirm': 'Eskaintza bidali',
  'transaction.solvency_none': 'Ez egiaztatua',
};
const transactionGl = {
  'transaction.buyer_header_label': 'COMPRADOR',
  'transaction.offer_sent': 'Oferta Enviada',
  'transaction.offer_withdrawn_step': 'Oferta Retirada',
  'transaction.arras_complete_btn': 'Completar entrevista',
  'transaction.visit_confirmed_step': 'Visita Confirmada',
  'transaction.visit_date_confirmed': 'Cita acordada: {date}',
  'transaction.withdraw_dialog_title': 'Retirar oferta',
  'transaction.withdraw_btn': 'Retirar',
  'transaction.solvency_level_silver': 'Prata',
  'transaction.solvency_joint_purchase': 'Compra conxunta',
  'transaction.withdraw_offer_btn': 'Retirar Oferta',
  'transaction.footer_legal': 'Legal',
  'transaction.tasacion_time_label': 'Hora aproximada',
  'transaction.tasacion_select': 'Seleccionar',
  'transaction.tasacion_snack_rejected': 'Contraoferta enviada ao comprador',
  'transaction.notaria_time_label': 'Hora',
  'transaction.notaria_select_time': 'Seleccionar hora',
  'transaction.notaria_scheduled': 'Cita programada',
  'transaction.notaria_buyer_label': 'Comprador',
  'transaction.notaria_detail_notary': 'Notaría',
  'transaction.notaria_other_buyer': 'o comprador',
  'transaction.notaria_doc_buyer_1': 'DNI / NIE en vigor (orixinal)',
  'transaction.notaria_doc_seller_2': 'DNI / NIE en vigor (orixinal)',
  'transaction.pv_not_applicable_btn': 'Non aplica',
  'transaction.pv_not_applicable_badge': 'Non aplica',
  'transaction.pv_gas_label': 'Gas',
  'transaction.pv_gas_sub': 'Última factura (se aplica)',
  'transaction.pv_ibi_label': 'IBI',
  'transaction.keys_buyer': 'Comprador',
  'transaction.tasacion_appointment_format': '{day}/{month}/{year}  ·  {time}',
  'transaction.pv_not_applicable_label': 'Non aplica',
  'transaction.role_buyer': 'COMPRADOR',
  'transaction.step_offer': 'Oferta Enviada',
  'transaction.fein_cta_review': 'Revisar FEIN',
  'transaction.fein_cta_default': 'Xestionar FEIN',
  'transaction.notary_cta_confirm': 'Confirmar cita',
  'transaction.dialog_withdraw_title': 'Retirar oferta',
  'transaction.dialog_withdraw_confirm': 'Retirar oferta',
  'transaction.dialog_new_offer_confirm': 'Enviar oferta',
  'transaction.solvency_none': 'Non verificada',
};
const transactionFr = {
  'transaction.buyer_header_label': 'ACHETEUR',
  'transaction.offer_sent': 'Offre Envoyée',
  'transaction.offer_withdrawn_step': 'Offre Retirée',
  'transaction.arras_complete_btn': "Compléter l'entretien",
  'transaction.visit_confirmed_step': 'Visite Confirmée',
  'transaction.visit_date_confirmed': 'Rendez-vous convenu : {date}',
  'transaction.withdraw_dialog_title': "Retirer l'offre",
  'transaction.withdraw_btn': 'Retirer',
  'transaction.solvency_level_silver': 'Argent',
  'transaction.solvency_joint_purchase': 'Achat conjoint',
  'transaction.withdraw_offer_btn': "Retirer l'Offre",
  'transaction.footer_legal': 'Légal',
  'transaction.tasacion_time_label': 'Heure approximative',
  'transaction.tasacion_select': 'Sélectionner',
  'transaction.tasacion_snack_rejected': "Contre-proposition envoyée à l'acheteur",
  'transaction.notaria_time_label': 'Heure',
  'transaction.notaria_select_time': "Sélectionner l'heure",
  'transaction.notaria_scheduled': 'Rendez-vous planifié',
  'transaction.notaria_buyer_label': 'Acheteur',
  'transaction.notaria_detail_notary': 'Notaire',
  'transaction.notaria_other_buyer': "l'acheteur",
  'transaction.notaria_doc_buyer_1': 'DNI / NIE en cours de validité (original)',
  'transaction.notaria_doc_seller_2': 'DNI / NIE en cours de validité (original)',
  'transaction.pv_not_applicable_btn': 'Non applicable',
  'transaction.pv_not_applicable_badge': 'Non applicable',
  'transaction.pv_gas_label': 'Gaz',
  'transaction.pv_gas_sub': 'Dernière facture (si applicable)',
  'transaction.pv_ibi_label': 'IBI (Taxe foncière)',
  'transaction.keys_buyer': 'Acheteur',
  'transaction.tasacion_appointment_format': '{day}/{month}/{year}  ·  {time}',
  'transaction.pv_not_applicable_label': 'Non applicable',
  'transaction.role_buyer': 'ACHETEUR',
  'transaction.step_offer': 'Offre Envoyée',
  'transaction.fein_cta_review': 'Examiner FEIN',
  'transaction.fein_cta_default': 'Gérer FEIN',
  'transaction.notary_cta_confirm': 'Confirmer le rendez-vous',
  'transaction.dialog_withdraw_title': "Retirer l'offre",
  'transaction.dialog_withdraw_confirm': "Retirer l'offre",
  'transaction.dialog_new_offer_confirm': 'Envoyer une offre',
  'transaction.solvency_none': 'Non vérifié',
};

// ============================================================
// MISC: discovery, smart_explorer, nota_simple, amenities, lifestyle, not_found, smart_bid_risk, visits, arras_contract, app, errors, misc
// ============================================================
const miscCa = {
  // discovery
  'discovery.twin_zones.header': 'Zones Recomanades a la teva Cerca',
  'discovery.twin_zones.ai_label': 'Suggeriment IA',
  'discovery.twin_zones.tooltip_template': 'Aquesta zona ofereix un {pct}% més de {advantage} pel mateix preu',
  'discovery.twins.header_bottom': 'Immobles en Zones amb Perfil Similar',
  'discovery.twins.match_score': '{score}% compatibilitat',
  'discovery.twins.loading': 'Cercant barris bessons...',
  'discovery.twins.section_title': 'BARRIS BESSONS',
  'discovery.twins.section_subtitle': 'Zones amb perfil similar a la teva cerca actual',
  // smart_explorer
  'smart_explorer.header': 'Hem trobat la teva zona ideal fora de la teva cerca habitual',
  'smart_explorer.advantage_price': 'Preu',
  'smart_explorer.advantage_quality': 'Qualitat',
  'smart_explorer.advantage_future': 'Futur',
  // nota_simple
  'nota_simple.titular_label': 'Titular registral',
  'nota_simple.surface_registered': 'Superfície registral',
  'nota_simple.surface_announced': 'Superfície anunciada',
  'nota_simple.surface_alert': 'Discrepància de superfície detectada: {pct}%',
  // amenities
  'amenities.exterior': 'Exterior',
  'amenities.lift': 'Ascensor',
  'amenities.pool': 'Piscina',
  // lifestyle
  'lifestyle.ready_slider_end': 'Potencial de reforma',
  'lifestyle.profile_investor': 'Inversor/a',
  'lifestyle.profile_match_hint': 'Encaixa amb el teu perfil de {}',
  // not_found
  'not_found.secure_infrastructure': 'Infraestructura segura',
  'not_found.direct_architecture': 'Arquitectura directa',
  // smart_bid_risk
  'smart_bid_risk.scale_low': 'BAIXA',
  'smart_bid_risk.scale_high': 'ALTA',
  // visits
  'visits.active': 'ACTIVA',
  'visits.status_confirmed': 'Confirmada',
  // arras_contract
  'arras_contract.preview_buyer': 'COMPRADOR',
  'arras_contract.preview_section_arras': 'ARRES (10%)',
  // app
  'app.name': 'InmuFácil',
  // errors
  'errors.server_error': 'Error del servidor',
  // pre_offer_tax
  'pre_offer_tax.optional_badge': 'OPCIONAL',
  // share
  'share.bedrooms_short': 'hab.',
  // admin
  'admin.ai_analytics_title': 'IA Analytics Admin',
  // notifications
  'notifications.retry': 'Reintentar',
};

const miscEu = {
  'discovery.twin_zones.header': 'Zure Bilaketan Gomendatutako Eremuak',
  'discovery.twin_zones.ai_label': 'IE Iradokizuna',
  'discovery.twin_zones.tooltip_template': 'Eremu honek {pct}% gehiago eskaintzen du {advantage} prezio berdinaren truke',
  'discovery.twins.header_bottom': 'Profil Antzeko Eremuetako Higiezinak',
  'discovery.twins.match_score': '{score}% bateragarritasuna',
  'discovery.twins.loading': 'Auzokide bikoiztuak bilatzen...',
  'discovery.twins.section_title': 'AUZOKIDE BIKOIZTUAK',
  'discovery.twins.section_subtitle': 'Zure uneko bilaketaren profil antzeko eremuak',
  'smart_explorer.header': 'Zure eremu ideala aurkitu dugu zure ohiko bilaketaz kanpo',
  'smart_explorer.advantage_price': 'Prezioa',
  'smart_explorer.advantage_quality': 'Kalitatea',
  'smart_explorer.advantage_future': 'Etorkizuna',
  'nota_simple.titular_label': 'Titular erregistrala',
  'nota_simple.surface_registered': 'Azalera erregistrala',
  'nota_simple.surface_announced': 'Iragarritako azalera',
  'nota_simple.surface_alert': 'Azalera desadostasuna antzeman da: {pct}%',
  'amenities.exterior': 'Kanpora begira',
  'amenities.lift': 'Igogailua',
  'amenities.pool': 'Igerilekua',
  'lifestyle.ready_slider_end': 'Erreforma potentziala',
  'lifestyle.profile_investor': 'Inbertitzailea',
  'lifestyle.profile_match_hint': 'Zure {} profilarekin bat dator',
  'not_found.secure_infrastructure': 'Azpiegitura segurua',
  'not_found.direct_architecture': 'Arkitektura zuzena',
  'smart_bid_risk.scale_low': 'BAXUA',
  'smart_bid_risk.scale_high': 'ALTUA',
  'visits.active': 'AKTIBO',
  'visits.status_confirmed': 'Berretsia',
  'arras_contract.preview_buyer': 'EROSLEAK',
  'arras_contract.preview_section_arras': 'ARRAS (%10)',
  'app.name': 'InmuFácil',
  'errors.server_error': 'Zerbitzari errorea',
  'pre_offer_tax.optional_badge': 'AUKERAZKOA',
  'share.bedrooms_short': 'log.',
  'admin.ai_analytics_title': 'IE Analytics Admin',
  'notifications.retry': 'Berriro saiatu',
};

const miscGl = {
  'discovery.twin_zones.header': 'Zonas Recomendadas na túa Busca',
  'discovery.twin_zones.ai_label': 'Suxerencia IA',
  'discovery.twin_zones.tooltip_template': 'Esta zona ofrece un {pct}% máis de {advantage} polo mesmo prezo',
  'discovery.twins.header_bottom': 'Inmobles en Zonas con Perfil Similar',
  'discovery.twins.match_score': '{score}% compatibilidade',
  'discovery.twins.loading': 'Buscando barrios xemelgos...',
  'discovery.twins.section_title': 'BARRIOS XEMELGOS',
  'discovery.twins.section_subtitle': 'Zonas con perfil similar á túa busca actual',
  'smart_explorer.header': 'Atopamos a túa zona ideal fóra da túa busca habitual',
  'smart_explorer.advantage_price': 'Prezo',
  'smart_explorer.advantage_quality': 'Calidade',
  'smart_explorer.advantage_future': 'Futuro',
  'nota_simple.titular_label': 'Titular rexistral',
  'nota_simple.surface_registered': 'Superficie rexistral',
  'nota_simple.surface_announced': 'Superficie anunciada',
  'nota_simple.surface_alert': 'Discrepancia de superficie detectada: {pct}%',
  'amenities.exterior': 'Exterior',
  'amenities.lift': 'Ascensor',
  'amenities.pool': 'Piscina',
  'lifestyle.ready_slider_end': 'Potencial de reforma',
  'lifestyle.profile_investor': 'Inversor/a',
  'lifestyle.profile_match_hint': 'Encaixa co teu perfil de {}',
  'not_found.secure_infrastructure': 'Infraestrutura segura',
  'not_found.direct_architecture': 'Arquitectura directa',
  'smart_bid_risk.scale_low': 'BAIXA',
  'smart_bid_risk.scale_high': 'ALTA',
  'visits.active': 'ACTIVA',
  'visits.status_confirmed': 'Confirmada',
  'arras_contract.preview_buyer': 'COMPRADOR',
  'arras_contract.preview_section_arras': 'ARRAS (10%)',
  'app.name': 'InmuFácil',
  'errors.server_error': 'Erro do servidor',
  'pre_offer_tax.optional_badge': 'OPCIONAL',
  'share.bedrooms_short': 'hab.',
  'admin.ai_analytics_title': 'IA Analytics Admin',
  'notifications.retry': 'Reintentar',
};

const miscFr = {
  'discovery.twin_zones.header': 'Zones Recommandées dans votre Recherche',
  'discovery.twin_zones.ai_label': 'Suggestion IA',
  'discovery.twin_zones.tooltip_template': 'Cette zone offre {pct}% de plus de {advantage} pour le même prix',
  'discovery.twins.header_bottom': 'Biens dans des Zones au Profil Similaire',
  'discovery.twins.match_score': '{score}% de compatibilité',
  'discovery.twins.loading': 'Recherche de quartiers jumeaux...',
  'discovery.twins.section_title': 'QUARTIERS JUMEAUX',
  'discovery.twins.section_subtitle': 'Zones au profil similaire à votre recherche actuelle',
  'smart_explorer.header': "Nous avons trouvé votre zone idéale en dehors de votre recherche habituelle",
  'smart_explorer.advantage_price': 'Prix',
  'smart_explorer.advantage_quality': 'Qualité',
  'smart_explorer.advantage_future': 'Avenir',
  'nota_simple.titular_label': 'Titulaire cadastral',
  'nota_simple.surface_registered': 'Surface cadastrale',
  'nota_simple.surface_announced': 'Surface annoncée',
  'nota_simple.surface_alert': 'Écart de surface détecté : {pct}%',
  'amenities.exterior': 'Extérieur',
  'amenities.lift': 'Ascenseur',
  'amenities.pool': 'Piscine',
  'lifestyle.ready_slider_end': 'Potentiel de rénovation',
  'lifestyle.profile_investor': 'Investisseur/se',
  'lifestyle.profile_match_hint': 'Correspond à votre profil de {}',
  'not_found.secure_infrastructure': 'Infrastructure sécurisée',
  'not_found.direct_architecture': 'Architecture directe',
  'smart_bid_risk.scale_low': 'FAIBLE',
  'smart_bid_risk.scale_high': 'ÉLEVÉ',
  'visits.active': 'ACTIVE',
  'visits.status_confirmed': 'Confirmée',
  'arras_contract.preview_buyer': 'ACHETEUR',
  'arras_contract.preview_section_arras': 'ARRES (10%)',
  'app.name': 'InmuFácil',
  'errors.server_error': 'Erreur serveur',
  'pre_offer_tax.optional_badge': 'OPTIONNEL',
  'share.bedrooms_short': 'ch.',
  'admin.ai_analytics_title': 'IA Analytics Admin',
  'notifications.retry': 'Réessayer',
};

// ============================================================
// Apply all
// ============================================================
function applyDict(locale, dict) {
  const data = readJson(locale);
  for (const [key, val] of Object.entries(dict)) {
    setVal(data, key, val);
  }
  writeJson(locale, data);
  console.log('Updated', locale, '(' + Object.keys(dict).length + ' keys)');
}

// ca-ES
const allCa = { ...urgencyCa, ...reportCa, ...visitCancelCa, ...commonCa, ...chatCa, ...homeCa, ...offersCa, ...transactionCa, ...miscCa };
applyDict('ca-ES', allCa);

// va-ES: copy Catalan
applyDict('va-ES', allCa);

// eu-ES
const allEu = { ...urgencyEu, ...reportEu, ...visitCancelEu, ...commonEu, ...chatEu, ...homeEu, ...offersEu, ...transactionEu, ...miscEu };
applyDict('eu-ES', allEu);

// gl-ES
const allGl = { ...urgencyGl, ...reportGl, ...visitCancelGl, ...commonGl, ...chatGl, ...homeGl, ...offersGl, ...transactionGl, ...miscGl };
applyDict('gl-ES', allGl);

// fr-FR
const allFr = { ...urgencyFr, ...reportFr, ...visitCancelFr, ...commonFr, ...chatFr, ...homeFr, ...offersFr, ...transactionFr, ...miscFr };
applyDict('fr-FR', allFr);

// fr-CA: copy French
applyDict('fr-CA', allFr);

// en-GB, en-CA: sync from en-US
const enUs = readJson('en-US');
const enFlat = flatten(enUs);
const enGbData = readJson('en-GB');
const enCaData = readJson('en-CA');
for (const key of Object.keys(allFr)) {
  if (enFlat[key] !== undefined) {
    setVal(enGbData, key, enFlat[key]);
    setVal(enCaData, key, enFlat[key]);
  }
}
writeJson('en-GB', enGbData);
writeJson('en-CA', enCaData);
console.log('Updated en-GB and en-CA (synced from en-US)');

console.log('Done: _phase_c_regional_c');

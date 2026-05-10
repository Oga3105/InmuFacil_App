'use strict';
// Phase C Regional D: arras_interview remaining + profile + info (non-legal) + fallback en-US for gl-ES/eu-ES
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
  return Object.entries(obj).reduce(function(acc, e) {
    const key = prefix ? prefix + '.' + e[0] : e[0];
    if (typeof e[1] === 'object' && e[1] !== null && !Array.isArray(e[1])) Object.assign(acc, flatten(e[1], key));
    else acc[key] = e[1];
    return acc;
  }, {});
}

// ============================================================
// ARRAS_INTERVIEW remaining for ca-ES
// ============================================================
const arrasInterviewCa = {
  'arras_interview.deposit_pct_label': 'Percentatge de arres (sobre {amount} EUR)',
  'arras_interview.deadline_title': 'Termini màxim per signar a la notaria',
  'arras_interview.days_label': '{n} dies',
  'arras_interview.months_approx': '~{n} mesos',
  'arras_interview.days_min': '15 dies',
  'arras_interview.days_max': '180 dies',
  'arras_interview.notary_pref_title': 'Notaria preferida (opcional)',
  'arras_interview.notary_pref_hint': 'Ex: Notaria de Barcelona — López i Associats',
  'arras_interview.max_date_title': 'Data màxima de signatura (opcional)',
  'arras_interview.select_date': 'Seleccionar data',
  'arras_interview.property_ids_title': 'Dades identificatives de l\'immoble',
  'arras_interview.property_ids_subtitle': 'Necessàries per a la validesa legal del contracte',
  'arras_interview.buyer_address_label': 'El teu domicili (comprador)',
  'arras_interview.address_hint': 'Carrer, número, pis, localitat, CP',
  'arras_interview.property_address_label': 'Adreça completa de l\'habitatge',
  'arras_interview.cadastral_label': 'Referència cadastral',
  'arras_interview.cadastral_hint': 'Ex: 9872023 VH5797S 0001 WX',
  'arras_interview.registry_label': 'Dades registrals',
  'arras_interview.registry_hint': 'Registre, tom, foli, finca, inscripció',
  'arras_interview.mortgage_clause_title': 'Subjecte a la concessió d\'hipoteca',
  'arras_interview.mortgage_clause_sub': 'El contracte queda condicionat a l\'aprovació del préstec',
  'arras_interview.extension_sub': 'Es pot ampliar el termini per causes justificades',
  'arras_interview.extension_reasons_header': 'Causes admeses:',
  'arras_interview.ext_reason_work': 'Motius laborals',
  'arras_interview.ext_reason_mortgage': 'Retard en hipoteca',
  'arras_interview.ext_reason_family': 'Motius familiars',
  'arras_interview.ext_reason_legal': 'Procediment legal',
  'arras_interview.ext_reason_other': 'Altres causes',
  'arras_interview.ibi_retention_sub': 'Es reté l\'import de l\'IBI pendent d\'emissió',
  'arras_interview.payment_method_sub': 'Selecciona com tens previst pagar',
  'arras_interview.payment_required': 'Selecciona el teu mètode de finançament',
  'arras_interview.extra_clauses_title': 'Clàusules addicionals (opcional)',
  'arras_interview.extra_clauses_sub': 'Qualsevol condició especial que vulguis incloure en el contracte',
  'arras_interview.extra_clauses_hint': 'Ex: L\'habitatge s\'ha d\'entregar buit...',
  'arras_interview.interview_sent_buyer': 'Entrevista enviada. Esperant al venedor.',
  'arras_interview.seller_step1_title': 'Estat de l\'Habitatge',
  'arras_interview.seller_step1_subtitle': 'Pas 1 de 3 — Ocupació i subministraments',
  'arras_interview.seller_step2_title': 'Comunitat i Càrregues',
  'arras_interview.seller_step2_subtitle': 'Pas 2 de 3 — Deutes i gravàmens',
  'arras_interview.seller_step3_title': 'Finances i Impostos',
  'arras_interview.seller_step3_subtitle': 'Pas 3 de 3 — Plusvàlua i cobrament',
  'arras_interview.free_of_tenants_title': 'Habitatge lliure de llogaters',
  'arras_interview.free_of_tenants_sub': 'L\'immoble estarà desocupat en el moment del lliurament',
  'arras_interview.utilities_active_title': 'Subministraments actius',
  'arras_interview.utilities_active_sub': 'Llum, aigua i gas donats d\'alta en el moment del lliurament',
  'arras_interview.utilities_maintenance_title': 'Compromís de manteniment de subministraments',
  'arras_interview.utilities_maintenance_sub': 'El venedor mantindrà els subministraments actius fins al lliurament',
  'arras_interview.approved_levies_title': 'Derrames aprovades en comunitat',
  'arras_interview.approved_levies_sub': 'Hi ha derrames aprovades pendents de pagament',
  'arras_interview.levy_details_label': 'Detall de derrames',
  'arras_interview.levy_details_hint': 'Descriu les derrames pendents...',
  'arras_interview.zero_debt_cert_title': 'Certificat de deute zero amb la comunitat',
  'arras_interview.zero_debt_cert_sub': 'S\'entregarà certificat de no tenir deutes amb la comunitat',
  'arras_interview.mortgage_cancel_title': 'Té hipoteca pendent de cancel·lar',
  'arras_interview.mortgage_cancel_sub': 'Es cancel·larà amb el producte de la venda',
  'arras_interview.mortgage_amount_label': 'Import pendent d\'hipoteca',
  'arras_interview.mortgage_amount_hint': 'Import en euros',
  'arras_interview.plusvalia_title': 'Assumeix la plusvàlua municipal',
  'arras_interview.plusvalia_sub': 'El venedor assumeix el pagament de l\'impost de plusvàlua',
  'arras_interview.ibi_retention_seller_title': 'Accepta la retenció de l\'IBI',
  'arras_interview.ibi_retention_seller_sub': 'Es reté part del preu per cobrir l\'IBI pendent',
  'arras_interview.iban_hint': 'ES00 0000 0000 0000 0000 0000',
  'arras_interview.bank_name_label': 'Entitat bancària',
  'arras_interview.bank_name_hint': 'Nom del banc',
  'arras_interview.seller_address_label': 'El teu domicili (venedor)',
  'arras_interview.buyer': 'Comprador',
  'arras_interview.shared_continue': 'Continua',
  'arras_interview.hub_buyer_title': 'Comprador',
  'arras_interview.hub_hero_buyer': 'Comprador',
  'arras_interview.equity_status_favorable': 'Favorable',
  'arras_interview.equity_status_neutral': 'Neutral',
  'arras_interview.equity_status_alert': 'Alerta',
  'arras_interview.equity_out_of_100': 'de 100',
  'arras_interview.equity_status_neutral_label': 'Neutral',
  'arras_interview.equity_status_alert_label': 'Alerta',
  'arras_interview.equity_label_favorable': 'Favorable',
  'arras_interview.equity_label_unfavorable': 'Desfavorable',
  'arras_interview.payment_mortgage': 'Hipoteca',
};

const arrasInterviewFr = {
  'arras_interview.deposit_pct_label': 'Pourcentage des arrhes (sur {amount} EUR)',
  'arras_interview.deadline_title': 'Délai maximum pour signer chez le notaire',
  'arras_interview.days_label': '{n} jours',
  'arras_interview.months_approx': '~{n} mois',
  'arras_interview.days_min': '15 jours',
  'arras_interview.days_max': '180 jours',
  'arras_interview.notary_pref_title': 'Notaire préféré (optionnel)',
  'arras_interview.notary_pref_hint': 'Ex : Étude notariale Paris — Martin & Associés',
  'arras_interview.max_date_title': 'Date limite de signature (optionnel)',
  'arras_interview.select_date': 'Sélectionner une date',
  'arras_interview.property_ids_title': 'Données d\'identification du bien',
  'arras_interview.property_ids_subtitle': 'Nécessaires pour la validité légale du contrat',
  'arras_interview.buyer_address_label': 'Votre adresse (acheteur)',
  'arras_interview.address_hint': 'Rue, numéro, étage, ville, code postal',
  'arras_interview.property_address_label': 'Adresse complète du bien',
  'arras_interview.cadastral_label': 'Référence cadastrale',
  'arras_interview.cadastral_hint': 'Ex : 9872023 VH5797S 0001 WX',
  'arras_interview.registry_label': 'Données du registre foncier',
  'arras_interview.registry_hint': 'Registre, tome, folio, bien, inscription',
  'arras_interview.mortgage_clause_title': 'Sous condition d\'obtention du prêt immobilier',
  'arras_interview.mortgage_clause_sub': 'Le contrat est conditionnel à l\'approbation du prêt',
  'arras_interview.extension_sub': 'Le délai peut être prolongé pour des raisons justifiées',
  'arras_interview.extension_reasons_header': 'Raisons acceptées :',
  'arras_interview.ext_reason_work': 'Raisons professionnelles',
  'arras_interview.ext_reason_mortgage': 'Retard du prêt immobilier',
  'arras_interview.ext_reason_family': 'Raisons familiales',
  'arras_interview.ext_reason_legal': 'Procédure judiciaire',
  'arras_interview.ext_reason_other': 'Autres raisons',
  'arras_interview.ibi_retention_sub': 'Le montant de l\'IBI en attente est retenu',
  'arras_interview.payment_method_sub': 'Sélectionnez comment vous prévoyez de payer',
  'arras_interview.payment_required': 'Sélectionnez votre mode de financement',
  'arras_interview.extra_clauses_title': 'Clauses additionnelles (optionnel)',
  'arras_interview.extra_clauses_sub': 'Toute condition spéciale à inclure dans le contrat',
  'arras_interview.extra_clauses_hint': 'Ex : Le bien doit être livré vide...',
  'arras_interview.interview_sent_buyer': 'Entretien soumis. En attente du vendeur.',
  'arras_interview.seller_step1_title': 'État du Bien',
  'arras_interview.seller_step1_subtitle': 'Étape 1 sur 3 — Occupation et services',
  'arras_interview.seller_step2_title': 'Copropriété et Charges',
  'arras_interview.seller_step2_subtitle': 'Étape 2 sur 3 — Dettes et charges',
  'arras_interview.seller_step3_title': 'Finances et Impôts',
  'arras_interview.seller_step3_subtitle': 'Étape 3 sur 3 — Plus-value et paiement',
  'arras_interview.free_of_tenants_title': 'Bien libre de locataires',
  'arras_interview.free_of_tenants_sub': 'Le bien sera inoccupé lors de la remise des clés',
  'arras_interview.utilities_active_title': 'Services actifs',
  'arras_interview.utilities_active_sub': 'Électricité, eau et gaz connectés lors de la remise',
  'arras_interview.utilities_maintenance_title': 'Engagement de maintien des services',
  'arras_interview.utilities_maintenance_sub': 'Le vendeur maintiendra les services actifs jusqu\'à la remise',
  'arras_interview.approved_levies_title': 'Charges de copropriété approuvées',
  'arras_interview.approved_levies_sub': 'Des charges approuvées sont en attente de paiement',
  'arras_interview.levy_details_label': 'Détail des charges',
  'arras_interview.levy_details_hint': 'Décrivez les charges en attente...',
  'arras_interview.zero_debt_cert_title': 'Certificat de solde nul avec la copropriété',
  'arras_interview.zero_debt_cert_sub': 'Un certificat de non-endettement envers la copropriété sera fourni',
  'arras_interview.mortgage_cancel_title': 'Hypothèque à rembourser',
  'arras_interview.mortgage_cancel_sub': 'Sera remboursée avec le produit de la vente',
  'arras_interview.mortgage_amount_label': 'Montant de l\'hypothèque en cours',
  'arras_interview.mortgage_amount_hint': 'Montant en euros',
  'arras_interview.plusvalia_title': 'Assume la taxe sur la plus-value municipale',
  'arras_interview.plusvalia_sub': 'Le vendeur assume le paiement de la taxe sur la plus-value',
  'arras_interview.ibi_retention_seller_title': 'Accepte la retenue de l\'IBI',
  'arras_interview.ibi_retention_seller_sub': 'Une partie du prix est retenue pour couvrir l\'IBI en attente',
  'arras_interview.iban_hint': 'ES00 0000 0000 0000 0000 0000',
  'arras_interview.bank_name_label': 'Établissement bancaire',
  'arras_interview.bank_name_hint': 'Nom de la banque',
  'arras_interview.seller_address_label': 'Votre adresse (vendeur)',
  'arras_interview.buyer': 'Acheteur',
  'arras_interview.shared_continue': 'Continuer',
  'arras_interview.hub_buyer_title': 'Acheteur',
  'arras_interview.hub_hero_buyer': 'Acheteur',
  'arras_interview.equity_status_favorable': 'Favorable',
  'arras_interview.equity_status_neutral': 'Neutre',
  'arras_interview.equity_status_alert': 'Alerte',
  'arras_interview.equity_out_of_100': 'sur 100',
  'arras_interview.equity_status_neutral_label': 'Neutre',
  'arras_interview.equity_status_alert_label': 'Alerte',
  'arras_interview.equity_label_favorable': 'Favorable',
  'arras_interview.equity_label_unfavorable': 'Défavorable',
  'arras_interview.payment_mortgage': 'Crédit immobilier',
};

// ============================================================
// PROFILE remaining for ca-ES
// ============================================================
const profileCa = {
  'profile.full_name_label': 'Nom Complet',
  'profile.phone_label': 'Telèfon',
  'profile.email_label_readonly': 'Correu Electrònic (No editable)',
  'profile.save_data': 'Desar Dades',
  'profile.edit_profile': 'Editar Perfil',
  'profile.data_saved': 'Dades desades correctament',
  'profile.password_min_hint': 'Mínim 8 caràcters',
  'profile.password_repeat_hint': 'Repeteix la teva contrasenya',
  'profile.reactivate': 'Reactivar',
  'profile.suspend_coming_soon': 'Funció de suspensió pròximament disponible',
  'profile.delete_photo_title': 'Eliminar foto',
  'profile.photo_updated': 'Foto de perfil actualitzada',
  'profile.photo_error_upload': 'Error en pujar la foto',
  'profile.photo_deleted': 'Foto de perfil eliminada',
  'profile.photo_error_delete': 'Error en eliminar la foto',
  'profile.solvency_passport_title': 'Passaport de Solvència',
  'profile.solvency_complete_hint': 'Completa l\'assistent per mostrar el teu nivell de qualificació',
  'profile.solvency_passport_label': 'PASSAPORT DE SOLVÈNCIA',
  'profile.solvency_level': 'Nivell {level}',
  'profile.sort_newest': 'Més recents',
  'profile.sort_oldest': 'Més antigues',
  'profile.sort_price_asc': 'Preu: menor a major',
  'profile.sort_price_desc': 'Preu: major a menor',
  'profile.filter_all': 'Totes',
  'profile.filter_published': 'Publicades',
  'profile.filter_draft': 'Esborranys',
  'profile.filter_unpublished': 'No publicades',
  'profile.delete_property_title': 'Eliminar propietat',
  'profile.delete_property_confirm': 'Aquesta acció no es pot desfer. La propietat serà eliminada permanentment.',
  'profile.no_properties_title': 'No tens propietats actives',
  'profile.no_properties_quote': '"Comença avui mateix el teu procés de venda directa sense intermediaris."',
  'profile.publish_property': 'Publicar propietat',
  'profile.another_property': 'Tens una altra propietat?',
  'profile.publish_another': 'Publicar un altre anunci ara',
  'profile.verified_badge': 'VERIFICAT',
  'profile.user_type_agent': 'Agent Immobiliari',
  'profile.user_type_owner': 'Propietari Particular',
  'profile.my_offers_title': 'Les Meves Ofertes',
  'profile.my_offers_subtitle': 'Ofertes enviades i rebudes.',
  'profile.sort_amount_asc': 'Import: menor a major',
  'profile.sort_amount_desc': 'Import: major a menor',
  'profile.no_offers': 'Encara no hi ha ofertes.',
  'profile.offer_sent': 'Enviada',
  'profile.offer_received': 'Rebuda',
  'profile.offer_timeline': 'Seguiment',
  'profile.offer_status_pending': 'Pendent',
  'profile.offer_status_accepted': 'Acceptada',
  'profile.offer_status_counter': 'Contraoferta',
  'profile.offer_status_signing': 'En signatura',
  'profile.offer_status_signed': 'Signada',
  'profile.offer_status_completed': 'Completada',
  'profile.offer_status_rejected': 'Rebutjada',
  'profile.offer_status_withdrawn': 'Retirada',
  'profile.my_visits_title': 'Les Meves Visites',
  'profile.my_visits_subtitle': 'Visites programades com a comprador o venedor.',
  'profile.sort_soonest': 'Més pròximes',
  'profile.sort_latest': 'Més llunyanes',
  'profile.sort_by_status': 'Per estat',
  'profile.visits_error': 'Error en carregar visites',
  'profile.no_visits_title': 'Sense visites programades',
  'profile.no_visits_body': 'Les visites que reservis o acceptis apareixeran aquí.',
  'profile.role_buyer': 'Comprador',
  'profile.role_seller': 'Venedor',
  'profile.visit_reschedule': 'Reprogramar',
  'profile.visit_cancel': 'Anul·lar',
  'profile.visit_reschedule_hint': 'Per reprogramar una visita d\'agenda, anul·la aquesta visita i demana una nova data',
  'profile.visit_cancel_from_chat': 'Si us plau, anul·la la visita des d\'aquesta pantalla de xat.',
  'profile.visit_cancelled_ok': 'Visita anul·lada correctament.',
  'profile.visit_cancel_error': 'Error en anul·lar la visita.',
  'profile.visit_status_pending': 'Pendent',
  'profile.visit_status_confirmed': 'Confirmada',
  'profile.visit_status_rejected': 'Rebutjada',
  'profile.visit_status_cancelled': 'Cancel·lada',
  'profile.visit_status_completed': 'Completada',
  'profile.visit_status_no_show': 'No presentat',
  'profile.messages_title': 'Missatges',
  'profile.messages_subtitle': 'Les teves converses actives amb compradors i venedors.',
  'profile.sort_unread': 'No llegits primer',
  'profile.no_messages_title': 'Sense converses actives',
  'profile.no_messages_body': 'Quan hi hagi missatges en una oferta, apareixeran aquí.',
  'profile.retry': 'Reintentar',
  'profile.verification_pending_msg': 'La teva verificació està en curs. Et notificarem quan estigui llesta.',
  'profile.verification_rejected_msg': 'La teva verificació va ser rebutjada. Pots tornar-ho a intentar.',
  'profile.verification_unverified_msg': 'Verifica la teva identitat per a major seguretat i destacar els teus anuncis.',
  'profile.verification_pending_btn': 'Veure Estat',
  'profile.verification_rejected_btn': 'Reintentar',
  'profile.verification_unverified_btn': 'Verificar Ara',
  'profile.home_button': 'Inici',
  'profile.action_activate': 'Activar',
  'profile.action_deactivate': 'Desactivar',
  'profile.personal_info.email_readonly': 'Email (No editable)',
  'profile.personal_info.edit_btn': 'Editar perfil',
  'profile.solvency.silver': 'Plata',
  'profile.property_status.active': 'ACTIU',
  'profile.property_status.draft': 'ESBORRANY',
  'profile.property_status.in_review': 'EN REVISIÓ',
  'profile.verification.retry_btn': 'Reintentar',
  'profile.offers_tab.sent': 'Enviada',
  'profile.offers_tab.received': 'Rebuda',
  'profile.offers_tab.property_placeholder': 'Propietat',
  'profile.offers_tab.status.pending': 'Pendent',
  'profile.offers_tab.status.accepted': 'Acceptada',
  'profile.offers_tab.status.counter_offer': 'Contraoferta',
  'profile.offers_tab.status.signing_pending': 'En signatura',
  'profile.offers_tab.status.signed': 'Signada',
  'profile.offers_tab.status.completed': 'Completada',
  'profile.offers_tab.status.rejected': 'Rebutjada',
  'profile.offers_tab.status.withdrawn': 'Retirada',
  'profile.visits_tab.buyer': 'Comprador',
  'profile.visits_tab.status_approved': 'Confirmada',
  'profile.visits_tab.status_completed': 'Completada',
  'profile.visits_tab.reject_error': 'Error en rebutjar la visita',
  'profile.visits_tab.months_abbr': 'GEN,FEB,MAR,ABR,MAI,JUN,JUL,AGO,SET,OCT,NOV,DES',
  'profile.manage_btn': 'Gestionar',
  'profile.delete_photo_success': 'Foto eliminada',
};

const profileFr = {
  'profile.full_name_label': 'Nom Complet',
  'profile.phone_label': 'Téléphone',
  'profile.email_label_readonly': 'E-mail (Non modifiable)',
  'profile.save_data': 'Enregistrer les données',
  'profile.edit_profile': 'Modifier le profil',
  'profile.data_saved': 'Données enregistrées avec succès',
  'profile.password_min_hint': 'Minimum 8 caractères',
  'profile.password_repeat_hint': 'Répétez votre mot de passe',
  'profile.reactivate': 'Réactiver',
  'profile.suspend_coming_soon': 'Fonctionnalité de suspension bientôt disponible',
  'profile.delete_photo_title': 'Supprimer la photo',
  'profile.photo_updated': 'Photo de profil mise à jour',
  'profile.photo_error_upload': 'Erreur lors du téléchargement de la photo',
  'profile.photo_deleted': 'Photo de profil supprimée',
  'profile.photo_error_delete': 'Erreur lors de la suppression de la photo',
  'profile.solvency_passport_title': 'Passeport de Solvabilité',
  'profile.solvency_complete_hint': 'Complétez l\'assistant pour afficher votre niveau de qualification',
  'profile.solvency_passport_label': 'PASSEPORT DE SOLVABILITÉ',
  'profile.solvency_level': 'Niveau {level}',
  'profile.sort_newest': 'Les plus récents',
  'profile.sort_oldest': 'Les plus anciens',
  'profile.sort_price_asc': 'Prix : croissant',
  'profile.sort_price_desc': 'Prix : décroissant',
  'profile.filter_all': 'Tous',
  'profile.filter_published': 'Publiés',
  'profile.filter_draft': 'Brouillons',
  'profile.filter_unpublished': 'Non publiés',
  'profile.delete_property_title': 'Supprimer le bien',
  'profile.delete_property_confirm': 'Cette action est irréversible. Le bien sera définitivement supprimé.',
  'profile.no_properties_title': 'Vous n\'avez pas de biens actifs',
  'profile.no_properties_quote': '"Commencez votre processus de vente directe sans intermédiaires dès aujourd\'hui."',
  'profile.publish_property': 'Publier un bien',
  'profile.another_property': 'Avez-vous un autre bien ?',
  'profile.publish_another': 'Publier une autre annonce maintenant',
  'profile.verified_badge': 'VÉRIFIÉ',
  'profile.user_type_agent': 'Agent Immobilier',
  'profile.user_type_owner': 'Propriétaire Particulier',
  'profile.my_offers_title': 'Mes Offres',
  'profile.my_offers_subtitle': 'Offres envoyées et reçues.',
  'profile.sort_amount_asc': 'Montant : croissant',
  'profile.sort_amount_desc': 'Montant : décroissant',
  'profile.no_offers': 'Pas encore d\'offres.',
  'profile.offer_sent': 'Envoyée',
  'profile.offer_received': 'Reçue',
  'profile.offer_timeline': 'Suivi',
  'profile.offer_status_pending': 'En attente',
  'profile.offer_status_accepted': 'Acceptée',
  'profile.offer_status_counter': 'Contre-offre',
  'profile.offer_status_signing': 'En signature',
  'profile.offer_status_signed': 'Signée',
  'profile.offer_status_completed': 'Complétée',
  'profile.offer_status_rejected': 'Rejetée',
  'profile.offer_status_withdrawn': 'Retirée',
  'profile.my_visits_title': 'Mes Visites',
  'profile.my_visits_subtitle': 'Visites planifiées en tant qu\'acheteur ou vendeur.',
  'profile.sort_soonest': 'Les plus proches',
  'profile.sort_latest': 'Les plus éloignées',
  'profile.sort_by_status': 'Par statut',
  'profile.visits_error': 'Erreur lors du chargement des visites',
  'profile.no_visits_title': 'Aucune visite planifiée',
  'profile.no_visits_body': 'Les visites que vous réservez ou acceptez apparaîtront ici.',
  'profile.role_buyer': 'Acheteur',
  'profile.role_seller': 'Vendeur',
  'profile.visit_reschedule': 'Reprogrammer',
  'profile.visit_cancel': 'Annuler',
  'profile.visit_reschedule_hint': 'Pour reprogrammer une visite calendrier, annulez cette visite et demandez une nouvelle date',
  'profile.visit_cancel_from_chat': 'Veuillez annuler la visite depuis cet écran de chat.',
  'profile.visit_cancelled_ok': 'Visite annulée avec succès.',
  'profile.visit_cancel_error': 'Erreur lors de l\'annulation de la visite.',
  'profile.visit_status_pending': 'En attente',
  'profile.visit_status_confirmed': 'Confirmée',
  'profile.visit_status_rejected': 'Rejetée',
  'profile.visit_status_cancelled': 'Annulée',
  'profile.visit_status_completed': 'Complétée',
  'profile.visit_status_no_show': 'Absence',
  'profile.messages_title': 'Messages',
  'profile.messages_subtitle': 'Vos conversations actives avec acheteurs et vendeurs.',
  'profile.sort_unread': 'Non lus en premier',
  'profile.no_messages_title': 'Aucune conversation active',
  'profile.no_messages_body': 'Lorsqu\'il y aura des messages sur une offre, ils apparaîtront ici.',
  'profile.retry': 'Réessayer',
  'profile.verification_pending_msg': 'Votre vérification est en cours. Nous vous notifierons lorsqu\'elle sera prête.',
  'profile.verification_rejected_msg': 'Votre vérification a été rejetée. Vous pouvez réessayer.',
  'profile.verification_unverified_msg': 'Vérifiez votre identité pour plus de sécurité et mettre en avant vos annonces.',
  'profile.verification_pending_btn': 'Voir le statut',
  'profile.verification_rejected_btn': 'Réessayer',
  'profile.verification_unverified_btn': 'Vérifier maintenant',
  'profile.home_button': 'Accueil',
  'profile.action_activate': 'Activer',
  'profile.action_deactivate': 'Désactiver',
  'profile.personal_info.email_readonly': 'E-mail (Non modifiable)',
  'profile.personal_info.edit_btn': 'Modifier le profil',
  'profile.solvency.silver': 'Argent',
  'profile.property_status.active': 'ACTIF',
  'profile.property_status.draft': 'BROUILLON',
  'profile.property_status.in_review': 'EN RÉVISION',
  'profile.verification.retry_btn': 'Réessayer',
  'profile.offers_tab.sent': 'Envoyée',
  'profile.offers_tab.received': 'Reçue',
  'profile.offers_tab.property_placeholder': 'Bien',
  'profile.offers_tab.status.pending': 'En attente',
  'profile.offers_tab.status.accepted': 'Acceptée',
  'profile.offers_tab.status.counter_offer': 'Contre-offre',
  'profile.offers_tab.status.signing_pending': 'En signature',
  'profile.offers_tab.status.signed': 'Signée',
  'profile.offers_tab.status.completed': 'Complétée',
  'profile.offers_tab.status.rejected': 'Rejetée',
  'profile.offers_tab.status.withdrawn': 'Retirée',
  'profile.visits_tab.buyer': 'Acheteur',
  'profile.visits_tab.status_approved': 'Confirmée',
  'profile.visits_tab.status_completed': 'Complétée',
  'profile.visits_tab.reject_error': 'Erreur lors du rejet de la visite',
  'profile.visits_tab.months_abbr': 'JAN,FÉV,MAR,AVR,MAI,JUN,JUL,AOÛ,SEP,OCT,NOV,DÉC',
  'profile.manage_btn': 'Gérer',
  'profile.delete_photo_success': 'Photo supprimée',
};

// ============================================================
// INFO non-legal remaining for ca-ES
// ============================================================
const infoCa = {
  'info.what_is.title': 'Per què InmuFácil?',
  'info.what_is.hero_title': 'InmuFácil',
  'info.what_is.hero_subtitle': 'La plataforma P2P de compravenda immobiliària sense comissions d\'agència.',
  'info.what_is.savings_title': '0 EUR en comissions d\'agència',
  'info.what_is.savings_body': 'El que pagues amb una agència tradicional:',
  'info.what_is.features.0.title': 'Sense intermediaris',
  'info.what_is.features.0.body': 'Connectem directament compradors i venedors particulars, eliminant les comissions d\'agència.',
  'info.what_is.features.1.title': 'Procés guiat',
  'info.what_is.features.1.body': 'Des de la visita fins a la signatura notarial, t\'acompanyem en cada pas amb eines legals i financeres.',
  'info.what_is.features.2.title': 'Seguretat jurídica',
  'info.what_is.features.2.body': 'Verificació d\'identitat KYC, Contracte d\'Arres digital generat per IA i signatura electrònica de documents.',
  'info.what_is.features.3.title': 'Solvència conscient',
  'info.what_is.features.3.body': 'Qüestionari financer perquè els compradors coneguin la seva situació real abans de fer una oferta.',
  'info.what_is.features.4.title': 'Transparència total',
  'info.what_is.features.4.body': 'Historial d\'ofertes i negociació completament visible per a ambdues parts.',
  'info.what_is.savings_table.buyer': 'Comprador',
  'info.what_is.savings_table.percentage_seller': '5%\n(rang 3%–7%)',
  'info.what_is.savings_table.percentage_buyer': '3%\n(rang 0%–5%)',
  'info.what_is.savings_table.fixed_min_seller': '7.260€ – 9.000€',
  'info.what_is.savings_table.fixed_min_buyer': '3.000€ – 4.500€',
  'info.what_is.savings_table.online_fee_seller': '4.000€ – 8.000€',
  'info.what_is.savings_table.online_fee_buyer': 'Variable',
  'info.what_is.savings_table.financial_seller': 'N/A',
  'info.what_is.savings_table.financial_buyer': '3.000€ – 6.000€',
  'info.how_it_works.title': 'El procés complet',
  'info.how_it_works.steps.0.title': 'Publica o cerca la teva propietat',
  'info.how_it_works.steps.0.body': 'El venedor crea l\'anunci amb fotos, descripció i preu. El Certificat Energètic és obligatori per llei.',
  'info.how_it_works.steps.1.title': 'Sol·licita i gestiona visites',
  'info.how_it_works.steps.1.body': 'El comprador sol·licita visita. El venedor configura les seves franges horàries i confirma cites.',
  'info.how_it_works.steps.2.title': 'Oferta amb Passaport de Solvència',
  'info.how_it_works.steps.2.body': 'El comprador adjunta el seu Passaport de Solvència (nivell Bronze, Plata o Or) a l\'oferta.',
  'info.how_it_works.steps.3.title': 'Verificació de Solvència',
  'info.how_it_works.steps.3.body': 'El venedor revisa el Passaport de Solvència del comprador i decideix si accepta, rebutja o contraferta.',
  'info.how_it_works.steps.4.title': 'Contracte d\'Arres',
  'info.how_it_works.steps.4.body': 'Ambdues parts completen una entrevista guiada. La IA genera l\'esborrany del contracte.',
  'info.how_it_works.steps.5.title': 'Taxació de l\'Habitatge',
  'info.how_it_works.steps.5.body': 'Es coordina la cita amb el taxador oficial. L\'informe de taxació és el pas previ a la notaria.',
  'info.contact.title': 'Estem per ajudar-te',
  'info.contact.email_subtitle': 'suport@inmufacil.com',
  'info.contact.email_action': 'Enviar email',
  'info.buyer_guide.title': 'Guia del Comprador',
  'info.buyer_guide.sections.0.title': 'Cerca la teva propietat ideal',
  'info.buyer_guide.sections.1.title': 'Completa el teu Passaport de Solvència',
  'info.buyer_guide.sections.2.title': 'Fes la teva oferta',
  'info.buyer_guide.sections.3.title': 'Costos que has de preveure',
  'info.seller_guide.title': 'Guia del Venedor',
  'info.seller_guide.subtitle': 'Ven la teva propietat sense pagar comissions d\'agència.',
  'info.seller_guide.sections.0.title': 'Publica la teva propietat',
  'info.seller_guide.sections.1.title': 'Gestiona la solvència',
  'info.seller_guide.sections.2.title': 'Documentació necessària',
  'info.seller_guide.sections.3.title': 'Costos del venedor',
  'info.faq.title': 'Preguntes freqüents',
};

const infoFr = {
  'info.what_is.title': 'Pourquoi InmuFácil ?',
  'info.what_is.hero_title': 'InmuFácil',
  'info.what_is.hero_subtitle': 'La plateforme P2P d\'achat-vente immobilier sans commissions d\'agence.',
  'info.what_is.savings_title': '0 EUR de commissions d\'agence',
  'info.what_is.savings_body': 'Ce que vous paieriez avec une agence traditionnelle :',
  'info.what_is.features.0.title': 'Sans intermédiaires',
  'info.what_is.features.0.body': 'Nous mettons en contact directement acheteurs et vendeurs particuliers, éliminant les commissions d\'agence.',
  'info.what_is.features.1.title': 'Processus guidé',
  'info.what_is.features.1.body': 'De la visite à la signature notariale, nous vous accompagnons à chaque étape avec des outils légaux et financiers.',
  'info.what_is.features.2.title': 'Sécurité juridique',
  'info.what_is.features.2.body': 'Vérification d\'identité KYC, Contrat d\'Arrhes numérique généré par IA et signature électronique de documents.',
  'info.what_is.features.3.title': 'Solvabilité consciente',
  'info.what_is.features.3.body': 'Questionnaire financier pour que les acheteurs connaissent leur situation réelle avant de faire une offre.',
  'info.what_is.features.4.title': 'Transparence totale',
  'info.what_is.features.4.body': 'Historique des offres et négociations entièrement visible pour les deux parties.',
  'info.what_is.savings_table.buyer': 'Acheteur',
  'info.what_is.savings_table.percentage_seller': '5%\n(fourchette 3%–7%)',
  'info.what_is.savings_table.percentage_buyer': '3%\n(fourchette 0%–5%)',
  'info.what_is.savings_table.fixed_min_seller': '7 260€ – 9 000€',
  'info.what_is.savings_table.fixed_min_buyer': '3 000€ – 4 500€',
  'info.what_is.savings_table.online_fee_seller': '4 000€ – 8 000€',
  'info.what_is.savings_table.online_fee_buyer': 'Variable',
  'info.what_is.savings_table.financial_seller': 'N/A',
  'info.what_is.savings_table.financial_buyer': '3 000€ – 6 000€',
  'info.how_it_works.title': 'Le processus complet',
  'info.how_it_works.steps.0.title': 'Publiez ou cherchez votre bien',
  'info.how_it_works.steps.0.body': 'Le vendeur crée l\'annonce avec photos, description et prix. Le Diagnostic de Performance Énergétique est obligatoire.',
  'info.how_it_works.steps.1.title': 'Demandez et gérez les visites',
  'info.how_it_works.steps.1.body': 'L\'acheteur demande une visite. Le vendeur configure ses créneaux horaires et confirme les rendez-vous.',
  'info.how_it_works.steps.2.title': 'Offre avec Passeport de Solvabilité',
  'info.how_it_works.steps.2.body': 'L\'acheteur joint son Passeport de Solvabilité (niveau Bronze, Argent ou Or) à l\'offre.',
  'info.how_it_works.steps.3.title': 'Vérification de Solvabilité',
  'info.how_it_works.steps.3.body': 'Le vendeur examine le Passeport de Solvabilité de l\'acheteur et décide d\'accepter, rejeter ou faire une contre-offre.',
  'info.how_it_works.steps.4.title': 'Contrat d\'Arrhes',
  'info.how_it_works.steps.4.body': 'Les deux parties complètent un entretien guidé. L\'IA génère le brouillon du contrat.',
  'info.how_it_works.steps.5.title': 'Expertise du Bien',
  'info.how_it_works.steps.5.body': 'Le rendez-vous avec l\'expert officiel est coordonné. Le rapport d\'expertise est l\'étape préalable au notaire.',
  'info.contact.title': 'Nous sommes là pour vous aider',
  'info.contact.email_subtitle': 'support@inmufacil.com',
  'info.contact.email_action': 'Envoyer un e-mail',
  'info.buyer_guide.title': 'Guide de l\'Acheteur',
  'info.buyer_guide.sections.0.title': 'Trouvez votre bien idéal',
  'info.buyer_guide.sections.1.title': 'Complétez votre Passeport de Solvabilité',
  'info.buyer_guide.sections.2.title': 'Faites votre offre',
  'info.buyer_guide.sections.3.title': 'Coûts à prévoir',
  'info.seller_guide.title': 'Guide du Vendeur',
  'info.seller_guide.subtitle': 'Vendez votre bien sans payer de commissions d\'agence.',
  'info.seller_guide.sections.0.title': 'Publiez votre bien',
  'info.seller_guide.sections.1.title': 'Gérez la solvabilité',
  'info.seller_guide.sections.2.title': 'Documents nécessaires',
  'info.seller_guide.sections.3.title': 'Coûts du vendeur',
  'info.faq.title': 'Questions fréquentes',
};

// ============================================================
// Apply all translations
// ============================================================
function applyDict(locale, dict) {
  const data = readJson(locale);
  let count = 0;
  for (const [key, val] of Object.entries(dict)) {
    setVal(data, key, val);
    count++;
  }
  writeJson(locale, data);
  console.log('Updated', locale, '(' + count + ' keys)');
}

// ca-ES: Catalan
const allCa = { ...arrasInterviewCa, ...profileCa, ...infoCa };
applyDict('ca-ES', allCa);

// va-ES: copy Catalan
applyDict('va-ES', allCa);

// fr-FR: French
const allFr = { ...arrasInterviewFr, ...profileFr, ...infoFr };
applyDict('fr-FR', allFr);

// fr-CA: copy French
applyDict('fr-CA', allFr);

// en-GB, en-CA: sync from en-US
const enUs = readJson('en-US');
const enFlat = flatten(enUs);
const esEs = readJson('es-ES');
const esFlat = flatten(esEs);
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

// gl-ES: Apply en-US values as fallback for ALL remaining keys (better than showing Spanish)
const glEsData = readJson('gl-ES');
const glFlat = flatten(glEsData);
let glCount = 0;
for (const key of Object.keys(esFlat)) {
  if (glFlat[key] === esFlat[key] && enFlat[key] !== undefined && enFlat[key] !== esFlat[key]) {
    setVal(glEsData, key, enFlat[key]);
    glCount++;
  }
}
writeJson('gl-ES', glEsData);
console.log('Updated gl-ES (' + glCount + ' keys using en-US fallback)');

// eu-ES: Apply en-US values as fallback for remaining keys
const euEsData = readJson('eu-ES');
const euFlat = flatten(euEsData);
let euCount = 0;
for (const key of Object.keys(esFlat)) {
  if (euFlat[key] === esFlat[key] && enFlat[key] !== undefined && enFlat[key] !== esFlat[key]) {
    setVal(euEsData, key, enFlat[key]);
    euCount++;
  }
}
writeJson('eu-ES', euEsData);
console.log('Updated eu-ES (' + euCount + ' keys using en-US fallback)');

console.log('Done: _phase_c_regional_d');

const fs = require('fs');
const base = 'C:/Users/Os/.gemini/antigravity/scratch/InmuFacil_Project/frontend/assets/translations/';

function setVal(obj, path, val) {
  const parts = path.split('.');
  const last = parts.pop();
  const target = parts.reduce((o, k) => { if (!o[k]) o[k] = {}; return o[k]; }, obj);
  target[last] = val;
}

// Month/weekday names per language
const timeData = {
  'en-US': {
    months_num: {1:'January',2:'February',3:'March',4:'April',5:'May',6:'June',7:'July',8:'August',9:'September',10:'October',11:'November',12:'December'},
    months_str: {jan:'January',feb:'February',mar:'March',apr:'April',may:'May',jun:'June',jul:'July',aug:'August',sep:'September',oct:'October',nov:'November',dec:'December'},
    short_num: {1:'Jan',2:'Feb',3:'Mar',4:'Apr',5:'May',6:'Jun',7:'Jul',8:'Aug',9:'Sep',10:'Oct',11:'Nov',12:'Dec'},
    short_str: {jan:'Jan',feb:'Feb',mar:'Mar',apr:'Apr',may:'May',jun:'Jun',jul:'Jul',aug:'Aug',sep:'Sep',oct:'Oct',nov:'Nov',dec:'Dec'},
    wd_num: {1:'Mo',2:'Tu',3:'We',4:'Th',5:'Fr',6:'Sa',7:'Su'},
    wd_str: {mon:'Mo',tue:'Tu',wed:'We',thu:'Th',fri:'Fr',sat:'Sa',sun:'Su'},
  },
  'fr-FR': {
    months_num: {1:'Janvier',2:'Février',3:'Mars',4:'Avril',5:'Mai',6:'Juin',7:'Juillet',8:'Août',9:'Septembre',10:'Octobre',11:'Novembre',12:'Décembre'},
    months_str: {jan:'Janvier',feb:'Février',mar:'Mars',apr:'Avril',may:'Mai',jun:'Juin',jul:'Juillet',aug:'Août',sep:'Septembre',oct:'Octobre',nov:'Novembre',dec:'Décembre'},
    short_num: {1:'Jan',2:'Fév',3:'Mar',4:'Avr',5:'Mai',6:'Jun',7:'Jul',8:'Aoû',9:'Sep',10:'Oct',11:'Nov',12:'Déc'},
    short_str: {jan:'Jan',feb:'Fév',mar:'Mar',apr:'Avr',may:'Mai',jun:'Jun',jul:'Jul',aug:'Aoû',sep:'Sep',oct:'Oct',nov:'Nov',dec:'Déc'},
    wd_num: {1:'Lu',2:'Ma',3:'Me',4:'Je',5:'Ve',6:'Sa',7:'Di'},
    wd_str: {mon:'Lu',tue:'Ma',wed:'Me',thu:'Je',fri:'Ve',sat:'Sa',sun:'Di'},
  },
  'ca-ES': {
    months_num: {1:'Gener',2:'Febrer',3:'Març',4:'Abril',5:'Maig',6:'Juny',7:'Juliol',8:'Agost',9:'Setembre',10:'Octubre',11:'Novembre',12:'Desembre'},
    months_str: {jan:'Gener',feb:'Febrer',mar:'Març',apr:'Abril',may:'Maig',jun:'Juny',jul:'Juliol',aug:'Agost',sep:'Setembre',oct:'Octubre',nov:'Novembre',dec:'Desembre'},
    short_num: {1:'Gen',2:'Feb',3:'Mar',4:'Abr',5:'Mai',6:'Jun',7:'Jul',8:'Ago',9:'Set',10:'Oct',11:'Nov',12:'Des'},
    short_str: {jan:'Gen',feb:'Feb',mar:'Mar',apr:'Abr',may:'Mai',jun:'Jun',jul:'Jul',aug:'Ago',sep:'Set',oct:'Oct',nov:'Nov',dec:'Des'},
    wd_num: {1:'Dl',2:'Dt',3:'Dc',4:'Dj',5:'Dv',6:'Ds',7:'Dg'},
    wd_str: {mon:'Dl',tue:'Dt',wed:'Dc',thu:'Dj',fri:'Dv',sat:'Ds',sun:'Dg'},
  },
  'eu-ES': {
    months_num: {1:'Urtarrila',2:'Otsaila',3:'Martxoa',4:'Apirila',5:'Maiatza',6:'Ekaina',7:'Uztaila',8:'Abuztua',9:'Iraila',10:'Urria',11:'Azaroa',12:'Abendua'},
    months_str: {jan:'Urtarrila',feb:'Otsaila',mar:'Martxoa',apr:'Apirila',may:'Maiatza',jun:'Ekaina',jul:'Uztaila',aug:'Abuztua',sep:'Iraila',oct:'Urria',nov:'Azaroa',dec:'Abendua'},
    short_num: {1:'Urt',2:'Ots',3:'Mar',4:'Api',5:'Mai',6:'Eka',7:'Uzt',8:'Abu',9:'Ira',10:'Urr',11:'Aza',12:'Abe'},
    short_str: {jan:'Urt',feb:'Ots',mar:'Mar',apr:'Api',may:'Mai',jun:'Eka',jul:'Uzt',aug:'Abu',sep:'Ira',oct:'Urr',nov:'Aza',dec:'Abe'},
    wd_num: {1:'Al',2:'As',3:'Az',4:'Og',5:'Or',6:'La',7:'Ig'},
    wd_str: {mon:'Al',tue:'As',wed:'Az',thu:'Og',fri:'Or',sat:'La',sun:'Ig'},
  },
  'gl-ES': {
    months_num: {1:'Xaneiro',2:'Febreiro',3:'Marzo',4:'Abril',5:'Maio',6:'Xuño',7:'Xullo',8:'Agosto',9:'Setembro',10:'Outubro',11:'Novembro',12:'Decembro'},
    months_str: {jan:'Xaneiro',feb:'Febreiro',mar:'Marzo',apr:'Abril',may:'Maio',jun:'Xuño',jul:'Xullo',aug:'Agosto',sep:'Setembro',oct:'Outubro',nov:'Novembro',dec:'Decembro'},
    short_num: {1:'Xan',2:'Feb',3:'Mar',4:'Abr',5:'Mai',6:'Xuñ',7:'Xul',8:'Ago',9:'Set',10:'Out',11:'Nov',12:'Dec'},
    short_str: {jan:'Xan',feb:'Feb',mar:'Mar',apr:'Abr',may:'Mai',jun:'Xuñ',jul:'Xul',aug:'Ago',sep:'Set',oct:'Out',nov:'Nov',dec:'Dec'},
    wd_num: {1:'Lu',2:'Ma',3:'Me',4:'Xo',5:'Ve',6:'Sa',7:'Do'},
    wd_str: {mon:'Lu',tue:'Ma',wed:'Me',thu:'Xo',fri:'Ve',sat:'Sa',sun:'Do'},
  },
};

// Translations for common, not_found, profile remaining, home, kyc, pre_offer_tax, smart_bid_risk, ai_consent
const translations = {
  // HOME
  'home.extras_label': { 'en-US':'Extras','fr-FR':'Extras','ca-ES':'Extres','eu-ES':'Gehigarriak','gl-ES':'Extras' },
  'home.zero_properties': { 'en-US':'0 PROPERTIES','fr-FR':'0 BIENS','ca-ES':'0 IMMOBLES','eu-ES':'0 PROPIETATE','gl-ES':'0 INMOBLES' },
  'home.verified_this_week': { 'en-US':'Verified this week','fr-FR':'Vérifiées cette semaine','ca-ES':'Verificades aquesta setmana','eu-ES':'Aste honetan egiaztatuak','gl-ES':'Verificadas esta semana' },
  // COMMON
  'common.save': { 'en-US':'Save','fr-FR':'Enregistrer','ca-ES':'Desar','eu-ES':'Gorde','gl-ES':'Gardar' },
  'common.cancel': { 'en-US':'Cancel','fr-FR':'Annuler','ca-ES':'Cancel·lar','eu-ES':'Bertan behera utzi','gl-ES':'Cancelar' },
  'common.delete': { 'en-US':'Delete','fr-FR':'Supprimer','ca-ES':'Eliminar','eu-ES':'Ezabatu','gl-ES':'Eliminar' },
  'common.edit': { 'en-US':'Edit','fr-FR':'Modifier','ca-ES':'Editar','eu-ES':'Editatu','gl-ES':'Editar' },
  'common.confirm': { 'en-US':'Confirm','fr-FR':'Confirmer','ca-ES':'Confirmar','eu-ES':'Baieztatu','gl-ES':'Confirmar' },
  'common.home_btn': { 'en-US':'Home','fr-FR':'Accueil','ca-ES':'Inici','eu-ES':'Hasiera','gl-ES':'Inicio' },
  'common.draft_saved': { 'en-US':'Draft saved successfully','fr-FR':'Brouillon enregistré avec succès','ca-ES':'Esborrany desat correctament','eu-ES':'Zirriborroa behar bezala gorde da','gl-ES':'Borrador gardado correctamente' },
  'common.timeline_btn': { 'en-US':'Back to timeline','fr-FR':'Retour au calendrier','ca-ES':'Tornar al timeline','eu-ES':'Itzuli denbora-lerrora','gl-ES':'Volver ao timeline' },
  'common.retry': { 'en-US':'Retry','fr-FR':'Réessayer','ca-ES':'Reintentar','eu-ES':'Saiatu berriro','gl-ES':'Reintentar' },
  'common.my_contracts': { 'en-US':'My Contracts','fr-FR':'Mes Contrats','ca-ES':'Els meus Contractes','eu-ES':'Nire Kontratuak','gl-ES':'Os meus Contratos' },
  'common.contracts_wip': { 'en-US':'Contracts Area (Coming soon)','fr-FR':'Zone des Contrats (Prochainement)','ca-ES':'Zona de Contractes (Properament)','eu-ES':'Kontratu Eremua (Laster)','gl-ES':'Zona de Contratos (Proximamente)' },
  // NOT FOUND
  'not_found.building_future_part1': { 'en-US':'We are building ','fr-FR':'Nous construisons ','ca-ES':'Estem construint ','eu-ES':'Eraikitzen ari gara ','gl-ES':'Estamos construíndo ' },
  'not_found.building_future_part2': { 'en-US':'the future.','fr-FR':'l\'avenir.','ca-ES':'el futur.','eu-ES':'etorkizuna.','gl-ES':'o futuro.' },
  'not_found.description': { 'en-US':'The page you are looking for is still in development or does not exist. We are working hard to bring you the best P2P experience.','fr-FR':'La page que vous recherchez est encore en développement ou n\'existe pas. Nous travaillons dur pour vous offrir la meilleure expérience P2P.','ca-ES':'La pàgina que busques encara està en fase de desenvolupament o no existeix. Estem treballant dur per portar-te la millor experiència P2P.','eu-ES':'Bilatzen ari zaren orrialdea oraindik garapenean dago edo ez da existitzen. Gogotsu lan egiten ari gara P2P esperientzia onena eskaintzeko.','gl-ES':'A páxina que buscas aínda está en fase de desenvolvemento ou non existe. Estamos traballando duro para traerche a mellor experiencia P2P.' },
  'not_found.notify_me_label': { 'en-US':'Would you like us to notify you when it\'s ready?','fr-FR':'Souhaitez-vous être notifié quand ce sera prêt ?','ca-ES':'Vols que t\'avisem quan estigui llesta?','eu-ES':'Nahi duzu prest dagoenean jakinaraztea?','gl-ES':'Queres que che avisemos cando estea lista?' },
  'not_found.email_placeholder': { 'en-US':'Enter your email...','fr-FR':'Entrez votre email...','ca-ES':'Introdueix el teu email...','eu-ES':'Sartu zure emaila...','gl-ES':'Introduce o teu email...' },
  'not_found.notify_button': { 'en-US':'Notify me','fr-FR':'Me notifier','ca-ES':'Avisar-me','eu-ES':'Jakinarazi','gl-ES':'Avisar' },
  'not_found.security_text': { 'en-US':'Your data is safe with us.','fr-FR':'Vos données sont en sécurité chez nous.','ca-ES':'Les teves dades estan segures amb nosaltres.','eu-ES':'Zure datuak seguru daude gurekin.','gl-ES':'Os teus datos están seguros connosco.' },
  'not_found.secure_infrastructure': { 'en-US':'Secure infrastructure','fr-FR':'Infrastructure sécurisée','ca-ES':'Infraestructura segura','eu-ES':'Azpiegitura segurua','gl-ES':'Infraestrutura segura' },
  'not_found.direct_architecture': { 'en-US':'Direct architecture','fr-FR':'Architecture directe','ca-ES':'Arquitectura directa','eu-ES':'Arkitektura zuzena','gl-ES':'Arquitectura directa' },
  'not_found.copyright_text': { 'en-US':'InmuFácil Tech. All rights reserved.','fr-FR':'InmuFácil Tech. Tous droits réservés.','ca-ES':'InmuFácil Tech. Tots els drets reservats.','eu-ES':'InmuFácil Tech. Eskubide guztiak erreserbatuak.','gl-ES':'InmuFácil Tech. Todos os dereitos reservados.' },
  'not_found.notify_me_success': { 'en-US':'Thank you! We will notify you soon.','fr-FR':'Merci ! Nous vous notifierons bientôt.','ca-ES':'Gràcies! T\'avisarem aviat.','eu-ES':'Eskerrik asko! Laster jakinaraziko dizugu.','gl-ES':'Grazas! Avisarémoste pronto.' },
  // PROFILE remaining
  'profile.visit_hours': { 'en-US':'Visit hours','fr-FR':'Horaires de visite','ca-ES':'Horaris de visita','eu-ES':'Bisita-orduak','gl-ES':'Horarios de visita' },
  'profile.another_property_question': { 'en-US':'Do you have another property?','fr-FR':'Avez-vous un autre bien ?','ca-ES':'Tens una altra propietat?','eu-ES':'Ba al duzu beste propietaterik?','gl-ES':'Tes outra propiedade?' },
  'profile.publish_another_now': { 'en-US':'List another property now','fr-FR':'Publier un autre bien maintenant','ca-ES':'Publicar un altre anunci ara','eu-ES':'Argitaratu beste propietate bat orain','gl-ES':'Publicar outro anuncio agora' },
  'profile.min_8_chars': { 'en-US':'Minimum 8 characters','fr-FR':'Minimum 8 caractères','ca-ES':'Mínim 8 caràcters','eu-ES':'Gutxienez 8 karaktere','gl-ES':'Mínimo 8 caracteres' },
  'profile.repeat_password': { 'en-US':'Repeat your password','fr-FR':'Répétez votre mot de passe','ca-ES':'Repeteix la teva contrasenya','eu-ES':'Errepikatu zure pasahitza','gl-ES':'Repite o teu contrasinal' },
  'profile.location_error': { 'en-US':'Could not get your location. Showing Spain.','fr-FR':'Impossible d\'obtenir votre localisation. Affichage de l\'Espagne.','ca-ES':'No s\'ha pogut obtenir la teva ubicació. Mostrant Espanya.','eu-ES':'Ezin da zure kokapena lortu. Espainia erakusten.','gl-ES':'Non se puido obter a túa ubicación. Mostrando España.' },
  'profile.camera_activating': { 'en-US':'Activating camera...','fr-FR':'Activation de la caméra...','ca-ES':'Activant càmera...','eu-ES':'Kamera aktibatzen...','gl-ES':'Activando cámara...' },
  'profile.camera_error': { 'en-US':'Capture error: {error}','fr-FR':'Erreur de capture : {error}','ca-ES':'Error en capturar: {error}','eu-ES':'Harrapatzean errorea: {error}','gl-ES':'Erro ao capturar: {error}' },
  'profile.no_camera': { 'en-US':'No camera found.','fr-FR':'Aucune caméra disponible.','ca-ES':'No s\'ha trobat cap càmera disponible.','eu-ES':'Ez da kamerarik aurkitu.','gl-ES':'Non se atopou ningunha cámara dispoñible.' },
  'profile.camera_access_error': { 'en-US':'Error accessing camera: {error}','fr-FR':'Erreur d\'accès à la caméra : {error}','ca-ES':'Error en accedir a la càmera: {error}','eu-ES':'Kamerara sartzerakoan errorea: {error}','gl-ES':'Erro ao acceder á cámara: {error}' },
  'profile.switch_camera': { 'en-US':'Switch camera','fr-FR':'Changer de caméra','ca-ES':'Canviar càmera','eu-ES':'Aldatu kamera','gl-ES':'Cambiar cámara' },
  'profile.default_username': { 'en-US':'User','fr-FR':'Utilisateur','ca-ES':'Usuari','eu-ES':'Erabiltzailea','gl-ES':'Usuario' },
  'profile.status_verified': { 'en-US':'VERIFIED','fr-FR':'VÉRIFIÉ','ca-ES':'VERIFICAT','eu-ES':'EGIAZTATUTA','gl-ES':'VERIFICADO' },
  'profile.status_unverified': { 'en-US':'NOT VERIFIED','fr-FR':'NON VÉRIFIÉ','ca-ES':'NO VERIFICAT','eu-ES':'EGIAZTATU GABE','gl-ES':'NON VERIFICADO' },
  'profile.status_pending': { 'en-US':'PENDING','fr-FR':'EN ATTENTE','ca-ES':'PENDENT','eu-ES':'ZAIN','gl-ES':'PENDENTE' },
  'profile.delete_photo_success': { 'en-US':'Photo deleted','fr-FR':'Photo supprimée','ca-ES':'Foto eliminada','eu-ES':'Argazkia ezabatuta','gl-ES':'Foto eliminada' },
  'profile.delete_photo_error': { 'en-US':'Error deleting photo','fr-FR':'Erreur lors de la suppression de la photo','ca-ES':'Error en eliminar la foto','eu-ES':'Argazkia ezabatzean errorea','gl-ES':'Erro ao eliminar a foto' },
  // KYC
  'kyc.badge_verified_user': { 'en-US':'verified_user','fr-FR':'verified_user','ca-ES':'verified_user','eu-ES':'verified_user','gl-ES':'verified_user' },
  'kyc.badge_encrypted': { 'en-US':'AES-256 Encrypted','fr-FR':'AES-256 Chiffré','ca-ES':'AES-256 Xifrat','eu-ES':'AES-256 Enkriptatuta','gl-ES':'AES-256 Cifrado' },
  'kyc.ssl_secure': { 'en-US':'SSL SECURE','fr-FR':'SSL SÉCURISÉ','ca-ES':'SSL SEGUR','eu-ES':'SSL SEGURUA','gl-ES':'SSL SEGURO' },
  // PRE_OFFER_TAX
  'pre_offer_tax.offer_amount_label': { 'en-US':'YOUR ECONOMIC OFFER','fr-FR':'VOTRE OFFRE ÉCONOMIQUE','ca-ES':'LA TEVA OFERTA ECONÒMICA','eu-ES':'ZURE PROPOSAMEN EKONOMIKOA','gl-ES':'A TÚA OFERTA ECONÓMICA' },
  'pre_offer_tax.offer_subtitle': { 'en-US':'Proposed amount for the purchase of the property','fr-FR':'Montant proposé pour l\'achat du bien','ca-ES':'Import proposat per a la compra de l\'immoble','eu-ES':'Propietateen erosketa proposatutako zenbatekoa','gl-ES':'Importe proposto para a compra do inmoble' },
  'pre_offer_tax.header': { 'en-US':'Estimated Costs and Taxes','fr-FR':'Estimation des Frais et Impôts','ca-ES':'Estimació de Despeses i Impostos','eu-ES':'Gastu eta Zergen Estimazioa','gl-ES':'Estimación de Gastos e Impostos' },
  'pre_offer_tax.itp_label': { 'en-US':'Transfer Tax (ITP {rate})','fr-FR':'Impôt sur les mutations (ITP {rate})','ca-ES':'Impost Transmissions (ITP {rate})','eu-ES':'Eskualdaketa-zerga (ITP {rate})','gl-ES':'Imposto Transmisións (ITP {rate})' },
  'pre_offer_tax.notary_label': { 'en-US':'Notary (Est.)','fr-FR':'Notaire (Est.)','ca-ES':'Notaria (Est.)','eu-ES':'Notaria (Est.)','gl-ES':'Notaría (Est.)' },
  'pre_offer_tax.notary_sublabel': { 'en-US':'Public purchase deed','fr-FR':'Acte de vente public','ca-ES':'Escriptura pública de compravenda','eu-ES':'Erosketa-salmenta escritura publikoa','gl-ES':'Escritura pública de compravenda' },
  'pre_offer_tax.registry_label': { 'en-US':'Registry (Est.)','fr-FR':'Registre (Est.)','ca-ES':'Registre (Est.)','eu-ES':'Erregistroa (Est.)','gl-ES':'Rexistro (Est.)' },
  'pre_offer_tax.registry_sublabel': { 'en-US':'Land Registry entry','fr-FR':'Inscription au registre foncier','ca-ES':'Inscripció al Registre de la Propietat','eu-ES':'Jabetza Erregistroan inskripzioa','gl-ES':'Inscrición no Rexistro da Propiedade' },
  'pre_offer_tax.agency_label': { 'en-US':'Management (Optional)','fr-FR':'Gestion (Optionnel)','ca-ES':'Gestoria (Opcional)','eu-ES':'Gestoria (Aukerakoa)','gl-ES':'Xestoría (Opcional)' },
  'pre_offer_tax.agency_sublabel': { 'en-US':'Processing and tax settlement','fr-FR':'Traitement et liquidation des impôts','ca-ES':'Tramitació i liquidació d\'impostos','eu-ES':'Tramitazioa eta zergen likidazioa','gl-ES':'Tramitación e liquidación de impostos' },
  'pre_offer_tax.optional_badge': { 'en-US':'OPTIONAL','fr-FR':'OPTIONNEL','ca-ES':'OPCIONAL','eu-ES':'AUKERAKOA','gl-ES':'OPCIONAL' },
  'pre_offer_tax.total_label': { 'en-US':'TOTAL ESTIMATED COSTS','fr-FR':'TOTAL FRAIS ESTIMÉS','ca-ES':'TOTAL DESPESES ESTIMADES','eu-ES':'GASTU ESTIMATU OSOA','gl-ES':'TOTAL GASTOS ESTIMADOS' },
  'pre_offer_tax.total_sublabel': { 'en-US':'Excluding the property price','fr-FR':'Hors prix du bien','ca-ES':'Sense incloure el preu de l\'immoble','eu-ES':'Propietatearen prezioa kanpo utzita','gl-ES':'Sen incluír o prezo do inmoble' },
  'pre_offer_tax.foral_clause': { 'en-US':'In special or regional tax regimes (Basque Country, Navarre, Canary Islands), ITP and other costs may vary significantly. We recommend consulting a local tax advisor.','fr-FR':'Dans les régimes fiscaux spéciaux ou régionaux (Pays Basque, Navarre, Canaries), l\'ITP et autres frais peuvent varier considérablement. Nous vous recommandons de consulter un conseiller fiscal local.','ca-ES':'En els règims forals o especials (País Basc, Navarra, Canàries), l\'ITP i altres despeses poden variar significativament. Us recomanem consultar un assessor fiscal local.','eu-ES':'Foru edo erregimeneko berezien kasuan (Euskadi, Nafarroa, Kanariak), ITPa eta beste gastuak nabarmen alda daitezke. Tokiko zerga-aholkulari batekin kontsultatzea gomendatzen dizugu.','gl-ES':'Nos réximes forais ou especiais (País Vasco, Navarra, Canarias), o ITP e outros gastos poden variar significativamente. Recomendamos consultar cun asesor fiscal local.' },
  'pre_offer_tax.disclaimer': { 'en-US':'This calculation is purely informative and is based on standard tax rates. The final settlement will depend on personal circumstances and the regulations in force at the time of signing.','fr-FR':'Ce calcul est purement informatif et se base sur des taux d\'imposition standard. La liquidation finale dépendra des circonstances personnelles et de la réglementation en vigueur au moment de la signature.','ca-ES':'Aquest càlcul és purament informatiu i es basa en tipus impositius estàndard. La liquidació final dependrà de les circumstàncies personals i la normativa vigent en el moment de la firma.','eu-ES':'Kalkulu hau informatibo hutsa da eta zerga-tasa estandarretan oinarritzen da. Azken likidazioa inguruabar pertsonaletan eta sinaduran indarrean dagoen araudian oinarrituko da.','gl-ES':'Este cálculo é puramente informativo e baséase en tipos impositivos estándar. A liquidación final dependerá das circunstancias persoais e a normativa vixente no momento da firma.' },
  'pre_offer_tax.confirm_button': { 'en-US':'Confirm and send offer','fr-FR':'Confirmer et envoyer l\'offre','ca-ES':'Confirmar i enviar oferta','eu-ES':'Baieztatu eta bidali eskaintza','gl-ES':'Confirmar e enviar oferta' },
  'pre_offer_tax.back_button': { 'en-US':'Back to offer','fr-FR':'Retour à l\'offre','ca-ES':'Tornar a l\'oferta','eu-ES':'Itzuli eskaintzara','gl-ES':'Volver á oferta' },
  'pre_offer_tax.notarial_disclaimer': { 'en-US':'Notary and registry costs are estimates based on current official fee schedules.','fr-FR':'Les frais de notaire et d\'enregistrement sont des estimations basées sur les barèmes officiels en vigueur.','ca-ES':'Les despeses de notaria i registre són estimacions basades en els aranzeladors oficials vigents.','eu-ES':'Notaria eta erregistro gastuak gaur indarrean dauden aranzel ofizialetan oinarritutako estimazioak dira.','gl-ES':'Os gastos de notaría e rexistro son estimacións baseadas nos aranceis oficiais vixentes.' },
  // SMART BID RISK
  'smart_bid_risk.your_offer_label': { 'en-US':'YOUR OFFER','fr-FR':'VOTRE OFFRE','ca-ES':'LA TEVA OFERTA','eu-ES':'ZURE ESKAINTZA','gl-ES':'A TÚA OFERTA' },
  'smart_bid_risk.asking_price_label': { 'en-US':'ASKING PRICE','fr-FR':'PRIX DEMANDÉ','ca-ES':'PREU SORTIDA','eu-ES':'IRTEERA PREZIOA','gl-ES':'PREZO SAÍDA' },
  'smart_bid_risk.gauge_title': { 'en-US':'Acceptance Probability','fr-FR':'Probabilité d\'Acceptation','ca-ES':'Probabilitat d\'Acceptació','eu-ES':'Onarpenaren Probabilitatea','gl-ES':'Probabilidade de Aceptación' },
  'smart_bid_risk.label_low': { 'en-US':'Low Risk','fr-FR':'Risque Faible','ca-ES':'Risc Baix','eu-ES':'Arrisku Baxua','gl-ES':'Risco Baixo' },
  'smart_bid_risk.label_medium': { 'en-US':'Medium Risk','fr-FR':'Risque Moyen','ca-ES':'Risc Mitjà','eu-ES':'Arrisku Ertaina','gl-ES':'Risco Medio' },
  'smart_bid_risk.label_medium_high': { 'en-US':'Moderate Risk','fr-FR':'Risque Modéré','ca-ES':'Risc Moderat','eu-ES':'Arrisku Moderatua','gl-ES':'Risco Moderado' },
  'smart_bid_risk.label_high': { 'en-US':'High Risk','fr-FR':'Risque Élevé','ca-ES':'Risc Alt','eu-ES':'Arrisku Altua','gl-ES':'Risco Alto' },
  'smart_bid_risk.label_low_detail': { 'en-US':'Your offer is equal to or above the asking price. It is very likely to be accepted if there are no other competitive offers.','fr-FR':'Votre offre est égale ou supérieure au prix de vente. Elle a de très bonnes chances d\'être acceptée s\'il n\'y a pas d\'autres offres compétitives.','ca-ES':'La teva oferta és igual o superior al preu de venda. És molt probable que sigui acceptada si no hi ha altres ofertes competitives.','eu-ES':'Zure eskaintza salmenta-prezioaren berdina edo handiagoa da. Oso litekeena da onartzea beste eskaintza lehiakiderik ez badago.','gl-ES':'A túa oferta é igual ou superior ao prezo de venda. É moi probable que sexa aceptada se non hai outras ofertas competitivas.' },
  'smart_bid_risk.label_medium_detail': { 'en-US':'Your offer is slightly below the asking price. The seller may accept it or send you a counteroffer.','fr-FR':'Votre offre est légèrement inférieure au prix demandé. Le vendeur pourrait l\'accepter ou vous envoyer une contre-offre.','ca-ES':'La teva oferta és lleugerament per sota del preu. El venedor podria acceptar-la o enviar-te una contraoferta.','eu-ES':'Zure eskaintza prezioa baino zertxobait baxuagoa da. Saltzaileak onar dezake edo kontraeskaintza bidal diezazuke.','gl-ES':'A túa oferta está lixeiramente por baixo do prezo. O vendedor podería aceptala ou enviarte unha contraoferta.' },
  'smart_bid_risk.label_medium_high_detail': { 'en-US':'There is a considerable difference. You will need strong arguments or for the property to have been on the market for a long time.','fr-FR':'Il y a une différence considérable. Vous aurez besoin d\'arguments solides ou que le bien soit sur le marché depuis longtemps.','ca-ES':'Hi ha una diferència considerable. Necessitaràs arguments sòlids o que l\'immoble porti temps al mercat.','eu-ES':'Alde nabarmena dago. Argudio sendoak edo jabetza denboratik merkatuan egon behar izango duzu.','gl-ES':'Hai unha diferenza considerable. Necesitarás argumentos sólidos ou que o inmoble leve tempo no mercado.' },
  'smart_bid_risk.label_high_detail': { 'en-US':'The offer is well below the asking price. There is a high risk of immediate rejection.','fr-FR':'L\'offre est bien en dessous du prix demandé. Il existe un risque élevé de rejet immédiat.','ca-ES':'L\'oferta és molt per sota del preu de sortida. Hi ha un alt risc de rebuig immediat.','eu-ES':'Eskaintza irteera-prezioa baino askoz baxuagoa da. Berehala ezetza jasotzeko arrisku handia dago.','gl-ES':'A oferta está moi por baixo do prezo de saída. Existe un alto risco de rexeitamento inmediato.' },
  'smart_bid_risk.no_historical_data': { 'en-US':'Not enough historical data in this area for an accurate prediction.','fr-FR':'Pas assez de données historiques dans cette zone pour une prédiction précise.','ca-ES':'Sense dades històriques suficients en aquesta zona per a una predicció exacta.','eu-ES':'Ez dago datu historikorik nahikorik inguru honetan iragarpen zehatz bat egiteko.','gl-ES':'Sen datos históricos suficientes nesta zona para unha predición exacta.' },
  'smart_bid_risk.statistical_disclaimer': { 'en-US':'The risk level is a statistical estimate based on the current market, not a prediction of the seller\'s behaviour.','fr-FR':'Le niveau de risque est une estimation statistique basée sur le marché actuel, pas une prédiction du comportement du vendeur.','ca-ES':'El nivell de risc és una estimació estadística basada en el mercat actual, no una predicció del comportament humà del venedor.','eu-ES':'Arrisku-maila uneko merkatuan oinarritutako estimazio estatistikoa da, eta ez da saltzailearen portaeraren iragarpen bat.','gl-ES':'O nivel de risco é unha estimación estatística baseada no mercado actual, non unha predición do comportamento humano do vendedor.' },
  'smart_bid_risk.understood_button': { 'en-US':'Understood, continue','fr-FR':'Compris, continuer','ca-ES':'Entès, continuar','eu-ES':'Ulertuta, jarraitu','gl-ES':'Entendido, continuar' },
  'smart_bid_risk.extreme_low_offer': { 'en-US':'Very aggressive offer','fr-FR':'Offre très agressive','ca-ES':'Oferta molt agressiva','eu-ES':'Eskaintza oso oldarkorra','gl-ES':'Oferta moi agresiva' },
  // LIFESTYLE
  'lifestyle.profile_senior': { 'en-US':'Senior','fr-FR':'Senior','ca-ES':'Sènior','eu-ES':'Senior','gl-ES':'Senior' },
  // AI CONSENT
  'ai_consent.title': { 'en-US':'AI Consent History','fr-FR':'Historique des Consentements IA','ca-ES':'Historial de Consentiments IA','eu-ES':'AI Baimenen Historia','gl-ES':'Historial de Consentimentos IA' },
  'ai_consent.subtitle': { 'en-US':'Record of explicit consents for AI data processing (Art. 15 GDPR).','fr-FR':'Registre des consentements explicites pour le traitement des données par IA (Art. 15 RGPD).','ca-ES':'Registre de consentiments explícits per al tractament de dades per IA (Art. 15 RGPD).','eu-ES':'AIak datuen tratamendurako baimenaren erregistroa (Art. 15 GDPR).','gl-ES':'Rexistro de consentimentos explícitos para o tratamento de datos por IA (Art. 15 RXPD).' },
  'ai_consent.no_records': { 'en-US':'No records yet','fr-FR':'Aucun enregistrement pour l\'instant','ca-ES':'Sense registres encara','eu-ES':'Oraindik ez dago erregistrorik','gl-ES':'Sen rexistros aínda' },
  'ai_consent.records_count': { 'en-US':'{} consents recorded','fr-FR':'{} consentements enregistrés','ca-ES':'{} consentiments registrats','eu-ES':'{} baimen erregistratuta','gl-ES':'{} consentimentos rexistrados' },
  'ai_consent.records_count_singular': { 'en-US':'1 consent recorded','fr-FR':'1 consentement enregistré','ca-ES':'1 consentiment registrat','eu-ES':'1 baimen erregistratuta','gl-ES':'1 consentimento rexistrado' },
  'ai_consent.gdpr_notice': { 'en-US':'Legal basis: Art. 6.1.a GDPR / Art. 7 LOPDGDD. Right of access: Art. 15 GDPR.','fr-FR':'Base juridique : Art. 6.1.a RGPD / Art. 7 LOPDGDD. Droit d\'accès : Art. 15 RGPD.','ca-ES':'Base jurídica: Art. 6.1.a RGPD / Art. 7 LOPDGDD. Dret d\'accés: Art. 15 RGPD.','eu-ES':'Oinarri juridikoa: Art. 6.1.a GDPR / Art. 7 LOPDGDD. Sarbide-eskubidea: Art. 15 GDPR.','gl-ES':'Base xurídica: Art. 6.1.a RXPD / Art. 7 LOPDGDD. Dereito de acceso: Art. 15 RXPD.' },
  'ai_consent.accepted': { 'en-US':'ACCEPTED','fr-FR':'ACCEPTÉ','ca-ES':'ACCEPTAT','eu-ES':'ONARTUTA','gl-ES':'ACEPTADO' },
  'ai_consent.provider': { 'en-US':'AI Provider','fr-FR':'Fournisseur IA','ca-ES':'Proveïdor d\'IA','eu-ES':'AI Hornitzailea','gl-ES':'Provedor de IA' },
  'ai_consent.purpose': { 'en-US':'Purpose','fr-FR':'Finalité','ca-ES':'Finalitat','eu-ES':'Xedea','gl-ES':'Finalidade' },
  'ai_consent.data_sent': { 'en-US':'Data sent to provider','fr-FR':'Données envoyées au fournisseur','ca-ES':'Dades enviades al proveïdor','eu-ES':'Hornitzaileari bidalitako datuak','gl-ES':'Datos enviados ao provedor' },
  'ai_consent.reference_property': { 'en-US':'Reference property','fr-FR':'Bien de référence','ca-ES':'Immoble de referència','eu-ES':'Erreferentzia-propietatea','gl-ES':'Inmoble de referencia' },
  'ai_consent.record_id': { 'en-US':'Record #{}','fr-FR':'Enregistrement #{}','ca-ES':'Registre #{}','eu-ES':'Erregistroa #{}','gl-ES':'Rexistro #{}' },
  'ai_consent.version': { 'en-US':'Version {}','fr-FR':'Version {}','ca-ES':'Versió {}','eu-ES':'Bertsioa {}','gl-ES':'Versión {}' },
  'ai_consent.empty_state': { 'en-US':'No consent records','fr-FR':'Aucun enregistrement de consentement','ca-ES':'Sense registres de consentiment','eu-ES':'Ez dago baimenaren erregistrorik','gl-ES':'Sen rexistros de consentimento' },
  'ai_consent.empty_state_desc': { 'en-US':'When you use AI features (property description, identity verification…) and give your consent, records will appear here.','fr-FR':'Lorsque vous utilisez des fonctionnalités IA (description du bien, vérification d\'identité…) et donnez votre consentement, les enregistrements apparaîtront ici.','ca-ES':'Quan usis funcions d\'IA (descripció d\'immoble, verificació d\'identitat…) i atorguis el teu consentiment, els registres apareixeran aquí.','eu-ES':'AI funtzioak erabiltzen dituzunean (propietatearen deskribapena, nortasunaren egiaztapena...) eta zure baimena ematen duzunean, erregistroak hemen agertuko dira.','gl-ES':'Cando uses funcións de IA (descrición de inmoble, verificación de identidade…) e outorgues o teu consentimento, os rexistros aparecerán aquí.' },
  'ai_consent.back_home': { 'en-US':'Back to home','fr-FR':'Retour à l\'accueil','ca-ES':'Tornar a l\'inici','eu-ES':'Itzuli hasierara','gl-ES':'Volver ao inicio' },
  'ai_consent.error_loading': { 'en-US':'Could not load consent history','fr-FR':'Impossible de charger l\'historique des consentements','ca-ES':'No s\'ha pogut carregar l\'historial','eu-ES':'Ezin da baimenen historia kargatu','gl-ES':'Non se puido cargar o historial' },
  'ai_consent.button_title': { 'en-US':'AI Consent History','fr-FR':'Historique des Consentements IA','ca-ES':'Historial de Consentiments IA','eu-ES':'AI Baimenen Historia','gl-ES':'Historial de Consentimentos IA' },
  'ai_consent.button_desc': { 'en-US':'Review the AI uses you have authorised','fr-FR':'Vérifiez les utilisations IA que vous avez autorisées','ca-ES':'Revisa els usos d\'IA que has autoritzat','eu-ES':'Baimendutako AI erabilerak berrikusi','gl-ES':'Revisa os usos de IA que autorizaches' },
  // PROPERTY WIZARD
  'property_wizard.market_ref_detail': { 'en-US':'({} EUR/m², {})','fr-FR':'({} EUR/m², {})','ca-ES':'({} EUR/m², {})','eu-ES':'({} EUR/m², {})','gl-ES':'({} EUR/m², {})' },
};

const langs = ['en-US','en-GB','en-CA','fr-FR','fr-CA','ca-ES','va-ES','eu-ES','gl-ES'];

langs.forEach(lang => {
  const fp = base + lang + '.json';
  const json = JSON.parse(fs.readFileSync(fp, 'utf8'));
  let count = 0;

  // Fix time months/weekdays
  let src = lang;
  if (lang === 'en-GB' || lang === 'en-CA') src = 'en-US';
  if (lang === 'fr-CA') src = 'fr-FR';
  if (lang === 'va-ES') src = 'ca-ES';

  const td = timeData[src];
  if (td) {
    if (!json.time) json.time = {};
    if (!json.time.months) json.time.months = {};
    if (!json.time.short_months) json.time.short_months = {};
    if (!json.time.weekdays_short) json.time.weekdays_short = {};
    Object.assign(json.time.months, td.months_num, td.months_str);
    Object.assign(json.time.short_months, td.short_num, td.short_str);
    Object.assign(json.time.weekdays_short, td.wd_num, td.wd_str);
    count += 24 + 24 + 14; // approximate
  }

  // Apply text translations
  Object.entries(translations).forEach(([path, vals]) => {
    const val = vals[src] || vals['en-US'];
    if (val !== undefined) {
      setVal(json, path, val);
      count++;
    }
  });

  fs.writeFileSync(fp, JSON.stringify(json, null, 2), 'utf8');
  console.log(lang + ': updated ~' + count + ' time+common+remaining keys');
});

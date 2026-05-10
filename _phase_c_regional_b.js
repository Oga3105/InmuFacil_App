'use strict';
// Phase C Regional B: solvency second set + verification + kyc + second_buyer
// Languages: ca-ES, va-ES, eu-ES, gl-ES, fr-FR, fr-CA, en-GB, en-CA
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
// SOLVENCY second key set
// ============================================================
const solvencyCa = {
  'solvency.home_button': 'Inici',
  'solvency.step_label': 'Pas {current} de {total}',
  'solvency.step_purchase_type': 'Tipus de Compra',
  'solvency.step_awareness': 'Consciència Financera',
  'solvency.step_dna': 'ADN Financer',
  'solvency.prev_button': 'Anterior',
  'solvency.continue_button': 'Continua',
  'solvency.get_passport': 'Obtenir el meu Passaport',
  'solvency.error_saving': 'Error en desar: {error}',
  'solvency.page0_title': 'Tipus de compra',
  'solvency.page0_subtitle': 'Per personalitzar el teu passaport necessitem saber quants titulars participen en la compra.',
  'solvency.buyer_solo_title': 'Només jo',
  'solvency.buyer_solo_subtitle': 'Compra individual. Només tu com a titular.',
  'solvency.buyer_joint_title': 'Amb algú més',
  'solvency.buyer_joint_subtitle': 'Compra conjunta: parella, familiar o altre cotitular.',
  'solvency.joint_info': "Perfecte. En els passos següents introdueix les dades financeres SUMADES de tots dos titulars. Més endavant sol·licitarem la verificació d'identitat del segon titular.",
  'solvency.disclaimer_title': 'Avís de Responsabilitat Civil',
  'solvency.disclaimer_read_before': 'Llegeix atentament abans de continuar',
  'solvency.disclaimer_text': "Aquest Passaport de Solvència és una declaració voluntària i veraç de la teva situació financera. La informació que proporcionis no és verificada per InmuFácil i el seu ús indegut pot comportar responsabilitat civil.\n\nInmuFácil actua com a plataforma neutral. La decisió final d'acceptar o rebutjar una oferta basant-se en aquest passaport correspon exclusivament a cada venedor.\n\nLes teves dades es processen d'acord amb el RGPD/LOPD i s'eliminaran automàticament als 90 dies.",
  'solvency.disclaimer_accept': "He llegit i accepto els termes de responsabilitat. Declaro que la informació que proporcionaré és veraç.",
  'solvency.awareness_title': 'Consciència Financera',
  'solvency.awareness_subtitle': 'L\'\"Advocat del Diable\" — siguem honestos',
  'solvency.costs_question_solo': "Coneixes les despeses addicionals de la compra?\n(ITP/IVA, notaria, gestoria, registre...)",
  'solvency.costs_question_joint': "Heu tingut en compte les despeses addicionals de la compra?\n(ITP/IVA, notaria, gestoria, registre...)",
  'solvency.costs_hint': "Generalment un 10-15% addicional sobre el preu de compra.",
  'solvency.debt_ratio_title': "Ràtio d'endeutament mensual",
  'solvency.debt_ratio_subtitle': 'Deutes mensuals totals ÷ ingressos nets mensuals',
  'solvency.emergency_question_solo': "Comptes amb un fons d'emergència d'almenys 3-6 mesos de despeses?",
  'solvency.emergency_question_joint': "Compteu amb un fons d'emergència d'almenys 3-6 mesos de despeses?",
  'solvency.emergency_hint': "Independent dels diners per a la compra.",
  'solvency.yes': 'Sí',
  'solvency.no': 'No',
  'solvency.payment_question': "Com planifiques finançar la compra?",
  'solvency.payment_cash': 'Pagament al comptat',
  'solvency.payment_mortgage_approved': 'Hipoteca aprovada',
  'solvency.payment_mortgage_pending': 'Hipoteca en tramitació',
  'solvency.payment_savings_plus_mortgage': 'Estalvis + hipoteca',
  'solvency.payment_house_to_sell': "Venda d'habitatge actual",
  'solvency.payment_bridge_mortgage': 'Hipoteca pont',
  'solvency.payment_savings_only': 'Només estalvis (Sense banc encara)',
  'solvency.payment_no_process': 'Sense tràmits iniciats',
  'solvency.savings_question_solo': "Disposes d'estalvis inicials per a l'entrada i despeses?",
  'solvency.savings_question_joint': "Disposeu d'estalvis inicials per a l'entrada i despeses?",
  'solvency.savings_hint': "Habitualment entre un 20-30% del preu de la propietat.",
  'solvency.preapproval_question_solo': "Tens una preaprovació hipotecària d'un banc?",
  'solvency.preapproval_question_joint': "Teniu una preaprovació hipotecària d'un banc?",
  'solvency.dna_title': 'ADN Financer',
  'solvency.dna_subtitle': 'Càlcul personalitzat de viabilitat — opcional i privat',
  'solvency.dna_privacy_note': "Aquestes dades es xifren amb AES-256. El venedor MAI veu els teus ingressos ni deutes — només rep el resultat de viabilitat (Verd/Ambre/Vermell).",
  'solvency.income_label_solo': 'Ingressos nets mensuals',
  'solvency.income_label_joint': 'Ingressos nets mensuals (total compradors)',
  'solvency.income_hint': 'ex. 2.500',
  'solvency.savings_label_solo': 'Estalvis líquids totals',
  'solvency.savings_label_joint': 'Estalvis líquids totals (suma de compradors)',
  'solvency.savings_hint_field': 'ex. 50.000',
  'solvency.level_silver': 'PLATA',
  'solvency.retry': 'Reintentar',
  'solvency.expires_on': 'Expira el ',
  'solvency.silver': 'PLATA',
  'solvency.step_of': ' de ',
  'solvency.individual_purchase': 'Compra individual',
  'solvency.pts': ' pts',
  'solvency.co_titular': 'CO-TITULAR',
  'solvency.repeat_photo': 'Repetir foto',
  'solvency.capture_btn': 'Capturar',
};

const solvencyEu = {
  'solvency.home_button': 'Hasiera',
  'solvency.step_label': '{current}. urratsa {total}tik',
  'solvency.step_purchase_type': 'Erosketa Mota',
  'solvency.step_awareness': 'Finantza Kontzientzia',
  'solvency.step_dna': 'Finantza ADN',
  'solvency.prev_button': 'Aurrekoa',
  'solvency.continue_button': 'Jarraitu',
  'solvency.get_passport': 'Nire Pasaportea Lortu',
  'solvency.error_saving': 'Gordetzeko errorea: {error}',
  'solvency.page0_title': 'Erosketa mota',
  'solvency.page0_subtitle': 'Zure pasaportea pertsonalizatzeko, zenbat titular parte hartzen duten jakin behar dugu.',
  'solvency.buyer_solo_title': 'Ni bakarrik',
  'solvency.buyer_solo_subtitle': 'Banakako erosketa. Zu soilik titular gisa.',
  'solvency.buyer_joint_title': 'Norbait gehiagorekin',
  'solvency.buyer_joint_subtitle': 'Erosketa bateratua: bikotekidea, senidea edo beste kotitular bat.',
  'solvency.joint_info': 'Ezin hobea. Hurrengo urratseetan bi titularren finantza datuak BATURIK sartu. Geroago bigarren titularraren identitate egiaztatpena eskatuko dugu.',
  'solvency.disclaimer_title': 'Erantzukizun Zibil Oharra',
  'solvency.disclaimer_read_before': 'Irakurri arretaz jarraitu aurretik',
  'solvency.disclaimer_text': 'Solventzia Pasaporte hau zure egoera finantzariaren borondatezko eta egiazko adierazpena da. Emandako informazioa InmuFácil-ek egiaztatu gabe dago eta bere erabilera okerrak erantzukizun zibila ekar dezake.\n\nInmuFácil plataforma neutral gisa jarduten du. Pasaporte honetan oinarrituta eskaintza onartzeko edo baztertzeko azken erabakia saltzaile bakoitzari dagokie.\n\nZure datuak RGPD/LOPD-ren arabera prozesatzen dira eta automatikoki ezabatuko dira 90 egunetan.',
  'solvency.disclaimer_accept': 'Irakurri eta erantzukizun baldintzak onartzen ditut. Emango dudan informazioa egiazkotzat deklaratzen dut.',
  'solvency.awareness_title': 'Finantza Kontzientzia',
  'solvency.awareness_subtitle': '"Debruaren Abokatu" — zintzoak izan gaitezen',
  'solvency.costs_question_solo': 'Badakizu erosketan dauden gastu osagarriak?\n(ITP/BEZ, notaria, gestoría, erregistroa...)',
  'solvency.costs_question_joint': 'Kontutan hartu al duzue erosketan dauden gastu osagarriak?\n(ITP/BEZ, notaria, gestoría, erregistroa...)',
  'solvency.costs_hint': 'Oro har erosketa prezioaren gaineko %10-15 osagarria.',
  'solvency.debt_ratio_title': 'Hileko zorpen tasa',
  'solvency.debt_ratio_subtitle': 'Hileko zor guztiak ÷ hileko sarrera garbiak',
  'solvency.emergency_question_solo': 'Badaukazu gutxienez 3-6 hilabeteko gastuen larrialdi funtsa?',
  'solvency.emergency_question_joint': 'Badaukete gutxienez 3-6 hilabeteko gastuen larrialdi funtsa?',
  'solvency.emergency_hint': 'Erosketa diruarengandik aparte.',
  'solvency.yes': 'Bai',
  'solvency.no': 'Ez',
  'solvency.payment_question': 'Nola planeatu duzu erosketa finantzatzea?',
  'solvency.payment_cash': 'Ordainketa eskudirutan',
  'solvency.payment_mortgage_approved': 'Hipoteka onartua',
  'solvency.payment_mortgage_pending': 'Hipoteka izapidetzen',
  'solvency.payment_savings_plus_mortgage': 'Aurrezkiak + hipoteka',
  'solvency.payment_house_to_sell': 'Uneko etxebizitzaren salmenta',
  'solvency.payment_bridge_mortgage': 'Zubia hipoteka',
  'solvency.payment_savings_only': 'Aurrezkiak soilik (Bankurik gabe oraindik)',
  'solvency.payment_no_process': 'Izapiderik hasi gabe',
  'solvency.savings_question_solo': 'Badaukazu hasierako aurrezkiak sarrera eta gastuetarako?',
  'solvency.savings_question_joint': 'Badaukete hasierako aurrezkiak sarrera eta gastuetarako?',
  'solvency.savings_hint': 'Normalean propietatearen prezioaren %20-30 artean.',
  'solvency.preapproval_question_solo': 'Badaukazu banku baten hipoteka aurre-onespena?',
  'solvency.preapproval_question_joint': 'Badaukete banku baten hipoteka aurre-onespena?',
  'solvency.dna_title': 'Finantza ADN',
  'solvency.dna_subtitle': 'Bideragarritasunaren kalkulu pertsonalizatua — aukerazkoa eta pribatua',
  'solvency.dna_privacy_note': 'Datu hauek AES-256-rekin enkriptatzen dira. Saltzaileak INOIZ ez ditu zure sarrerak edo zorrak ikusten — bideragarritasun emaitza soilik jasotzen du (Berdea/Horia/Gorria).',
  'solvency.income_label_solo': 'Hileko sarrera garbiak',
  'solvency.income_label_joint': 'Hileko sarrera garbiak (erosleak guztira)',
  'solvency.income_hint': 'ad. 2.500',
  'solvency.savings_label_solo': 'Aurrezki likido guztiak',
  'solvency.savings_label_joint': 'Aurrezki likido guztiak (erosleen batura)',
  'solvency.savings_hint_field': 'ad. 50.000',
  'solvency.level_silver': 'ZILAR',
  'solvency.retry': 'Berriro saiatu',
  'solvency.expires_on': 'Iraungi da ',
  'solvency.silver': 'ZILAR',
  'solvency.step_of': ' / ',
  'solvency.individual_purchase': 'Banakako erosketa',
  'solvency.pts': ' puntu',
  'solvency.co_titular': 'KO-TITULARRA',
  'solvency.repeat_photo': 'Argazkia errepikatu',
  'solvency.capture_btn': 'Argazkia atera',
};

const solvencyGl = {
  'solvency.home_button': 'Inicio',
  'solvency.step_label': 'Paso {current} de {total}',
  'solvency.step_purchase_type': 'Tipo de Compra',
  'solvency.step_awareness': 'Conciencia Financeira',
  'solvency.step_dna': 'ADN Financeiro',
  'solvency.prev_button': 'Anterior',
  'solvency.continue_button': 'Continuar',
  'solvency.get_passport': 'Obter o meu Pasaporte',
  'solvency.error_saving': 'Erro ao gardar: {error}',
  'solvency.page0_title': 'Tipo de compra',
  'solvency.page0_subtitle': 'Para personalizar o teu pasaporte necesitamos saber cantos titulares participan na compra.',
  'solvency.buyer_solo_title': 'Só eu',
  'solvency.buyer_solo_subtitle': 'Compra individual. Só ti como titular.',
  'solvency.buyer_joint_title': 'Con alguén máis',
  'solvency.buyer_joint_subtitle': 'Compra conxunta: parella, familiar ou outro cotitular.',
  'solvency.joint_info': 'Perfecto. Nos seguintes pasos introduce os datos financeiros SUMADOS de ambos titulares. Máis adiante solicitaremos a verificación de identidade do segundo titular.',
  'solvency.disclaimer_title': 'Aviso de Responsabilidade Civil',
  'solvency.disclaimer_read_before': 'Le atentamente antes de continuar',
  'solvency.disclaimer_text': 'Este Pasaporte de Solvencia é unha declaración voluntaria e veraz da túa situación financeira. A información que proporciones non é verificada por InmuFácil e o seu uso indebido pode acarrear responsabilidade civil.\n\nInmuFácil actúa como plataforma neutral. A decisión final de aceptar ou rexeitar unha oferta baseándose neste pasaporte corresponde exclusivamente a cada vendedor.\n\nOs teus datos son procesados conforme ao RXPD/LOPD e eliminaranse automaticamente aos 90 días.',
  'solvency.disclaimer_accept': 'Lin e acepto os termos de responsabilidade. Declaro que a información que vou proporcionar é veraz.',
  'solvency.awareness_title': 'Conciencia Financeira',
  'solvency.awareness_subtitle': 'O "Avogado do Diaño" — sexamos honestos',
  'solvency.costs_question_solo': 'Coñeces os gastos adicionais da compra?\n(ITP/IVE, notaría, xestoría, rexistro...)',
  'solvency.costs_question_joint': 'Tivestes en conta os gastos adicionais da compra?\n(ITP/IVE, notaría, xestoría, rexistro...)',
  'solvency.costs_hint': 'Xeralmente un 10-15% adicional sobre o prezo de compra.',
  'solvency.debt_ratio_title': 'Ratio de endebedamento mensual',
  'solvency.debt_ratio_subtitle': 'Débedas mensuais totais ÷ ingresos netos mensuais',
  'solvency.emergency_question_solo': 'Contas cun fondo de emerxencia de polo menos 3-6 meses de gastos?',
  'solvency.emergency_question_joint': 'Contades cun fondo de emerxencia de polo menos 3-6 meses de gastos?',
  'solvency.emergency_hint': 'Independente do diñeiro para a compra.',
  'solvency.yes': 'Si',
  'solvency.no': 'Non',
  'solvency.payment_question': 'Como planeas financiar a compra?',
  'solvency.payment_cash': 'Pago ao contado',
  'solvency.payment_mortgage_approved': 'Hipoteca aprobada',
  'solvency.payment_mortgage_pending': 'Hipoteca en tramitación',
  'solvency.payment_savings_plus_mortgage': 'Aforros + hipoteca',
  'solvency.payment_house_to_sell': 'Venda de vivenda actual',
  'solvency.payment_bridge_mortgage': 'Hipoteca ponte',
  'solvency.payment_savings_only': 'Só aforros (Sen banco aínda)',
  'solvency.payment_no_process': 'Sen trámites iniciados',
  'solvency.savings_question_solo': 'Dispós de aforros iniciais para a entrada e gastos?',
  'solvency.savings_question_joint': 'Dispondes de aforros iniciais para a entrada e gastos?',
  'solvency.savings_hint': 'Habitualmente entre un 20-30% do prezo da propiedade.',
  'solvency.preapproval_question_solo': 'Tes unha preaprobación hipotecaria dun banco?',
  'solvency.preapproval_question_joint': 'Tendes unha preaprobación hipotecaria dun banco?',
  'solvency.dna_title': 'ADN Financeiro',
  'solvency.dna_subtitle': 'Cálculo personalizado de viabilidade — opcional e privado',
  'solvency.dna_privacy_note': 'Estes datos cífranse con AES-256. O vendedor NUNCA ve os teus ingresos nin débedas — só recibe o resultado de viabilidade (Verde/Ámbar/Vermello).',
  'solvency.income_label_solo': 'Ingresos netos mensuais',
  'solvency.income_label_joint': 'Ingresos netos mensuais (total compradores)',
  'solvency.income_hint': 'ex. 2.500',
  'solvency.savings_label_solo': 'Aforros líquidos totais',
  'solvency.savings_label_joint': 'Aforros líquidos totais (suma de compradores)',
  'solvency.savings_hint_field': 'ex. 50.000',
  'solvency.level_silver': 'PRATA',
  'solvency.retry': 'Reintentar',
  'solvency.expires_on': 'Expira o ',
  'solvency.silver': 'PRATA',
  'solvency.step_of': ' de ',
  'solvency.individual_purchase': 'Compra individual',
  'solvency.pts': ' pts',
  'solvency.co_titular': 'CO-TITULAR',
  'solvency.repeat_photo': 'Repetir foto',
  'solvency.capture_btn': 'Capturar',
};

const solvencyFr = {
  'solvency.home_button': 'Accueil',
  'solvency.step_label': 'Étape {current} sur {total}',
  'solvency.step_purchase_type': "Type d'Achat",
  'solvency.step_awareness': 'Conscience Financière',
  'solvency.step_dna': 'ADN Financier',
  'solvency.prev_button': 'Précédent',
  'solvency.continue_button': 'Continuer',
  'solvency.get_passport': 'Obtenir mon Passeport',
  'solvency.error_saving': 'Erreur lors de la sauvegarde : {error}',
  'solvency.page0_title': "Type d'achat",
  'solvency.page0_subtitle': "Pour personnaliser votre passeport, nous devons savoir combien de titulaires participent à l'achat.",
  'solvency.buyer_solo_title': 'Moi seul(e)',
  'solvency.buyer_solo_subtitle': 'Achat individuel. Vous êtes le seul titulaire.',
  'solvency.buyer_joint_title': 'Avec quelqu\'un d\'autre',
  'solvency.buyer_joint_subtitle': 'Achat conjoint : partenaire, membre de la famille ou autre co-titulaire.',
  'solvency.joint_info': "Parfait. Dans les étapes suivantes, entrez les données financières COMBINÉES des deux titulaires. Plus tard, nous demanderons la vérification d'identité du second titulaire.",
  'solvency.disclaimer_title': 'Avis de Responsabilité Civile',
  'solvency.disclaimer_read_before': 'Lisez attentivement avant de continuer',
  'solvency.disclaimer_text': "Ce Passeport de Solvabilité est une déclaration volontaire et sincère de votre situation financière. Les informations fournies ne sont pas vérifiées par InmuFácil et leur utilisation abusive peut entraîner une responsabilité civile.\n\nInmuFácil agit en tant que plateforme neutre. La décision finale d'accepter ou de refuser une offre sur la base de ce passeport appartient exclusivement à chaque vendeur.\n\nVos données sont traitées conformément au RGPD et seront automatiquement supprimées après 90 jours.",
  'solvency.disclaimer_accept': "J'ai lu et j'accepte les conditions de responsabilité. Je déclare que les informations que je vais fournir sont sincères.",
  'solvency.awareness_title': 'Conscience Financière',
  'solvency.awareness_subtitle': 'L\'«Avocat du Diable» — soyons honnêtes',
  'solvency.costs_question_solo': "Connaissez-vous les frais supplémentaires liés à l'achat ?\n(Taxes, notaire, frais de gestion, enregistrement...)",
  'solvency.costs_question_joint': "Avez-vous pris en compte les frais supplémentaires liés à l'achat ?\n(Taxes, notaire, frais de gestion, enregistrement...)",
  'solvency.costs_hint': "Généralement 10 à 15 % supplémentaires sur le prix d'achat.",
  'solvency.debt_ratio_title': "Taux d'endettement mensuel",
  'solvency.debt_ratio_subtitle': 'Total des dettes mensuelles ÷ revenus nets mensuels',
  'solvency.emergency_question_solo': "Disposez-vous d'un fonds d'urgence d'au moins 3 à 6 mois de dépenses ?",
  'solvency.emergency_question_joint': "Disposez-vous d'un fonds d'urgence d'au moins 3 à 6 mois de dépenses ?",
  'solvency.emergency_hint': "Indépendamment de l'argent pour l'achat.",
  'solvency.yes': 'Oui',
  'solvency.no': 'Non',
  'solvency.payment_question': "Comment prévoyez-vous de financer l'achat ?",
  'solvency.payment_cash': 'Paiement comptant',
  'solvency.payment_mortgage_approved': 'Prêt immobilier approuvé',
  'solvency.payment_mortgage_pending': 'Prêt immobilier en cours',
  'solvency.payment_savings_plus_mortgage': 'Épargne + prêt immobilier',
  'solvency.payment_house_to_sell': 'Vente du logement actuel',
  'solvency.payment_bridge_mortgage': 'Prêt relais',
  'solvency.payment_savings_only': "Épargne uniquement (Pas encore de banque)",
  'solvency.payment_no_process': 'Aucune démarche engagée',
  'solvency.savings_question_solo': "Disposez-vous d'économies initiales pour l'apport et les frais ?",
  'solvency.savings_question_joint': "Disposez-vous d'économies initiales pour l'apport et les frais ?",
  'solvency.savings_hint': "Généralement entre 20 et 30 % du prix du bien.",
  'solvency.preapproval_question_solo': "Avez-vous une pré-approbation de prêt immobilier d'une banque ?",
  'solvency.preapproval_question_joint': "Avez-vous une pré-approbation de prêt immobilier d'une banque ?",
  'solvency.dna_title': 'ADN Financier',
  'solvency.dna_subtitle': 'Calcul personnalisé de viabilité — optionnel et privé',
  'solvency.dna_privacy_note': "Ces données sont chiffrées avec AES-256. Le vendeur ne voit JAMAIS vos revenus ni vos dettes — il reçoit uniquement le résultat de viabilité (Vert/Amber/Rouge).",
  'solvency.income_label_solo': 'Revenus nets mensuels',
  'solvency.income_label_joint': 'Revenus nets mensuels (total acheteurs)',
  'solvency.income_hint': 'ex. 2 500',
  'solvency.savings_label_solo': 'Épargne liquide totale',
  'solvency.savings_label_joint': 'Épargne liquide totale (somme des acheteurs)',
  'solvency.savings_hint_field': 'ex. 50 000',
  'solvency.level_silver': 'ARGENT',
  'solvency.retry': 'Réessayer',
  'solvency.expires_on': 'Expire le ',
  'solvency.silver': 'ARGENT',
  'solvency.step_of': ' sur ',
  'solvency.individual_purchase': 'Achat individuel',
  'solvency.pts': ' pts',
  'solvency.co_titular': 'CO-TITULAIRE',
  'solvency.repeat_photo': 'Reprendre la photo',
  'solvency.capture_btn': 'Capturer',
};

// ============================================================
// VERIFICATION translations
// ============================================================
const verificationCa = {
  'verification.home_button': 'Inici',
  'verification.session_expired': 'La teva sessió ha caducat',
  'verification.login_again_hint': 'Inicia sessió de nou per continuar.',
  'verification.login_button': 'Inicia sessió',
  'verification.retry': 'Reintentar',
  'verification.not_started_title': 'Verifica la teva identitat',
  'verification.not_started_body': "Encara no has enviat els teus documents. Completa la verificació per accedir a totes les funcionalitats.",
  'verification.start_button': 'Inicia la verificació',
  'verification.in_progress_badge': 'VERIFICACIÓ EN CURS',
  'verification.pending_title': 'Estem revisant els teus documents',
  'verification.pending_body': 'El procés de verificació pot trigar fins a 24 hores.',
  'verification.step_sent': 'Enviat',
  'verification.step_validating': 'Validant',
  'verification.step_done': 'Completat',
  'verification.sent_date': 'Enviat el {date}',
  'verification.back_home': "Tornar a l'inici",
  'verification.resubmit': 'Tornar a enviar documents',
  'verification.approved_banner': 'IDENTITAT VERIFICADA',
  'verification.approved_status': 'ESTAT: VERIFICAT',
  'verification.approved_body': "La teva identitat ha estat verificada correctament.",
  'verification.publish_property': 'Publicar Immoble',
  'verification.back_profile': 'Tornar al perfil',
  'verification.rejected_banner': 'VERIFICACIÓ FALLIDA',
  'verification.rejected_title': 'No hem pogut verificar la teva identitat',
  'verification.rejection_reason_label': 'Motiu del rebuig:',
  'verification.service_unavailable': "El servei de verificació no està disponible en aquest moment. Torna-ho a intentar més tard.",
  'verification.rejected_hint': "Pots tornar a enviar els teus documents corregint els errors indicats.",
  'verification.retry_button': 'Reintentar la Verificació',
};

const verificationEu = {
  'verification.home_button': 'Hasiera',
  'verification.session_expired': 'Zure saioa iraungitu da',
  'verification.login_again_hint': 'Hasi saioa berriro jarraitzeko.',
  'verification.login_button': 'Saioa hasi',
  'verification.retry': 'Berriro saiatu',
  'verification.not_started_title': 'Egiaztatu zure identitatea',
  'verification.not_started_body': 'Oraindik ez dituzu zure dokumentuak bidali. Bete egiaztapena funtzionalitate guztietara sartzeko.',
  'verification.start_button': 'Hasi egiaztapena',
  'verification.in_progress_badge': 'EGIAZTAPENA MARTXAN',
  'verification.pending_title': 'Zure dokumentuak berrikustzen ari gara',
  'verification.pending_body': 'Egiaztapen prozesuak 24 ordu arte iraun dezake.',
  'verification.step_sent': 'Bidalita',
  'verification.step_validating': 'Balioztatzen',
  'verification.step_done': 'Amaituta',
  'verification.sent_date': '{date}an bidalita',
  'verification.back_home': 'Hasierara itzuli',
  'verification.resubmit': 'Dokumentuak berriro bidali',
  'verification.approved_banner': 'IDENTITATEA EGIAZTATUTA',
  'verification.approved_status': 'EGOERA: EGIAZTATUTA',
  'verification.approved_body': 'Zure identitatea behar bezala egiaztatu da.',
  'verification.publish_property': 'Higiezina Argitaratu',
  'verification.back_profile': 'Profilera itzuli',
  'verification.rejected_banner': 'EGIAZTAPEN HUTS EGINA',
  'verification.rejected_title': 'Ezin izan dugu zure identitatea egiaztatu',
  'verification.rejection_reason_label': 'Baztertze arrazoia:',
  'verification.service_unavailable': 'Egiaztapen zerbitzua ez dago eskuragarri momentu honetan. Saiatu beranduago.',
  'verification.rejected_hint': 'Adierazitako akatsak zuzenduz dokumentuak berriro bidal ditzakezu.',
  'verification.retry_button': 'Egiaztapena Berriro Saiatu',
};

const verificationGl = {
  'verification.home_button': 'Inicio',
  'verification.session_expired': 'A túa sesión caducou',
  'verification.login_again_hint': 'Inicia sesión de novo para continuar.',
  'verification.login_button': 'Iniciar sesión',
  'verification.retry': 'Reintentar',
  'verification.not_started_title': 'Verifica a túa identidade',
  'verification.not_started_body': 'Aínda non enviaches os teus documentos. Completa a verificación para acceder a todas as funcionalidades.',
  'verification.start_button': 'Iniciar verificación',
  'verification.in_progress_badge': 'VERIFICACIÓN EN CURSO',
  'verification.pending_title': 'Estamos revisando os teus documentos',
  'verification.pending_body': 'O proceso de verificación pode tardar ata 24 horas.',
  'verification.step_sent': 'Enviado',
  'verification.step_validating': 'Validando',
  'verification.step_done': 'Completado',
  'verification.sent_date': 'Enviado o {date}',
  'verification.back_home': 'Volver ao Inicio',
  'verification.resubmit': 'Volver a enviar documentos',
  'verification.approved_banner': 'IDENTIDADE VERIFICADA',
  'verification.approved_status': 'ESTADO: VERIFICADO',
  'verification.approved_body': 'A túa identidade foi verificada correctamente.',
  'verification.publish_property': 'Publicar Inmoble',
  'verification.back_profile': 'Volver ao perfil',
  'verification.rejected_banner': 'VERIFICACIÓN FALLIDA',
  'verification.rejected_title': 'Non puidemos verificar a túa identidade',
  'verification.rejection_reason_label': 'Motivo do rexeitamento:',
  'verification.service_unavailable': 'O servizo de verificación non está dispoñible neste momento. Téntao de novo máis tarde.',
  'verification.rejected_hint': 'Podes volver a enviar os teus documentos corrixindo os erros indicados.',
  'verification.retry_button': 'Reintentar Verificación',
};

const verificationFr = {
  'verification.home_button': 'Accueil',
  'verification.session_expired': 'Votre session a expiré',
  'verification.login_again_hint': 'Veuillez vous reconnecter pour continuer.',
  'verification.login_button': 'Se connecter',
  'verification.retry': 'Réessayer',
  'verification.not_started_title': 'Vérifiez votre identité',
  'verification.not_started_body': "Vous n'avez pas encore soumis vos documents. Complétez la vérification pour accéder à toutes les fonctionnalités.",
  'verification.start_button': 'Commencer la vérification',
  'verification.in_progress_badge': 'VÉRIFICATION EN COURS',
  'verification.pending_title': 'Nous examinons vos documents',
  'verification.pending_body': 'Le processus de vérification peut prendre jusqu\'à 24 heures.',
  'verification.step_sent': 'Envoyé',
  'verification.step_validating': 'Validation',
  'verification.step_done': 'Terminé',
  'verification.sent_date': 'Envoyé le {date}',
  'verification.back_home': "Retour à l'accueil",
  'verification.resubmit': 'Soumettre à nouveau',
  'verification.approved_banner': 'IDENTITÉ VÉRIFIÉE',
  'verification.approved_status': 'STATUT : VÉRIFIÉ',
  'verification.approved_body': 'Votre identité a été vérifiée avec succès.',
  'verification.publish_property': 'Publier un bien',
  'verification.back_profile': 'Retour au profil',
  'verification.rejected_banner': 'VÉRIFICATION ÉCHOUÉE',
  'verification.rejected_title': "Nous n'avons pas pu vérifier votre identité",
  'verification.rejection_reason_label': 'Raison du rejet :',
  'verification.service_unavailable': "Le service de vérification n'est pas disponible pour le moment. Veuillez réessayer plus tard.",
  'verification.rejected_hint': 'Vous pouvez soumettre à nouveau vos documents en corrigeant les erreurs indiquées.',
  'verification.retry_button': 'Réessayer la vérification',
};

// ============================================================
// KYC remaining
// ============================================================
const kycCa = {
  'kyc.title_badge': 'Verificar Identitat',
  'kyc.home_button': 'Inici',
  'kyc.discard_title': 'Cancel·lar la verificació?',
  'kyc.discard_content': "Si surts ara, els documents pujats no es desaran i hauràs de tornar a començar.",
  'kyc.stay_here': 'Seguir aquí',
  'kyc.confirm_cancel': 'Sí, cancel·la',
  'kyc.verify_title': 'Verifica la teva Identitat',
  'kyc.verify_subtitle': 'Confirmació de seguretat per a transaccions P2P segures.',
  'kyc.badge_verified_user': 'verified_user',
  'kyc.step_doc_type': 'Tipus de document',
  'kyc.step_scan': 'Escaneig de Document',
  'kyc.step_selfie': 'Prova de vida',
  'kyc.doc_front': 'Part Frontal',
  'kyc.doc_back': 'Part Posterior',
  'kyc.selfie_center_face': 'Centra el teu rostre',
  'kyc.selfie_lighting': "Il·luminació uniforme, sense accessoris",
  'kyc.selfie_retake': 'Repetir foto',
  'kyc.selfie_start_camera': 'Inicia la Càmera',
  'kyc.submit_button': 'Enviar Verificació',
  'kyc.terms_link': 'Termes de Servei',
  'kyc.privacy_link': 'Privacitat',
  'kyc.help_link': 'Ajuda',
  'kyc.retake_photo': 'Repetir foto',
  'kyc.dni': 'DNI',
  'kyc.nie': 'NIE',
  'kyc.error_reading_doc': 'Error en llegir el document.',
  'kyc.error_submitting': 'Error en enviar els documents.',
  'kyc.error_unexpected': 'Error inesperat.',
  'kyc.error_status': "Error en consultar l'estat.",
};

const kycEu = {
  'kyc.title_badge': 'Identitatea Egiaztatu',
  'kyc.home_button': 'Hasiera',
  'kyc.discard_title': 'Egiaztapena bertan behera utzi?',
  'kyc.discard_content': 'Orain irteten bazara, igotako dokumentuak ez dira gordeko eta berriro hasi beharko duzu.',
  'kyc.stay_here': 'Hemen geratu',
  'kyc.confirm_cancel': 'Bai, bertan behera utzi',
  'kyc.verify_title': 'Egiaztatu zure Identitatea',
  'kyc.verify_subtitle': 'P2P transakzio seguruen segurtasun konfirmazioa.',
  'kyc.badge_verified_user': 'verified_user',
  'kyc.step_doc_type': 'Agiri mota',
  'kyc.step_scan': 'Agiriaren Eskaneoa',
  'kyc.step_selfie': 'Bizitasun froga',
  'kyc.doc_front': 'Aurrealdea',
  'kyc.doc_back': 'Atzealdea',
  'kyc.selfie_center_face': 'Zentratu zure aurpegia',
  'kyc.selfie_lighting': 'Argiztapen uniformea, osagarririk gabe',
  'kyc.selfie_retake': 'Argazkia errepikatu',
  'kyc.selfie_start_camera': 'Kamera Hasi',
  'kyc.submit_button': 'Egiaztapena Bidali',
  'kyc.terms_link': 'Zerbitzu Baldintzak',
  'kyc.privacy_link': 'Pribatutasuna',
  'kyc.help_link': 'Laguntza',
  'kyc.retake_photo': 'Argazkia errepikatu',
  'kyc.dni': 'DNI',
  'kyc.nie': 'NIE',
  'kyc.error_reading_doc': 'Errorea dokumentua irakurtzerakoan.',
  'kyc.error_submitting': 'Errorea dokumentuak bidaltzean.',
  'kyc.error_unexpected': 'Ustekabeko errorea.',
  'kyc.error_status': 'Errorea egoera kontsultatzerakoan.',
};

const kycGl = {
  'kyc.title_badge': 'Verificar Identidade',
  'kyc.home_button': 'Inicio',
  'kyc.discard_title': 'Cancelar a verificación?',
  'kyc.discard_content': 'Se saes agora, os documentos subidos non se gardarán e terás que comezar de novo.',
  'kyc.stay_here': 'Seguir aquí',
  'kyc.confirm_cancel': 'Si, cancelar',
  'kyc.verify_title': 'Verifica a túa Identidade',
  'kyc.verify_subtitle': 'Confirmación de seguridade para transaccións P2P seguras.',
  'kyc.badge_verified_user': 'verified_user',
  'kyc.step_doc_type': 'Tipo de documento',
  'kyc.step_scan': 'Escaneo de Documento',
  'kyc.step_selfie': 'Proba de vida',
  'kyc.doc_front': 'Parte Frontal',
  'kyc.doc_back': 'Parte Traseira',
  'kyc.selfie_center_face': 'Centra o teu rostro',
  'kyc.selfie_lighting': 'Iluminación uniforme, sen accesorios',
  'kyc.selfie_retake': 'Repetir foto',
  'kyc.selfie_start_camera': 'Iniciar Cámara',
  'kyc.submit_button': 'Enviar Verificación',
  'kyc.terms_link': 'Termos de Servizo',
  'kyc.privacy_link': 'Privacidade',
  'kyc.help_link': 'Axuda',
  'kyc.retake_photo': 'Repetir foto',
  'kyc.dni': 'DNI',
  'kyc.nie': 'NIE',
  'kyc.error_reading_doc': 'Erro ao ler o documento.',
  'kyc.error_submitting': 'Erro ao enviar documentos.',
  'kyc.error_unexpected': 'Erro inesperado.',
  'kyc.error_status': 'Erro ao consultar o estado.',
};

const kycFr = {
  'kyc.title_badge': "Vérifier l'Identité",
  'kyc.home_button': 'Accueil',
  'kyc.discard_title': 'Annuler la vérification ?',
  'kyc.discard_content': "Si vous quittez maintenant, les documents téléchargés ne seront pas sauvegardés et vous devrez recommencer.",
  'kyc.stay_here': 'Rester ici',
  'kyc.confirm_cancel': 'Oui, annuler',
  'kyc.verify_title': 'Vérifiez votre Identité',
  'kyc.verify_subtitle': 'Confirmation de sécurité pour les transactions P2P sécurisées.',
  'kyc.badge_verified_user': 'verified_user',
  'kyc.step_doc_type': 'Type de document',
  'kyc.step_scan': 'Scan du Document',
  'kyc.step_selfie': 'Vitalité',
  'kyc.doc_front': 'Recto',
  'kyc.doc_back': 'Verso',
  'kyc.selfie_center_face': 'Centrez votre visage',
  'kyc.selfie_lighting': 'Éclairage uniforme, sans accessoires',
  'kyc.selfie_retake': 'Reprendre la photo',
  'kyc.selfie_start_camera': 'Démarrer la caméra',
  'kyc.submit_button': 'Soumettre la vérification',
  'kyc.terms_link': "Conditions d'utilisation",
  'kyc.privacy_link': 'Confidentialité',
  'kyc.help_link': 'Aide',
  'kyc.retake_photo': 'Reprendre la photo',
  'kyc.dni': 'DNI',
  'kyc.nie': 'NIE',
  'kyc.error_reading_doc': 'Erreur lors de la lecture du document.',
  'kyc.error_submitting': 'Erreur lors de la soumission des documents.',
  'kyc.error_unexpected': 'Erreur inattendue.',
  'kyc.error_status': "Erreur lors de la vérification du statut.",
};

// ============================================================
// SECOND_BUYER translations
// ============================================================
const secondBuyerCa = {
  'second_buyer.card_title': 'Dades del 2n Comprador',
  'second_buyer.card_subtitle': 'Introdueix les dades del segon titular de la compra.',
  'second_buyer.badge_cotitular': 'Co-titular',
  'second_buyer.full_name_label': 'Nom complet',
  'second_buyer.full_name_hint': 'Nom i cognoms',
  'second_buyer.full_name_error': 'Introdueix el nom complet',
  'second_buyer.email_hint': 'correu@exemple.com',
  'second_buyer.email_error': 'Introdueix un correu vàlid',
  'second_buyer.success_title': 'Identitat Verificada',
  'second_buyer.success_body': "La identitat del segon comprador ha estat verificada i les dades guardades de forma segura (AES-256).",
  'second_buyer.back_timeline': 'Tornar al timeline',
};

const secondBuyerEu = {
  'second_buyer.card_title': '2. Eroslearen Datuak',
  'second_buyer.card_subtitle': 'Sartu bigarren titularraren datuak.',
  'second_buyer.badge_cotitular': 'Ko-titularra',
  'second_buyer.full_name_label': 'Izen-abizenak',
  'second_buyer.full_name_hint': 'Izena eta abizenak',
  'second_buyer.full_name_error': 'Sartu izen-abizenak',
  'second_buyer.email_hint': 'helbidea@adibidea.com',
  'second_buyer.email_error': 'Sartu baliozko helbide elektroniko bat',
  'second_buyer.success_title': 'Identitatea Egiaztatuta',
  'second_buyer.success_body': 'Bigarren eroslearen identitatea egiaztatu eta datuak modu seguruan gorde dira (AES-256).',
  'second_buyer.back_timeline': 'Timelinera itzuli',
};

const secondBuyerGl = {
  'second_buyer.card_title': 'Datos do 2º Comprador',
  'second_buyer.card_subtitle': 'Introduce os datos do segundo titular da compra.',
  'second_buyer.badge_cotitular': 'Co-titular',
  'second_buyer.full_name_label': 'Nome completo',
  'second_buyer.full_name_hint': 'Nome e apelidos',
  'second_buyer.full_name_error': 'Introduce o nome completo',
  'second_buyer.email_hint': 'correo@exemplo.com',
  'second_buyer.email_error': 'Introduce un correo válido',
  'second_buyer.success_title': 'Identidade Verificada',
  'second_buyer.success_body': 'A identidade do segundo comprador foi verificada e os datos gardados de forma segura (AES-256).',
  'second_buyer.back_timeline': 'Volver ao timeline',
};

const secondBuyerFr = {
  'second_buyer.card_title': 'Données du 2e Acheteur',
  'second_buyer.card_subtitle': 'Saisissez les données du second titulaire de l\'achat.',
  'second_buyer.badge_cotitular': 'Co-titulaire',
  'second_buyer.full_name_label': 'Nom complet',
  'second_buyer.full_name_hint': 'Prénom et nom',
  'second_buyer.full_name_error': 'Veuillez entrer le nom complet',
  'second_buyer.email_hint': 'email@exemple.com',
  'second_buyer.email_error': 'Veuillez entrer un email valide',
  'second_buyer.success_title': 'Identité Vérifiée',
  'second_buyer.success_body': "L'identité du second acheteur a été vérifiée et les données sauvegardées de manière sécurisée (AES-256).",
  'second_buyer.back_timeline': 'Retour à la timeline',
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
const allCa = { ...solvencyCa, ...verificationCa, ...kycCa, ...secondBuyerCa };
applyDict('ca-ES', allCa);

// va-ES: copy Catalan
applyDict('va-ES', allCa);

// eu-ES
const allEu = { ...solvencyEu, ...verificationEu, ...kycEu, ...secondBuyerEu };
applyDict('eu-ES', allEu);

// gl-ES
const allGl = { ...solvencyGl, ...verificationGl, ...kycGl, ...secondBuyerGl };
applyDict('gl-ES', allGl);

// fr-FR
const allFr = { ...solvencyFr, ...verificationFr, ...kycFr, ...secondBuyerFr };
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

console.log('Done: _phase_c_regional_b');

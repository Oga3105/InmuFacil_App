const fs = require('fs');
const base = 'C:/Users/Os/.gemini/antigravity/scratch/InmuFacil_Project/frontend/assets/translations/';

function setVal(obj, path, val) {
  const parts = path.split('.');
  const last = parts.pop();
  const target = parts.reduce((o, k) => { if (!o[k]) o[k] = {}; return o[k]; }, obj);
  target[last] = val;
}

const translations = {
  'arras_interview.step1_title': { 'en-US':'Logistics and Notary','fr-FR':'Logistique et Notaire','ca-ES':'Logística i Notaria','eu-ES':'Logistika eta Notaria','gl-ES':'Loxística e Notaría' },
  'arras_interview.step1_subtitle': { 'en-US':'Step 1 of 3 — Deadlines, deposit and notary','fr-FR':'Étape 1 sur 3 — Délais, dépôt et notaire','ca-ES':'Pas 1 de 3 — Terminis, dipòsit i notaria','eu-ES':'1. urratsa 3-tik — Epeak, gordailua eta notaria','gl-ES':'Paso 1 de 3 — Prazos, depósito e notaría' },
  'arras_interview.step2_title': { 'en-US':'Security and Flexibility','fr-FR':'Sécurité et Flexibilité','ca-ES':'Seguretat i Flexibilitat','eu-ES':'Segurtasuna eta Malgutasuna','gl-ES':'Seguridade e Flexibilidade' },
  'arras_interview.step2_subtitle': { 'en-US':'Step 2 of 3 — Conditions and contingencies','fr-FR':'Étape 2 sur 3 — Conditions et contingences','ca-ES':'Pas 2 de 3 — Condicions i contingències','eu-ES':'2. urratsa 3-tik — Baldintzak eta kontingentzia','gl-ES':'Paso 2 de 3 — Condicións e continxencias' },
  'arras_interview.step3_title': { 'en-US':'Taxes and Charges','fr-FR':'Impôts et Charges','ca-ES':'Impostos i Càrregues','eu-ES':'Zergak eta Kargak','gl-ES':'Impostos e Cargas' },
  'arras_interview.step3_subtitle': { 'en-US':'Step 3 of 3 — Taxation and financing','fr-FR':'Étape 3 sur 3 — Fiscalité et financement','ca-ES':'Pas 3 de 3 — Fiscalitat i finançament','eu-ES':'3. urratsa 3-tik — Fiskalitatea eta finantzaketa','gl-ES':'Paso 3 de 3 — Fiscalidade e financiamento' },
  'arras_interview.hidden_defects_title': { 'en-US':'Accept hidden defects clause','fr-FR':'Accepter la clause de vices cachés','ca-ES':'Accepta clàusula de vicis ocults','eu-ES':'Ezkutuko akatsak klausula onartu','gl-ES':'Acepta cláusula de vicios ocultos' },
  'arras_interview.hidden_defects_sub': { 'en-US':'Art. 1484 CC — The seller is liable for hidden defects','fr-FR':'Art. 1484 CC — Le vendeur répond des vices cachés','ca-ES':'Art. 1484 CC — El venedor respon per defectes ocults','eu-ES':'Art. 1484 KZ — Saltzaileak ezkutuko akatsen erantzukizuna du','gl-ES':'Art. 1484 CC — O vendedor responde por defectos ocultos' },
  'arras_interview.community_debt_title': { 'en-US':'Retention for community debts','fr-FR':'Rétention pour dettes de copropriété','ca-ES':'Retenció per deutes de comunitat','eu-ES':'Erkidego-zorren atxikipena','gl-ES':'Retención por débedas de comunidade' },
  'arras_interview.community_debt_sub': { 'en-US':'Part of the price is withheld if the seller has outstanding debts','fr-FR':'Une partie du prix est retenue si le vendeur a des dettes en cours','ca-ES':'Es reté part del preu si el venedor té deutes pendents','eu-ES':'Prezioaren zati bat atxikitzen da saltzaileak zor ordaindu gabeak baditu','gl-ES':'Retense parte do prezo se o vendedor ten débedas pendentes' },
  'arras_interview.ibi_proration_title': { 'en-US':'IBI proration by days','fr-FR':'Proratisation de la taxe foncière par jours','ca-ES':'Prorateig d\'IBI per dies','eu-ES':'IBIren eguneko prorrateoa','gl-ES':'Prorrateo de IBI por días' },
  'arras_interview.ibi_proration_sub': { 'en-US':'The year\'s IBI is split proportionally between buyer and seller','fr-FR':'La taxe foncière de l\'année est répartie proportionnellement entre acheteur et vendeur','ca-ES':'L\'IBI de l\'any es reparteix proporcionalment entre comprador i venedor','eu-ES':'Urteko IBI erosleak eta saltzaileak proportzioz banatzen dute','gl-ES':'O IBI do ano repártese proporcionalmente entre comprador e vendedor' },
  'arras_interview.iban_hint': { 'en-US':'ES00 0000 0000 0000 0000 0000','fr-FR':'ES00 0000 0000 0000 0000 0000','ca-ES':'ES00 0000 0000 0000 0000 0000','eu-ES':'ES00 0000 0000 0000 0000 0000','gl-ES':'ES00 0000 0000 0000 0000 0000' },
  'arras_interview.iban_title': { 'en-US':'IBAN to receive the arras','fr-FR':'IBAN pour recevoir les arrhes','ca-ES':'IBAN per rebre les arres','eu-ES':'IBANa arrasen jasotzeko','gl-ES':'IBAN para recibir as arras' },
  'arras_interview.iban_encrypted': { 'en-US':'End-to-end encrypted — never visible to the buyer','fr-FR':'Chiffrement de bout en bout — jamais visible par l\'acheteur','ca-ES':'Xifrat extrem a extrem — mai visible per al comprador','eu-ES':'Muturretik muturrerako enkriptatuta — eroslearentzat inoiz ikusgai ez','gl-ES':'Cifrado de extremo a extremo — nunca visible ao comprador' },
  'arras_interview.iban_security_disclaimer': { 'en-US':'Your IBAN is stored encrypted with AES-256. The full account number and bank will appear in the contract for the arras payment.','fr-FR':'Votre IBAN est stocké chiffré avec AES-256. Le numéro complet et la banque apparaîtront dans le contrat pour le paiement des arrhes.','ca-ES':'El teu IBAN s\'emmagatzema xifrat amb AES-256. El número complet i l\'entitat bancària apareixeran al contracte per al pagament de les arres.','eu-ES':'Zure IBANA AES-256 zifratzarekin gordetzen da. Zenbaki osoa eta bankuaren izena kontratuaren arras-ordainketan agertuko dira.','gl-ES':'O teu IBAN almacénase cifrado con AES-256. O número completo e a entidade bancaria aparecerán no contrato para o pago das arras.' },
  'arras_interview.no_interview_info': { 'en-US':'No interview information available','fr-FR':'Aucune information d\'entretien disponible','ca-ES':'No hi ha informació de l\'entrevista','eu-ES':'Ez dago elkarrizketaren informaziorik','gl-ES':'Non hai información da entrevista' },
  'arras_interview.error_generating': { 'en-US':'Unknown error generating the contract','fr-FR':'Erreur inconnue lors de la génération du contrat','ca-ES':'Error desconegut en generar el contracte','eu-ES':'Errorea ezezaguna kontratuaren sortzean','gl-ES':'Erro descoñecido ao xerar o contrato' },
  'arras_interview.version_prefix': { 'en-US':'Version','fr-FR':'Version','ca-ES':'Versió','eu-ES':'Bertsioa','gl-ES':'Versión' },
  'arras_interview.shared_back': { 'en-US':'Back','fr-FR':'Retour','ca-ES':'Enrere','eu-ES':'Atzera','gl-ES':'Atrás' },
  'arras_interview.shared_continue': { 'en-US':'Continue','fr-FR':'Continuer','ca-ES':'Continuar','eu-ES':'Jarraitu','gl-ES':'Continuar' },
  'arras_interview.hub_buyer_title': { 'en-US':'Buyer','fr-FR':'Acheteur','ca-ES':'Comprador','eu-ES':'Eroslea','gl-ES':'Comprador' },
  'arras_interview.hub_seller_title': { 'en-US':'Seller','fr-FR':'Vendeur','ca-ES':'Venedor','eu-ES':'Saltzailea','gl-ES':'Vendedor' },
  'arras_interview.hub_completed': { 'en-US':'Completed','fr-FR':'Complété','ca-ES':'Completat','eu-ES':'Osatuta','gl-ES':'Completado' },
  'arras_interview.hub_pending': { 'en-US':'Pending','fr-FR':'En attente','ca-ES':'Pendent','eu-ES':'Zain','gl-ES':'Pendente' },
  'arras_interview.hub_view_edit': { 'en-US':'View / Edit','fr-FR':'Voir / Modifier','ca-ES':'Veure / Editar','eu-ES':'Ikusi / Editatu','gl-ES':'Ver / Editar' },
  'arras_interview.hub_start': { 'en-US':'Start','fr-FR':'Commencer','ca-ES':'Començar','eu-ES':'Hasi','gl-ES':'Empezar' },
  'arras_interview.hub_status_accepted': { 'en-US':'Contract accepted and ready for signing','fr-FR':'Contrat accepté et prêt pour la signature','ca-ES':'Contracte acceptat i llest per a firma','eu-ES':'Kontratua onartuta eta sinadurarako prest','gl-ES':'Contrato aceptado e listo para firma' },
  'arras_interview.hub_status_ready': { 'en-US':'Contract available for review','fr-FR':'Contrat disponible pour révision','ca-ES':'Contracte disponible per a revisió','eu-ES':'Kontratua berrikusteko eskuragarri','gl-ES':'Contrato dispoñible para revisión' },
  'arras_interview.hub_status_generating_ai': { 'en-US':'AI is drafting the contract...','fr-FR':'L\'IA rédige le contrat...','ca-ES':'La IA està redactant el contracte...','eu-ES':'AIak kontratua idazten ari da...','gl-ES':'A IA está redactando o contrato...' },
  'arras_interview.hub_status_generating_draft': { 'en-US':'Both interviews ready. Generating draft...','fr-FR':'Les deux entretiens sont prêts. Génération du brouillon...','ca-ES':'Ambdues entrevistes llestes. Generant esborrany...','eu-ES':'Bi elkarrizketak prest. Zirriborroa sortzen...','gl-ES':'Ambas entrevistas listas. Xerando borrador...' },
  'arras_interview.hub_status_default': { 'en-US':'Complete the interviews to generate the contract','fr-FR':'Complétez les entretiens pour générer le contrat','ca-ES':'Completa les entrevistes per generar el contracte','eu-ES':'Osatu elkarrizketak kontratua sortzeko','gl-ES':'Completa as entrevistas para xerar o contrato' },
  'arras_interview.hub_hero_title': { 'en-US':'Arras Contract','fr-FR':'Contrat d\'Arrhes','ca-ES':'Contracte d\'Arres','eu-ES':'Arras Kontratua','gl-ES':'Contrato de Arras' },
  'arras_interview.hub_hero_subtitle': { 'en-US':'Penitential','fr-FR':'Pénitentielles','ca-ES':'Penitencials','eu-ES':'Zigorgaitzak','gl-ES':'Penitenciais' },
  'arras_interview.hub_hero_arras_pct': { 'en-US':'{pct}% Arras','fr-FR':'{pct}% Arrhes','ca-ES':'{pct}% Arres','eu-ES':'%{pct} Arrasak','gl-ES':'{pct}% Arras' },
  'arras_interview.hub_hero_deadline': { 'en-US':'{days} day deadline','fr-FR':'{days} jours de délai','ca-ES':'{days} dies termini','eu-ES':'{days} egun epea','gl-ES':'{days} días prazo' },
  'arras_interview.hub_hero_buyer': { 'en-US':'Buyer','fr-FR':'Acheteur','ca-ES':'Comprador','eu-ES':'Eroslea','gl-ES':'Comprador' },
  'arras_interview.hub_hero_seller': { 'en-US':'Seller','fr-FR':'Vendeur','ca-ES':'Venedor','eu-ES':'Saltzailea','gl-ES':'Vendedor' },
  'arras_interview.hub_role_you': { 'en-US':'YOU','fr-FR':'VOUS','ca-ES':'TU','eu-ES':'ZU','gl-ES':'TI' },
  'arras_interview.hub_btn_view': { 'en-US':'View','fr-FR':'Voir','ca-ES':'Veure','eu-ES':'Ikusi','gl-ES':'Ver' },
  'arras_interview.hub_btn_start': { 'en-US':'Start','fr-FR':'Commencer','ca-ES':'Començar','eu-ES':'Hasi','gl-ES':'Empezar' },
  'arras_interview.hub_contract_accepted_title': { 'en-US':'Contract Accepted','fr-FR':'Contrat Accepté','ca-ES':'Contracte Acceptat','eu-ES':'Kontratua Onartuta','gl-ES':'Contrato Aceptado' },
  'arras_interview.hub_contract_accepted_desc': { 'en-US':'Both parties have validated the conditions','fr-FR':'Les deux parties ont validé les conditions','ca-ES':'Ambdues parts han validat les condicions','eu-ES':'Bi alderdiek baldintzak baliozkotzat jo dituzte','gl-ES':'Ambas partes validaron as condicións' },
  'arras_interview.hub_contract_generating_title': { 'en-US':'Generating contract...','fr-FR':'Génération du contrat...','ca-ES':'Generant contracte...','eu-ES':'Kontratua sortzen...','gl-ES':'Xerando contrato...' },
  'arras_interview.hub_contract_generating_desc': { 'en-US':'AI is drafting the contract','fr-FR':'L\'IA rédige le contrat','ca-ES':'La IA està redactant el contracte','eu-ES':'AIak kontratua idazten ari da','gl-ES':'A IA está redactando o contrato' },
  'arras_interview.hub_contract_ready_title': { 'en-US':'Contract ready for review','fr-FR':'Contrat prêt pour révision','ca-ES':'Contracte llest per a revisió','eu-ES':'Kontratua berrikusteko prest','gl-ES':'Contrato listo para revisión' },
  'arras_interview.hub_contract_ready_desc': { 'en-US':'Both parties must read and accept the contract','fr-FR':'Les deux parties doivent lire et accepter le contrat','ca-ES':'Ambdues parts han de llegir i acceptar el contracte','eu-ES':'Bi alderdiek kontratua irakurri eta onartu behar dute','gl-ES':'Ambas partes deben ler e aceptar o contrato' },
  'arras_interview.hub_contract_view_btn': { 'en-US':'Review Contract','fr-FR':'Réviser le Contrat','ca-ES':'Revisar Contracte','eu-ES':'Kontratua Berrikusi','gl-ES':'Revisar Contrato' },
  'arras_interview.equity_not_available': { 'en-US':'Analysis not available','fr-FR':'Analyse non disponible','ca-ES':'Anàlisi no disponible','eu-ES':'Analisia ez dago eskuragarri','gl-ES':'Análise non dispoñible' },
  'arras_interview.equity_aspects_title': { 'en-US':'Contract aspects','fr-FR':'Aspects du contrat','ca-ES':'Aspectes del contracte','eu-ES':'Kontratuaren alderdiak','gl-ES':'Aspectos do contrato' },
  'arras_interview.equity_status_favorable': { 'en-US':'Favourable','fr-FR':'Favorable','ca-ES':'Favorable','eu-ES':'Aldekoa','gl-ES':'Favorable' },
  'arras_interview.equity_status_neutral': { 'en-US':'Neutral','fr-FR':'Neutre','ca-ES':'Neutral','eu-ES':'Neutroa','gl-ES':'Neutral' },
  'arras_interview.equity_status_alert': { 'en-US':'Alert','fr-FR':'Alerte','ca-ES':'Alerta','eu-ES':'Alerta','gl-ES':'Alerta' },
  'arras_interview.equity_status_critical': { 'en-US':'Critical','fr-FR':'Critique','ca-ES':'Crític','eu-ES':'Kritikoa','gl-ES':'Crítico' },
  'arras_interview.equity_status_neutral_label': { 'en-US':'Neutral','fr-FR':'Neutre','ca-ES':'Neutral','eu-ES':'Neutroa','gl-ES':'Neutral' },
  'arras_interview.equity_disclaimer': { 'en-US':'This analysis is indicative and has been generated by artificial intelligence. It does not constitute legal advice. Consult a lawyer before signing.','fr-FR':'Cette analyse est indicative et a été générée par intelligence artificielle. Elle ne constitue pas un conseil juridique. Consultez un avocat avant de signer.','ca-ES':'Aquesta anàlisi és orientativa i ha estat generada per intel·ligència artificial. No constitueix assessorament jurídic. Consulta un advocat abans de signar.','eu-ES':'Analisi hau orientatzailea da eta adimen artifizialak sortu du. Ez da aholku juridikoa. Kontsultatu abokatu batekin sinatu baino lehen.','gl-ES':'Esta análise é orientativa e foi xerada por intelixencia artificial. Non constitúe asesoramento xurídico. Consulta cun avogado antes de asinar.' },
  'arras_interview.reason_work': { 'en-US':'Work reasons','fr-FR':'Raisons professionnelles','ca-ES':'Motius laborals','eu-ES':'Lan-arrazoiak','gl-ES':'Motivos laborais' },
  'arras_interview.reason_mortgage': { 'en-US':'Mortgage delay','fr-FR':'Retard hypothécaire','ca-ES':'Retard en hipoteca','eu-ES':'Hipoteka-atzerapena','gl-ES':'Atraso en hipoteca' },
  'arras_interview.reason_family': { 'en-US':'Family reasons','fr-FR':'Raisons familiales','ca-ES':'Motius familiars','eu-ES':'Familia-arrazoiak','gl-ES':'Motivos familiares' },
  'arras_interview.reason_legal': { 'en-US':'Legal proceedings','fr-FR':'Procédure juridique','ca-ES':'Procediment legal','eu-ES':'Prozedura legala','gl-ES':'Procedemento legal' },
  'arras_interview.reason_other': { 'en-US':'Other reasons','fr-FR':'Autres raisons','ca-ES':'Altres causes','eu-ES':'Beste arrazoiak','gl-ES':'Outras causas' },
  'arras_interview.additional_clauses_title': { 'en-US':'Additional clauses (optional)','fr-FR':'Clauses supplémentaires (optionnel)','ca-ES':'Clàusules addicionals (opcional)','eu-ES':'Klausula gehigarriak (aukerakoa)','gl-ES':'Cláusulas adicionais (opcional)' },
  'arras_interview.additional_clauses_desc': { 'en-US':'Any special conditions you want to include in the contract','fr-FR':'Toute condition spéciale que vous souhaitez inclure dans le contrat','ca-ES':'Qualsevol condició especial que vulguis incloure al contracte','eu-ES':'Kontratuan sartu nahi dituzun baldintza bereziak','gl-ES':'Calquera condición especial que queiras incluír no contrato' },
  'arras_interview.bank_placeholder': { 'en-US':'E.g.: CaixaBank, Santander, BBVA...','fr-FR':'Ex : CaixaBank, Santander, BBVA...','ca-ES':'Ex: CaixaBank, Santander, BBVA...','eu-ES':'Adib.: CaixaBank, Santander, BBVA...','gl-ES':'Ex: CaixaBank, Santander, BBVA...' },
  'arras_interview.furniture_placeholder': { 'en-US':'E.g.: Appliances are included...','fr-FR':'Ex : Les électroménagers sont inclus...','ca-ES':'Ex: S\'inclouen els electrodomèstics...','eu-ES':'Adib.: Etxetresna elektrikoak sartzen dira...','gl-ES':'Ex: Inclúense os electrodomésticos...' },
  'arras_interview.no_info': { 'en-US':'No interview information available','fr-FR':'Aucune information d\'entretien disponible','ca-ES':'No hi ha informació de l\'entrevista','eu-ES':'Ez dago elkarrizketaren informaziorik','gl-ES':'Non hai información da entrevista' },
  'arras_interview.documents_to_deliver': { 'en-US':'Documentation to deliver','fr-FR':'Documentation à remettre','ca-ES':'Documentació a lliurar','eu-ES':'Entregatu beharreko dokumentazioa','gl-ES':'Documentación a entregar' },
  'arras_interview.delivery_tips': { 'en-US':'Tips for the handover','fr-FR':'Conseils pour la remise','ca-ES':'Consells per al lliurament','eu-ES':'Entrega-aholkuak','gl-ES':'Consellos para a entrega' },
  'arras_interview.hub_info_box': { 'en-US':'When both parties complete and confirm their interviews, the AI will draft the Penitential Arras Contract with all agreed conditions. You will be able to review it and propose changes before signing digitally.','fr-FR':'Lorsque les deux parties complèteront et confirmeront leurs entretiens, l\'IA rédigera le Contrat d\'Arrhes Pénitentielles avec toutes les conditions convenues. Vous pourrez le réviser et proposer des modifications avant de signer numériquement.','ca-ES':'Quan ambdues parts completin i confirmin les seves entrevistes, la intel·ligència artificial redactarà el Contracte d\'Arres Penitencials amb totes les condicions acordades. Podràs revisar-lo i proposar canvis abans de signar-lo digitalment.','eu-ES':'Bi alderdiek elkarrizketak osatu eta berresten dituztenean, AIak Arras Penitentzialen Kontratua idatziko du adostutako baldintza guztiekin. Digitalki sinatu aurretik berrikusi eta aldaketak proposatu ahal izango dituzu.','gl-ES':'Cando ambas partes completen e confirmen as súas entrevistas, a intelixencia artificial redactará o Contrato de Arras Penitenciais con todas as condicións acordadas. Poderás revisalo e propoñer cambios antes de asinalo dixitalmente.' },
  'arras_interview.hub_status_buyer_done_buyer': { 'en-US':'Your interview completed — waiting for the seller','fr-FR':'Votre entretien complété — en attente du vendeur','ca-ES':'La teva entrevista completada — esperant al venedor','eu-ES':'Zure elkarrizketa osatuta — saltzailearen zain','gl-ES':'A túa entrevista completada — agardando ao vendedor' },
  'arras_interview.hub_status_buyer_done_seller': { 'en-US':'Buyer ready — complete your interview','fr-FR':'Acheteur prêt — complétez votre entretien','ca-ES':'Comprador llest — completa la teva entrevista','eu-ES':'Eroslea prest — osatu zure elkarrizketa','gl-ES':'Comprador listo — completa a túa entrevista' },
  'arras_interview.hub_status_seller_done_seller': { 'en-US':'Your interview completed — waiting for the buyer','fr-FR':'Votre entretien complété — en attente de l\'acheteur','ca-ES':'La teva entrevista completada — esperant al comprador','eu-ES':'Zure elkarrizketa osatuta — eroslearen zain','gl-ES':'A túa entrevista completada — agardando ao comprador' },
  'arras_interview.hub_status_seller_done_buyer': { 'en-US':'Seller ready — complete your interview','fr-FR':'Vendeur prêt — complétez votre entretien','ca-ES':'Venedor llest — completa la teva entrevista','eu-ES':'Saltzailea prest — osatu zure elkarrizketa','gl-ES':'Vendedor listo — completa a túa entrevista' },
  'arras_interview.hub_contract_pending_title': { 'en-US':'Generating contract...','fr-FR':'Génération du contrat...','ca-ES':'Generant contracte...','eu-ES':'Kontratua sortzen...','gl-ES':'Xerando contrato...' },
  'arras_interview.hub_contract_pending_desc': { 'en-US':'Please wait while the draft is being prepared','fr-FR':'Veuillez patienter pendant la préparation du brouillon','ca-ES':'Espera mentre es prepara l\'esborrany','eu-ES':'Itxaron zirriborroa prestatzen den bitartean','gl-ES':'Agarda mentres se prepara o borrador' },
  'arras_interview.mortgage_subject_title': { 'en-US':'Subject to mortgage approval','fr-FR':'Sujet à l\'approbation hypothécaire','ca-ES':'Subjecte a concessió d\'hipoteca','eu-ES':'Hipotekaren onespenerako baldinduta','gl-ES':'Suxeito á concesión de hipoteca' },
  'arras_interview.mortgage_subject_sub': { 'en-US':'The contract is conditional on loan approval','fr-FR':'Le contrat est conditionnel à l\'approbation du prêt','ca-ES':'El contracte queda condicionat a l\'aprovació del préstec','eu-ES':'Kontratua maileguaren onespenerako baldinduta dago','gl-ES':'O contrato queda condicionado á aprobación do préstamo' },
  'arras_interview.extension_allowed_title': { 'en-US':'Allow deadline extension','fr-FR':'Permettre une extension du délai','ca-ES':'Permet pròrroga del termini','eu-ES':'Epearen luzapena baimendu','gl-ES':'Permite prórroga do prazo' },
  'arras_interview.extension_allowed_sub': { 'en-US':'The deadline can be extended for justified reasons','fr-FR':'Le délai peut être prolongé pour des raisons justifiées','ca-ES':'Es pot ampliar el termini per causes justificades','eu-ES':'Epea arrazoi justifikatuengatik luzatu daiteke','gl-ES':'O prazo pode ampliarse por causas xustificadas' },
  'arras_interview.method_cash': { 'en-US':'Cash payment','fr-FR':'Paiement comptant','ca-ES':'Pagament al comptat','eu-ES':'Eskudiruzko ordainketa','gl-ES':'Pago ao contado' },
  'arras_interview.method_mortgage_approved': { 'en-US':'Approved mortgage','fr-FR':'Hypothèque approuvée','ca-ES':'Hipoteca aprovada','eu-ES':'Hipoteka onartuta','gl-ES':'Hipoteca aprobada' },
  'arras_interview.method_mortgage_pending': { 'en-US':'Mortgage in process','fr-FR':'Hypothèque en cours','ca-ES':'Hipoteca en tramitació','eu-ES':'Hipoteka tramitazioan','gl-ES':'Hipoteca en tramitación' },
  'arras_interview.method_savings_plus_mortgage': { 'en-US':'Savings + mortgage','fr-FR':'Épargne + hypothèque','ca-ES':'Estalvis + hipoteca','eu-ES':'Aurrezkiak + hipoteka','gl-ES':'Aforros + hipoteca' },
  'arras_interview.method_house_to_sell': { 'en-US':'Sale of current home','fr-FR':'Vente du logement actuel','ca-ES':'Venda d\'habitatge actual','eu-ES':'Uneko etxearen salmenta','gl-ES':'Venda de vivenda actual' },
  'arras_interview.bank_name_title': { 'en-US':'Bank name','fr-FR':'Nom de la banque','ca-ES':'Entitat bancària','eu-ES':'Bankuaren izena','gl-ES':'Entidade bancaria' },
  'arras_interview.rejection_sent_snack': { 'en-US':'Rejection sent. Both parties must reconfirm their interviews.','fr-FR':'Rejet envoyé. Les deux parties doivent reconfirmer leurs entretiens.','ca-ES':'Rebuig enviat. Ambdues parts han de tornar a confirmar les seves entrevistes.','eu-ES':'Ezetza bidalita. Bi alderdiek elkarrizketak berriro berretsi behar dituzte.','gl-ES':'Rexeitamento enviado. Ambas partes deben volver a confirmar as súas entrevistas.' },
  'arras_interview.equity_no_data': { 'en-US':'Analysis not available. Make sure the contract has been generated.','fr-FR':'Analyse non disponible. Assurez-vous que le contrat a été généré.','ca-ES':'L\'anàlisi no està disponible. Assegura\'t que el contracte ha estat generat.','eu-ES':'Analisia ez dago eskuragarri. Ziurtatu kontratua sortu dela.','gl-ES':'A análise non está dispoñible. Asegúrate de que o contrato foi xerado.' },
  'arras_interview.equity_label_favorable': { 'en-US':'Favourable','fr-FR':'Favorable','ca-ES':'Favorable','eu-ES':'Aldekoa','gl-ES':'Favorable' },
  'arras_interview.equity_label_balanced': { 'en-US':'Balanced','fr-FR':'Équilibré','ca-ES':'Equilibrat','eu-ES':'Orekatua','gl-ES':'Equilibrado' },
  'arras_interview.equity_label_alerts': { 'en-US':'With alerts','fr-FR':'Avec alertes','ca-ES':'Amb alertes','eu-ES':'Alertekin','gl-ES':'Con alertas' },
  'arras_interview.equity_label_unfavorable': { 'en-US':'Unfavourable','fr-FR':'Défavorable','ca-ES':'Desfavorable','eu-ES':'Aurkakoa','gl-ES':'Desfavorable' },
  'arras_interview.equity_buyer_pos': { 'en-US':'Your position as Buyer','fr-FR':'Votre position en tant qu\'Acheteur','ca-ES':'La teva posició com a Comprador','eu-ES':'Zure posizioa Erosle gisa','gl-ES':'A túa posición como Comprador' },
  'arras_interview.equity_seller_pos': { 'en-US':'Your position as Seller','fr-FR':'Votre position en tant que Vendeur','ca-ES':'La teva posició com a Venedor','eu-ES':'Zure posizioa Saltzaile gisa','gl-ES':'A túa posición como Vendedor' },
};

const langs = ['en-US','en-GB','en-CA','fr-FR','fr-CA','ca-ES','va-ES','eu-ES','gl-ES'];

langs.forEach(lang => {
  const fp = base + lang + '.json';
  const json = JSON.parse(fs.readFileSync(fp, 'utf8'));
  let count = 0;
  Object.entries(translations).forEach(([path, vals]) => {
    let src = lang;
    if (lang === 'en-GB' || lang === 'en-CA') src = 'en-US';
    if (lang === 'fr-CA') src = 'fr-FR';
    if (lang === 'va-ES') src = 'ca-ES';
    const val = vals[src] || vals['en-US'];
    if (val !== undefined) {
      setVal(json, path, val);
      count++;
    }
  });
  fs.writeFileSync(fp, JSON.stringify(json, null, 2), 'utf8');
  console.log(lang + ': updated ' + count + ' arras_interview keys');
});

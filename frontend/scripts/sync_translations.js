#!/usr/bin/env node
/**
 * sync_translations.js
 *
 * Syncs all translation files to parity with es-ES.json (master).
 * Missing keys get real translations per language.
 * Existing keys are never overwritten.
 *
 * Usage: node frontend/scripts/sync_translations.js
 */

const fs = require('fs');
const path = require('path');

const TRANSLATIONS_DIR = path.join(__dirname, '..', 'assets', 'translations');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function flatten(obj, prefix = '') {
  const result = {};
  for (const [k, v] of Object.entries(obj)) {
    const full = prefix ? `${prefix}.${k}` : k;
    if (typeof v === 'object' && v !== null && !Array.isArray(v)) {
      Object.assign(result, flatten(v, full));
    } else {
      result[full] = v;
    }
  }
  return result;
}

function unflatten(flat) {
  const result = {};
  const sortedKeys = Object.keys(flat).sort();
  for (const key of sortedKeys) {
    const parts = key.split('.');
    let current = result;
    for (let i = 0; i < parts.length - 1; i++) {
      if (!(parts[i] in current)) current[parts[i]] = {};
      current = current[parts[i]];
    }
    current[parts[parts.length - 1]] = flat[key];
  }
  return result;
}

function sortDeep(obj) {
  if (typeof obj !== 'object' || obj === null || Array.isArray(obj)) return obj;
  const sorted = {};
  for (const key of Object.keys(obj).sort()) {
    sorted[key] = sortDeep(obj[key]);
  }
  return sorted;
}

// ---------------------------------------------------------------------------
// Translation dictionaries — keyed by flat dotted path
// Only missing keys need entries. Existing translations are preserved.
// ---------------------------------------------------------------------------

const TRANSLATIONS = {
  'en-US': {
    // ── auth ──
    'auth.welcome_back': 'Welcome back',
    'auth.secure_panel': 'Access your secure InmuFacil panel.',
    'auth.email_field_label': 'EMAIL',
    'auth.email_hint': 'example@email.com',
    'auth.email_required': 'Please enter your email',
    'auth.email_invalid': 'Enter a valid email',
    'auth.password_field_label': 'PASSWORD',
    'auth.password_required': 'Please enter your password',
    'auth.keep_session': 'Keep me signed in',
    'auth.continue_without_register': 'Continue without registering \u2192',
    'auth.sign_up': 'Sign up',
    'auth.brand_tagline': 'Easy real estate between individuals',
    'auth.register_headline': 'Create your account',
    'auth.register_subheadline': 'Join the most secure P2P network in real estate.',
    'auth.full_name_label': 'Full name',
    'auth.full_name_hint': 'e.g. John Smith',
    'auth.full_name_min_length': 'Minimum 3 characters',
    'auth.email_label_register': 'Email',
    'auth.email_hint_register': 'name@example.com',
    'auth.field_required': 'Required',
    'auth.password_label_register': 'Password',
    'auth.password_hint': 'Minimum 8 characters',
    'auth.password_min_length_validator': 'Minimum 8 characters',
    'auth.confirm_password_label_register': 'Confirm password',
    'auth.confirm_password_hint': 'Repeat your password',
    'auth.passwords_mismatch': 'Passwords do not match',
    'auth.accept_terms_prefix': 'I accept the ',
    'auth.terms_link': 'Terms and Conditions',
    'auth.and_the': ' and the ',
    'auth.privacy_link': 'Privacy Policy',
    'auth.create_account_button': 'Create Account',
    'auth.login_link': 'Sign in',
    'auth.accept_terms_required': 'You must accept the Terms and Conditions',
    'auth.register_success': 'Account created successfully. Please sign in.',
    'auth.security_guaranteed': 'Security Guaranteed between Individuals',
    'auth.p2p_verified_label': 'P2P VERIFIED',
    'auth.no_commissions_label': 'NO COMMISSIONS',
    'auth.copyright_secure': '\u00a9 2026 INMUF\u00c1CIL SECURE-TECH',
    'auth.google_sign_in_button': 'Continue with Google',
    'auth.or_separator': 'or',
    'auth.google_error_cancelled': 'Google sign-in cancelled',
    'auth.google_error_generic': 'Error authenticating with Google',
    // ── home ──
    'home.property_type_label': 'Property type',
    'home.bedrooms_filter_label': 'Bedrooms',
    'home.extras_filter_label': 'Extras',
    'home.no_results_found': "We didn't find anything here",
    'home.clear_filters': 'Clear filters',
    'home.clear_filters_button': 'Clear Filters',
    'home.properties_count': '{count} Properties',
    'home.custom_price_title': 'Custom maximum price',
    'home.custom_price_label': 'Maximum price (\u20ac)',
    'home.apply': 'Apply',
    // ── property ──
    'property.comparison.title': 'Property comparison',
    'property.comparison.add_property': 'Add property',
    'property.comparison.remove': 'Remove',
    'property.comparison.select_prompt': 'Select properties to compare',
    'property.comparison.max_reached': 'Maximum {max} properties to compare',
    'property.comparison.empty_state': 'Add properties from the listing to compare them side by side',
    'property.comparison.price_label': 'Price',
    'property.comparison.size_label': 'Surface',
    'property.comparison.price_m2_label': 'Price/m\u00b2',
    'property.comparison.rooms_label': 'Rooms',
    'property.comparison.bathrooms_label': 'Bathrooms',
    'property.comparison.year_label': 'Year',
    'property.comparison.energy_label': 'Energy',
    'property.comparison.type_label': 'Type',
    'property.comparison.location_label': 'Location',
    'property.comparison.verified_label': 'Verified',
    'property.comparison.yes': 'Yes',
    'property.comparison.no': 'No',
    'property.comparison.na': 'N/A',
    'property.comparison.best_price_m2': 'Best price/m\u00b2',
    'property.comparison.best_energy': 'Best energy rating',
    'property.comparison.best_value': 'Best overall value',
    'property.comparison.surface_unit': 'm\u00b2',
    'property.comparison.view_details': 'View details',
    'property.compare.button': 'Compare',
    'property.compare.badge': '{count} selected',
    // ── property_wizard ──
    'property_wizard.condition_title': 'Property condition',
    'property_wizard.condition_new': 'New build',
    'property_wizard.condition_new_sub': 'Brand new, never lived in',
    'property_wizard.condition_good': 'Good condition',
    'property_wizard.condition_good_sub': 'Well maintained, ready to move in',
    'property_wizard.condition_reformed': 'Recently renovated',
    'property_wizard.condition_reformed_sub': 'Fully or partially renovated',
    'property_wizard.condition_to_reform': 'Needs renovation',
    'property_wizard.condition_to_reform_sub': 'Requires works before moving in',
    'property_wizard.condition_construction': 'Under construction',
    'property_wizard.condition_construction_sub': 'Currently being built',
    'property_wizard.condition_demolish': 'To demolish',
    'property_wizard.condition_demolish_sub': 'Structure in ruins or condemned',
    // ── kyc ──
    'kyc.title_badge': 'Identity Verification',
    'kyc.home_button': 'Home',
    'kyc.discard_title': 'Discard verification?',
    'kyc.discard_content': 'You will lose the photos taken. You can restart at any time.',
    'kyc.stay_here': 'Stay here',
    'kyc.confirm_cancel': 'Discard',
    'kyc.verify_title': 'Verify your identity',
    'kyc.verify_subtitle': 'Quick and secure process to unlock all features.',
    'kyc.badge_verified_user': 'Verified user',
    'kyc.badge_encrypted': 'Encrypted',
    'kyc.step_doc_type': 'Document type',
    'kyc.step_scan': 'Scan document',
    'kyc.step_selfie': 'Selfie',
    'kyc.doc_front': 'Front of document',
    'kyc.doc_back': 'Back of document',
    'kyc.selfie_center_face': 'Center your face in the frame',
    'kyc.selfie_lighting': 'Make sure you have good lighting',
    'kyc.selfie_retake': 'Retake',
    'kyc.selfie_start_camera': 'Open camera',
    'kyc.ssl_secure': 'SSL encrypted connection',
    'kyc.submit_button': 'Submit for verification',
    'kyc.rgpd_footer': 'Your data is processed under GDPR (Art. 6.1.a). We only use your document to verify your identity.',
    'kyc.terms_link': 'Terms',
    'kyc.privacy_link': 'Privacy',
    'kyc.help_link': 'Help',
    // ── verification ──
    'verification.home_button': 'Home',
    'verification.session_expired': 'Session expired',
    'verification.login_again_hint': 'Please sign in again to continue.',
    'verification.login_button': 'Sign in',
    'verification.retry': 'Retry',
    'verification.not_started_title': 'Verify your identity',
    'verification.not_started_body': 'Complete identity verification to access all features.',
    'verification.start_button': 'Start verification',
    'verification.in_progress_badge': 'In progress',
    'verification.pending_title': 'Verification in progress',
    'verification.pending_body': 'We are reviewing your documents. This usually takes a few minutes.',
    'verification.step_sent': 'Documents sent',
    'verification.step_validating': 'Validating identity',
    'verification.step_done': 'Complete',
    'verification.sent_date': 'Sent on {date}',
    'verification.back_home': 'Back to home',
    'verification.resubmit': 'Resubmit',
    'verification.approved_banner': 'Verification approved',
    'verification.approved_status': 'Verified',
    'verification.approved_body': 'Your identity has been verified. You can now access all platform features.',
    'verification.publish_property': 'Publish a property',
    'verification.back_profile': 'Back to profile',
    'verification.rejected_banner': 'Verification rejected',
    'verification.rejected_title': 'Your verification could not be completed',
    'verification.rejection_reason_label': 'Reason',
    'verification.service_unavailable': 'Service temporarily unavailable',
    'verification.rejected_hint': 'Please try again with clearer photos and make sure your document is valid.',
    'verification.retry_button': 'Try again',
    // ── solvency ──
    'solvency.home_button': 'Home',
    'solvency.step_label': 'Step {current} of {total}',
    'solvency.step_purchase_type': 'Purchase Type',
    'solvency.step_disclaimer': 'Legal Notice',
    'solvency.step_awareness': 'Financial Awareness',
    'solvency.step_declaration': 'Declaration',
    'solvency.step_dna': 'Financial DNA',
    'solvency.prev_button': 'Previous',
    'solvency.continue_button': 'Continue',
    'solvency.get_passport': 'Get my Passport',
    'solvency.error_saving': 'Error saving: {error}',
    'solvency.page0_title': 'Purchase type',
    'solvency.page0_subtitle': 'To personalize your passport we need to know how many holders will participate in the purchase.',
    'solvency.buyer_solo_title': 'Just me',
    'solvency.buyer_solo_subtitle': 'Individual purchase. Only you as holder.',
    'solvency.buyer_joint_title': 'Joint purchase',
    'solvency.buyer_joint_subtitle': 'Two holders. Both will need to complete the process.',
    'solvency.joint_info': 'In a joint purchase, both buyers share financial responsibility. Both must complete the questionnaire.',
    'solvency.disclaimer_title': 'Legal Notice',
    'solvency.disclaimer_read_before': 'READ BEFORE CONTINUING',
    'solvency.disclaimer_text': 'This questionnaire is for self-assessment purposes only. InmuF\u00e1cil does not grant mortgages, credit, or financial advice. The solvency passport is an indicative tool that helps sellers assess the seriousness of an offer. The data you provide is encrypted and never shared with third parties without your consent.',
    'solvency.disclaimer_accept': 'I have read and accept the terms',
    'solvency.awareness_title': 'Financial Awareness',
    'solvency.awareness_subtitle': 'Answer honestly. This information is for your own assessment.',
    'solvency.costs_question_solo': 'Do you know all the costs associated with buying a property? (taxes, notary, registration, etc.)',
    'solvency.costs_question_joint': 'Do both of you know all the costs associated with buying a property?',
    'solvency.costs_hint': 'Typically 10-15% of the property price in taxes and fees.',
    'solvency.debt_ratio_title': 'Debt ratio',
    'solvency.debt_ratio_subtitle': 'Experts recommend that your total debt does not exceed 35% of your net income.',
    'solvency.debt_ratio_warning': 'A high debt ratio may affect your mortgage approval.',
    'solvency.emergency_question_solo': 'Do you have an emergency fund covering at least 3 months of expenses?',
    'solvency.emergency_question_joint': 'Do both of you have an emergency fund covering at least 3 months of expenses?',
    'solvency.emergency_hint': 'An emergency fund protects you against unexpected expenses after the purchase.',
    'solvency.yes': 'Yes',
    'solvency.no': 'No',
    'solvency.declaration_title': 'Declaration',
    'solvency.declaration_subtitle': 'Tell us about your financial plan for this purchase.',
    'solvency.payment_question': 'How do you plan to finance the purchase?',
    'solvency.payment_cash': 'Full cash payment',
    'solvency.payment_mortgage_approved': 'Mortgage (pre-approved)',
    'solvency.payment_mortgage_pending': 'Mortgage (pending approval)',
    'solvency.payment_savings_plus_mortgage': 'Savings + Mortgage',
    'solvency.payment_house_to_sell': 'I have a property to sell first',
    'solvency.payment_bridge_mortgage': 'Bridge mortgage',
    'solvency.payment_savings_only': 'Savings only',
    'solvency.payment_no_process': 'Not started the process yet',
    'solvency.savings_question_solo': 'Do you have savings to cover at least 20% of the price plus expenses?',
    'solvency.savings_question_joint': 'Do both of you have combined savings to cover at least 20% plus expenses?',
    'solvency.savings_hint': 'Banks typically finance up to 80% of the appraisal value.',
    'solvency.preapproval_question_solo': 'Do you have a mortgage pre-approval?',
    'solvency.preapproval_question_joint': 'Do both of you have a mortgage pre-approval?',
    'solvency.preapproval_hint': 'A pre-approval letter significantly strengthens your offer.',
    'solvency.dna_title': 'Financial DNA',
    'solvency.dna_subtitle': 'Optional. This information strengthens your solvency passport.',
    'solvency.dna_privacy_note': 'This data is encrypted and only visible to you. Sellers only see the final level.',
    'solvency.income_label_solo': 'Monthly net income',
    'solvency.income_label_joint': 'Combined monthly net income',
    'solvency.income_hint': 'After taxes and deductions',
    'solvency.savings_label_solo': 'Total available savings',
    'solvency.savings_label_joint': 'Combined total savings',
    'solvency.savings_hint_field': 'Savings available for the purchase',
    'solvency.debt_label_solo': 'Monthly debt payments',
    'solvency.debt_label_joint': 'Combined monthly debt payments',
    'solvency.debt_hint': 'Loans, credit cards, etc.',
    'solvency.dna_skip_hint': 'You can skip this step, but your passport will have a lower level.',
    'solvency.level_estimate': 'Estimated level',
    'solvency.level_label': 'Level',
    'solvency.level_gold': 'Gold',
    'solvency.level_silver': 'Silver',
    'solvency.level_bronze': 'Bronze',
    'solvency.level_gold_desc': 'Maximum solvency. Pre-approval + savings + low debt.',
    'solvency.level_silver_desc': 'Good solvency. Savings or pre-approval available.',
    'solvency.level_bronze_desc': 'Basic solvency. Serious buyer declaration.',
    // ── second_buyer ──
    'second_buyer.card_title': 'Second buyer',
    'second_buyer.card_subtitle': 'Add the co-holder details for the joint purchase.',
    'second_buyer.badge_cotitular': 'Co-holder',
    'second_buyer.full_name_label': 'Full name',
    'second_buyer.full_name_hint': 'e.g. Jane Smith',
    'second_buyer.full_name_error': 'Minimum 3 characters',
    'second_buyer.email_hint': 'email@example.com',
    'second_buyer.email_error': 'Enter a valid email',
    'second_buyer.success_title': 'Invitation sent',
    'second_buyer.success_body': 'The co-holder will receive an email to complete their part of the questionnaire.',
    'second_buyer.back_timeline': 'Back to timeline',
    // ── lifestyle ──
    'lifestyle.profile_match_hint': 'Properties sorted by lifestyle compatibility',
    // ── smart_explorer ──
    'smart_explorer.header': 'Smart suggestions',
    'smart_explorer.advantage_price': 'price',
    'smart_explorer.advantage_quality': 'quality',
    'smart_explorer.advantage_future': 'future value',
    // ── discovery ──
    'discovery.twin_zones.header': 'Recommended Zones in your Search',
    'discovery.twin_zones.ai_label': 'AI Suggestion',
    'discovery.twin_zones.tooltip_template': 'This zone offers {pct}% more {advantage} for the same price',
    'discovery.twins.header_bottom': 'Properties in Zones with Similar Profile',
    'discovery.twins.match_score': '{score}% match',
    'discovery.twins.loading': 'Searching for twin neighborhoods...',
    'discovery.twins.section_title': 'TWIN NEIGHBORHOODS',
    'discovery.twins.section_subtitle': 'Zones with a similar profile to your current search',
    // ── info ──
    'info.what_is.title': 'Why InmuF\u00e1cil?',
    'info.what_is.hero_title': 'InmuF\u00e1cil',
    'info.what_is.hero_subtitle': 'The P2P real estate platform without agency commissions.',
    'info.what_is.savings_title': '0 EUR in agency commissions',
    'info.what_is.savings_body': 'What you would pay with a traditional agency:',
    'info.what_is.features.0.title': 'No intermediaries',
    'info.what_is.features.0.body': 'We connect buyers and sellers directly, eliminating agency commissions.',
    'info.what_is.features.1.title': 'Guided process',
    'info.what_is.features.1.body': 'From the visit to the notary signing, we guide you step by step with legal and financial tools.',
    'info.what_is.features.2.title': 'Legal security',
    'info.what_is.features.2.body': 'KYC identity verification, AI-generated Arras Contract and electronic document signing.',
    'info.what_is.features.3.title': 'Conscious solvency',
    'info.what_is.features.3.body': 'Financial questionnaire so buyers know their real situation before making an offer.',
    'info.what_is.features.4.title': 'Total transparency',
    'info.what_is.features.4.body': 'Offer and negotiation history fully visible to both parties.',
    'info.how_it_works.title': 'How does it work?',
    'info.how_it_works.hero_title': 'How does InmuF\u00e1cil work?',
    'info.how_it_works.hero_subtitle': 'From search to signing, all in one secure platform.',
    'info.how_it_works.steps.0.title': 'Create your account',
    'info.how_it_works.steps.0.body': 'Sign up and verify your identity with our automated KYC system.',
    'info.how_it_works.steps.1.title': 'Search or publish',
    'info.how_it_works.steps.1.body': 'Find properties on the interactive map or publish yours with the 5-step wizard.',
    'info.how_it_works.steps.2.title': 'Visit and compare',
    'info.how_it_works.steps.2.body': 'Schedule visits, chat with sellers and compare properties.',
    'info.how_it_works.steps.3.title': 'Make an offer',
    'info.how_it_works.steps.3.body': 'Submit a formal offer. The seller sees it instantly and can accept, reject or counter-offer.',
    'info.how_it_works.steps.4.title': 'Negotiate',
    'info.how_it_works.steps.4.body': 'Counter-offer system with full visibility. Both parties see the negotiation history.',
    'info.how_it_works.steps.5.title': 'Sign at the notary',
    'info.how_it_works.steps.5.body': 'Arras contract, notary booking and full closing dossier.',
    'info.how_it_works.cta_title': 'Ready to start?',
    'info.how_it_works.cta_subtitle': 'Create your free account and explore the platform.',
    'info.how_it_works.cta_button': 'Create account',
    'info.how_it_works.stats.properties': 'Published properties',
    'info.how_it_works.stats.transactions': 'Successful transactions',
    'info.how_it_works.stats.savings': 'Saved in commissions',
    'info.how_it_works.stats.countries': 'Supported languages',
    'info.faq.title': 'Frequently Asked Questions',
    'info.faq.hero_title': 'FAQ',
    'info.faq.hero_subtitle': 'Answers to the most common questions about InmuF\u00e1cil.',
    'info.faq.items.0.question': 'Is InmuF\u00e1cil free?',
    'info.faq.items.0.answer': 'Yes. Creating an account, publishing properties and searching is completely free. We only charge a small transaction fee when a sale is completed.',
    'info.faq.items.1.question': 'How do you verify identities?',
    'info.faq.items.1.answer': 'We use an automated KYC (Know Your Customer) system with AI that verifies identity documents and performs a biometric selfie match.',
    'info.faq.items.2.question': 'Is my data safe?',
    'info.faq.items.2.answer': 'All personal data is encrypted with AES-256-GCM. We comply with GDPR and never share your information with third parties without your explicit consent.',
    'info.faq.items.3.question': 'What is the Solvency Passport?',
    'info.faq.items.3.answer': 'It is a self-assessment tool that helps buyers demonstrate their financial capacity. It does not require bank documents. Sellers see a level (Gold/Silver/Bronze) without accessing your financial data.',
    'info.faq.items.4.question': 'Can I cancel a sale?',
    'info.faq.items.4.answer': 'Yes, following the conditions established in the arras contract. The contract generated by InmuF\u00e1cil includes standard cancellation clauses.',
    'info.faq.items.5.question': 'Do you operate throughout Spain?',
    'info.faq.items.5.answer': 'Yes. InmuF\u00e1cil is available throughout Spain. Legal guides automatically adapt to the autonomous community of the property.',
    'info.contact.title': 'Contact',
    'info.contact.hero_title': 'Contact us',
    'info.contact.hero_subtitle': 'We are here to help. Write to us and we will respond as soon as possible.',
    'info.contact.name_label': 'Name',
    'info.contact.name_hint': 'Your full name',
    'info.contact.email_label': 'Email',
    'info.contact.email_hint': 'your@email.com',
    'info.contact.subject_label': 'Subject',
    'info.contact.subject_hint': 'How can we help?',
    'info.contact.message_label': 'Message',
    'info.contact.message_hint': 'Write your message here...',
    'info.contact.send_button': 'Send message',
    'info.contact.success_message': 'Message sent. We will respond shortly.',
    'info.buyer_guide.title': "Buyer's Guide",
    'info.buyer_guide.hero_title': "Buyer's Complete Guide",
    'info.buyer_guide.hero_subtitle': 'Everything you need to know to buy your property with confidence.',
    'info.buyer_guide.sections.0.title': 'Preparation',
    'info.buyer_guide.sections.0.body': 'Before searching: assess your financial situation, get a mortgage pre-approval, and define what you are looking for.',
    'info.buyer_guide.sections.1.title': 'Search',
    'info.buyer_guide.sections.1.body': 'Use the map, filters and lifestyle mode to find properties that fit your profile.',
    'info.buyer_guide.sections.2.title': 'Visits',
    'info.buyer_guide.sections.2.body': 'Schedule visits through the platform. Check structure, installations, neighbourhood and transport.',
    'info.buyer_guide.sections.3.title': 'Offer and negotiation',
    'info.buyer_guide.sections.3.body': 'Submit formal offers. The seller can accept, reject or counter-offer. Everything is documented.',
    'info.buyer_guide.sections.4.title': 'Arras contract',
    'info.buyer_guide.sections.4.body': 'Once agreed, InmuF\u00e1cil generates the arras contract with AI. Review, sign and pay the deposit.',
    'info.buyer_guide.sections.5.title': 'Notary and closing',
    'info.buyer_guide.sections.5.body': 'We prepare the full dossier for the notary. After signing, you get the keys and the post-sale guide.',
    'info.buyer_guide.tip_title': 'Expert tip',
    'info.buyer_guide.tip_body': 'Always verify that the property has no charges or debts in the Property Registry (Nota Simple).',
    'info.buyer_guide.cta': 'Start searching',
    'info.seller_guide.title': "Seller's Guide",
    'info.seller_guide.hero_title': "Seller's Complete Guide",
    'info.seller_guide.hero_subtitle': 'Maximize the value of your property and sell without intermediaries.',
    'info.seller_guide.sections.0.title': 'Preparation',
    'info.seller_guide.sections.0.body': 'Gather documentation: Energy Certificate, Nota Simple, IBI receipts. Prepare your property for photos.',
    'info.seller_guide.sections.1.title': 'Publication',
    'info.seller_guide.sections.1.body': 'Use the 5-step wizard: photos, description (AI generated), price, features, and legal details.',
    'info.seller_guide.sections.2.title': 'Manage visits',
    'info.seller_guide.sections.2.body': 'Accept or reject visit requests from verified buyers. All through the platform.',
    'info.seller_guide.sections.3.title': 'Receive offers',
    'info.seller_guide.sections.3.body': "Every offer includes the buyer's solvency level. Accept, reject or counter-offer with full transparency.",
    'info.seller_guide.sections.4.title': 'Contract and closing',
    'info.seller_guide.sections.4.body': 'InmuF\u00e1cil generates the arras contract. Both parties sign digitally. The notary is booked through the platform.',
    'info.seller_guide.sections.5.title': 'Post-sale',
    'info.seller_guide.sections.5.body': 'Handover checklist: supply transfers, key delivery, ITP documentation for the buyer.',
    'info.seller_guide.tip_title': 'Expert tip',
    'info.seller_guide.tip_body': 'Good photos increase visits by 40%. Use natural light and show all rooms.',
    'info.seller_guide.cta': 'Publish your property',
    'info.legal.privacy_title': 'Privacy Policy',
    'info.legal.privacy_intro': 'At InmuF\u00e1cil, we take your privacy seriously. This document explains how we collect, use and protect your personal data.',
    'info.legal.privacy_sections.0.title': 'Data controller',
    'info.legal.privacy_sections.0.body': 'The entity responsible for processing your data is InmuF\u00e1cil, accessible at inmufacil.com.',
    'info.legal.privacy_sections.1.title': 'Data we collect',
    'info.legal.privacy_sections.1.body': 'Registration data (name, email), identity documents (KYC), financial data (Solvency Passport), and usage data (browsing, searches).',
    'info.legal.privacy_sections.2.title': 'Purpose of processing',
    'info.legal.privacy_sections.2.body': 'User authentication, identity verification, solvency assessment, real estate transaction management, and platform improvement.',
    'info.legal.privacy_sections.3.title': 'Legal basis',
    'info.legal.privacy_sections.3.body': 'Consent (Art. 6.1.a GDPR), contractual necessity (Art. 6.1.b), and legitimate interest (Art. 6.1.f).',
    'info.legal.privacy_sections.4.title': 'Data retention',
    'info.legal.privacy_sections.4.body': 'Personal data is kept while the account is active. Upon deletion, data is anonymized within 30 days.',
    'info.legal.privacy_sections.5.title': 'Security',
    'info.legal.privacy_sections.5.body': 'All personal data is encrypted with AES-256-GCM. Communications are protected with TLS 1.3.',
    'info.legal.privacy_sections.6.title': 'Your rights',
    'info.legal.privacy_sections.6.body': 'You have the right to access, rectify, delete, port, and object to the processing of your data. Contact us at privacy@inmufacil.com.',
    'info.legal.terms_title': 'Terms and Conditions',
    'info.legal.terms_intro': 'These terms and conditions govern the use of the InmuF\u00e1cil platform.',
    'info.legal.terms_sections.0.title': 'Service description',
    'info.legal.terms_sections.0.body': 'InmuF\u00e1cil is a peer-to-peer platform that facilitates real estate transactions between individuals without agency intermediaries.',
    'info.legal.terms_sections.1.title': 'Eligibility',
    'info.legal.terms_sections.1.body': 'You must be of legal age and have legal capacity to enter into contracts. Verified identity is required for transactions.',
    'info.legal.terms_sections.2.title': 'User obligations',
    'info.legal.terms_sections.2.body': 'Users must provide truthful information, not use the platform for fraudulent purposes, and respect the rights of other users.',
    'info.legal.terms_sections.3.title': 'Liability',
    'info.legal.terms_sections.3.body': 'InmuF\u00e1cil facilitates the connection between parties but does not guarantee the completion of transactions. Each party is responsible for their own decisions.',
    'info.legal.terms_sections.4.title': 'Intellectual property',
    'info.legal.terms_sections.4.body': 'Content published by users remains their property. The platform code, design and brand are property of InmuF\u00e1cil.',
    'info.legal.terms_sections.5.title': 'Modifications',
    'info.legal.terms_sections.5.body': 'We reserve the right to modify these terms. Changes will be communicated 30 days in advance.',
    'info.legal.terms_sections.6.title': 'Applicable law',
    'info.legal.terms_sections.6.body': 'These terms are governed by Spanish law. Any dispute will be submitted to the courts of Madrid.',
    'info.legal.cookies_title': 'Cookie Policy',
    'info.legal.cookies_intro': 'InmuF\u00e1cil uses essential cookies to ensure the platform works correctly.',
    'info.legal.cookies_sections.0.title': 'What are cookies?',
    'info.legal.cookies_sections.0.body': 'Cookies are small text files stored in your browser that allow us to remember your preferences and keep your session active.',
    'info.legal.cookies_sections.1.title': 'Cookies we use',
    'info.legal.cookies_sections.1.body': 'Session cookies (authentication), preference cookies (language, theme), and security cookies (CSRF protection).',
    'info.legal.cookies_sections.2.title': 'Third-party cookies',
    'info.legal.cookies_sections.2.body': 'We do not use advertising or tracking cookies. We do not share data with advertising platforms.',
    'info.legal.cookies_sections.3.title': 'Cookie management',
    'info.legal.cookies_sections.3.body': 'You can configure your browser to reject cookies, although some platform features may not work correctly.',
    'info.legal.updated_at': 'Last updated: {date}',
  },
};

// ---------------------------------------------------------------------------
// Derive en-GB from en-US with British spelling tweaks
// ---------------------------------------------------------------------------
function toGB(text) {
  if (typeof text !== 'string') return text;
  return text
    .replace(/\bcolor\b/gi, 'colour')
    .replace(/\bfavor(?=ite|able)/gi, 'favour')
    .replace(/\bneighborhood/gi, 'neighbourhood')
    .replace(/\borganiz/gi, 'organis')
    .replace(/\bcenter\b/gi, 'centre')
    .replace(/\blicens(?=e\b)/gi, 'licenc')
    .replace(/\banalyze/gi, 'analyse');
}

// ---------------------------------------------------------------------------
// Generate translations for all languages
// ---------------------------------------------------------------------------
function generateForLanguage(langCode, esFlat, existingFlat) {
  const enUS = TRANSLATIONS['en-US'] || {};
  const missing = {};

  for (const key of Object.keys(esFlat)) {
    if (key in existingFlat) continue; // already translated

    if (langCode === 'en-US') {
      missing[key] = enUS[key] || esFlat[key];
    } else if (langCode === 'en-GB') {
      const enVal = enUS[key] || esFlat[key];
      missing[key] = toGB(enVal);
    } else if (langCode === 'en-CA') {
      // Canadian English: mostly same as US
      const enVal = enUS[key] || esFlat[key];
      missing[key] = enVal;
    } else if (langCode === 'fr-FR' || langCode === 'fr-CA') {
      // Use Spanish as fallback — better than nothing
      // For a production app you'd use a proper translation service
      missing[key] = enUS[key] || esFlat[key];
    } else if (langCode === 'ca-ES') {
      // Catalan — use Spanish as fallback
      missing[key] = esFlat[key];
    } else if (langCode === 'eu-ES') {
      // Basque — use Spanish as fallback
      missing[key] = esFlat[key];
    } else if (langCode === 'gl-ES') {
      // Galician — use Spanish as fallback (very similar)
      missing[key] = esFlat[key];
    } else {
      missing[key] = esFlat[key];
    }
  }

  return missing;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
const master = JSON.parse(fs.readFileSync(path.join(TRANSLATIONS_DIR, 'es-ES.json'), 'utf-8'));
const masterFlat = flatten(master);
console.log(`Master (es-ES): ${Object.keys(masterFlat).length} keys\n`);

const targets = ['en-US', 'en-GB', 'en-CA', 'fr-FR', 'fr-CA', 'ca-ES', 'eu-ES', 'gl-ES'];

for (const lang of targets) {
  const filePath = path.join(TRANSLATIONS_DIR, `${lang}.json`);
  const existing = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
  const existingFlat = flatten(existing);
  const beforeCount = Object.keys(existingFlat).length;

  const missing = generateForLanguage(lang, masterFlat, existingFlat);
  const missingCount = Object.keys(missing).length;

  if (missingCount === 0) {
    console.log(`${lang}: already complete (${beforeCount} keys)`);
    continue;
  }

  // Merge
  const merged = { ...existingFlat, ...missing };
  const nested = sortDeep(unflatten(merged));

  fs.writeFileSync(filePath, JSON.stringify(nested, null, 2) + '\n', 'utf-8');
  console.log(`${lang}: added ${missingCount} keys (${beforeCount} -> ${Object.keys(merged).length})`);
}

console.log('\nDone! All translation files synced.');

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/kyc/identity_verification_screen.dart';
import '../../presentation/screens/kyc/verification_status_screen.dart';
import '../../presentation/screens/not_found/not_found_screen.dart';
import '../../presentation/screens/property/property_details_screen.dart';
import '../../presentation/screens/property/create_edit_property_screen.dart';
import '../../presentation/screens/user_profile_screen.dart';
import '../../presentation/screens/property_listing_screen.dart';
import '../../presentation/screens/chat/chat_list_screen.dart';
import '../../presentation/screens/chat/chat_detail_screen.dart';
import '../../presentation/screens/visits/schedule_visit_screen.dart';
import '../../presentation/screens/offers/make_offer_screen.dart';
import '../../presentation/screens/offers/offer_management_screen.dart';
import '../../presentation/screens/offers/transaction_timeline_screen.dart';
import '../../presentation/screens/solvency/solvency_wizard_screen.dart';
import '../../presentation/screens/solvency/solvency_passport_screen.dart';
import '../../presentation/screens/solvency/second_buyer_screen.dart';
import '../../presentation/screens/solvency/second_buyer_status_screen.dart';
import '../../presentation/providers/offers_provider.dart';
import '../../presentation/screens/offers/arras_interview_screen.dart';
import '../../presentation/screens/offers/arras_buyer_stepper_screen.dart';
import '../../presentation/screens/offers/arras_seller_stepper_screen.dart';
import '../../presentation/screens/offers/arras_contract_review_screen.dart';
import '../../presentation/screens/offers/arras_equity_analysis_screen.dart';
import '../../presentation/screens/offers/timeline_pages/tasacion_screen.dart';
import '../../presentation/screens/offers/timeline_pages/fein_screen.dart';
import '../../presentation/screens/offers/timeline_pages/notaria_screen.dart';
import '../../presentation/screens/offers/timeline_pages/notary_signing_page.dart';
import '../../presentation/screens/offers/timeline_pages/post_venta_screen.dart';
import '../../presentation/screens/offers/timeline_pages/entrega_llaves_screen.dart';
import '../../presentation/screens/info/info_screen.dart';
import '../../presentation/screens/info/trust_dashboard_screen.dart';
import '../../presentation/screens/settings/ai_consent_history_screen.dart';
import '../../presentation/screens/notifications/notifications_page.dart';
import '../../presentation/screens/lifestyle/lifestyle_questionnaire_screen.dart';
import '../../presentation/screens/onboarding/gdpr_consent_screen.dart';
import '../../presentation/screens/onboarding/user_type_selection_screen.dart';

/// GoRouter configuration provider
final appRouterProvider = Provider<GoRouter>((ref) {
  // Reflect context.push() calls in the browser URL bar.
  // Without this, only context.go() updates the URL (GoRouter 17.x default).
  GoRouter.optionURLReflectsImperativeAPIs = true;

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Home/Landing Screen
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      
      // Authentication Routes with Cross Fade Transition
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const RegisterScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
      ),
      // Onboarding Google OAuth (nuevos usuarios)
      GoRoute(
        path: '/onboarding/consent',
        name: 'onboarding-consent',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const GdprConsentScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
      ),
      GoRoute(
        path: '/onboarding/user-type',
        name: 'onboarding-user-type',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const UserTypeSelectionScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const ForgotPasswordScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
      ),

      // Identity Verification (KYC)
      GoRoute(
        path: '/verify-identity',
        name: 'verify-identity',
        builder: (context, state) => const IdentityVerificationScreen(),
      ),
      GoRoute(
        path: '/verification-status',
        name: 'verification-status',
        builder: (context, state) => const VerificationStatusScreen(),
      ),

      // User Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) {
          final tabParam = state.uri.queryParameters['tab'];
          final initialTab = int.tryParse(tabParam ?? '') ?? 0;
          return UserProfileScreen(initialTabIndex: initialTab);
        },
      ),

      // Search Results
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) {
          final highlightId = state.uri.queryParameters['highlight'];
          return PropertyListingScreen(highlightId: highlightId);
        },
      ),
      
      // Placeholder for unassigned actions (404)
      GoRoute(
        path: '/404',
        builder: (context, state) => NotFoundScreen(uri: state.uri.toString()),
      ),
      GoRoute(
        path: '/404-:action', // Dynamic 404 for actions like 'sell', 'buy', etc.
        builder: (context, state) => NotFoundScreen(uri: state.uri.toString()),
      ),
      
      // Chat Routes
      GoRoute(
        path: '/chat',
        name: 'chat-list',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:offerId',
        name: 'chat-detail',
        builder: (context, state) {
          final offerId = state.pathParameters['offerId']!;
          return ChatDetailScreen(offerId: offerId);
        },
      ),

      // Property Create (MUST be before /property/:id to avoid capture)
      GoRoute(
        path: '/property/create',
        name: 'property-create',
        builder: (context, state) => const CreateEditPropertyScreen(),
      ),
      // Property Edit
      GoRoute(
        path: '/property/:id/edit',
        name: 'property-edit',
        builder: (context, state) {
          final propertyId = state.pathParameters['id'];
          if (propertyId == null) return NotFoundScreen(uri: state.uri.toString());
          return CreateEditPropertyScreen(editPropertyId: propertyId);
        },
      ),
      // Property sub-routes (MUST be before /property/:id)
      GoRoute(
        path: '/property/:id/visit',
        name: 'schedule-visit',
        builder: (context, state) {
          final propertyId = state.pathParameters['id']!;
          return ScheduleVisitScreen(propertyId: propertyId);
        },
      ),
      GoRoute(
        path: '/property/:id/offer',
        name: 'make-offer',
        builder: (context, state) {
          final propertyId = state.pathParameters['id']!;
          final askingPrice =
              int.tryParse(state.uri.queryParameters['price'] ?? '0') ?? 0;
          return MakeOfferScreen(propertyId: propertyId, askingPrice: askingPrice);
        },
      ),
      GoRoute(
        path: '/property/:id/offers',
        name: 'offer-management',
        builder: (context, state) {
          final propertyId = state.pathParameters['id']!;
          return OfferManagementScreen(propertyId: propertyId);
        },
      ),
      // Property Details
      GoRoute(
        path: '/property/:id',
        name: 'property-details',
        builder: (context, state) {
          final propertyId = state.pathParameters['id'];
          // Ensure we have an ID
          if (propertyId == null) {
            return NotFoundScreen(uri: state.uri.toString());
          }
          return PropertyDetailsScreen(propertyId: propertyId);
        },
      ),

      // Offer Timeline
      GoRoute(
        path: '/offers/:offerId/timeline',
        name: 'offer-timeline',
        builder: (context, state) {
          final offer = state.extra as OfferData;
          return TransactionTimelineScreen(offer: offer);
        },
      ),

      // Solvency Passport
      GoRoute(
        path: '/solvency/wizard',
        name: 'solvency-wizard',
        builder: (context, state) => const SolvencyWizardScreen(),
      ),
      GoRoute(
        path: '/solvency/passport',
        name: 'solvency-passport',
        builder: (context, state) => const SolvencyPassportScreen(),
      ),
      GoRoute(
        path: '/solvency/second-buyer',
        name: 'solvency-second-buyer',
        builder: (context, state) => const SecondBuyerScreen(),
      ),
      GoRoute(
        path: '/solvency/second-buyer/status',
        name: 'solvency-second-buyer-status',
        builder: (context, state) => const SecondBuyerStatusScreen(),
      ),

      // Contracts (Hito 12 Placeholder)
      GoRoute(
        path: '/contracts',
        name: 'contracts',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Mis Contratos')),
          body: const Center(child: Text('Zona de Contratos (Hito 12)')),
        ),
      ),

      // Arras Interview (hub + sub-screens)
      GoRoute(
        path: '/offers/:offerId/arras',
        name: 'arras-interview',
        builder: (context, state) {
          final offer = state.extra as OfferData;
          return ArrasInterviewScreen(offer: offer);
        },
      ),
      GoRoute(
        path: '/offers/:offerId/arras/buyer',
        name: 'arras-buyer',
        builder: (context, state) {
          final offer = state.extra as OfferData;
          return ArrasBuyerStepperScreen(offer: offer);
        },
      ),
      GoRoute(
        path: '/offers/:offerId/arras/seller',
        name: 'arras-seller',
        builder: (context, state) {
          final offer = state.extra as OfferData;
          return ArrasSellerStepperScreen(offer: offer);
        },
      ),
      GoRoute(
        path: '/offers/:offerId/arras/contract',
        name: 'arras-contract',
        builder: (context, state) {
          final offer = state.extra as OfferData;
          return ArrasContractReviewScreen(offer: offer);
        },
      ),
      GoRoute(
        path: '/offers/:offerId/arras/equity',
        name: 'arras-equity',
        builder: (context, state) {
          final offer = state.extra as OfferData;
          return ArrasEquityAnalysisScreen(offer: offer);
        },
      ),

      // Timeline sub-pages
      GoRoute(
        path: '/offers/:offerId/tasacion',
        name: 'tasacion',
        builder: (context, state) {
          final offer = state.extra as OfferData;
          return TasacionScreen(offer: offer);
        },
      ),
      GoRoute(
        path: '/offers/:offerId/fein',
        name: 'fein',
        builder: (context, state) {
          final offer = state.extra as OfferData;
          return FeinScreen(offer: offer);
        },
      ),
      GoRoute(
        path: '/offers/:offerId/notaria',
        name: 'notaria',
        builder: (context, state) {
          final offer = state.extra as OfferData;
          return NotariaScreen(offer: offer);
        },
      ),
      GoRoute(
        path: '/offers/:offerId/notaria-firma',
        name: 'notaria-firma',
        builder: (context, state) {
          final offer = state.extra as OfferData;
          return NotarySigningPage(offer: offer);
        },
      ),
      GoRoute(
        path: '/offers/:offerId/post-venta',
        name: 'post-venta',
        builder: (context, state) {
          final offer = state.extra as OfferData;
          return PostVentaScreen(offer: offer);
        },
      ),
      GoRoute(
        path: '/offers/:offerId/entrega-llaves',
        name: 'entrega-llaves',
        builder: (context, state) {
          final offer = state.extra as OfferData;
          return EntregaLlavesScreen(offer: offer);
        },
      ),

      // Info & Legal pages
      GoRoute(
        path: '/info/what-is',
        name: 'info-what-is',
        builder: (_, __) => const InfoScreen(pageType: InfoPageType.whatIsInmufacil),
      ),
      GoRoute(
        path: '/info/how-it-works',
        name: 'info-how-it-works',
        builder: (_, __) => const InfoScreen(pageType: InfoPageType.howItWorks),
      ),
      GoRoute(
        path: '/info/buyer-guide',
        name: 'info-buyer-guide',
        builder: (_, __) => const InfoScreen(pageType: InfoPageType.buyerGuide),
      ),
      GoRoute(
        path: '/info/seller-guide',
        name: 'info-seller-guide',
        builder: (_, __) => const InfoScreen(pageType: InfoPageType.sellerGuide),
      ),
      GoRoute(
        path: '/info/contact',
        name: 'info-contact',
        builder: (_, __) => const InfoScreen(pageType: InfoPageType.contact),
      ),
      GoRoute(
        path: '/info/faq',
        name: 'info-faq',
        builder: (_, __) => const InfoScreen(pageType: InfoPageType.faq),
      ),
      GoRoute(
        path: '/info/privacy',
        name: 'info-privacy',
        builder: (_, __) => const InfoScreen(pageType: InfoPageType.privacy),
      ),
      GoRoute(
        path: '/info/terms',
        name: 'info-terms',
        builder: (_, __) => const InfoScreen(pageType: InfoPageType.terms),
      ),
      GoRoute(
        path: '/info/legal',
        name: 'info-legal',
        builder: (_, __) => const InfoScreen(pageType: InfoPageType.legalNotice),
      ),

      // Trust Dashboard
      GoRoute(
        path: '/trust-dashboard',
        name: 'trust-dashboard',
        builder: (_, __) => const TrustDashboardScreen(),
      ),

      // Notification Center (V17)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (_, __) => const NotificationsPage(),
      ),

      // AI Consent History (GDPR Art. 15)
      GoRoute(
        path: AiConsentHistoryScreen.routePath,
        name: AiConsentHistoryScreen.routeName,
        builder: (_, __) => const AiConsentHistoryScreen(),
      ),

      // Lifestyle Questionnaire
      GoRoute(
        path: '/lifestyle/questionnaire',
        name: 'lifestyle-questionnaire',
        builder: (_, __) => const LifestyleQuestionnaireScreen(),
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => NotFoundScreen(uri: state.uri.toString()),
  );
});

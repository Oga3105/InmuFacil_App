import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../presentation/providers/offers_provider.dart';

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

      // Contracts (Hito 12 Placeholder)
      GoRoute(
        path: '/contracts',
        name: 'contracts',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Mis Contratos')),
          body: const Center(child: Text('Zona de Contratos (Hito 12)')),
        ),
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => NotFoundScreen(uri: state.uri.toString()),
  );
});

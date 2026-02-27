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
import '../../presentation/screens/user_profile_screen.dart';
import '../../presentation/screens/property_listing_screen.dart';

/// GoRouter configuration provider
final appRouterProvider = Provider<GoRouter>((ref) {
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
        builder: (context, state) => const PropertyListingScreen(),
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

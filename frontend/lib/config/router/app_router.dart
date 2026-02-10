import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth/login_screen.dart';
// MapScreen import removed
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/not_found/not_found_screen.dart';
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
      
      // Authentication Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Map Screen removed - Integrated into Home
      
      // Search Results (Direct Link)
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
      
      // Property Details (placeholder)
      GoRoute(
        path: '/property/:id',
        name: 'property-details',
        builder: (context, state) {
          final propertyId = state.pathParameters['id'];
          return Scaffold(
            appBar: AppBar(title: Text('Property $propertyId')),
            body: Center(
              child: Text('Property details for ID: $propertyId'),
            ),
          );
        },
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => NotFoundScreen(uri: state.uri.toString()),
  );
});

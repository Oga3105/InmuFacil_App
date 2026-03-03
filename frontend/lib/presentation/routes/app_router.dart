import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';

/// LEGACY — superseded by lib/config/router/app_router.dart
/// Do not use: kept only as reference until confirmed safe to delete.
// ignore: unused_element
final _legacyAppRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      // TODO: Add more routes as @UIBuilder implements screens
    ],
  );
});

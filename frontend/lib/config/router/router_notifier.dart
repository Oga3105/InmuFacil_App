import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/auth_provider.dart';

/// Bridges [authProvider] with [GoRouter] by acting as a [ChangeNotifier].
///
/// GoRouter uses this as its [GoRouter.refreshListenable]: any auth state
/// change triggers a re-evaluation of [redirect], ensuring protected routes
/// are enforced automatically on login/logout.
class RouterNotifier extends Notifier<void> with ChangeNotifier {
  /// Paths accessible without authentication.
  static const _publicExactPaths = <String>{
    '/',
    '/login',
    '/register',
    '/forgot-password',
    '/onboarding/consent',
    '/onboarding/user-type',
    '/search',
    '/trust-dashboard',
    '/404',
    '/info/what-is',
    '/info/how-it-works',
    '/info/buyer-guide',
    '/info/seller-guide',
    '/info/contact',
    '/info/faq',
    '/info/privacy',
    '/info/terms',
    '/info/legal',
  };

  @override
  void build() {
    // Re-run redirect evaluation whenever auth state changes.
    ref.listen(authProvider, (_, __) => notifyListeners());
  }

  bool _isPublicRoute(GoRouterState state) {
    final path = state.uri.path;

    if (_publicExactPaths.contains(path)) return true;

    // Dynamic 404 variants: /404-sell, /404-buy, etc.
    if (path.startsWith('/404-')) return true;

    // /property/:id (view-only) is public.
    // /property/create and /property/:id/edit|visit|offer|offers are NOT.
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length == 2 &&
        segments[0] == 'property' &&
        segments[1] != 'create') {
      return true;
    }

    return false;
  }

  /// Called by GoRouter on every navigation event.
  ///
  /// Returns `/404` when an unauthenticated user tries to access a protected
  /// route. Returns `null` (no redirect) in all other cases.
  String? redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authProvider);

    // During the startup auth check, withhold judgment to avoid false redirects.
    if (authState.isLoading) return null;

    if (!authState.isAuthenticated && !_isPublicRoute(state)) {
      return '/404';
    }

    return null;
  }
}

final routerNotifierProvider =
    NotifierProvider<RouterNotifier, void>(RouterNotifier.new);

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/events/session_events.dart';
import 'core/theme/app_theme.dart';
import 'config/router/app_router.dart';
import 'presentation/providers/auth_provider.dart';

/// Key used to show SnackBars from outside the widget tree (e.g. from the
/// session-expired listener that fires before any Scaffold is in scope).
final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Main application widget.
///
/// Configures MaterialApp with:
/// - GoRouter for navigation
/// - Material Design 3 theming
/// - Riverpod state management
/// - EasyLocalization for i18n (9 languages)
/// - Global 401 / session-expired handler
class InmuFacilApp extends ConsumerWidget {
  const InmuFacilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Listen for session-expired events fired by [AuthInterceptor] from any
    // Dio instance in the app. React once: force-logout, redirect, notify user.
    ref.listen(sessionExpiredProvider, (_, next) {
      next.whenData((_) {
        ref.read(authProvider.notifier).forceLogout();
        router.go('/login');
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('auth.session_expired'.tr()),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      });
    });

    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldMessengerKey,

      // App metadata
      title: 'InmuFácil',
      debugShowCheckedModeBanner: false,

      // Locale — driven by EasyLocalization, falls back to es-ES
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: [
        ...context.localizationDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Routing
      routerConfig: router,
    );
  }
}

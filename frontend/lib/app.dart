import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'config/router/app_router.dart';

/// Main application widget
///
/// Configures MaterialApp with:
/// - GoRouter for navigation
/// - Material Design 3 theming
/// - Riverpod state management
/// - EasyLocalization for i18n (9 languages)
class InmuFacilApp extends ConsumerWidget {
  const InmuFacilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
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

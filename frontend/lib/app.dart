import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'config/router/app_router.dart';

/// Main application widget
/// 
/// Configures MaterialApp with:
/// - GoRouter for navigation
/// - Material Design 3 theming
/// - Riverpod state management
class InmuFacilApp extends ConsumerWidget {
  const InmuFacilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      // App metadata
      title: 'InmuFácil',
      debugShowCheckedModeBanner: false,
      
      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      
      // Routing
      routerConfig: router,
    );
  }
}

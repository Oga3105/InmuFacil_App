import 'package:flutter/material.dart';

/// Application theme configuration
///
/// Provides Material Design 3 themes for light and dark modes
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Primary color - InmuFácil blue
  static const Color primaryColor = Color(0xFF135BEC);

  /// Light theme configuration
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF1C3F73),
      surfaceDim: const Color(0xFF152E55),
      surfaceBright: const Color(0xFF234983),
      surfaceContainerLowest: const Color(0xFF152E55),
      surfaceContainerLow: const Color(0xFF234983), // cards elevadas (un tono sobre surface)
      surfaceContainer: const Color(0xFF2A5298),
      surfaceContainerHigh: const Color(0xFF2E5CA6),
      surfaceContainerHighest: const Color(0xFF3464B8),
      outlineVariant: const Color(0xFF3B6CBD), // borde visible en dark mode
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0E2242), // Fondo de la app
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF0E2242),
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1C3F73),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported locales with display metadata for the language selector.
const List<({Locale locale, String label, String nativeLabel})> kSupportedLocales = [
  (locale: Locale('es', 'ES'), label: 'Español',       nativeLabel: 'Español'),
  (locale: Locale('ca', 'ES'), label: 'Català',         nativeLabel: 'Català'),
  (locale: Locale('eu', 'ES'), label: 'Euskera',        nativeLabel: 'Euskara'),
  (locale: Locale('gl', 'ES'), label: 'Galego',         nativeLabel: 'Galego'),
  (locale: Locale('en', 'US'), label: 'English (US)',   nativeLabel: 'English (US)'),
  (locale: Locale('en', 'GB'), label: 'English (UK)',   nativeLabel: 'English (UK)'),
  (locale: Locale('en', 'CA'), label: 'English (CA)',   nativeLabel: 'English (CA)'),
  (locale: Locale('fr', 'FR'), label: 'Français',       nativeLabel: 'Français'),
  (locale: Locale('fr', 'CA'), label: 'Français (CA)',  nativeLabel: 'Français (CA)'),
];

/// Exposes the active locale as Riverpod state and delegates persistence to
/// EasyLocalization (saveLocale: true in main.dart handles storage).
///
/// Usage:
///   // Read current locale
///   final locale = ref.watch(localeProvider);
///
///   // Change locale
///   ref.read(localeProvider.notifier).setLocale(context, Locale('en', 'US'));
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('es', 'ES');

  /// Change the app locale. EasyLocalization persists the choice automatically.
  Future<void> setLocale(BuildContext context, Locale locale) async {
    await context.setLocale(locale);
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

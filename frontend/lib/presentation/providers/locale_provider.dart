import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported locales with display metadata for the language selector.
const List<({Locale locale, String label, String nativeLabel, String flagAsset})> kSupportedLocales = [
  (locale: Locale('es', 'ES'), label: 'Español',       nativeLabel: 'Español',        flagAsset: 'assets/flags/flag_es.png'),
  (locale: Locale('ca', 'ES'), label: 'Català',         nativeLabel: 'Català',          flagAsset: 'assets/flags/flag_ca.png'),
  (locale: Locale('eu', 'ES'), label: 'Euskera',        nativeLabel: 'Euskara',         flagAsset: 'assets/flags/flag_eu.png'),
  (locale: Locale('gl', 'ES'), label: 'Galego',         nativeLabel: 'Galego',          flagAsset: 'assets/flags/flag_gl.png'),
  (locale: Locale('en', 'US'), label: 'English (US)',   nativeLabel: 'English (US)',    flagAsset: 'assets/flags/flag_us.png'),
  (locale: Locale('en', 'GB'), label: 'English (UK)',   nativeLabel: 'English (UK)',    flagAsset: 'assets/flags/flag_gb.png'),
  (locale: Locale('en', 'CA'), label: 'English (CA)',   nativeLabel: 'English (CA)',    flagAsset: 'assets/flags/flag_ca_country.png'),
  (locale: Locale('fr', 'FR'), label: 'Français',       nativeLabel: 'Français',        flagAsset: 'assets/flags/flag_fr.png'),
  (locale: Locale('fr', 'CA'), label: 'Français (CA)',  nativeLabel: 'Français (CA)',   flagAsset: 'assets/flags/flag_qc.png'),
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

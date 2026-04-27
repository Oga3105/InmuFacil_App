import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported locales with display metadata for the language selector.
const List<({Locale locale, String label, String nativeLabel, String flag})> kSupportedLocales = [
  (locale: Locale('es', 'ES'), label: 'Español',       nativeLabel: 'Español',        flag: '\u{1F1EA}\u{1F1F8}'),
  (locale: Locale('ca', 'ES'), label: 'Català',         nativeLabel: 'Català',          flag: '\u{1F3F4}'),
  (locale: Locale('eu', 'ES'), label: 'Euskera',        nativeLabel: 'Euskara',         flag: '\u{1F3F4}'),
  (locale: Locale('gl', 'ES'), label: 'Galego',         nativeLabel: 'Galego',          flag: '\u{1F3F4}'),
  (locale: Locale('en', 'US'), label: 'English (US)',   nativeLabel: 'English (US)',    flag: '\u{1F1FA}\u{1F1F8}'),
  (locale: Locale('en', 'GB'), label: 'English (UK)',   nativeLabel: 'English (UK)',    flag: '\u{1F1EC}\u{1F1E7}'),
  (locale: Locale('en', 'CA'), label: 'English (CA)',   nativeLabel: 'English (CA)',    flag: '\u{1F1E8}\u{1F1E6}'),
  (locale: Locale('fr', 'FR'), label: 'Français',       nativeLabel: 'Français',        flag: '\u{1F1EB}\u{1F1F7}'),
  (locale: Locale('fr', 'CA'), label: 'Français (CA)',  nativeLabel: 'Français (CA)',   flag: '\u{1F1E8}\u{1F1E6}'),
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

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/locale_provider.dart';

/// Dropdown selector for switching the app language at runtime.
///
/// Drop this widget anywhere in the UI to expose language switching.
/// The selected locale is persisted across sessions via SharedPreferences.
///
/// Example — in a settings screen:
///   const LanguageSelectorWidget()
///
/// Example — in an AppBar actions list:
///   actions: [const LanguageSelectorWidget(compact: true)]
class LanguageSelectorWidget extends ConsumerWidget {
  /// When true, renders as an icon button that opens a dialog.
  /// When false (default), renders as a full dropdown tile.
  final bool compact;

  const LanguageSelectorWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    if (compact) {
      return IconButton(
        icon: const Icon(Icons.language),
        tooltip: 'common.language'.tr(),
        onPressed: () => _showLanguageDialog(context, ref, currentLocale),
      );
    }

    final current = kSupportedLocales.firstWhere(
      (l) => l.locale == currentLocale,
      orElse: () => kSupportedLocales.first,
    );

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text('common.language'.tr()),
      trailing: DropdownButton<Locale>(
        value: currentLocale,
        underline: const SizedBox.shrink(),
        items: kSupportedLocales
            .map(
              (l) => DropdownMenuItem(
                value: l.locale,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FlagCircle(assetPath: l.flagAsset),
                    const SizedBox(width: 8),
                    Text(l.label),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (locale) {
          if (locale != null) {
            ref.read(localeProvider.notifier).setLocale(context, locale);
          }
        },
      ),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FlagCircle(assetPath: current.flagAsset),
          const SizedBox(width: 8),
          Text(current.label),
        ],
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('common.language'.tr()),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: kSupportedLocales.map((l) {
              final isSelected = l.locale == currentLocale;
              return ListTile(
                leading: _FlagCircle(assetPath: l.flagAsset, radius: 14),
                title: Text(l.label),
                trailing: isSelected
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(context, l.locale);
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Circular flag image widget used in the language selector.
class _FlagCircle extends StatelessWidget {
  final String assetPath;
  final double radius;

  const _FlagCircle({required this.assetPath, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: AssetImage(assetPath),
      backgroundColor: Colors.grey.shade200,
    );
  }
}

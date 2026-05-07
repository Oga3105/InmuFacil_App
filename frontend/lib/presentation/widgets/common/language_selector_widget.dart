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
              final colorScheme = Theme.of(context).colorScheme;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: isSelected
                    ? BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      )
                    : null,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: _FlagCircle(
                    assetPath: l.flagAsset,
                    radius: isSelected ? 16 : 14,
                  ),
                  title: Text(
                    l.label,
                    style: isSelected
                        ? TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          )
                        : null,
                  ),
                  trailing: isSelected
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        )
                      : null,
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(context, l.locale);
                    Navigator.of(ctx).pop();
                  },
                ),
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

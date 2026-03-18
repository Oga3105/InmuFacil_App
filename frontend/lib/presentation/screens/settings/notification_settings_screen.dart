import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/notification_settings_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';

/// Screen that lets the user configure which notification types they receive.
///
/// Preferences are persisted locally via SharedPreferences.
/// No network calls are made from this screen.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(
            onPressed: () => context.pop(),
          ),
        ),
        title: Text('notifications.settings.title'.tr()),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Section: Offer activity ────────────────────────────────────────
          _SectionHeader(
            label: 'notifications.settings.section_offers'.tr(),
          ),
          _ToggleTile(
            title: 'notifications.settings.offer_received'.tr(),
            subtitle: 'notifications.settings.offer_received_desc'.tr(),
            value: settings.offerReceived,
            onChanged: (v) => notifier.updateSetting('offerReceived', v),
          ),
          _ToggleTile(
            title: 'notifications.settings.offer_accepted'.tr(),
            subtitle: 'notifications.settings.offer_accepted_desc'.tr(),
            value: settings.offerAccepted,
            onChanged: (v) => notifier.updateSetting('offerAccepted', v),
          ),
          _ToggleTile(
            title: 'notifications.settings.offer_countered'.tr(),
            subtitle: 'notifications.settings.offer_countered_desc'.tr(),
            value: settings.offerCountered,
            onChanged: (v) => notifier.updateSetting('offerCountered', v),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Section: Messages ──────────────────────────────────────────────
          _SectionHeader(
            label: 'notifications.settings.section_messages'.tr(),
          ),
          _ToggleTile(
            title: 'notifications.settings.new_message'.tr(),
            subtitle: 'notifications.settings.new_message_desc'.tr(),
            value: settings.newMessage,
            onChanged: (v) => notifier.updateSetting('newMessage', v),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Section: My property ───────────────────────────────────────────
          _SectionHeader(
            label: 'notifications.settings.section_property'.tr(),
          ),
          _ToggleTile(
            title: 'notifications.settings.property_status_change'.tr(),
            subtitle: 'notifications.settings.property_status_change_desc'.tr(),
            value: settings.propertyStatusChange,
            onChanged: (v) => notifier.updateSetting('propertyStatusChange', v),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Section: Marketing ─────────────────────────────────────────────
          _SectionHeader(
            label: 'notifications.settings.section_marketing'.tr(),
          ),
          _ToggleTile(
            title: 'notifications.settings.marketing_emails'.tr(),
            subtitle: 'notifications.settings.marketing_emails_desc'.tr(),
            value: settings.marketingEmails,
            onChanged: (v) => notifier.updateSetting('marketingEmails', v),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Private widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: const Color(0xFF2563EB),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF2563EB),
    );
  }
}

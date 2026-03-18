import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/notification_settings.dart';

/// SharedPreferences key used to persist notification settings.
const String _kPrefsKey = 'notification_settings_v1';

/// Provider that exposes [NotificationSettings] and persists changes to
/// SharedPreferences automatically.
///
/// Usage (read current state):
///   final settings = ref.watch(notificationSettingsProvider);
///
/// Usage (update a setting):
///   ref.read(notificationSettingsProvider.notifier).updateSetting('offerReceived', false);
final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    // Load asynchronously and update state once ready.
    // Initial state is the default while loading.
    _loadFromPrefs();
    return NotificationSettings.defaultSettings;
  }

  /// Loads persisted settings from SharedPreferences.
  /// If no data is found or parsing fails, [NotificationSettings.defaultSettings]
  /// is used and immediately persisted so subsequent reads are fast.
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefsKey);
      if (raw != null) {
        state = NotificationSettings.fromJsonString(raw);
      } else {
        // First launch: persist defaults so the key exists on next read.
        await _save(NotificationSettings.defaultSettings);
      }
    } catch (_) {
      // Parsing or I/O error — fall back to defaults silently.
      state = NotificationSettings.defaultSettings;
    }
  }

  /// Updates a single notification preference by [key] and persists the new state.
  ///
  /// Valid keys match the field names of [NotificationSettings]:
  /// - offerReceived
  /// - offerAccepted
  /// - offerCountered
  /// - newMessage
  /// - propertyStatusChange
  /// - marketingEmails
  Future<void> updateSetting(String key, bool value) async {
    final updated = _applyKey(state, key, value);
    state = updated;
    await _save(updated);
  }

  /// Persists [settings] to SharedPreferences as a JSON string.
  Future<void> _save(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, settings.toJsonString());
  }

  /// Returns a new [NotificationSettings] with the field named [key] set to [value].
  /// Throws [ArgumentError] for unknown keys so callers surface mistakes early.
  NotificationSettings _applyKey(
    NotificationSettings current,
    String key,
    bool value,
  ) {
    switch (key) {
      case 'offerReceived':
        return current.copyWith(offerReceived: value);
      case 'offerAccepted':
        return current.copyWith(offerAccepted: value);
      case 'offerCountered':
        return current.copyWith(offerCountered: value);
      case 'newMessage':
        return current.copyWith(newMessage: value);
      case 'propertyStatusChange':
        return current.copyWith(propertyStatusChange: value);
      case 'marketingEmails':
        return current.copyWith(marketingEmails: value);
      default:
        throw ArgumentError.value(key, 'key', 'Clave de notificacion desconocida');
    }
  }
}

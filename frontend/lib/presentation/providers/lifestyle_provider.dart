import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inmufacil_frontend/domain/entities/lifestyle_profile.dart';

/// V63 — Lifestyle Matcher: persisted profile provider
///
/// Persists the user's lifestyle profile to SharedPreferences so it survives
/// app restarts. Uses key [_kPrefsKey] to store/retrieve the JSON payload.

const String _kPrefsKey = 'lifestyle_profile_v1';

class LifestyleNotifier extends Notifier<LifestyleProfile> {
  @override
  LifestyleProfile build() {
    _loadFromPrefs();
    return LifestyleProfile.defaultProfile;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    if (raw != null) {
      try {
        final profile = LifestyleProfile.fromJsonString(raw);
        state = profile;
      } catch (_) {
        // Malformed stored data — fall back to default silently
        state = LifestyleProfile.defaultProfile;
      }
    }
  }

  /// Persists [profile] to SharedPreferences and updates the state.
  Future<void> updateProfile(LifestyleProfile profile) async {
    state = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, profile.toJsonString());
  }
}

final lifestyleProfileProvider =
    NotifierProvider<LifestyleNotifier, LifestyleProfile>(
  LifestyleNotifier.new,
);

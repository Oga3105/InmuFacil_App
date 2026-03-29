import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inmufacil_frontend/domain/entities/lifestyle_profile.dart';
import 'package:inmufacil_frontend/presentation/providers/auth_provider.dart';
import 'package:inmufacil_frontend/presentation/providers/search_provider.dart';

const String _kPrefsKey = 'lifestyle_profile_v1';

class LifestyleNotifier extends Notifier<LifestyleProfile> {
  @override
  LifestyleProfile build() {
    _loadProfile();
    return LifestyleProfile.defaultProfile;
  }

  Future<void> _loadProfile() async {
    // Load from SharedPreferences first (fast, offline-safe)
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    if (raw != null) {
      try {
        state = LifestyleProfile.fromJsonString(raw);
      } catch (_) {
        state = LifestyleProfile.defaultProfile;
      }
    }

    // If authenticated, fetch from backend and override local data
    try {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        final apiClient = ref.read(apiClientProvider);
        final response = await apiClient.client.get('/lifestyle/profile');
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          // Only parse if at least one field is set (non-empty profile)
          if (data.values.any((v) => v != null)) {
            final profile = LifestyleProfile.fromJson(data);
            state = profile;
            await prefs.setString(_kPrefsKey, profile.toJsonString());
          }
        }
      }
    } catch (_) {
      // Backend unavailable — keep local data silently
    }
  }

  /// Persists [profile] locally and to backend if authenticated.
  Future<void> updateProfile(LifestyleProfile profile) async {
    state = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, profile.toJsonString());

    // Sync to backend if authenticated
    try {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.client.post(
          '/lifestyle/profile',
          data: {
            'lifestyle_pace': profile.pace.name,
            'work_style': profile.workStyle.name,
            'mobility_style': profile.mobility.name,
            'sleep_sensitivity': profile.sleep.name,
            'green_needs': profile.greenNeeds.name,
            'profile_type': profile.profileType.name,
            'natural_light_weight': profile.naturalLightWeight,
            'social_weight': profile.socialWeight,
            'ready_to_live_weight': profile.readyToLiveWeight,
          },
        );
      }
    } catch (_) {
      // Backend sync failed silently — local data already saved
    }
  }
}

final lifestyleProfileProvider =
    NotifierProvider<LifestyleNotifier, LifestyleProfile>(
  LifestyleNotifier.new,
);

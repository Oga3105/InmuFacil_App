import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _kConsultedGuidesKey = 'consulted_guides_v1';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final consultedGuidesProvider =
    NotifierProvider<ConsultedGuidesNotifier, Set<String>>(
  ConsultedGuidesNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ConsultedGuidesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    // Kick off async load from SharedPreferences immediately
    Future.microtask(_loadFromPrefs);
    return {};
  }

  /// Load persisted guide keys from SharedPreferences
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_kConsultedGuidesKey);
      if (stored != null && stored.isNotEmpty) {
        final decoded = jsonDecode(stored) as List<dynamic>;
        state = decoded.map((e) => e.toString()).toSet();
      }
    } catch (e) {
      debugPrint('[ConsultedGuidesNotifier] Load error: $e');
    }
  }

  /// Persist current set to SharedPreferences
  Future<void> _save(Set<String> s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kConsultedGuidesKey, jsonEncode(s.toList()));
    } catch (e) {
      debugPrint('[ConsultedGuidesNotifier] Save error: $e');
    }
  }

  /// Mark a guide as consulted and persist.
  /// guideKey format: "${ccaa}_${guideType}"
  Future<void> markAsConsulted(String guideKey) async {
    if (state.contains(guideKey)) return;
    final updated = {...state, guideKey};
    state = updated;
    await _save(updated);
  }

  /// Returns true if the guide has already been consulted.
  bool isConsulted(String guideKey) => state.contains(guideKey);
}

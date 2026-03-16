import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import 'auth_provider.dart';
import 'search_provider.dart';

/// Key used in SharedPreferences to persist favorite IDs locally.
const _kLocalFavoritesKey = 'inmufacil_favorites_v1';

/// Provider to manage the set of favorite property IDs.
/// Persistence strategy:
///   1. Loads from SharedPreferences immediately (instant UI — no flash).
///   2. Syncs from API in background and updates state.
///   3. On every toggle: optimistic update + backend sync + local cache save.
///   4. On backend error: rolls back state to previous value.
final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<Set<String>> {
  late bool _isLoggedIn;
  late dynamic _apiClient;

  @override
  Set<String> build() {
    final authState = ref.watch(authProvider);
    _apiClient = ref.watch(apiClientProvider);
    _isLoggedIn = authState.user != null;

    // Load from local cache immediately (synchronous path via Future.microtask)
    Future.microtask(_initFavorites);

    return {};
  }

  Future<void> _initFavorites() async {
    // 1. Load local cache for instant display
    final cached = await _loadLocalCache();
    if (cached.isNotEmpty) {
      state = cached;
    }

    // 2. Sync from API if authenticated (authoritative source)
    if (_isLoggedIn) {
      await _loadFavoritesFromApi();
    }
  }

  // ---------------------------------------------------------------------------
  // Local cache (SharedPreferences)
  // ---------------------------------------------------------------------------

  Future<Set<String>> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_kLocalFavoritesKey) ?? [];
      return stored.toSet();
    } catch (e) {
      debugPrint('Favorites local cache read error: $e');
      return {};
    }
  }

  Future<void> _saveLocalCache(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kLocalFavoritesKey, ids.toList());
    } catch (e) {
      debugPrint('Favorites local cache write error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Remote sync
  // ---------------------------------------------------------------------------

  Future<void> _loadFavoritesFromApi() async {
    try {
      final response = await _apiClient.client.get(ApiConstants.favoritesList);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final fromApi = data.map((id) => id.toString()).toSet();
        state = fromApi;
        // Keep local cache in sync with authoritative API response
        await _saveLocalCache(fromApi);
      }
    } catch (e) {
      debugPrint('Favorites API load error: $e');
      // Keep whatever was loaded from local cache
    }
  }

  // ---------------------------------------------------------------------------
  // Toggle with optimistic UI + rollback
  // ---------------------------------------------------------------------------

  void toggleFavorite(String propertyId) {
    final previous = Set<String>.from(state);
    final updated = Set<String>.from(state);

    if (updated.contains(propertyId)) {
      updated.remove(propertyId);
    } else {
      updated.add(propertyId);
    }

    // Optimistic update
    state = updated;
    _saveLocalCache(updated);

    if (_isLoggedIn) {
      _syncToggleWithApi(propertyId, previous);
    }
  }

  Future<void> _syncToggleWithApi(
      String propertyId, Set<String> previousState) async {
    try {
      await _apiClient.client.post(ApiConstants.favoriteToggle(propertyId));
    } catch (e) {
      debugPrint('Favorites sync error: $e');
      // Rollback to previous state on backend failure
      state = previousState;
      await _saveLocalCache(previousState);
    }
  }

  // ---------------------------------------------------------------------------
  // Public refresh (call after login)
  // ---------------------------------------------------------------------------

  Future<void> refresh() async {
    if (_isLoggedIn) {
      await _loadFavoritesFromApi();
    }
  }
}

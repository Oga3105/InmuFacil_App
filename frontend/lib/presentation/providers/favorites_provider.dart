import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import 'auth_provider.dart';
import 'search_provider.dart'; // To get apiClientProvider

/// Provider to manage the set of favorite property IDs.
final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<Set<String>> {
  late bool _isLoggedIn;
  late dynamic _apiClient; // Using dynamic or exact type if known

  @override
  Set<String> build() {
    final authState = ref.watch(authProvider);
    _apiClient = ref.watch(apiClientProvider);
    _isLoggedIn = authState.user != null;
    if (_isLoggedIn) {
      Future.microtask(_loadFavoritesFromApi);
    }
    return {};
  }

  Future<void> _loadFavoritesFromApi() async {
    try {
      final response = await _apiClient.client.get(ApiConstants.favoritesList);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        state = data.map((id) => id.toString()).toSet();
      }
    } catch (e) {
      // Handle error silently or log it
      debugPrint('Error loading favorites: $e');
    }
  }

  void toggleFavorite(String propertyId) {
    final newState = Set<String>.from(state);
    if (newState.contains(propertyId)) {
      newState.remove(propertyId);
      if (_isLoggedIn) {
        _syncToggleWithApi(propertyId);
      }
    } else {
      newState.add(propertyId);
      if (_isLoggedIn) {
        _syncToggleWithApi(propertyId);
      }
    }
    state = newState;
  }

  Future<void> _syncToggleWithApi(String propertyId) async {
    try {
      // Endpoint is /favorites/{property_id} (api_v1 is in baseUrl)
      await _apiClient.client.post(ApiConstants.favoriteToggle(propertyId));
    } catch (e) {
      debugPrint('Error syncing favorite: $e');
    }
  }
}

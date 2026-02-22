import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'search_provider.dart'; // To get apiClientProvider

/// Provider to manage the set of favorite property IDs.
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  final authState = ref.watch(authProvider);
  final apiClient = ref.watch(apiClientProvider);
  return FavoritesNotifier(ref, authState.user != null, apiClient);
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final Ref _ref;
  final bool _isLoggedIn;
  final _apiClient; // Using dynamic or exact type if known

  FavoritesNotifier(this._ref, this._isLoggedIn, this._apiClient) : super({}) {
    if (_isLoggedIn) {
      _loadFavoritesFromApi();
    }
  }

  Future<void> _loadFavoritesFromApi() async {
    try {
      final response = await _apiClient.client.get('/api/v1/favorites/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        state = data.map((id) => id.toString()).toSet();
      }
    } catch (e) {
      // Handle error silently or log it
      print('Error loading favorites: $e');
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
      // Endpoint is /api/v1/favorites/{property_id}
      await _apiClient.client.post('/api/v1/favorites/$propertyId');
    } catch (e) {
      print('Error syncing favorite: $e');
    }
  }
}

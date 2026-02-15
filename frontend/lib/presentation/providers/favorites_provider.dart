import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

/// Provider to manage the set of favorite property IDs.
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  final authState = ref.watch(authProvider);
  return FavoritesNotifier(ref, authState.user != null);
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final Ref _ref;
  final bool _isLoggedIn;

  FavoritesNotifier(this._ref, this._isLoggedIn) : super({}) {
    if (_isLoggedIn) {
      _loadFavoritesFromApi();
    }
  }

  Future<void> _loadFavoritesFromApi() async {
    // TODO: Implement API call to GET /api/v1/favorites/
    // Since we don't have the API client integrated here yet, 
    // we'll simulate or wait for repository implementation.
    // For now, it maintains the local set.
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
    // TODO: Implement API call to POST /api/v1/favorites/{id}
  }
}

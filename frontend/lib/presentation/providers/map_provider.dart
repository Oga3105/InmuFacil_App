import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmufacil_frontend/domain/entities/property.dart';
import 'package:inmufacil_frontend/domain/entities/property_type.dart';
import 'package:inmufacil_frontend/presentation/providers/search_provider.dart';

/// Provider to manage the state of properties displayed on the map
final mapPropertiesProvider = StateNotifierProvider<MapPropertiesNotifier, AsyncValue<List<Property>>>((ref) {
  final repository = ref.watch(propertyRepositoryProvider);
  return MapPropertiesNotifier(repository);
});

class MapPropertiesNotifier extends StateNotifier<AsyncValue<List<Property>>> {
  final dynamic _repository; // Using dynamic because strict type might fail if Provider not exported yet

  MapPropertiesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProperties();
  }

  Future<void> loadProperties() async {
    try {
      state = const AsyncValue.loading();
      
      // Initial load: Get all properties (or default filter)
      final result = await _repository.getProperties(
        type: PropertyType.all,
      );
      
      result.fold(
        (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
        (properties) => state = AsyncValue.data(properties),
      );
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }
  
  Future<void> refresh() async {
    await loadProperties();
  }
}

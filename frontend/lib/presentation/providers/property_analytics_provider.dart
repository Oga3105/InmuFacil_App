import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/property_model.dart';
import '../../domain/entities/property.dart';
import 'search_provider.dart'; // apiClientProvider

class PropertyAnalytics {
  const PropertyAnalytics({
    required this.views,
    required this.favorites,
    required this.offers,
  });

  final int views;
  final int favorites;
  final int offers;
}

/// Fetches seller analytics for a property. Only the owner can read these.
/// Returns null on error (e.g. not the owner).
final propertyAnalyticsProvider =
    FutureProvider.autoDispose.family<PropertyAnalytics?, String>(
  (ref, propertyId) async {
    final client = ref.watch(apiClientProvider);
    try {
      final resp =
          await client.client.get('/properties/$propertyId/analytics');
      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        return PropertyAnalytics(
          views: (data['views'] as num?)?.toInt() ?? 0,
          favorites: (data['favorites'] as num?)?.toInt() ?? 0,
          offers: (data['offers'] as num?)?.toInt() ?? 0,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  },
);

/// Fetches a single property by ID directly from the API.
/// Used as fallback in property_details_screen when the property is not yet
/// in the search cache (e.g. just created or just edited with new images).
final propertyByIdProvider =
    FutureProvider.autoDispose.family<Property?, String>(
  (ref, propertyId) async {
    final client = ref.watch(apiClientProvider);
    try {
      final resp = await client.client.get('/api/v1/properties/$propertyId');
      if (resp.statusCode == 200) {
        return PropertyModel.fromJson(
                resp.data as Map<String, dynamic>)
            .toEntity();
      }
      return null;
    } catch (_) {
      return null;
    }
  },
);

/// FutureProvider that logs a view — call via ref.read().
/// Use logPropertyViewProvider(propertyId) and ignore the result.
final logPropertyViewProvider =
    FutureProvider.autoDispose.family<void, String>(
  (ref, propertyId) async {
    final client = ref.watch(apiClientProvider);
    try {
      await client.client.post('/properties/$propertyId/view');
    } catch (_) {}
  },
);

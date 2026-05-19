import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/api_client.dart';
import 'search_provider.dart';
import 'lifestyle_provider.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class NeighborhoodTwin {
  const NeighborhoodTwin({
    required this.postalCode,
    required this.neighborhoodName,
    required this.city,
    required this.similarityScore,
    this.avgPriceSqm,
    this.keySimilarities = const [],
    this.keyDifferences = const [],
    this.vibe = '',
    this.availableCount = 0,
    this.priceFrom,
    this.priceTo,
  });

  final String postalCode;
  final String neighborhoodName;
  final String city;
  final int similarityScore;
  final int? avgPriceSqm;
  final List<String> keySimilarities;
  final List<String> keyDifferences;
  final String vibe;
  // Real stock on InmuFacil for this twin zone
  final int availableCount;
  final int? priceFrom;
  final int? priceTo;

  factory NeighborhoodTwin.fromJson(Map<String, dynamic> json) {
    return NeighborhoodTwin(
      postalCode: json['postal_code'] as String? ?? '',
      neighborhoodName: json['neighborhood_name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      similarityScore: (json['similarity_score'] as num?)?.toInt() ?? 0,
      avgPriceSqm: (json['avg_price_sqm'] as num?)?.toInt(),
      keySimilarities: (json['key_similarities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      keyDifferences: (json['key_differences'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      vibe: json['vibe'] as String? ?? '',
      availableCount: (json['available_count'] as num?)?.toInt() ?? 0,
      priceFrom: (json['price_from'] as num?)?.toInt(),
      priceTo: (json['price_to'] as num?)?.toInt(),
    );
  }
}

class NeighborhoodTwinsResult {
  const NeighborhoodTwinsResult({
    required this.sourcePostalCode,
    required this.twins,
    required this.lowData,
    required this.disclaimer,
  });

  final String sourcePostalCode;
  final List<NeighborhoodTwin> twins;
  final bool lowData;
  final String disclaimer;

  factory NeighborhoodTwinsResult.fromJson(Map<String, dynamic> json) {
    return NeighborhoodTwinsResult(
      sourcePostalCode: json['source_postal_code'] as String? ?? '',
      twins: (json['twins'] as List<dynamic>?)
              ?.map((e) => NeighborhoodTwin.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lowData: json['low_data'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Request key — combines postal code + lifestyle params for cache identity
// ---------------------------------------------------------------------------

class TwinsRequestKey {
  const TwinsRequestKey({
    required this.postalCode,
    this.city,
    this.contextCities,
  });
  final String postalCode;
  final String? city;
  // Cities visible/active in the frontend — constrains Gemini to local stock
  final List<String>? contextCities;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TwinsRequestKey &&
          other.postalCode == postalCode &&
          other.city == city &&
          _listEquals(other.contextCities, contextCities);

  @override
  int get hashCode => Object.hash(postalCode, city, contextCities?.join(','));

  static bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Fetches neighborhood twins for a given postal code, enriched with the
/// user's lifestyle profile when available.
final neighborhoodTwinsProvider = FutureProvider.autoDispose
    .family<NeighborhoodTwinsResult?, TwinsRequestKey>((ref, key) async {
  if (key.postalCode.isEmpty) return null;

  final apiClient = ref.watch(apiClientProvider);
  final lifestyle = ref.watch(lifestyleProfileProvider);

  final body = <String, dynamic>{
    'postal_code': key.postalCode,
    if (key.city != null) 'city': key.city,
    if (key.contextCities != null && key.contextCities!.isNotEmpty)
      'context_cities': key.contextCities,
    'lifestyle_pace': lifestyle.pace.name,
    'work_style': lifestyle.workStyle.name,
    'mobility_style': lifestyle.mobility.name,
    'green_needs': lifestyle.greenNeeds.name,
    'max_results': 5,
  };

  try {
    final response = await apiClient.client.post(
      '/ai/neighborhood-twins',
      data: body,
    );

    if (response.statusCode == 200 && response.data != null) {
      return NeighborhoodTwinsResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return null;
  } catch (_) {
    return null;
  }
});

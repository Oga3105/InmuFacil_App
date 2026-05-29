import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:inmufacil_frontend/domain/entities/property.dart';
import 'package:inmufacil_frontend/domain/entities/property_type.dart';
import 'package:inmufacil_frontend/domain/repositories/property_repository.dart';
import 'package:inmufacil_frontend/data/repositories/property_repository_impl.dart';
import 'package:inmufacil_frontend/data/datasources/remote/api_client.dart';
import 'package:inmufacil_frontend/core/services/location_service.dart';
import 'package:inmufacil_frontend/presentation/providers/map_state_provider.dart';
import 'package:inmufacil_frontend/presentation/providers/lifestyle_provider.dart';
import 'package:inmufacil_frontend/domain/entities/lifestyle_profile.dart';

/// Search state for property filtering
class SearchState {
  
  const SearchState({
    this.propertyType = PropertyType.all,
    this.location = '',
    this.priceRange = const RangeValues(0, 1000000),
    this.currentMaxPriceLimit = 1000000,
    this.filteredProperties = const [],
    this.mapCenter = _spainCenter,
    this.isLoading = false,
    this.error,
    this.isUsingFallbackLocation = false,
    this.onlyFavorites = false,
    this.onlyVerified = false,
    this.currentPage = 1,
    this.itemsPerPage = 5,
    this.viewMode = PropertyViewMode.list,
    this.sortBy = SortOption.relevance,
    this.minBedrooms = 0,
    this.selectedExtras = const [],
    this.lastSearchResultGeoJson,
    this.lastSearchResultBbox,
    this.useLifestyleFilter = false,
  });
  final PropertyType propertyType;
  final String location;
  final RangeValues priceRange;
  final double currentMaxPriceLimit;
  final List<Property> filteredProperties;
  final LatLng? mapCenter;
  final bool isLoading;
  final String? error;
  final bool isUsingFallbackLocation;
  final bool onlyFavorites; // Added
  final bool onlyVerified; // Added
  final int currentPage; // Added
  final int itemsPerPage; // Added
  final PropertyViewMode viewMode; // Added
  final SortOption sortBy; // Added
  final int minBedrooms; // Added missing field
  final List<String> selectedExtras; // Added missing field
  final String? lastSearchResultGeoJson; // Restored
  final List<String>? lastSearchResultBbox; // Restored
  final bool useLifestyleFilter;
  
  // Spain center coordinates for initial wide view (shows entire country)
  static const LatLng _spainCenter = LatLng(40.4, -3.7);
  
  SearchState copyWith({
    PropertyType? propertyType,
    String? location,
    RangeValues? priceRange,
    double? currentMaxPriceLimit,
    List<Property>? filteredProperties,
    LatLng? mapCenter,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isUsingFallbackLocation,
    bool? onlyFavorites,
    bool? onlyVerified,
    int? currentPage,
    int? itemsPerPage,
    PropertyViewMode? viewMode,
    SortOption? sortBy,
    int? minBedrooms,
    List<String>? selectedExtras,
    String? lastSearchResultGeoJson,
    List<String>? lastSearchResultBbox,
    bool? useLifestyleFilter,
  }) {
    return SearchState(
      propertyType: propertyType ?? this.propertyType,
      location: location ?? this.location,
      priceRange: priceRange ?? this.priceRange,
      currentMaxPriceLimit: currentMaxPriceLimit ?? this.currentMaxPriceLimit,
      filteredProperties: filteredProperties ?? this.filteredProperties,
      mapCenter: mapCenter ?? this.mapCenter,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isUsingFallbackLocation: isUsingFallbackLocation ?? this.isUsingFallbackLocation,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      onlyVerified: onlyVerified ?? this.onlyVerified,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      viewMode: viewMode ?? this.viewMode,
      sortBy: sortBy ?? this.sortBy,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      selectedExtras: selectedExtras ?? this.selectedExtras,
      lastSearchResultGeoJson: lastSearchResultGeoJson ?? this.lastSearchResultGeoJson,
      lastSearchResultBbox: lastSearchResultBbox ?? this.lastSearchResultBbox,
      useLifestyleFilter: useLifestyleFilter ?? this.useLifestyleFilter,
    );
  }
}

/// Search provider for managing property search state
class SearchNotifier extends Notifier<SearchState> {
  late PropertyRepository _repository;
  late LocationService _locationService;
  Timer? _debounceTimer;

  @override
  SearchState build() {
    _repository = ref.watch(propertyRepositoryProvider);
    _locationService = ref.watch(locationServiceProvider);
    ref.onDispose(() => _debounceTimer?.cancel());
    return const SearchState();
  }
  
  
  /// Initialize user location (or fallback to Sevilla)
  Future<void> initLocation() async {
    state = state.copyWith(isLoading: true);
    
    final result = await _locationService.getCurrentLocation();
    
    state = state.copyWith(
      mapCenter: result.location,
      isUsingFallbackLocation: result.isFallback,
      isLoading: false,
    );
    
    // Load properties after location is set
    await _loadProperties();
  }
  
  /// Update property type filter
  void updatePropertyType(PropertyType type) {
    state = state.copyWith(propertyType: type, currentPage: 1);
    _loadProperties();
  }
  
  /// Update location and geocode to coordinates
  Future<void> updateLocation(String location) async {
    if (location.isEmpty) {
      state = state.copyWith(
        location: '',
        mapCenter: LocationService.spainFallback,
      );
      return;
    }
    
    state = state.copyWith(
      location: location,
      isLoading: true,
      clearError: true,
    );
    
    try {
      // Geocode location to coordinates
      final locations = await locationFromAddress('$location, España');
      if (locations.isNotEmpty) {
        final coords = LatLng(
          locations.first.latitude,
          locations.first.longitude,
        );
        state = state.copyWith(
          mapCenter: coords,
          isLoading: false,
        );
        await _loadProperties();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudo encontrar la ubicación: $location',
      );
    }
  }

  /// Toggle favorites filter
  void toggleOnlyFavorites() {
    state = state.copyWith(onlyFavorites: !state.onlyFavorites);
    // Note: Local filter applies in UI or here? 
    // Usually local favorites are filtered in the widget based on IDs.
  }

  /// Toggle verified properties filter
  void toggleOnlyVerified() {
    state = state.copyWith(onlyVerified: !state.onlyVerified, currentPage: 1);
    _loadProperties();
  }

  /// Toggle lifestyle profile filter
  void toggleLifestyleFilter() {
    state = state.copyWith(useLifestyleFilter: !state.useLifestyleFilter);
  }

  /// Update current page for pagination
  void setPage(int page) {
    state = state.copyWith(currentPage: page);
    _loadProperties();
  }

  /// Update view mode (grid/list) and adjust items per page
  void updateViewMode(PropertyViewMode mode) {
    final itemsPerPage = mode == PropertyViewMode.list ? 5 : 9;
    state = state.copyWith(viewMode: mode, itemsPerPage: itemsPerPage, currentPage: 1);
  }

  /// Update sorting criteria
  void setSortBy(SortOption option) {
    state = state.copyWith(sortBy: option);
    _loadProperties();
  }

  /// Clear location text and search state
  void clearSearchText() {
    state = state.copyWith(location: '', clearError: true);
  }

  /// Reset only search criteria filters (preserves location and map bounds)
  void resetFilters() {
    state = state.copyWith(
      propertyType: PropertyType.all,
      priceRange: const RangeValues(0, 1000000),
      currentMaxPriceLimit: 1000000,
      minBedrooms: 0,
      selectedExtras: [],
    );
    _loadProperties(); // Refresh the list without these filters
  }

  /// Update minimum bedrooms filter
  void updateMinBedrooms(int value) {
    state = state.copyWith(minBedrooms: value, currentPage: 1);
    _loadProperties();
  }

  /// Toggle extra feature filter
  void toggleExtra(String extra) {
    final extras = List<String>.from(state.selectedExtras);
    if (extras.contains(extra)) {
      extras.remove(extra);
    } else {
      extras.add(extra);
    }
    state = state.copyWith(selectedExtras: extras, currentPage: 1);
    _loadProperties();
  }

  /// Update price range filter
  void updatePriceRange(RangeValues range) {
    state = state.copyWith(priceRange: range, currentPage: 1);
    _loadProperties();
  }
  
  /// Update maximum price limit (for custom price input)
  void updateMaxPriceLimit(double newLimit) {
    if (newLimit <= 0) return;
    
    state = state.copyWith(
      currentMaxPriceLimit: newLimit,
      // Adjust priceRange if it exceeds the new limit
      priceRange: RangeValues(
        state.priceRange.start,
        state.priceRange.end > newLimit 
            ? newLimit 
            : state.priceRange.end,
      ),
    );
    _loadProperties();
  }
  
  /// Execute search with current filters
  void search() {
    state = state.copyWith(currentPage: 1);
    _loadProperties();
  }
  
  /// Search for a city using Nominatim geocoding API (with 500ms debounce).
  /// Use for real-time text-field input only.
  /// For explicit button presses use [searchCityNow].
  Future<void> searchCity(String query) async {
    final sanitized = query.trim();
    if (sanitized.isEmpty) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await _doSearchCity(sanitized);
    });
  }

  /// Search for a city immediately (no debounce).
  /// Use for explicit button presses on Home and Search pages.
  Future<void> searchCityNow(String query) async {
    final sanitized = query.trim();
    if (sanitized.isEmpty) return;

    // Cancel any pending debounced search to avoid a later overwrite.
    _debounceTimer?.cancel();
    await _doSearchCity(sanitized);
  }

  /// Core geocoding logic shared by [searchCity] and [searchCityNow].
  ///
  /// Strategy: "Local First, Global Fallback"
  /// 1. Try Spain-only search first (prioritizes local results)
  /// 2. If no results, automatically search worldwide
  ///
  /// Security: Input sanitized, length-limited, character-validated
  Future<void> _doSearchCity(String sanitized) async {
    // SECURITY: Length validation (Nominatim recommends max 200 chars)
    if (sanitized.length > 200) {
      state = state.copyWith(
        error: 'Búsqueda demasiado larga (máx. 200 caracteres)',
        isLoading: false,
      );
      return;
    }

    // SECURITY: Character whitelist - Allow letters, numbers, spaces, common punctuation
    final validPattern = RegExp(r"^[a-zA-ZáéíóúñÁÉÍÓÚÑüÜ0-9\s,.\-\']+$");
    if (!validPattern.hasMatch(sanitized)) {
      state = state.copyWith(
        error: 'Caracteres no válidos en la búsqueda',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // STEP 1: Primary attempt - Search only in Spain
      final urlSpain = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$sanitized&format=json&limit=1&countrycodes=es&polygon_geojson=1&addressdetails=1',
      );

      var response = await http.get(urlSpain, headers: {
        'User-Agent': 'com.inmufacil.app/1.0',
      });

      var data = json.decode(response.body);

      // STEP 2: Verification and Fallback
      if (data is List && data.isEmpty) {
        debugPrint('Not found in Spain. Searching globally...');

        final urlGlobal = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$sanitized&format=json&limit=1&polygon_geojson=1&addressdetails=1',
        );

        response = await http.get(urlGlobal, headers: {
          'User-Agent': 'com.inmufacil.app/1.0',
        });

        data = json.decode(response.body);
      }

      // STEP 3: Final Processing
      if (data is List && data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        final displayName = data[0]['display_name'] as String;

        // Extract Bounding Box safely
        List<String>? bbox;
        if (data[0]['boundingbox'] != null && data[0]['boundingbox'] is List) {
          bbox = (data[0]['boundingbox'] as List).map((e) => e.toString()).toList();
        }

        // Extract GeoJSON for "Real Shape"
        String? geoJsonStr;
        if (data[0]['geojson'] != null) {
          geoJsonStr = json.encode(data[0]['geojson']);
        }

        // Update search state
        state = state.copyWith(
          mapCenter: LatLng(lat, lon),
          location: displayName.split(',')[0],
          isUsingFallbackLocation: false,
          isLoading: false,
          lastSearchResultBbox: bbox,
          lastSearchResultGeoJson: geoJsonStr,
          currentPage: 1,
        );

        // Sync mapState directly so Home map reflects the new location even
        // when OpenStreetMapWidget is in the background (onPositionChanged
        // does not fire for programmatic moves on off-screen widgets).
        _syncMapState(bbox, geoJsonStr);

        debugPrint('Location found: $displayName');

        // Reload properties for new location
        await _loadProperties();
      } else {
        debugPrint('Location not found anywhere.');
        state = state.copyWith(
          error: 'No se encontró la ubicación: $sanitized',
          isLoading: false,
        );
      }
    } catch (e) {
      // SECURITY: Generic error message (don't expose exception details to user)
      debugPrint('Error in search algorithm: $e');
      state = state.copyWith(
        error: 'Error al buscar ubicación. Inténtalo de nuevo.',
        isLoading: false,
      );
    }
  }

  /// Synchronise [mapStateProvider] with the geocoding result.
  ///
  /// This is necessary when the search is triggered from the Search page
  /// (PropertyListingScreen) while the Home map widget is in the navigation
  /// background. In that scenario, [OpenStreetMapWidget.onPositionChanged]
  /// does not fire for programmatic moves, so [mapState.visibleBounds] and
  /// [mapState.cityBoundaryPolygon] would remain stale (pointing to the
  /// previous city). As a result, [filteredByMapPropertiesProvider] would
  /// filter out all properties for the new location when the user returns
  /// to the Home map.
  void _syncMapState(List<String>? bbox, String? geoJsonStr) {
    final mapNotifier = ref.read(mapStateProvider.notifier);

    // Update city boundary polygon from GeoJSON (real shape) or bbox fallback
    if (geoJsonStr != null) {
      try {
        final geoJsonData = json.decode(geoJsonStr) as Map<String, dynamic>;
        mapNotifier.setCityBoundaryFromGeoJson(geoJsonData);
      } catch (_) {
        if (bbox != null) mapNotifier.setCityBoundary(bbox);
      }
    } else if (bbox != null) {
      mapNotifier.setCityBoundary(bbox);
    }

    // Update visible bounds from bbox so filteredByMapPropertiesProvider
    // immediately reflects the new search area.
    if (bbox != null && bbox.length == 4) {
      try {
        final south = double.parse(bbox[0]);
        final north = double.parse(bbox[1]);
        final west = double.parse(bbox[2]);
        final east = double.parse(bbox[3]);
        mapNotifier.setVisibleBounds(
          LatLngBounds(LatLng(south, west), LatLng(north, east)),
        );
      } catch (_) {}
    }
  }
  
  /// Load properties from repository with current filters
  Future<void> _loadProperties() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    final result = await _repository.getProperties(
      type: state.propertyType != PropertyType.all 
          ? state.propertyType 
          : null,
      minPrice: state.priceRange.start,
      maxPrice: state.priceRange.end,
      center: state.mapCenter,
      radiusKm: 50, // 50km radius from center
    );
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
          filteredProperties: [], // Estado cero on error
        );
      },
      (properties) {
        // CLIENT-SIDE FILTERING (Type, Bedrooms, Extras)
        var filteredList = properties;

        // 0. Exclude sold properties (safety net — backend also filters, but
        //    a case mismatch between legacy UPPERCASE names and lowercase values
        //    stored by closing_service can let sold rows slip through).
        filteredList = filteredList
            .where((p) => (p.status ?? '').toLowerCase() != 'sold')
            .toList();

        // 1. Filter by Property Type (Guarantee strict match regardless of backend)
        if (state.propertyType != PropertyType.all) {
          filteredList = filteredList.where((p) => p.type == state.propertyType).toList();
        }
        
        // 2. Filter by Bedrooms
        if (state.minBedrooms > 0) {
          filteredList = filteredList.where((p) => p.bedrooms >= state.minBedrooms).toList();
        }
        
        // 2. Filter by Extras
        if (state.selectedExtras.isNotEmpty) {
          filteredList = filteredList.where((p) {
            final txt = '${p.title} ${p.description} ${p.address}'.toLowerCase();
            for (final extra in state.selectedExtras) {
              if (extra == 'Piscina' && !txt.contains('piscina') && !txt.contains('pool')) return false;
              if (extra == 'Terraza' && !txt.contains('terraza') && !txt.contains('terrace')) return false;
              if (extra == 'Garaje' && !txt.contains('garaje') && !txt.contains('parking') && !txt.contains('plaza')) return false;
              if (extra == 'Jardín' && !txt.contains('jardín') && !txt.contains('jardin') && !txt.contains('garden')) return false;
              if (extra == 'Ascensor' && !txt.contains('ascensor') && !txt.contains('lift') && !txt.contains('elevator')) return false;
              if (extra == 'Aire Acondicionado' && !txt.contains('aire') && !txt.contains('acondicionado') && !txt.contains('ac')) return false;
              if (extra == 'Calefacción' && !txt.contains('calefacción') && !txt.contains('calefaccion') && !txt.contains('heating')) return false;
              if (extra == 'Trastero' && !txt.contains('trastero') && !txt.contains('storage')) return false;
              if (extra == 'Armarios Empotrados' && !txt.contains('armario') && !txt.contains('wardrobe')) return false;
              if (extra == 'Exterior' && !txt.contains('exterior')) return false;
              if (extra == 'Acceso movilidad reducida' && !txt.contains('accesible') && !txt.contains('movilidad')) return false;
            }
            return true;
          }).toList();
        }

        // CLIENT-SIDE SORTING
        switch (state.sortBy) {
          case SortOption.priceLowToHigh:
            filteredList.sort((a, b) => a.price.compareTo(b.price));
          case SortOption.priceHighToLow:
            filteredList.sort((a, b) => b.price.compareTo(a.price));
          case SortOption.newest:
            filteredList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          case SortOption.relevance:
            break; // Keep API default order
        }

        state = state.copyWith(
          isLoading: false,
          clearError: true,
          filteredProperties: filteredList,
        );
      },
    );
  }
  
  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Force-reload the property list from the API (call after create/edit).
  Future<void> refresh() => _loadProperties();

  /// Reset all filters and clear geographic map bounds so filteredByMapPropertiesProvider
  /// returns all loaded properties (no location filter active).
  void reset() {
    state = const SearchState();
    ref.read(mapStateProvider.notifier).clearBounds();
    initLocation();
  }
}

/// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for PropertyRepository
final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PropertyRepositoryImpl(apiClient);
});

/// Provider for search state
final searchProvider = NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

/// Provider that exposes only the filtered properties from the search state
/// Used by Home screen and Map widgets for reactivity
final filteredByMapPropertiesProvider = Provider<List<Property>>((ref) {
  final searchState = ref.watch(searchProvider);
  final mapState = ref.watch(mapStateProvider);
  
  var properties = searchState.filteredProperties;
  
  if (properties.isEmpty) return [];

  var filtered = properties.where((property) {
    // 1. Check Custom Zone (Highest priority if active)
    if (mapState.currentZonePolygon.isNotEmpty) {
      if (!_isPointInPolygon(property.location, mapState.currentZonePolygon)) {
        return false;
      }
    }
    // 2. Check City Boundary (Nominatim Search Result)
    else if (mapState.cityBoundaryPolygon.isNotEmpty) {
      if (!_isPointInPolygon(property.location, mapState.cityBoundaryPolygon)) {
        return false;
      }
    }

    // 3. ALWAYS check Visible Viewport
    if (mapState.visibleBounds != null) {
      if (!mapState.visibleBounds!.contains(property.location)) {
        return false;
      }
    }

    return true;
  }).toList();

  // Lifestyle filter — sort by match score (best first), never hide properties
  if (searchState.useLifestyleFilter) {
    final profile = ref.watch(lifestyleProfileProvider);
    filtered.sort((a, b) =>
        _lifestyleScore(b, profile).compareTo(_lifestyleScore(a, profile)));
  }

  return filtered;
});

/// Computes a lifestyle compatibility score for a property given a profile.
/// Uses text search on title+description+address (same as extras filtering).
int _lifestyleScore(Property prop, LifestyleProfile profile) {
  int score = 0;
  final txt = '${prop.title} ${prop.description} ${prop.address}'.toLowerCase();
  final bedrooms = prop.bedrooms;

  // Movilidad → Garaje
  if (profile.mobility == MobilityStyle.private_car &&
      (txt.contains('garaje') || txt.contains('parking') || txt.contains('plaza'))) score++;
  // Entorno verde → Jardin, Terraza
  if ((profile.greenNeeds == GreenNeeds.needs_green || profile.greenNeeds == GreenNeeds.mountain_nature) &&
      (txt.contains('jardín') || txt.contains('jardin') || txt.contains('terraza'))) score++;
  // Teletrabajo/hibrido/freelance → habitacion extra (minimo 2 hab)
  if ((profile.workStyle == WorkStyle.home_office || profile.workStyle == WorkStyle.hybrid || profile.workStyle == WorkStyle.freelance) &&
      bedrooms >= 2) score++;
  // Familia con niños → mas habitaciones
  if (profile.profileType == ProfileType.family_children && bedrooms >= 3) score++;
  // Senior → ascensor
  if (profile.profileType == ProfileType.senior &&
      (txt.contains('ascensor') || txt.contains('lift') || txt.contains('elevator'))) score++;
  // Sensible al ruido → exterior
  if (profile.sleep == SleepSensitivity.high_noise_sensitivity && txt.contains('exterior')) score++;
  // Social alto → piscina
  if (profile.socialWeight > 0.6 && txt.contains('piscina')) score++;
  // Bicicleta/a pie → terraza o exterior
  if ((profile.mobility == MobilityStyle.cycling || profile.mobility == MobilityStyle.walking) &&
      (txt.contains('exterior') || txt.contains('terraza'))) score++;
  // Inversor → cualquier propiedad suma (siempre positivo)
  if (profile.profileType == ProfileType.investor) score++;

  return score;
}

/// Lifestyle-sorted properties for the listing screen (no geo/viewport filter).
/// Used when there is no active location search, so the viewport does not
/// eliminate results — only the sort order changes.
final lifestyleSortedPropertiesProvider = Provider<List<Property>>((ref) {
  final searchState = ref.watch(searchProvider);
  final properties = searchState.filteredProperties;
  if (properties.isEmpty) return [];
  if (!searchState.useLifestyleFilter) return properties;
  final profile = ref.watch(lifestyleProfileProvider);
  final sorted = List<Property>.from(properties);
  sorted.sort((a, b) => _lifestyleScore(b, profile).compareTo(_lifestyleScore(a, profile)));
  return sorted;
});

/// Ray-casting algorithm to determine if a point is within a polygon
bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
  int intersectCount = 0;
  for (int j = 0; j < polygon.length - 1; j++) {
    if (_rayCastIntersect(point, polygon[j], polygon[j + 1])) {
      intersectCount++;
    }
  }
  // Check closing segment
  if (_rayCastIntersect(point, polygon[polygon.length - 1], polygon[0])) {
    intersectCount++;
  }
  return (intersectCount % 2) == 1; // Odd means inside
}

bool _rayCastIntersect(LatLng point, LatLng vertA, LatLng vertB) {
  double aY = vertA.latitude;
  double bY = vertB.latitude;
  double aX = vertA.longitude;
  double bX = vertB.longitude;
  double pY = point.latitude;
  double pX = point.longitude;

  if ((aY > pY && bY > pY) || (aY < pY && bY < pY) || (aX < pX && bX < pX)) {
    return false;
  }
  
  if (aX == bX) {
     return true; // Vertical line segment intersection
  }
  
  double m = (aY - bY) / (aX - bX);
  double b = (-aX) * m + aY;
  double xIntersect = (pY - b) / m;
  
  return xIntersect > pX;
}

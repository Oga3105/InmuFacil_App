import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
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
  }) {
    return SearchState(
      propertyType: propertyType ?? this.propertyType,
      location: location ?? this.location,
      priceRange: priceRange ?? this.priceRange,
      currentMaxPriceLimit: currentMaxPriceLimit ?? this.currentMaxPriceLimit,
      filteredProperties: filteredProperties ?? this.filteredProperties,
      mapCenter: mapCenter ?? this.mapCenter,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
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
    state = state.copyWith(propertyType: type);
    _loadProperties();
  }
  
  /// Update location and geocode to coordinates
  Future<void> updateLocation(String location) async {
    if (location.isEmpty) {
      state = state.copyWith(
        location: '',
        mapCenter: LocationService.sevillaFallback,
      );
      return;
    }
    
    state = state.copyWith(
      location: location,
      isLoading: true,
      error: null,
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
    state = state.copyWith(onlyVerified: !state.onlyVerified);
    _loadProperties();
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
    state = state.copyWith(location: '', error: null);
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
    state = state.copyWith(minBedrooms: value);
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
    state = state.copyWith(selectedExtras: extras);
    _loadProperties();
  }
  
  /// Update price range filter
  void updatePriceRange(RangeValues range) {
    state = state.copyWith(priceRange: range);
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
    _loadProperties();
  }
  
  /// Search for a city using Nominatim geocoding API
  /// Strategy: "Local First, Global Fallback"
  /// 1. Try Spain-only search first (prioritizes local results)
  /// 2. If no results, automatically search worldwide
  /// 
  /// Security: Input sanitized, length-limited, character-validated
  Future<void> searchCity(String query) async {
    // SECURITY: Trim whitespace
    final sanitized = query.trim();
    
    // SECURITY: Check empty
    if (sanitized.isEmpty) return;
    
    // SECURITY: Rate limiting (Debouncing)
    // Cancel any pending search to prevent API abuse (Nominatim policy: max 1 req/sec)
    _debounceTimer?.cancel();
    
    // Wait 500ms before executing search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      // SECURITY: Length validation (Nominatim recommends max 200 chars)
      if (sanitized.length > 200) {
        state = state.copyWith(
          error: 'Búsqueda demasiado larga (máx. 200 caracteres)',
          isLoading: false,
        );
        return;
      }
      
      // SECURITY: Character whitelist - Allow letters, numbers, spaces, common punctuation
      // Prevents injection attempts and ensures valid city names
      final validPattern = RegExp(r"^[a-zA-ZáéíóúñÁÉÍÓÚÑüÜ0-9\s,.\-\']+$");
      if (!validPattern.hasMatch(sanitized)) {
        state = state.copyWith(
          error: 'Caracteres no válidos en la búsqueda',
          isLoading: false,
        );
        return;
      }
      
      state = state.copyWith(isLoading: true, error: null);
      
      try {
        // STEP 1: Primary attempt - Search only in Spain
        // This ensures "Córdoba" or "Valencia" lead to Spanish cities by default
        final urlSpain = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$sanitized&format=json&limit=1&countrycodes=es&polygon_geojson=1&addressdetails=1',
        );
        
        var response = await http.get(urlSpain, headers: {
          'User-Agent': 'com.inmufacil.app/1.0',
        },);
        
        var data = json.decode(response.body);
        
        // STEP 2: Verification and Fallback
        // If empty list, location is not in Spain OR user searches outside (e.g., "Paris", "Córdoba, Argentina")
        if (data is List && data.isEmpty) {
          debugPrint('📍 Not found in Spain. Searching globally...');
          
          // Launch WORLDWIDE search (without countrycodes)
          final urlGlobal = Uri.parse(
            'https://nominatim.openstreetmap.org/search?q=$sanitized&format=json&limit=1&polygon_geojson=1&addressdetails=1',
          );
          
          response = await http.get(urlGlobal, headers: {
            'User-Agent': 'com.inmufacil.app/1.0',
          },);
          
          data = json.decode(response.body);
        }
        
        // STEP 3: Final Processing (if we found something in step 1 or 2)
        if (data is List && data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final displayName = data[0]['display_name']; // Full name for confirmation
          
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
          
          // Update state
          state = state.copyWith(
            mapCenter: LatLng(lat, lon),
            location: displayName.split(',')[0], // Take only city name for input
            isUsingFallbackLocation: false,
            isLoading: false,
            lastSearchResultBbox: bbox,
            lastSearchResultGeoJson: geoJsonStr, // NEW: Store GeoJSON as String
          );
          
          // Visual feedback (useful for TFM demonstration)
          debugPrint('✅ Location found: $displayName');
          
          // Reload properties for new location
          await _loadProperties();
        } else {
          // STEP 4: If everything fails (neither in Spain nor worldwide)
          debugPrint('❌ Location not found anywhere.');
          state = state.copyWith(
            error: 'No se encontró la ubicación: $sanitized',
            isLoading: false,
          );
        }
      } catch (e) {
        // SECURITY: Generic error message (don't expose exception details to user)
        debugPrint('⚠️ Error in search algorithm: $e');
        state = state.copyWith(
          error: 'Error al buscar ubicación. Inténtalo de nuevo.',
          isLoading: false,
        );
      }
    });
  }
  
  /// Load properties from repository with current filters
  Future<void> _loadProperties() async {
    state = state.copyWith(isLoading: true, error: null);
    
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
          error: null,
          filteredProperties: filteredList,
        );
      },
    );
  }
  
  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  /// Reset all filters
  void reset() {
    state = const SearchState();
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

  return properties.where((property) {
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

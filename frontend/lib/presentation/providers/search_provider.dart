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
import 'package:inmufacil_frontend/presentation/providers/map_state_provider.dart'; // Required for mapStateProvider

/// Search state for property filtering
class SearchState {
  final PropertyType propertyType;
  final String location;
  final RangeValues priceRange;
  final double currentMaxPriceLimit;
  final List<Property> filteredProperties;
  final LatLng? mapCenter;
  final bool isLoading;
  final String? error;
  final bool isUsingFallbackLocation;
  final List<String>? lastSearchResultBbox; // [south, north, west, east] from Nominatim
  final Map<String, dynamic>? lastSearchResultGeoJson; // NEW: GeoJSON for real shape
  final bool isSearchActive; // NEW: Track if search button has been pressed
  final int minBedrooms; // NEW: Filter
  final List<String> selectedExtras; // NEW: Filter
  
  // Default view centered on Sevilla for MVP/Demo purposes
  static const LatLng _spainCenter = LatLng(37.3891, -5.9845);
  
  const SearchState({
    this.propertyType = PropertyType.all,
    this.location = '',
    this.priceRange = const RangeValues(0, 1000000), // Updated to match new max
    this.currentMaxPriceLimit = 1000000, // Changed from 10M to 1M for better precision
    this.filteredProperties = const [],
    this.mapCenter = _spainCenter, // Spain-wide view initially
    this.isLoading = false,
    this.error,
    this.isUsingFallbackLocation = false,
    this.lastSearchResultBbox,
    this.lastSearchResultGeoJson,
    this.isSearchActive = false,
    this.minBedrooms = 0,
    this.selectedExtras = const [],
  });
  
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
    List<String>? lastSearchResultBbox,
    Map<String, dynamic>? lastSearchResultGeoJson,
    bool? isSearchActive,
    int? minBedrooms,
    List<String>? selectedExtras,
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
      lastSearchResultBbox: lastSearchResultBbox ?? this.lastSearchResultBbox,
      lastSearchResultGeoJson: lastSearchResultGeoJson ?? this.lastSearchResultGeoJson,
      isSearchActive: isSearchActive ?? this.isSearchActive,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      selectedExtras: selectedExtras ?? this.selectedExtras,
    );
  }
}

/// Search provider for managing property search state
class SearchNotifier extends StateNotifier<SearchState> {
  final PropertyRepository _repository;
  final LocationService _locationService;
  
  SearchNotifier(this._repository, this._locationService) 
      : super(const SearchState());
      
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
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

  /// Update min bedrooms filter
  void updateMinBedrooms(int bedrooms) {
    state = state.copyWith(minBedrooms: bedrooms);
    _loadProperties();
  }

  /// Update extras filter
  void toggleExtra(String extra) {
    final currentExtras = List<String>.from(state.selectedExtras);
    if (currentExtras.contains(extra)) {
      currentExtras.remove(extra);
    } else {
      currentExtras.add(extra);
    }
    state = state.copyWith(selectedExtras: currentExtras);
    _loadProperties();
  }
  
  /// Update location and geocode to coordinates
  Future<void> updateLocation(String location) async {
    if (location.isEmpty) {
      state = state.copyWith(
        location: '',
        mapCenter: LocationService.sevillaFallback,
        lastSearchResultBbox: null,
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
  /// This activates the "Results Mode"
  void search() {
    state = state.copyWith(isSearchActive: true);
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
        // STEP 1: Primary attempt - Search only in Spain with MULTIPLE results
        // fetching 5 results to filter the best match (City vs Province)
        final urlSpain = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$sanitized&format=json&limit=5&countrycodes=es&polygon_geojson=1&addressdetails=1'
        );
        
        var response = await http.get(urlSpain, headers: {
          'User-Agent': 'com.inmufacil.app/1.0'
        });
        
        var data = json.decode(response.body);
        
        // STEP 2: Verification and Fallback
        if (data is List && data.isEmpty) {
          debugPrint("📍 Not found in Spain. Searching globally...");
          
          final urlGlobal = Uri.parse(
            'https://nominatim.openstreetmap.org/search?q=$sanitized&format=json&limit=5&polygon_geojson=1&addressdetails=1'
          );
          
          response = await http.get(urlGlobal, headers: {
            'User-Agent': 'com.inmufacil.app/1.0'
          });
          
          data = json.decode(response.body);
        }
        
        // STEP 3: Final Processing - INTELLIGENT SELECTION
        if (data is List && data.isNotEmpty) {
          // Default to the first result
          var item = data[0];
          
          // Try to find a specific CITY/TOWN/MUNICIPALITY result
          // This fixes the issue where "Sevilla" returns the Province (huge area) first
          final preferredTypes = ['city', 'town', 'municipality', 'village'];
          
          final bestMatch = data.firstWhere(
            (element) => preferredTypes.contains(element['addresstype']),
            orElse: () => null,
          );
          
          if (bestMatch != null) {
            debugPrint("🎯 Found preferred match: ${bestMatch['addresstype']} - ${bestMatch['display_name']}");
            item = bestMatch;
          } else {
             debugPrint("ℹ️ Using default match: ${item['type']} - ${item['display_name']}");
          }
          
          // ROBUST PARSING: Handle potential nulls or types safely
          final lat = double.tryParse(item['lat'].toString()) ?? 0.0;
          final lon = double.tryParse(item['lon'].toString()) ?? 0.0;
          final displayName = item['display_name']?.toString() ?? sanitized;
          
          // Extract Bounding Box safely
          List<String>? bbox;
          if (item['boundingbox'] != null && item['boundingbox'] is List) {
            bbox = (item['boundingbox'] as List).map((e) => e.toString()).toList();
          }
          
          // Extract GeoJSON for "Real Shape"
          // We pass this raw map to the MapState to handle the complex parsing
          Map<String, dynamic>? geoJson;
          if (item['geojson'] != null) {
            geoJson = item['geojson'] as Map<String, dynamic>;
          }
          
          // Update state
          state = state.copyWith(
            mapCenter: LatLng(lat, lon),
            location: displayName.split(',')[0],
            isUsingFallbackLocation: false,
            isLoading: false,
            lastSearchResultBbox: bbox,
            lastSearchResultGeoJson: geoJson, // NEW: Store GeoJSON
            isSearchActive: true, // AUTO-ACTIVATE Search when location found
          );
          
          debugPrint("✅ Location found: $displayName");
          
          await _loadProperties();
        } else {
          debugPrint("❌ Location not found anywhere.");
          state = state.copyWith(
            error: 'No se encontró la ubicación: $sanitized',
            isLoading: false,
          );
        }
      } catch (e, stackTrace) {
        debugPrint("⚠️ Error in search algorithm: $e");
        debugPrint(stackTrace.toString());
        state = state.copyWith(
          error: 'Error al buscar: $e',
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
        // Apply Client-Side Filtering for fields not supported by API yet
        // Apply Client-Side Filtering
        
        // 1. Filter by Bedrooms
        var results = properties.where((p) => p.bedrooms >= state.minBedrooms).toList();
        
        // 2. Filter by Extras
        if (state.selectedExtras.isNotEmpty) {
          results = results.where((p) {
            for (final extra in state.selectedExtras) {
              if (extra == 'Piscina') {
                if (!p.features.contains('pool')) return false;
              } else if (extra == 'Terraza') {
                if (!p.features.contains('terrace')) return false;
              } else if (extra == 'Garaje') {
                final text = '${p.title} ${p.address}'.toLowerCase(); 
                if (!text.contains('garaje') && !text.contains('parking') && !text.contains('plaza')) return false;
              } else if (extra == 'Jardín') {
                 if (!p.features.contains('garden')) return false;
              }
            }
            return true;
          }).toList();
        }

        state = state.copyWith(
          isLoading: false,
          error: null,
          filteredProperties: results,
        );
      },
    );
  }
  
  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  /// Reset all filters and view mode
  void reset() {
    state = const SearchState(isSearchActive: false); // Reset to Landing View
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
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final repository = ref.watch(propertyRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  return SearchNotifier(repository, locationService);
});

/// Provider for dynamic map filtering (Polygon vs Viewport)
final filteredByMapPropertiesProvider = Provider<List<Property>>((ref) {
  final searchState = ref.watch(searchProvider);
  final mapState = ref.watch(mapStateProvider);
  
  final allFiltered = searchState.filteredProperties;
  
  // 1. Polygon Mode (Priority)
  if (mapState.currentZonePolygon.isNotEmpty) {
    if (mapState.currentZonePolygon.length < 3) return []; // Invalid polygon
    return allFiltered.where((p) => _isPointInPolygon(p.location, mapState.currentZonePolygon)).toList();
  }
  
  // 2. Viewport Mode
  if (mapState.visibleBounds != null) {
    return allFiltered.where((p) => mapState.visibleBounds!.contains(p.location)).toList();
  }
  
  // Fallback (e.g. map not initialized yet), return all or none?
  // If map is loading, maybe return all.
  return allFiltered;
});

/// Ray Casting algorithm to check if point is in polygon
bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
  int intersectCount = 0;
  for (int i = 0; i < polygon.length; i++) {
    final j = (i + 1) % polygon.length;
    final vert1 = polygon[i];
    final vert2 = polygon[j];
    
    if ((vert1.latitude > point.latitude) != (vert2.latitude > point.latitude) &&
        (point.longitude < (vert2.longitude - vert1.longitude) * (point.latitude - vert1.latitude) / (vert2.latitude - vert1.latitude) + vert1.longitude)) {
      intersectCount++;
    }
  }
  return (intersectCount % 2) == 1;
}

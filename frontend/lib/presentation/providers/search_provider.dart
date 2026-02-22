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
  
  // Spain center coordinates for initial wide view (shows entire country)
  static const LatLng _spainCenter = LatLng(40.4, -3.7);
  
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
          'https://nominatim.openstreetmap.org/search?q=$sanitized&format=json&limit=1&countrycodes=es'
        );
        
        var response = await http.get(urlSpain, headers: {
          'User-Agent': 'com.inmufacil.app/1.0'
        });
        
        var data = json.decode(response.body);
        
        // STEP 2: Verification and Fallback
        // If empty list, location is not in Spain OR user searches outside (e.g., "Paris", "Córdoba, Argentina")
        if (data is List && data.isEmpty) {
          debugPrint("📍 Not found in Spain. Searching globally...");
          
          // Launch WORLDWIDE search (without countrycodes)
          final urlGlobal = Uri.parse(
            'https://nominatim.openstreetmap.org/search?q=$sanitized&format=json&limit=1'
          );
          
          response = await http.get(urlGlobal, headers: {
            'User-Agent': 'com.inmufacil.app/1.0'
          });
          
          data = json.decode(response.body);
        }
        
        // STEP 3: Final Processing (if we found something in step 1 or 2)
        if (data is List && data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final displayName = data[0]['display_name']; // Full name for confirmation
          
          // Update state
          state = state.copyWith(
            mapCenter: LatLng(lat, lon),
            location: displayName.split(',')[0], // Take only city name for input
            isUsingFallbackLocation: false,
            isLoading: false,
          );
          
          // Visual feedback (useful for TFM demonstration)
          debugPrint("✅ Location found: $displayName");
          
          // Reload properties for new location
          await _loadProperties();
        } else {
          // STEP 4: If everything fails (neither in Spain nor worldwide)
          debugPrint("❌ Location not found anywhere.");
          state = state.copyWith(
            error: 'No se encontró la ubicación: $sanitized',
            isLoading: false,
          );
        }
      } catch (e) {
        // SECURITY: Generic error message (don't expose exception details to user)
        debugPrint("⚠️ Error in search algorithm: $e");
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
        state = state.copyWith(
          isLoading: false,
          error: null,
          filteredProperties: properties, // Can be empty list (estado cero)
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
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final repository = ref.watch(propertyRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  return SearchNotifier(repository, locationService);
});

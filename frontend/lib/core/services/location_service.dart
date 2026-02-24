import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Service for handling user location with fallback
class LocationService {
  /// Sevilla coordinates as fallback
  static const LatLng sevillaFallback = LatLng(37.3891, -5.9845);
  
  /// Get current user location or fallback to Sevilla
  /// 
  /// Returns [LocationResult] with location and whether it's a fallback
  Future<LocationResult> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.fallback(sevillaFallback);
      }
      
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return LocationResult.fallback(sevillaFallback);
      }
      
      // Get position with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      
      return LocationResult.success(
        LatLng(position.latitude, position.longitude),
      );
    } catch (e) {
      // Any error (timeout, service unavailable, etc.) → fallback
      return LocationResult.fallback(sevillaFallback);
    }
  }
  
  /// Calculate distance between two points in kilometers
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    ) / 1000; // Convert meters to kilometers
  }
}

/// Result of location request
class LocationResult {
  
  const LocationResult._(this.location, this.isFallback);
  
  /// Successful location retrieval
  factory LocationResult.success(LatLng location) {
    return LocationResult._(location, false);
  }
  
  /// Fallback location (permission denied or error)
  factory LocationResult.fallback(LatLng location) {
    return LocationResult._(location, true);
  }
  final LatLng location;
  final bool isFallback;
}

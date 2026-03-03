// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Service for handling user location with fallback
class LocationService {
  /// Spain (Madrid) coordinates as generic fallback
  static const LatLng spainFallback = LatLng(40.4168, -3.7038);

  /// Get current user location using browser Geolocation API directly.
  ///
  /// This is more reliable on Flutter Web than the geolocator plugin,
  /// which often returns [isLocationServiceEnabled] = false in Chrome.
  ///
  /// Returns [LocationResult] with location and whether it's a fallback.
  Future<LocationResult> getCurrentLocation() async {
    // Use Web Geolocation API directly (works on localhost & HTTPS)
    try {
      final geoposition = await html.window.navigator.geolocation
          .getCurrentPosition(
            enableHighAccuracy: true,
            timeout: const Duration(seconds: 15),
          );
      final lat = geoposition.coords!.latitude!.toDouble();
      final lng = geoposition.coords!.longitude!.toDouble();
      return LocationResult.success(LatLng(lat, lng));
    } catch (_) {
      // User denied or timeout — fall through to geolocator fallback
    }

    // Secondary: try geolocator (native/mobile)
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.deniedForever &&
            permission != LocationPermission.denied) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );
          return LocationResult.success(
            LatLng(position.latitude, position.longitude),
          );
        }
      }
    } catch (_) {}

    return LocationResult.fallback(spainFallback);
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          to.latitude,
          to.longitude,
        ) /
        1000;
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

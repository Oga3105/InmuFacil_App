import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Environment configuration for the application.
/// Fail-safe implementation: Returns defaults if dotenv fails to load (e.g., on web)
class EnvConfig {
  /// Base URL for API requests
  static String get apiBaseUrl {
    try {
      // Attempt to read from dotenv. If not initialized, this throws NotInitializedError
      return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1';
    } catch (e) {
      // Fail-safe: Return default if dotenv is not initialized (common on web)
      debugPrint('⚠️ EnvConfig Warning: dotenv not initialized. Using default localhost.');
      return 'http://localhost:8000/api/v1';
    }
  }
  
  /// API timeout in milliseconds
  static int get apiTimeout {
    try {
      return int.tryParse(dotenv.env['API_TIMEOUT'] ?? '') ?? 30000;
    } catch (e) {
      debugPrint('⚠️ EnvConfig Warning: dotenv not initialized. Using default timeout.');
      return 30000;
    }
  }
  
  /// Enable detailed logging (dev only)
  static bool get enableLogging {
    try {
      return dotenv.env['ENABLE_LOGGING'] == 'true';
    } catch (e) {
      debugPrint('⚠️ EnvConfig Warning: dotenv not initialized. Logging disabled.');
      return false;
    }
  }
  
  /// Google Maps API Key (not used - using OpenStreetMap)
  static String get googleMapsApiKey {
    try {
      return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    } catch (e) {
      debugPrint('⚠️ EnvConfig Warning: dotenv not initialized. No Maps API key.');
      return '';
    }
  }
}

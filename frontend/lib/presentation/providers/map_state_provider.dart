import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart'; // Required for LatLngBounds

/// State for Map interactions (Drawing, Zoning)
class MapState {
  final bool isDrawingMode;
  final List<LatLng> currentDrawingPoints; // Points being drawn right now
  final List<LatLng> currentZonePolygon;   // Completed polygon (Search Filter)
  final List<LatLng> cityBoundaryPolygon;  // Visual boundary from Nominatim (e.g. Madrid)
  final LatLngBounds? visibleBounds;       // Current Map Viewport
  
  const MapState({
    this.isDrawingMode = false,
    this.currentDrawingPoints = const [],
    this.currentZonePolygon = const [],
    this.cityBoundaryPolygon = const [],
    this.visibleBounds,
  });
  
  MapState copyWith({
    bool? isDrawingMode,
    List<LatLng>? currentDrawingPoints,
    List<LatLng>? currentZonePolygon,
    List<LatLng>? cityBoundaryPolygon,
    LatLngBounds? visibleBounds,
  }) {
    return MapState(
      isDrawingMode: isDrawingMode ?? this.isDrawingMode,
      currentDrawingPoints: currentDrawingPoints ?? this.currentDrawingPoints,
      currentZonePolygon: currentZonePolygon ?? this.currentZonePolygon,
      cityBoundaryPolygon: cityBoundaryPolygon ?? this.cityBoundaryPolygon,
      visibleBounds: visibleBounds ?? this.visibleBounds,
    );
  }
}

class MapStateNotifier extends StateNotifier<MapState> {
  MapStateNotifier() : super(const MapState());
  
  /// Set visible bounds (Viewport)
  void setVisibleBounds(LatLngBounds bounds) {
    state = state.copyWith(visibleBounds: bounds);
  }

  /// Toggle drawing mode
  void toggleDrawingMode() {
    state = state.copyWith(
      isDrawingMode: !state.isDrawingMode,
      currentDrawingPoints: [], // Reset points when toggling
    );
  }
  
  /// Start a new drawing session (clears previous points)
  void startDrawing() {
    state = state.copyWith(
      isDrawingMode: true,
      currentDrawingPoints: [],
      currentZonePolygon: [], // Clear previous zone if any
    );
  }

  /// Add point to current drawing
  void addPoint(LatLng point) {
    if (!state.isDrawingMode) return;
    
    // Optimization: Don't add if too close to last point (simple dedup)
    if (state.currentDrawingPoints.isNotEmpty) {
      final last = state.currentDrawingPoints.last;
      if (last.latitude == point.latitude && last.longitude == point.longitude) {
        return;
      }
    }
    
    final newPoints = List<LatLng>.from(state.currentDrawingPoints)..add(point);
    state = state.copyWith(currentDrawingPoints: newPoints);
  }
  
  /// Complete drawing and set as filter zone
  void completeDrawing() {
    // For freehand, even 3 points might be too few if they are collinear, 
    // but 3 is the geometric minimum for a polygon.
    if (state.currentDrawingPoints.length < 3) {
        // If not enough points, just cancel/clear
        state = state.copyWith(
            currentDrawingPoints: [],
            // Keep isDrawingMode = true so user can try again? 
            // Or false? User released mouse. Let's keep true or just reset points.
            // User expectation: If I fail, I probably want to try again immediately.
        );
        return; 
    }
    
    state = state.copyWith(
      isDrawingMode: false, // Exit drawing mode on release
      currentZonePolygon: state.currentDrawingPoints,
      currentDrawingPoints: [],
    );
  }
  
  /// Clear all zones
  void clearZones() {
    state = state.copyWith(
      currentZonePolygon: [],
      cityBoundaryPolygon: [],
      currentDrawingPoints: [],
      isDrawingMode: false,
    );
  }
  
  /// Set city boundary (from Nominatim BoundingBox)
  /// Nominatim returns [south, north, west, east]
  void setCityBoundary(List<String> bbox) {
    if (bbox.length != 4) return;
    
    try {
      final south = double.parse(bbox[0]);
      final north = double.parse(bbox[1]);
      final west = double.parse(bbox[2]);
      final east = double.parse(bbox[3]);
      
      // Create a rectangular polygon from the bounding box
      final polygon = [
        LatLng(north, west), // Top Left
        LatLng(north, east), // Top Right
        LatLng(south, east), // Bottom Right
        LatLng(south, west), // Bottom Left
        LatLng(north, west), // Close loop
      ];
      
      state = state.copyWith(cityBoundaryPolygon: polygon);
    } catch (e) {
      // Ignore parse errors
    }
  }

  /// Set city boundary from GeoJSON (Real Shape)
  /// Supports Polygon and MultiPolygon (takes the first/outer ring)
  void setCityBoundaryFromGeoJson(Map<String, dynamic> geoJson) {
    try {
      final type = geoJson['type'];
      final coordinates = geoJson['coordinates'];
      
      debugPrint("🗺️ GeoJSON Type: $type");
      
      List<LatLng> polygonPoints = [];
      
      if (type == 'Polygon') {
        // Polygon coordinates: [ [ [lon, lat], ... ] ]
        // We take the first ring (exterior boundary)
        final outerRing = coordinates[0] as List;
        polygonPoints = _parseRing(outerRing);
        debugPrint("✅ Parsed Polygon with ${polygonPoints.length} points");
      } else if (type == 'MultiPolygon') {
        // MultiPolygon coordinates: [ [ [ [lon, lat], ... ] ] ]
        // CRITICAL FIX: Take the LARGEST polygon, not the first
        // The first polygon might be a small administrative island/district
        // The largest polygon is usually the main city area
        final allPolygons = coordinates as List;
        
        // Find the polygon with the most points (largest area approximation)
        int maxPoints = 0;
        List? largestOuterRing;
        
        for (var polygon in allPolygons) {
          final outerRing = polygon[0] as List;
          if (outerRing.length > maxPoints) {
            maxPoints = outerRing.length;
            largestOuterRing = outerRing;
          }
        }
        
        if (largestOuterRing != null) {
          polygonPoints = _parseRing(largestOuterRing);
          debugPrint("✅ Parsed MultiPolygon (LARGEST of ${allPolygons.length} polygons) with ${polygonPoints.length} points");
        }
      } else {
        debugPrint("⚠️ Unknown GeoJSON type: $type");
      }
      
      if (polygonPoints.isNotEmpty) {
        debugPrint("🎯 Setting cityBoundaryPolygon with ${polygonPoints.length} points");
        debugPrint("   First point: ${polygonPoints.first}");
        debugPrint("   Last point: ${polygonPoints.last}");
        state = state.copyWith(cityBoundaryPolygon: polygonPoints);
      } else {
        debugPrint("❌ No polygon points extracted from GeoJSON");
      }
    } catch (e) {
      // Fallback or ignore
      debugPrint("❌ Error parsing GeoJSON: $e");
    }
  }
  
  /// Helper to parse a ring of [lon, lat] arrays into LatLng
  List<LatLng> _parseRing(List ring) {
    return ring.map((point) {
      final p = point as List;
      // GeoJSON is [lon, lat], LatLng is (lat, lon)
      return LatLng(
        double.parse(p[1].toString()), 
        double.parse(p[0].toString())
      );
    }).toList();
  }
}

final mapStateProvider = StateNotifierProvider<MapStateNotifier, MapState>((ref) {
  return MapStateNotifier();
});

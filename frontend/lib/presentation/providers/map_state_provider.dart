
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// State for Map interactions (Drawing, Zoning)
class MapState {
  final bool isDrawingMode;
  final List<LatLng> currentDrawingPoints; // Points being drawn right now
  final List<LatLng> currentZonePolygon;   // Completed polygon (Search Filter)
  final List<LatLng> cityBoundaryPolygon;  // Visual boundary from Nominatim (e.g. Madrid)
  
  const MapState({
    this.isDrawingMode = false,
    this.currentDrawingPoints = const [],
    this.currentZonePolygon = const [],
    this.cityBoundaryPolygon = const [],
  });
  
  MapState copyWith({
    bool? isDrawingMode,
    List<LatLng>? currentDrawingPoints,
    List<LatLng>? currentZonePolygon,
    List<LatLng>? cityBoundaryPolygon,
  }) {
    return MapState(
      isDrawingMode: isDrawingMode ?? this.isDrawingMode,
      currentDrawingPoints: currentDrawingPoints ?? this.currentDrawingPoints,
      currentZonePolygon: currentZonePolygon ?? this.currentZonePolygon,
      cityBoundaryPolygon: cityBoundaryPolygon ?? this.cityBoundaryPolygon,
    );
  }
}

class MapStateNotifier extends StateNotifier<MapState> {
  MapStateNotifier() : super(const MapState());
  
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
      
      List<LatLng> polygonPoints = [];
      
      if (type == 'Polygon') {
        // Polygon coordinates: [ [ [lon, lat], ... ] ]
        // We take the first ring (exterior boundary)
        final outerRing = coordinates[0] as List;
        polygonPoints = _parseRing(outerRing);
      } else if (type == 'MultiPolygon') {
        // MultiPolygon coordinates: [ [ [ [lon, lat], ... ] ] ]
        // We take the first polygon's first ring for now (usually the main landmass)
        // Improved logic: could iterate to find largest, but first is safe start
        final firstPolygon = coordinates[0] as List;
        final outerRing = firstPolygon[0] as List;
        polygonPoints = _parseRing(outerRing);
      }
      
      if (polygonPoints.isNotEmpty) {
        state = state.copyWith(cityBoundaryPolygon: polygonPoints);
      }
    } catch (e) {
      // Fallback or ignore
      print("Error parsing GeoJSON: $e");
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

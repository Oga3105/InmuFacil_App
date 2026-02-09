import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math'; // For Point
// import 'package:easy_localization/easy_localization.dart'; // TEMP DISABLED

import 'package:inmufacil_frontend/presentation/providers/search_provider.dart';
import 'package:inmufacil_frontend/presentation/providers/map_state_provider.dart';
import 'package:inmufacil_frontend/domain/entities/property.dart';
import 'package:inmufacil_frontend/core/utils/temp_translations.dart'; // TEMP REPLACEMENT

/// OpenStreetMap widget with custom property markers, Drawing and Zoning
class OpenStreetMapWidget extends ConsumerStatefulWidget {
  const OpenStreetMapWidget({super.key});
  
  @override
  ConsumerState<OpenStreetMapWidget> createState() => _OpenStreetMapWidgetState();
}

class _OpenStreetMapWidgetState extends ConsumerState<OpenStreetMapWidget> {
  final MapController _mapController = MapController();
  LatLng? _previousCenter; // Track previous center to detect changes
  Map<String, dynamic>? _previousGeoJson; // Track GeoJSON changes
  
  // Sevilla coordinates for geolocation fallback
  static const LatLng _sevillaFallback = LatLng(37.3891, -5.9845);
  
  // Track zoom level for marker adaptivity
  double _currentZoom = 13.0; // Default matching initial logic

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final mapState = ref.watch(mapStateProvider);
    
    // EFFECT: Update camera/boundary when search location changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Handle Center Change
      if (searchState.mapCenter != null && searchState.mapCenter != _previousCenter) {
        _previousCenter = searchState.mapCenter;
        
        final zoom = searchState.isUsingFallbackLocation 
            ? 13.0  
            : 12.0; 
        
        _mapController.move(searchState.mapCenter!, zoom);
        if (_currentZoom != zoom) {
             setState(() => _currentZoom = zoom);
        }
      }
      
      // 2. Handle City Boundary (GeoJSON > Bbox)
      // Check if GeoJSON changed to update the polygon in State
      if (searchState.lastSearchResultGeoJson != null && 
          searchState.lastSearchResultGeoJson != _previousGeoJson) {
        _previousGeoJson = searchState.lastSearchResultGeoJson;
        
        // Pass to MapState to generate REAL SHAPE polygon
        ref.read(mapStateProvider.notifier).setCityBoundaryFromGeoJson(searchState.lastSearchResultGeoJson!);
        
        // Use BBOX only for Camera Fitting (if available)
        if (searchState.lastSearchResultBbox != null) {
          try {
              final south = double.parse(searchState.lastSearchResultBbox![0]);
              final north = double.parse(searchState.lastSearchResultBbox![1]);
              final west = double.parse(searchState.lastSearchResultBbox![2]);
              final east = double.parse(searchState.lastSearchResultBbox![3]);
              
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: LatLngBounds(
                    LatLng(south, west),
                    LatLng(north, east),
                  ),
                  padding: const EdgeInsets.all(40), // More padding for better view
                ),
              );
          } catch (_) {}
        }
      }
    });
    
    
    // UI REFACTOR: Cursor changes based on mode

    // UI REFACTOR: Cursor changes based on mode
    return MouseRegion(
      cursor: mapState.isDrawingMode 
          ? SystemMouseCursors.precise  // Crosshair for drawing
          : SystemMouseCursors.basic,
      child: Stack(
        children: [
          Listener(
            // FREEHAND DRAWING LOGIC (Lasso)
            onPointerDown: (event) {
              if (mapState.isDrawingMode) {
                 ref.read(mapStateProvider.notifier).startDrawing();
                 _addPointFromEvent(event.localPosition);
              }
            },
            onPointerMove: (event) {
               if (mapState.isDrawingMode) {
                 _addPointFromEvent(event.localPosition);
               }
            },
            onPointerUp: (event) {
               if (mapState.isDrawingMode) {
                 // Completion logic is now automatic on release
                 ref.read(mapStateProvider.notifier).completeDrawing();
               }
            },
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: searchState.mapCenter ?? _sevillaFallback,
                initialZoom: 6.0,
                minZoom: 5,
                maxZoom: 18,
                
                // TRACK ZOOM LEVEL
                onPositionChanged: (position, hasGesture) {
                  if (position.zoom != null && position.zoom != _currentZoom) {
                    setState(() {
                      _currentZoom = position.zoom!;
                    });
                  }
                },
                
                // INTERACTION: Disable panning/zooming when drawing
                interactionOptions: InteractionOptions(
                   flags: mapState.isDrawingMode 
                      ? InteractiveFlag.none 
                      : InteractiveFlag.all,
                ),
                
                // REMOVED onTap: Freehand uses Listener
              ),
              children: [
                // 1. Tile Layer
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.inmufacil.app',
                  maxZoom: 19,
                ),
                
                // 2. Polygon Layer (City Boundaries & User Zones)
                PolygonLayer(
                  polygons: [
                    // City Boundary (Blue, Transparent, Real Shape)
                    if (mapState.cityBoundaryPolygon.isNotEmpty)
                      Polygon(
                        points: mapState.cityBoundaryPolygon,
                        color: const Color(0xFF2563EB).withOpacity(0.15), 
                        isFilled: true,
                        borderColor: const Color(0xFF2563EB),
                        borderStrokeWidth: 2,
                        label: searchState.location.isNotEmpty ? searchState.location : "Zona",
                        labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      
                    // User Drawn Zone (Green - Completed)
                    if (mapState.currentZonePolygon.isNotEmpty)
                       Polygon(
                        points: mapState.currentZonePolygon,
                        color: Colors.green.withOpacity(0.2), 
                        isFilled: true,
                        borderColor: Colors.green,
                        borderStrokeWidth: 2,
                      ),
                      
                     // Drawing Progress (Orange - Active)
                     if (mapState.isDrawingMode && mapState.currentDrawingPoints.isNotEmpty)
                       Polygon(
                        points: mapState.currentDrawingPoints, // Don't close loop while dragging
                        color: Colors.orange.withOpacity(0.1), 
                        isFilled: true,
                        borderColor: Colors.orange,
                        borderStrokeWidth: 2,
                        isDotted: true,
                      ),
                  ],
                ),
                
                // 3. Drawing Vertices (Markers) - HIDE for Freehand (too many points)
                // Only show start point? No, cleaner without.
                
                // 4. Property Markers (Hide when drawing)
                // Use mapPropertiesProvider as primary source, falling back to searchState if needed (or replacing entirely)
                if (!mapState.isDrawingMode)
                  _buildPropertyMarkers(ref),
              ],
            ),
          ),
          
          // --- UI OVERLAYS ---
          // ... (Rest of UI overlays remain unchanged) ...
          
          // A. Drawing Instructions Banner
          if (mapState.isDrawingMode)
             Positioned(
              top: 70, 
              left: 0, 
              right: 0,
              child: Center(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mode_edit_outline, color: Colors.orange, size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          "Dibuja tu zona punto a punto",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                           onPressed: () => ref.read(mapStateProvider.notifier).completeDrawing(),
                           style: FilledButton.styleFrom(
                             backgroundColor: Colors.green,
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                             visualDensity: VisualDensity.compact,
                           ),
                           icon: const Icon(Icons.check, size: 16),
                           label: const Text("TERMINAR"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // B. Consolidated Map Toolbar (Right Side)
          Positioned(
            right: 16,
            bottom: 32, // Anchored to bottom-right
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Clear Map (Trash) - Conditional
                if (mapState.currentZonePolygon.isNotEmpty || 
                    mapState.cityBoundaryPolygon.isNotEmpty || 
                    mapState.isDrawingMode)
                  _MapToolButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Limpiar mapa',
                    color: Colors.red,
                    onPressed: () {
                      ref.read(mapStateProvider.notifier).clearZones();
                      // Also reset search bounding box if coming from search
                      // (Optional: ref.read(searchProvider .notifier).resetLocation()?)
                    },
                  ),
                
                const SizedBox(height: 8),
                
                // 2. Draw Toggle
                _MapToolButton(
                  icon: mapState.isDrawingMode ? Icons.close : Icons.draw,
                  tooltip: mapState.isDrawingMode ? 'Cancelar dibujo' : 'Dibujar zona',
                  isActive: mapState.isDrawingMode,
                  onPressed: () => ref.read(mapStateProvider.notifier).toggleDrawingMode(),
                ),
                
                const SizedBox(height: 16), // Spacer between tools and zoom
                
                // 3. Zoom In
                _MapToolButton(
                  icon: Icons.add,
                  tooltip: 'Acercar',
                  onPressed: () => _zoomIn(),
                ),
                
                const SizedBox(height: 8),
                
                // 4. Zoom Out
                _MapToolButton(
                  icon: Icons.remove,
                  tooltip: 'Alejar',
                  onPressed: () => _zoomOut(),
                ),
                
                const SizedBox(height: 16),
                
                // 5. My Location
                _MapToolButton(
                  icon: Icons.my_location,
                  tooltip: 'Mi ubicación',
                  onPressed: () => _goToMyLocation(),
                ),
              ],
            ),
          ),
          
          // C. Loading & Error Overlays
          if (searchState.isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          
          if (searchState.error != null)
             Positioned(
              bottom: 40,
              left: 20,
              right: 80, // Avoid overlapping with Toolbar
              child: _AutoDismissErrorBanner(
                errorMessage: searchState.error!,
                onDismiss: () => ref.read(searchProvider.notifier).clearError(),
              ),
            ),
        ],
      ),
    );
  }
  
  // -- Helper Methods --
  
  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
  }
  
  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
  }
  
  void _goToMyLocation() {
    final searchState = ref.read(searchProvider);
    _mapController.move(searchState.mapCenter ?? _sevillaFallback, 13.0);
  }

  // OLD _buildMarkers removed, logic now in _buildPropertyMarkers
  
  void _showPropertyDetails(Property property) {
    // Implementation remains same as before...
     showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(property.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(property.formattedPrice, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ver Detalles'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPropertyMarkers(WidgetRef ref) {
    final searchState = ref.watch(searchProvider);
    final properties = searchState.filteredProperties;
    
    if (properties.isEmpty) return const SizedBox.shrink();
    
    // Zoom Logic: 
    // < 13: Show simple GPS Pin
    // >= 13: Show Price Label
    final bool showPrice = _currentZoom >= 13.0;

    return MarkerLayer(
      markers: properties.map((property) {
        return Marker(
          point: property.location,
          width: showPrice ? 80 : 40, // Adjust width based on type
          height: 40,
          child: GestureDetector(
            onTap: () => _showPropertyDetails(property),
            child: showPrice 
                ? _CompactPriceMarker(price: property.formattedPrice)
                : const _GpsPinMarker(),
          ),
        );
      }).toList(),
    );
  }

  /// Helper to convert screen coordinates to LatLng and add to drawing
  void _addPointFromEvent(Offset localPosition) {
    // Convert screen point to LatLng using the map camera
    final point = _mapController.camera.pointToLatLng(Point(localPosition.dx, localPosition.dy));
    ref.read(mapStateProvider.notifier).addPoint(point);
  }
}

/// Helper Widget for Uniform Toolbar Buttons
class _MapToolButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isActive;
  final Color? color;

  const _MapToolButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isActive = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = color ?? theme.colorScheme.primary;
    
    return SizedBox(
      width: 40,
      height: 40,
      child: FloatingActionButton(
        heroTag: 'map_tool_${icon.codePoint}', // Unique tag
        onPressed: onPressed,
        tooltip: tooltip,
        elevation: 2,
        backgroundColor: isActive ? baseColor : Colors.white,
        foregroundColor: isActive ? Colors.white : (color ?? Colors.black87),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

/// Simple GPS Pin for Low Zoom
class _GpsPinMarker extends StatelessWidget {
  const _GpsPinMarker();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.location_on,
      color: Color(0xFF2563EB), // Primary Blue
      size: 40,
      shadows: [
        Shadow(
          blurRadius: 4,
          color: Colors.black26,
          offset: Offset(0, 2),
        ),
      ],
    );
  }
}

/// Compact Price Label for High Zoom
class _CompactPriceMarker extends StatelessWidget {
  final String price;
  const _CompactPriceMarker({required this.price});
  
  @override
  Widget build(BuildContext context) {
    // Simplify price string "€350K" -> "350K" to save space? 
    // Or keep formatted but use smaller font.
    // Let's keep formatted property.formattedPrice e.g. "€350K"
    
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB), // Primary Blue
          borderRadius: BorderRadius.circular(12), // Rounded capsule
          boxShadow: const [
            BoxShadow(
              blurRadius: 2, 
              color: Colors.black26,
              offset: Offset(0, 1)
            )
          ],
        ),
        child: Text(
          price,
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 11, // Smaller font
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _AutoDismissErrorBanner extends StatefulWidget {
  final String errorMessage;
  final VoidCallback onDismiss;
  const _AutoDismissErrorBanner({required this.errorMessage, required this.onDismiss});
  @override
  State<_AutoDismissErrorBanner> createState() => _AutoDismissErrorBannerState();
}

class _AutoDismissErrorBannerState extends State<_AutoDismissErrorBanner> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if(mounted) widget.onDismiss();
    });
  }
  @override
  Widget build(BuildContext context) {
     return Card(
      color: Colors.red.shade50,
      child: ListTile(
        leading: const Icon(Icons.error, color: Colors.red),
        title: Text(widget.errorMessage, style: const TextStyle(color: Colors.red)),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: widget.onDismiss,
        ),
      ),
    );
  }
}

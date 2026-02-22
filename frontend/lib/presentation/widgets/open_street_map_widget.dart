import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'dart:async'; // For Timer (Hover Debounce)
import 'dart:convert';
// import 'package:easy_localization/easy_localization.dart'; // TEMP DISABLED

import 'package:inmufacil_frontend/presentation/providers/search_provider.dart';
import 'package:inmufacil_frontend/presentation/providers/map_state_provider.dart';
import 'package:inmufacil_frontend/presentation/providers/hover_provider.dart'; // [NEW] Hover Provider
import 'package:inmufacil_frontend/domain/entities/property.dart';
import 'package:inmufacil_frontend/presentation/widgets/map/property_floating_card.dart';
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
  bool? _previousIsFallback; // Track previous fallback state
  String? _previousGeoJson; // Track GeoJSON changes
  
  // Spain (Madrid) coordinates for geolocation fallback
  static const LatLng _spainFallback = LatLng(40.4168, -3.7038);
  
  // State
  // Property? _selectedProperty; // REMOVED: Managed by provider now
  double _currentZoom = 6.0;
  // Property? _hoveredProperty; // REMOVED: Managed by provider now
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final mapState = ref.watch(mapStateProvider);
    // [FIX] Use the same provider as counter for Strict Sync
    final filteredProperties = ref.watch(filteredByMapPropertiesProvider);
    
    // EFFECT: Update camera/boundary when search location changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Handle Center Change
      // Updated to also trigger if fallback status changes (e.g. initial load vs detected 'no location')
      if (searchState.mapCenter != null && 
          (searchState.mapCenter != _previousCenter || searchState.isUsingFallbackLocation != _previousIsFallback)) {
        
        _previousCenter = searchState.mapCenter;
        _previousIsFallback = searchState.isUsingFallbackLocation;
        
        final zoom = searchState.isUsingFallbackLocation 
            ? 6.2  // Zoom 6.2 to show Spain closer (Step 17525)
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
        final geoJsonData = json.decode(searchState.lastSearchResultGeoJson!) as Map<String, dynamic>;
        ref.read(mapStateProvider.notifier).setCityBoundaryFromGeoJson(geoJsonData);
        
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
        fit: StackFit.expand, // [FIX] Force Map to fill parent (Positioned.fill)
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
            // FLOATING CARD: Clear hover if mouse moves on map (not on marker)
            onPointerHover: (event) {
              // Only clear if we are NOT over a marker (handled by marker's MouseRegion)
              // But Marker is a child, so this listener might trigger first or bubble up.
              // Actually, MarkerLayer is below.
              // Logic: If map hovered, and we are not hovering a marker?
              // Let's rely on MouseRegion.onExit of the marker to clear hover.
            },
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                // FLOATING CARD: Clear SELECTION on map tap (if not hitting marker)
                // ERROR HANDLING: Clear error on tap
                onTap: (tapPosition, point) {
                   // [FIX] REMOVED CLEAR SELECTION ON MAP TAP
                   // This was causing conflict with Marker Tap (Race condition)
                   // Selection is now only cleared by hovering other markers or explicitly closed
                   
                   // User Interaction -> Clear Error & Text
                   ref.read(searchProvider.notifier).clearSearchText();
                },
                // ERROR HANDLING: Clear error on map move (drag/pan)
                onPositionChanged: (position, hasGesture) {
                  // Only clear if USER initiated the move (hasGesture)
                  // preventing clear on programmatic moves (e.g. search result flyTo)
                  if (hasGesture) {
                     final notifier = ref.read(searchProvider.notifier);
                     // Check if there is something to clear to avoid redundant calls
                     if (ref.read(searchProvider).error != null || ref.read(searchProvider).location.isNotEmpty) {
                        notifier.clearSearchText();
                     }
                  }
                  
                  if (position.zoom != null && position.zoom != _currentZoom) {
                    setState(() {
                      _currentZoom = position.zoom!;
                    });
                  }
                  
                  // Update Visible Bounds
                  final bounds = _mapController.camera.visibleBounds;
                  ref.read(mapStateProvider.notifier).setVisibleBounds(bounds);
                },
                initialCenter: searchState.mapCenter ?? _spainFallback,
                initialZoom: 6.2,
                minZoom: 5,
                maxZoom: 18,
                
                // TRACK ZOOM & BOUNDS
                // REMOVED old onPositionChanged (merged above)
                
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
                        isDotted: true,
                        borderColor: Colors.orange,
                        borderStrokeWidth: 2,
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
          
          // A. Drawing Instructions Banner
          if (mapState.isDrawingMode)
             Positioned(
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
                // 2. Clear Map (Trash) - Show when active components exist
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
                
                // 3. Draw Toggle - Hide when ANY Zone Exists (Prevent Overlap)
                if (mapState.currentZonePolygon.isEmpty && mapState.cityBoundaryPolygon.isEmpty) 
                   _MapToolButton(
                    icon: mapState.isDrawingMode ? Icons.close : Icons.draw,
                    tooltip: mapState.isDrawingMode ? 'Cancelar dibujo' : 'Dibujar zona',
                    isActive: mapState.isDrawingMode,
                    // If drawing is active, allow cancelling via toggle. 
                    // If not active, allow starting ONLY if no zones exist (double check logic)
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
          // --- UI OVERLAYS ---
          // 4. Loading Indicator
          if (searchState.isLoading)
             const Center(
               child: CircularProgressIndicator(),
             ),
             
          // 5. Error Banner (Top Persistence)
          if (searchState.error != null)
            Positioned(
              top: 90, // Raised to avoid bottom overlaps, below top nav
              left: 20,
              right: 20,
              child: _ErrorBanner(
                message: searchState.error!,
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
    _mapController.move(searchState.mapCenter ?? _spainFallback, 12.0);
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
    // [FIX] Use parameters captured in build() or re-watch here (better to pass from build)
    // Re-watching for safety within helper
    final properties = ref.watch(filteredByMapPropertiesProvider); 
    final hoveredProperty = ref.watch(hoveredPropertyProvider); 
    final selectedProperty = ref.watch(selectedPropertyProvider); // [NEW] Watch global selection
    
    if (properties.isEmpty) return const SizedBox.shrink();
    
    // Zoom Logic: 
    // < 13: Show simple GPS Pin
    // >= 13: Show Price Label
    final bool showPrice = _currentZoom >= 13.0;

    return MarkerLayer(
      markers: properties.map<Marker>((property) {
        // Determine Active State (Hovered OR Selected via Provider)
        final bool isSelected = selectedProperty?.id == property.id;
        final bool isHovered = hoveredProperty?.id == property.id;
        final bool isActive = isSelected || isHovered;
        
        return Marker(
          point: property.location,
          width: showPrice ? 90 : 40, 
          height: showPrice ? 45 : 40,
          child: MouseRegion(
            hitTestBehavior: HitTestBehavior.opaque, // Ensure hover is caught
            onEnter: (_) {
               // [NEW] Hovering another marker CLEARS any existing selection
               // This prevents the "fixed" card from reappearing after leaving this marker
               ref.read(selectedPropertyProvider.notifier).state = null;
               
               // Update Hover Provider to show this marker's info
               // print("DEBUG OnEnter Marker: ${property.id}");
               ref.read(hoveredPropertyProvider.notifier).setHoveredProperty(property);
            },
            onExit: (_) {
               // Only clear hover
               ref.read(hoveredPropertyProvider.notifier).startHideTimer();
            },
            cursor: SystemMouseCursors.click,
      child: GestureDetector(
              behavior: HitTestBehavior.opaque, // Ensure tap is caught
              onTap: () {
                ref.read(selectedPropertyProvider.notifier).state = property;
              },
              onDoubleTap: () {
                // Navigate to details (Full Page) on Double Tap
                context.pushNamed(
                  'property-details',
                  pathParameters: {'id': property.id},
                );
              },
              child: showPrice 
                  ? _CompactPriceMarker(
                      price: property.formattedPrice,
                      color: isActive ? const Color(0xFF16A34A) : const Color(0xFF2563EB), // Green if active
                    )
                  : _GpsPinMarker(
                      color: isActive ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                    ),
            ),
          ),
          // FLOATING CARD: Ensure tip of tail is on the coordinate
          // Alignment.bottomCenter means the bottom center of the widget is at the coordinate
          // Our bubble tail is at the bottom center of the widget, so it points exactly to the point.
          alignment: Alignment.bottomCenter,
        );
      }).toList(),
    );
  }
  

  /// Helper to convert screen coordinates to LatLng and add to drawing
  void _addPointFromEvent(Offset localPosition) {
    // Convert screen point to LatLng using the map camera.
    // In flutter_map 6.x+, use pointToLatLng with math.Point
    final point = _mapController.camera.pointToLatLng(math.Point(localPosition.dx, localPosition.dy));
    ref.read(mapStateProvider.notifier).addPoint(point);
  }
}

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

/// Compact Price Label for High Zoom
class _CompactPriceMarker extends StatelessWidget {
  final String price;
  final Color color;
  const _CompactPriceMarker({
    required this.price,
    this.color = const Color(0xFF2563EB),
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Price Bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                blurRadius: 4, 
                color: Colors.black26,
                offset: Offset(0, 2)
              )
            ],
          ),
          child: Text(
            price,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        // 2. Tail / Pointer
        CustomPaint(
          size: const Size(12, 6),
          painter: _TrianglePainter(color: color),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
    
    // Optional: Subtle shadow for the tail
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    canvas.drawPath(path.shift(const Offset(0, 1)), shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GpsPinMarker extends StatelessWidget {
  final Color color;
  const _GpsPinMarker({this.color = const Color(0xFF2563EB)});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.location_on,
      color: color, // Dynamic Color
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

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container( // Removed auto-dismiss timer logic
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withOpacity(0.05),
             blurRadius: 10,
             offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade400, size: 20),
            onPressed: onDismiss, 
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )
        ],
      ),
    );
  }
}

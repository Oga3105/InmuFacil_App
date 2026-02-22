import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// import 'package:easy_localization/easy_localization.dart'; // TEMP DISABLED

import 'package:inmufacil_frontend/presentation/providers/search_provider.dart';
import 'package:inmufacil_frontend/domain/entities/property.dart';
import 'package:inmufacil_frontend/core/utils/temp_translations.dart'; // TEMP REPLACEMENT

/// OpenStreetMap widget with custom property markers
class OpenStreetMapWidget extends ConsumerStatefulWidget {
  const OpenStreetMapWidget({super.key});
  
  @override
  ConsumerState<OpenStreetMapWidget> createState() => _OpenStreetMapWidgetState();
}

class _OpenStreetMapWidgetState extends ConsumerState<OpenStreetMapWidget> {
  final MapController _mapController = MapController();
  LatLng? _previousCenter; // Track previous center to detect changes
  
  // Sevilla coordinates for geolocation fallback (when user denies permission)
  static const LatLng _sevillaFallback = LatLng(37.3891, -5.9845);
  
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    
    // Update camera when map center changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (searchState.mapCenter != null && searchState.mapCenter != _previousCenter) {
        _previousCenter = searchState.mapCenter;
        
        // Use different zoom levels based on context
        final zoom = searchState.isUsingFallbackLocation 
            ? 13.0  // Fallback to Sevilla (closer zoom)
            : 12.0; // City search result (standard zoom)
        
        _mapController.move(searchState.mapCenter!, zoom);
      }
    });
    
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: searchState.mapCenter ?? _sevillaFallback,
            initialZoom: 6.0, // Spain-wide view initially
            minZoom: 5,
            maxZoom: 18,
          ),
          children: [
            // OpenStreetMap tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.inmufacil.app',
              maxZoom: 19,
            ),
            
            // Property markers layer (only if properties exist)
            if (searchState.filteredProperties.isNotEmpty)
              MarkerLayer(
                markers: _buildMarkers(searchState.filteredProperties),
              ),
          ],
        ),
        
        // Loading indicator
        if (searchState.isLoading)
          Container(
            color: Colors.black26,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('home.map_loading'.tr()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        
        // Error message with auto-dismiss after 15 seconds
        if (searchState.error != null)
          Positioned(
            top: 60, // Below navigation bar (~48px height)
            left: 16,
            right: 16,
            child: _AutoDismissErrorBanner(
              errorMessage: searchState.error!,
              onDismiss: () {
                // Clear error from state
                ref.read(searchProvider.notifier).clearError();
              },
            ),
          ),
        
        // Fallback location banner
        if (searchState.isUsingFallbackLocation)
          Positioned(
            top: 60, // Below navigation bar
            left: 16,
            right: 16,
            child: Card(
              color: Colors.orange.shade50,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ubicación no detectada. Mostrando Sevilla por defecto.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Custom zoom controls
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                onPressed: () => _zoomIn(),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                onPressed: () => _zoomOut(),
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
        
        // My location button
        Positioned(
          right: 16,
          bottom: 32,
          child: FloatingActionButton.small(
            heroTag: 'my_location',
            onPressed: () => _goToMyLocation(),
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
  
  /// Build markers for filtered properties using native Flutter widgets
  List<Marker> _buildMarkers(List<Property> properties) {
    return properties.map((property) {
      return Marker(
        point: property.location,
        width: 100,
        height: 50,
        child: GestureDetector(
          onTap: () => _showPropertyDetails(property),
          child: _PriceMarker(price: property.formattedPrice),
        ),
      );
    }).toList();
  }
  
  /// Show property details bottom sheet
  void _showPropertyDetails(Property property) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              property.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              property.formattedPrice,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF135BEC),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    property.address,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (property.bedrooms > 0) ...[
                  Icon(Icons.bed, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${property.bedrooms}'),
                  const SizedBox(width: 16),
                ],
                if (property.bathrooms > 0) ...[
                  Icon(Icons.bathroom, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${property.bathrooms}'),
                  const SizedBox(width: 16),
                ],
                if (property.squareMeters > 0) ...[
                  Icon(Icons.square_foot, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${property.squareMeters.toInt()}m²'),
                ],
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to property details
                  // context.go('/property/${property.id}');
                },
                child: const Text('Ver Detalles'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Zoom in on map
  void _zoomIn() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom + 1,
    );
  }
  
  /// Zoom out on map
  void _zoomOut() {
    _mapController.move(
      _mapController.camera.center,
      _mapController.camera.zoom - 1,
    );
  }
  
  /// Go to user's current location
  void _goToMyLocation() {
    final searchState = ref.read(searchProvider);
    if (searchState.mapCenter != null) {
      _mapController.move(searchState.mapCenter!, 12);
    } else {
      // Fallback to Sevilla center
      _mapController.move(_sevillaFallback, 13.0);
    }
  }
}

/// Custom price marker widget
class _PriceMarker extends StatelessWidget {
  final String price;
  
  const _PriceMarker({required this.price});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF135BEC),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          price,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Auto-dismissing error banner for map errors
class _AutoDismissErrorBanner extends StatefulWidget {
  final String errorMessage;
  final VoidCallback onDismiss;
  
  const _AutoDismissErrorBanner({
    required this.errorMessage,
    required this.onDismiss,
  });
  
  @override
  State<_AutoDismissErrorBanner> createState() => _AutoDismissErrorBannerState();
}

class _AutoDismissErrorBannerState extends State<_AutoDismissErrorBanner> {
  bool _isVisible = true;
  
  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() => _isVisible = false);
        widget.onDismiss();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();
    
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.errorMessage,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.red.shade700, size: 20),
              onPressed: () {
                setState(() => _isVisible = false);
                widget.onDismiss();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

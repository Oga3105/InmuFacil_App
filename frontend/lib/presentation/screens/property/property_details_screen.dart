import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// import 'package:easy_localization/easy_localization.dart';

import '../../../domain/entities/property.dart';
import '../../../domain/entities/property_type.dart'; // [FIX] Import added
// import '../../providers/property_provider.dart'; // TODO: Implement specific provider
import '../../providers/search_provider.dart';
import '../../providers/favorites_provider.dart'; // [NEW] Favorites Logic
import '../../widgets/common/premium_button.dart';

class PropertyDetailsScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends ConsumerState<PropertyDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    // Find property from provider
    final properties = ref.watch(searchProvider).filteredProperties;
    // Fallback to a default mock/empty if not found (prevents crash on reload)
    // In a real app, this should trigger a fetchById(propertyId)
    final property = properties.firstWhere(
      (p) => p.id == widget.propertyId,
      orElse: () => const Property(
        id: 'fallback', 
        title: 'Cargando Propiedad...', 
        type: PropertyType.all, 
        price: 0, 
        location: LatLng(40.4168, -3.7038), 
        address: '...'
      ),
    );

    // If still fallback/loading, maybe show spinner? 
    // For now, render with what we have.

    // Navigation Logic (Next/Prev)
    final currentIndex = properties.indexWhere((p) => p.id == widget.propertyId);
    final prevPropertyId = currentIndex > 0 ? properties[currentIndex - 1].id : null;
    final nextPropertyId = (currentIndex != -1 && currentIndex < properties.length - 1) ? properties[currentIndex + 1].id : null;

    // Favorite Logic
    final favoriteIds = ref.watch(favoritesProvider);
    final isFavorite = favoriteIds.contains(property.id);

    // Colors from HTML
    final colorPrimary = const Color(0xFF135bec);
    final colorNavy = const Color(0xFF0f172a);
    
    // Shared AppBar Logic
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo_inmufacil.png', height: 32),
                  const SizedBox(width: 8),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      children: [
                        const TextSpan(text: 'Inmu', style: TextStyle(color: Color(0xFF2563EB))),
                        const TextSpan(text: 'Fácil', style: TextStyle(color: Color(0xFF16A34A))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
           Padding(
             padding: const EdgeInsets.only(right: 24.0),
             child: Row(
               children: [
                  TextButton(
                    onPressed: () {}, 
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Comprar', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold))
                  ),
                  // Removed Buttons as requested (Clean Look)
                  /*
                  TextButton(
                    onPressed: () {}, 
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Comprar', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold))
                  ),
                  */
                  
                  // Removed 'Vender' and 'Mis favoritos' as requested
                  /*
                  TextButton(
                    onPressed: () {}, 
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Vender', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))
                  ),
                  Container(height: 20, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 16)),
                  TextButton(
                    onPressed: () => ref.read(searchProvider.notifier).toggleOnlyFavorites(), 
                    ...
                  ),
                  */
                  const SizedBox(width: 16),
                  PremiumButton(
                    label: 'Publicar Gratis',
                    onPressed: () {},
                    color: const Color(0xFF2563EB),
                    fullWidth: false,
                    fontSize: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
               ],
             ),
           )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1024;
              
              if (isDesktop) {
                 return _buildDesktopLayout(context, property, isFavorite, ref);
              } else {
                return _buildMobileLayout(context, property, isFavorite, ref);
              }
            },
          ),
          
          // Navigation Arrows (Overlay)
          // Desktop: Centered vertically on screen edges
          // Mobile: Maybe unobtrusive or bottom near image? User said "a los lados"
          if (prevPropertyId != null)
            Positioned(
              left: 16,
              top: 0, bottom: 0,
              child: Center(
                child: _NavigationArrow(
                  icon: Icons.chevron_left, 
                  label: "Anterior",
                  onTap: () => context.pushNamed('property-details', pathParameters: {'id': prevPropertyId}),
                ),
              ),
            ),
            
          if (nextPropertyId != null)
            Positioned(
              right: 16,
              top: 0, bottom: 0,
              child: Center(
                child: _NavigationArrow(
                  icon: Icons.chevron_right, 
                  label: "Siguiente",
                  onTap: () => context.pushNamed('property-details', pathParameters: {'id': nextPropertyId}),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Property property, bool isFavorite, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT COLUMN (7/12 approx 58%)
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroImageSection(property: property, isFavorite: isFavorite, onToggleFavorite: () => ref.read(favoritesProvider.notifier).toggleFavorite(property.id)),
                    const SizedBox(height: 32),
                    _DescriptionSection(property: property),
                    const SizedBox(height: 32),
                    _LocationSection(location: property.location),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              // RIGHT COLUMN (5/12 approx 42%) - Sticky
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _SummaryCard(property: property),
                    const SizedBox(height: 24),
                    _MortgageCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, Property property, bool isFavorite, WidgetRef ref) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100), // Space for fixed bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               _HeroImageSection(
                 property: property,
                 isMobile: true,
                 isFavorite: isFavorite,
                 onToggleFavorite: () => ref.read(favoritesProvider.notifier).toggleFavorite(property.id),
               ),
               Padding(
                 padding: const EdgeInsets.all(20),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      // Title & Price (Mobile Order)
                      Text(
                        property.formattedPrice, // Fixed getter name
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0f172a)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        property.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      const SizedBox(height: 16),
                      _PropertyStatsGrid(property: property),
                      const SizedBox(height: 24),
                      Divider(color: Colors.grey[200]),
                      const SizedBox(height: 24),
                      _DescriptionSection(property: property),
                      const SizedBox(height: 32),
                      _LocationSection(location: property.location), // Passing location
                      const SizedBox(height: 32),
                      _OwnerCard(),
                   ],
                 ),
               ),
            ],
          ),
        ),
        // Fixed Bottom Bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
              boxShadow: [
                 BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0f172a),
                      side: const BorderSide(color: Color(0xFF0f172a), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Visitar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF135bec),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- WIDGET COMPONENTS ---

class _HeroImageSection extends StatelessWidget {
  final Property property; // [FIX] Receive full property to check fields
  final bool isMobile;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const _HeroImageSection({required this.property, this.isMobile = false, required this.isFavorite, required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    // Determine image list (add fallback if empty)
    final imageList = property.images.isNotEmpty 
        ? property.images 
        : (property.imageUrl != null ? [property.imageUrl!] : []);

    final showDocs = imageList.length > 1;

    return Stack(
      children: [
        Container(
          height: isMobile ? 300 : 500,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(16),
            color: Colors.grey[200], 
            image: imageList.isNotEmpty ? DecorationImage(
              image: NetworkImage(imageList.first), // Todo: Carousel implementation
              fit: BoxFit.cover,
            ) : null,
            boxShadow: isMobile ? [] : [
               BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: imageList.isEmpty ? const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 48)) : null,
        ),
        // Overlays
        Positioned(
          top: 16,
          right: 16,
          child: Row(
            children: [
               _CircleButton(icon: Icons.share_outlined, color: const Color(0xFF0f172a), onPressed: () {}),
               const SizedBox(width: 8),
               _CircleButton(
                  icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey.shade400, // [FIX] Match Home Card Style
                  onPressed: onToggleFavorite,
              ),
            ],
          ),
        ),
        // Dots (Only if multiple images)
        if (showDocs)
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(imageList.length > 5 ? 5 : imageList.length, (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: index == 0 ? Colors.white : Colors.white38,
                    shape: BoxShape.circle,
                  ),
                )),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _CircleButton({required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell( // Added InkWell for interactivity
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final Property property;
  const _DescriptionSection({required this.property});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Sobre esta propiedad", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
        const SizedBox(height: 12),
        Text(
          property.description.isNotEmpty 
              ? property.description 
              : "No hay descipción disponible para esta propiedad.", // [FIX] Fallback text
          style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            foregroundColor: const Color(0xFF135bec),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Leer más", style: TextStyle(fontWeight: FontWeight.bold)),
              Icon(Icons.keyboard_arrow_down, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationSection extends StatelessWidget {
  final LatLng location;
  const _LocationSection({this.location = const LatLng(40.4168, -3.7038)});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Ubicación aproximada", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield_outlined, size: 14, color: Color(0xFF135bec)),
                  SizedBox(width: 4),
                  Text("UBICACIÓN PROTEGIDA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF135bec))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Non-interactive map preview
                FlutterMap(
                  options: MapOptions(
                    initialCenter: location, // Use actual location
                    initialZoom: 15,
                    interactionOptions: InteractionOptions(flags: InteractiveFlag.none), // Static
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.inmufacil.app',
                    ),
                    CircleLayer(
                         circles: [
                           CircleMarker(
                             point: location, // Use actual location
                             radius: 200, // meters
                             useRadiusInMeter: true,
                             color: const Color(0xFF135bec).withOpacity(0.2),
                             borderColor: const Color(0xFF135bec),
                             borderStrokeWidth: 2,
                           ),
                         ],
                    ),
                  ],
                ),
                // Privacy overlay text
                Positioned(
                  bottom: 16,
                  left: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.95),
                       borderRadius: BorderRadius.circular(8),
                       boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: const Text(
                      "Por seguridad y privacidad, no mostramos la ubicación exacta hasta que la visita sea confirmada.",
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF64748b)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Property property;
  const _SummaryCard({required this.property});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${property.formattedPrice}', // Fixed getter name
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0f172a)),
              ),
              const SizedBox(width: 8),
              const Text(
                'I.V.A incluido',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF94a3b8)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            property.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFF94a3b8)),
              const SizedBox(width: 4),
              Text(
                property.address.isNotEmpty ? property.address : "Dirección no disponible", // [FIX] Fallback for address
                style: const TextStyle(color: Color(0xFF64748b)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey[100]),
          const SizedBox(height: 16),
          // Stats
          _PropertyStatsGrid(property: property),
          const SizedBox(height: 16),
          // Owner
          _OwnerCard(),
          const SizedBox(height: 24),
          // Actions
          Row(
             children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      side: const BorderSide(color: Color(0xFF0f172a), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 20, color: Color(0xFF0f172a)),
                        SizedBox(width: 8),
                        Text("Chat Directo", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.calendar_month, color: Colors.white), // White Icon
                    label: const Text("Solicitar Visita", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), // White Text
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB), // Brand Blue like Publicar Gratis
                      elevation: 8, // Shadow effect
                      shadowColor: const Color(0xFF2563EB).withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
             ],
          ),
        ],
      ),
    );
  }
}

class _PropertyStatsGrid extends StatelessWidget {
  final Property property;
  const _PropertyStatsGrid({required this.property});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 8,
      childAspectRatio: 1.5,
      children: [
        _StatItem(icon: Icons.bed, label: '${property.bedrooms} Hab.'),
        _StatItem(icon: Icons.bathtub_outlined, label: '${property.bathrooms} Baños'),
        _StatItem(icon: Icons.square_foot, label: '${property.squareMeters} m²'), // [FIX] Getter is 'squareMeters'
        _StatItem(icon: Icons.layers_outlined, label: '3ª Planta'), // Mock
        _StatItem(icon: Icons.wb_sunny_outlined, label: 'Exterior'), // Mock
        _StatItem(icon: Icons.elevator_outlined, label: 'Ascensor'), // Mock
      ],
    );
  }
}

class _NavigationArrow extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavigationArrow({required this.icon, required this.label, required this.onTap});

  @override
  State<_NavigationArrow> createState() => _NavigationArrowState();
}

class _NavigationArrowState extends State<_NavigationArrow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Hide arrows on small mobile screens to prevent overlapping content?
    // Or make them smaller/transparent.
    final isSmall = MediaQuery.of(context).size.width < 800;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF135bec) : Colors.white.withOpacity(0.9), // Brand Blue on hover
            shape: BoxShape.circle,
            boxShadow: [
               BoxShadow(
                 color: _isHovered ? const Color(0xFF135bec).withOpacity(0.4) : Colors.black.withOpacity(0.1), 
                 blurRadius: 12, 
                 offset: const Offset(0, 4)
               ),
            ],
            border: Border.all(
              color: _isHovered ? const Color(0xFF135bec) : Colors.grey.shade200, 
              width: 1
            ),
          ),
          child: Icon(
            widget.icon, 
            color: _isHovered ? Colors.white : const Color(0xFF0f172a), 
            size: isSmall ? 24 : 32
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF94a3b8), size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0f172a)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _OwnerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuAsgtm795Zdl3axDwufNv7j752Z91W8tEevRe5uo-RTW8WGYApLQWnknr0MGudgquMmPf6kfbaec9fL_KBcWCWITk8joJ4qMyBq3Xefkr2AoK6mwMxxmlQLiMySavKF1OFx00ZpBTdPO8FvB2151EwRrhb1YGh3DSOGq67NqXRobtlnO27igPDZFqOs1cyXo6i9nqQwChdq-juC6b0a4CQuiS4oEgR9lC8zF-sy_o5HmFw2VjnOEXC-xdYDUWH_3un4hlBI40ZckfQt'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 const Text("Ricardo M. Blanco", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
                 const SizedBox(height: 2),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                   decoration: BoxDecoration(
                     color: Colors.green[50], 
                     borderRadius: BorderRadius.circular(4),
                     border: Border.all(color: Colors.green[100]!),
                   ),
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Icon(Icons.verified, size: 10, color: Colors.green[600]),
                       const SizedBox(width: 4),
                       Text("IDENTIDAD VERIFICADA", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.green[600], letterSpacing: 0.5)),
                     ],
                   ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MortgageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF135bec).withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF135bec).withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TU HIPOTECA IDEAL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF135bec), letterSpacing: 1)),
                const SizedBox(height: 4),
                const Text("Desde 2.140€ / mes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
              ],
            ),
            IconButton(
              onPressed: () {}, 
              icon: const Icon(Icons.calculate_outlined), 
              color: const Color(0xFF135bec),
              style: IconButton.styleFrom(
                 backgroundColor: Colors.white,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                 side: BorderSide(color: const Color(0xFF135bec).withOpacity(0.1)),
              ),
            ),
        ],
      ),
    );
  }
}

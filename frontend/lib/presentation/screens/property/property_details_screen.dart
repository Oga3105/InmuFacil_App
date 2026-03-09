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
import '../../providers/auth_provider.dart';
import '../../providers/offers_provider.dart';
import '../../providers/solvency_provider.dart' as solvency_prov;
import '../../providers/property_form_provider.dart';
import '../../widgets/common/premium_button.dart';
import '../../widgets/common/time_badge.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

class PropertyDetailsScreen extends ConsumerStatefulWidget {

  const PropertyDetailsScreen({super.key, required this.propertyId});
  final String propertyId;

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
      orElse: () => Property(
        id: 'fallback', 
        title: 'Cargando Propiedad...', 
        description: '',
        type: PropertyType.all, 
        price: 0, 
        location: const LatLng(40.4168, -3.7038), 
        address: '...',
        bedrooms: 0,
        bathrooms: 0,
        squareMeters: 0,
        images: const [],
        isVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // If still fallback/loading, maybe show spinner? 
    // For now, render with what we have.

    // Navigation Logic (Next/Prev)
    final currentIndex = properties.indexWhere((p) => p.id == widget.propertyId);
    final prevPropertyId = currentIndex > 0 ? properties[currentIndex - 1].id : null;
    final nextPropertyId = (currentIndex != -1 && currentIndex < properties.length - 1) ? properties[currentIndex + 1].id : null;

    // Owner check — owners should not see visitor navigation arrows
    final currentUserId = ref.watch(authProvider).user?.id;
    final isOwner = property.ownerId != null &&
        currentUserId != null &&
        property.ownerId == currentUserId;
    final effectivePrevId = isOwner ? null : prevPropertyId;
    final effectiveNextId = isOwner ? null : nextPropertyId;

    // Favorite Logic
    final favoriteIds = ref.watch(favoritesProvider);
    final isFavorite = favoriteIds.contains(property.id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
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
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      children: [
                        TextSpan(text: 'Inmu', style: TextStyle(color: Color(0xFF2563EB))),
                        TextSpan(text: 'Fácil', style: TextStyle(color: Color(0xFF16A34A))),
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
                  TextButton.icon(
                    onPressed: () {
                      // Calculate which page this property is on based on the
                      // current filtered list and items-per-page setting.
                      final allFiltered = ref.read(searchProvider).filteredProperties;
                      final ipp = ref.read(searchProvider).itemsPerPage;
                      final idx = allFiltered.indexWhere((p) => p.id == widget.propertyId);
                      if (idx >= 0) {
                        final page = (idx ~/ ipp) + 1;
                        ref.read(searchProvider.notifier).setPage(page);
                      }
                      context.go('/search?highlight=${widget.propertyId}');
                    },
                    icon: const Icon(Icons.format_list_bulleted, size: 18, color: Color(0xFF2563EB)),
                    label: const Text('Ver Inmuebles', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  PremiumButton(
                    label: 'Publicar Gratis',
                    onPressed: () {},
                    color: const Color(0xFF2563EB),
                    fullWidth: false,
                    fontSize: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  const SizedBox(width: 12),
                  // [AUTH STATE LOGIC] User icon - same as HomeScreen
                  Builder(
                    builder: (context) {
                      final isAuthenticated = ref.watch(authProvider).isAuthenticated;
                      if (isAuthenticated) {
                        return const UserAvatarMenu();
                      } else {
                        return InkWell(
                          onTap: () => context.pushNamed('login'),
                          borderRadius: BorderRadius.circular(20),
                          child: _buildUserAvatar(ref, authenticated: false),
                        );
                      }
                    },
                  ),
               ],
             ),
           ),
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
          if (effectivePrevId != null)
            Positioned(
              left: 16,
              top: 0, bottom: 0,
              child: Center(
                child: _NavigationArrow(
                  icon: Icons.chevron_left,
                  label: 'Anterior',
                  onTap: () => context.pushNamed('property-details', pathParameters: {'id': effectivePrevId}),
                ),
              ),
            ),

          if (effectiveNextId != null)
            Positioned(
              right: 16,
              top: 0, bottom: 0,
              child: Center(
                child: _NavigationArrow(
                  icon: Icons.chevron_right,
                  label: 'Siguiente',
                  onTap: () => context.pushNamed('property-details', pathParameters: {'id': effectiveNextId}),
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
                        property.formattedPriceFull, // Full price with thousands separator
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0f172a)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        property.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                       const SizedBox(height: 16),
                       // Time Badge
                        PropertyTimeBadge(
                          createdAt: property.createdAt,
                          updatedAt: property.updatedAt,
                          large: true,
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
                      _OwnerCard(property: property),
                      if (!isOwner) ...[
                        const SizedBox(height: 24),
                        _PropertyViabilityCard(propertyId: property.id, ref: ref),
                        const SizedBox(height: 80), // space for bottom bar
                      ],
                   ],
                 ),
               ),
            ],
          ),
        ),
        // Mobile fixed bottom action bar
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _ActionBar(property: property, ref: ref, context: context),
        ),
      ],
    );
  }

  Widget _buildUserAvatar(WidgetRef ref, {required bool authenticated}) {
    if (!authenticated) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey[200],
        child: Icon(Icons.person, color: Colors.grey[600], size: 20),
      );
    }
    final photoUrl = ref.watch(authProvider).user?.profilePhotoUrl;
    if (photoUrl != null) {
      return ClipOval(
        child: Image.network(
          '$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}',
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF2563EB),
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      );
    }
    return const CircleAvatar(
      radius: 18,
      backgroundColor: Color(0xFF2563EB),
      child: Icon(Icons.person, color: Colors.white, size: 20),
    );
  }
}

// --- WIDGET COMPONENTS ---

class _HeroImageSection extends StatefulWidget {

  const _HeroImageSection({required this.property, this.isMobile = false, required this.isFavorite, required this.onToggleFavorite});
  final Property property;
  final bool isMobile;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  State<_HeroImageSection> createState() => _HeroImageSectionState();
}

class _HeroImageSectionState extends State<_HeroImageSection> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _imageList {
    if (widget.property.images.isNotEmpty) return widget.property.images;
    if (widget.property.imageUrl != null) return [widget.property.imageUrl!];
    return [];
  }

  void _goTo(int index) {
    final images = _imageList;
    if (images.isEmpty) return;
    final target = index.clamp(0, images.length - 1);
    _pageController.animateToPage(target, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _openFullscreen(BuildContext context, int index) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullscreenGallery(images: _imageList, initialIndex: index),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final images = _imageList;
    final height = widget.isMobile ? 300.0 : 500.0;
    final hasMultiple = images.length > 1;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Main image area
          ClipRRect(
            borderRadius: widget.isMobile ? BorderRadius.zero : BorderRadius.circular(16),
            child: images.isEmpty
                ? Container(
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 48)),
                  )
                : GestureDetector(
                    onTap: () => _openFullscreen(context, _currentIndex),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _currentIndex = i),
                      itemBuilder: (_, i) => Image.network(
                        images[i],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 48)),
                        ),
                      ),
                    ),
                  ),
          ),
          // Left arrow
          if (hasMultiple && _currentIndex > 0)
            Positioned(
              left: 8,
              top: 0, bottom: 0,
              child: Center(
                child: _NavArrow(icon: Icons.chevron_left, onPressed: () => _goTo(_currentIndex - 1)),
              ),
            ),
          // Right arrow
          if (hasMultiple && _currentIndex < images.length - 1)
            Positioned(
              right: 8,
              top: 0, bottom: 0,
              child: Center(
                child: _NavArrow(icon: Icons.chevron_right, onPressed: () => _goTo(_currentIndex + 1)),
              ),
            ),
          // Top-right action buttons
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              children: [
                _CircleButton(icon: Icons.share_outlined, color: const Color(0xFF0f172a), onPressed: () {}),
                const SizedBox(width: 8),
                _CircleButton(
                  icon: widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: widget.isFavorite ? Colors.red : Colors.grey.shade400,
                  onPressed: widget.onToggleFavorite,
                ),
              ],
            ),
          ),
          // Fullscreen hint icon (bottom-left)
          if (images.isNotEmpty)
            Positioned(
              bottom: hasMultiple ? 44 : 12,
              left: 12,
              child: GestureDetector(
                onTap: () => _openFullscreen(context, _currentIndex),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                ),
              ),
            ),
          // Dots indicator
          if (hasMultiple)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      images.length > 7 ? 7 : images.length,
                      (i) {
                        final dotIndex = images.length > 7 ? (i * (images.length - 1) ~/ 6) : i;
                        final active = dotIndex == _currentIndex || (i == 6 && _currentIndex >= dotIndex);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 8 : 6,
                          height: active ? 8 : 6,
                          decoration: BoxDecoration(
                            color: active ? Colors.white : Colors.white38,
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({required this.images, required this.initialIndex});
  final List<String> images;
  final int initialIndex;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_current + 1} / ${widget.images.length}', style: const TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: Image.network(
                  widget.images[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 64),
                ),
              ),
            ),
          ),
          if (_current > 0)
            Positioned(
              left: 8, top: 0, bottom: 0,
              child: Center(child: _NavArrow(icon: Icons.chevron_left, onPressed: () {
                _ctrl.animateToPage(_current - 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              })),
            ),
          if (_current < widget.images.length - 1)
            Positioned(
              right: 8, top: 0, bottom: 0,
              child: Center(child: _NavArrow(icon: Icons.chevron_right, onPressed: () {
                _ctrl.animateToPage(_current + 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              })),
            ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.color, required this.onPressed});
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

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
  const _DescriptionSection({required this.property});
  final Property property;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sobre esta propiedad', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
        const SizedBox(height: 12),
        Text(
          property.description.isNotEmpty 
              ? property.description 
              : 'No hay descipción disponible para esta propiedad.', // [FIX] Fallback text
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
              Text('Leer más', style: TextStyle(fontWeight: FontWeight.bold)),
              Icon(Icons.keyboard_arrow_down, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({this.location = const LatLng(40.4168, -3.7038)});
  final LatLng location;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Ubicación aproximada', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: Color(0xFF135bec)),
                  SizedBox(width: 4),
                  Text('UBICACIÓN PROTEGIDA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF135bec))),
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
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Static
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
                      'Por seguridad y privacidad, no mostramos la ubicación exacta hasta que la visita sea confirmada.',
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

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.property});
  final Property property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.blue.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
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
                property.formattedPriceFull,
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
                property.address.isNotEmpty ? property.address : 'Dirección no disponible',
                style: const TextStyle(color: Color(0xFF64748b)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PropertyTimeBadge(
            createdAt: property.createdAt,
            updatedAt: property.updatedAt,
            large: true,
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey[100]),
          const SizedBox(height: 16),
          _PropertyStatsGrid(property: property),
          const SizedBox(height: 16),
          _OwnerCard(property: property),
          const SizedBox(height: 24),
          // Viability widget — only shown to non-owners (buyers)
          if (!isOwner) ...[
            _PropertyViabilityCard(propertyId: property.id, ref: ref),
            const SizedBox(height: 16),
          ],
          // Action buttons
          _ActionBar(property: property, ref: ref, context: context, vertical: true),
        ],
      ),
    );
  }
}

// ─── Property Viability Card (buyer-only) ────────────────────────────────────

class _PropertyViabilityCard extends ConsumerWidget {
  const _PropertyViabilityCard({required this.propertyId, required this.ref});

  final String propertyId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(solvency_prov.propertyViabilityProvider(propertyId));

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (viability) {
        if (viability == null) return const SizedBox.shrink();

        Color bg;
        Color border;
        Color textColor;
        IconData icon;

        switch (viability.verdict) {
          case 'green':
            bg = const Color(0xFFF0FDF4);
            border = const Color(0xFF86EFAC);
            textColor = const Color(0xFF166534);
            icon = Icons.check_circle_outline;
            break;
          case 'amber':
            bg = const Color(0xFFFFFBEB);
            border = const Color(0xFFFBBF24);
            textColor = const Color(0xFF92400E);
            icon = Icons.warning_amber_outlined;
            break;
          case 'red':
            bg = const Color(0xFFFFF1F2);
            border = const Color(0xFFFCA5A5);
            textColor = const Color(0xFF991B1B);
            icon = Icons.cancel_outlined;
            break;
          default: // insufficient_data
            bg = const Color(0xFFF8FAFC);
            border = const Color(0xFFCBD5E1);
            textColor = const Color(0xFF475569);
            icon = Icons.info_outline;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart_outlined, color: textColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Mi Viabilidad para este Piso',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(icon, color: textColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viability.verdictLabel,
                      style: TextStyle(fontSize: 12, color: textColor, height: 1.4),
                    ),
                  ),
                ],
              ),
              if (viability.hasFinancialDna && viability.dtiRatio != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ViabilityMetric(
                        label: 'Ratio deuda/ingreso',
                        value: '${(viability.dtiRatio! * 100).toStringAsFixed(0)}%',
                        color: textColor,
                      ),
                    ),
                    if (viability.monthlyMortgageEstimate != null)
                      Expanded(
                        child: _ViabilityMetric(
                          label: 'Cuota est.',
                          value: '${viability.monthlyMortgageEstimate} EUR/mes',
                          color: textColor,
                        ),
                      ),
                  ],
                ),
              ],
              if (!viability.hasFinancialDna) ...[
                const SizedBox(height: 10),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.push('/solvency/wizard'),
                    child: Text(
                      'Completar ADN Financiero',
                      style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ViabilityMetric extends StatelessWidget {
  const _ViabilityMetric({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// ─── Shared action-bar (desktop vertical + mobile horizontal) ──────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.property,
    required this.ref,
    required this.context,
    this.vertical = false,
  });
  final Property property;
  final WidgetRef ref;
  final BuildContext context;
  final bool vertical;

  // ── guard: returns true if the action can proceed ──
  bool _canAct(String action) {
    final auth = ref.read(authProvider);
    final isLoggedIn = auth.isAuthenticated;
    if (!isLoggedIn) {
      _dialog(
        title: 'Cuenta requerida',
        message: action == 'visit'
            ? 'Debes estar registrado para solicitar una visita a esta propiedad.'
            : action == 'contact'
                ? 'Debes estar registrado para contactar con el propietario de esta propiedad.'
                : 'Debes estar registrado para hacer una oferta por esta propiedad.',
        icon: Icons.person_outline,
        cta: 'Iniciar sesión',
        onCta: () { Navigator.of(context).pop(); context.pushNamed('login'); },
      );
      return false;
    }
    final dniStatus = (auth.user?.dniStatus ?? '').toUpperCase();
    final isVerified = dniStatus == 'VALIDADO';
    if (!isVerified) {
      _dialog(
        title: 'Verificación requerida',
        message: action == 'visit'
            ? 'Solo los usuarios con identidad verificada pueden solicitar visitas. Completa tu verificación KYC para continuar.'
            : action == 'contact'
                ? 'Solo los usuarios con identidad verificada pueden contactar con particulares. Completa tu verificación KYC para continuar.'
                : 'Solo los usuarios con identidad verificada pueden hacer ofertas. Completa tu verificación KYC para continuar.',
        icon: Icons.verified_user_outlined,
        cta: 'Verificar identidad',
        onCta: () { Navigator.of(context).pop(); context.push('/verify-identity'); },
      );
      return false;
    }
    return true;
  }

  void _dialog({
    required String title,
    required String message,
    required IconData icon,
    required String cta,
    required VoidCallback onCta,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 28),
        ),
        title: Text(title, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Text(message, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            onPressed: onCta,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(cta),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context2) {
    final auth = ref.watch(authProvider);
    final currentUserId = auth.user?.id;
    final isOwner = property.ownerId != null &&
        currentUserId != null &&
        property.ownerId == currentUserId;

    if (vertical) {
      // Desktop: vertical stack
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isOwner) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () { if (_canAct('visit')) context.push('/property/${property.id}/visit'); },
                    icon: const Icon(Icons.calendar_month_outlined, size: 20),
                    label: const Text('Solicitar Visita', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0f172a),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF0f172a), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () { if (_canAct('offer')) context.push('/property/${property.id}/offer?price=${property.price}'); },
                    icon: const Icon(Icons.gavel_rounded, size: 20),
                    label: const Text('Hacer Oferta', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ContactarButton(propertyId: property.id),
          ],
          if (isOwner) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push('/property/${property.id}/offers'),
              icon: const Icon(Icons.list_alt_outlined, size: 20),
              label: const Text('Gestionar Ofertas', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            _OwnerVisitsToggle(property: property, ref: ref),
          ],
        ],
      );
    }

    // Mobile: horizontal row in a styled bar
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isOwner) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () { if (_canAct('visit')) context.push('/property/${property.id}/visit'); },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Solicitar Visita'),
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
                  child: FilledButton.icon(
                    onPressed: () { if (_canAct('offer')) context.push('/property/${property.id}/offer?price=${property.price}'); },
                    icon: const Icon(Icons.gavel_rounded),
                    label: const Text('Hacer Oferta'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: _ContactarButton(propertyId: property.id),
            ),
          ],
          if (isOwner) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/property/${property.id}/offers'),
                icon: const Icon(Icons.list_alt_outlined),
                label: const Text('Gestionar Ofertas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            _OwnerVisitsToggle(property: property, ref: ref),
          ],
        ],
      ),
    );
  }
}

class _OwnerVisitsToggle extends StatefulWidget {
  const _OwnerVisitsToggle({required this.property, required this.ref});
  final Property property;
  final WidgetRef ref;

  @override
  State<_OwnerVisitsToggle> createState() => _OwnerVisitsToggleState();
}

class _OwnerVisitsToggleState extends State<_OwnerVisitsToggle> {
  late bool _allowVisits;

  @override
  void initState() {
    super.initState();
    _allowVisits = widget.property.allowVisits;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Permitir visitas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(
        _allowVisits ? 'Los interesados pueden solicitar visita' : 'Visitas desactivadas',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      value: _allowVisits,
      onChanged: (v) async {
        setState(() => _allowVisits = v);
        try {
          await widget.ref.read(propertyFormProvider.notifier).patchAllowVisits(
            widget.property.id,
            value: v,
          );
        } catch (_) {
          setState(() => _allowVisits = !v);
        }
      },
    );
  }
}

class _PropertyStatsGrid extends StatelessWidget {
  const _PropertyStatsGrid({required this.property});
  final Property property;

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
        _StatItem(icon: Icons.layers_outlined, label: property.floor ?? 'Bajo'), // [FIX] Use real floor data
        const _StatItem(icon: Icons.wb_sunny_outlined, label: 'Exterior'), // Mock
        const _StatItem(icon: Icons.elevator_outlined, label: 'Ascensor'), // Mock
      ],
    );
  }
}

class _NavigationArrow extends StatefulWidget {

  const _NavigationArrow({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
                 offset: const Offset(0, 4),
               ),
            ],
            border: Border.all(
              color: _isHovered ? const Color(0xFF135bec) : Colors.grey.shade200, 
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon, 
            color: _isHovered ? Colors.white : const Color(0xFF0f172a), 
            size: isSmall ? 24 : 32,
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

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
  const _OwnerCard({required this.property});
  final Property property;

  @override
  Widget build(BuildContext context) {
    final name = property.ownerName ?? 'Propietario';
    final isVerified = property.ownerIsVerified;
    final photoUrl = property.ownerPhotoUrl;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              final ts = DateTime.now().millisecondsSinceEpoch;
              return SizedBox(
                width: 40,
                height: 40,
                child: ClipOval(
                  child: photoUrl != null
                      ? Image.network(
                          '$photoUrl?v=$ts',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF2563EB),
                            alignment: Alignment.center,
                            child: const Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF2563EB),
                          alignment: Alignment.center,
                          child: const Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
                const SizedBox(height: 2),
                if (isVerified)
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
                        Text('IDENTIDAD VERIFICADA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.green[600], letterSpacing: 0.5)),
                      ],
                    ),
                  )
                else
                  Text('Identidad pendiente de verificar', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TU HIPOTECA IDEAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF135bec), letterSpacing: 1)),
                SizedBox(height: 4),
                Text('Desde 2.140€ / mes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
              ],
            ),
            IconButton(
              onPressed: () {}, 
              icon: const Icon(Icons.calculate_outlined), 
              color: const Color(0xFF135bec),
              style: IconButton.styleFrom(
                 backgroundColor: Colors.white,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                 side: BorderSide(color: const Color(0xFF135bec).withValues(alpha: 0.1)),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ContactarButton — navega directo al chat de la oferta activa
// ---------------------------------------------------------------------------

class _ContactarButton extends ConsumerStatefulWidget {
  const _ContactarButton({required this.propertyId});
  final String propertyId;

  @override
  ConsumerState<_ContactarButton> createState() => _ContactarButtonState();
}

class _ContactarButtonState extends ConsumerState<_ContactarButton> {
  bool _loading = false;

  static const _activeStatuses = {
    'pending', 'counter_offer', 'countered', 'accepted',
    'signing_pending', 'signed',
  };

  Future<void> _onPressed() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) {
      context.pushNamed('login');
      return;
    }

    final sentOffers = ref.read(sentOffersProvider).asData?.value ?? [];
    final activeOffer = sentOffers.where((o) =>
      o.propertyId == widget.propertyId &&
      _activeStatuses.contains(o.status.toLowerCase()),
    ).firstOrNull;

    if (activeOffer == null) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Haz una oferta primero'),
          content: const Text(
            'El chat privado con el vendedor se abre al hacer una oferta. '
            'Ambas partes pueden chatear desde ese momento.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/property/${widget.propertyId}/offer');
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Hacer Oferta'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(sentOffersProvider.notifier).enableChat(activeOffer.id);
    } catch (_) {
      // ignore — chat might already be enabled
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (mounted) context.push('/chat/${activeOffer.id}');
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _onPressed,
      icon: _loading
          ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chat_bubble_outline, size: 20),
      label: Text(
        'Contactar Particular',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB),
        side: const BorderSide(color: Color(0xFF2563EB)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

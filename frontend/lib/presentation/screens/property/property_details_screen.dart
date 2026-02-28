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
import '../../widgets/common/premium_button.dart';
import '../../widgets/common/time_badge.dart';
import '../../widgets/common/app_bar_back_button.dart';

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
                  TextButton(
                    onPressed: () {}, 
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Comprar', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
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
                        return PopupMenuButton<String>(
                          offset: const Offset(0, 40),
                          tooltip: 'Menú de usuario',
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'profile',
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text('Mi Perfil'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'my-properties',
                              child: Row(
                                children: [
                                  Icon(Icons.home_work_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('Mis Propiedades'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'contracts',
                              child: Row(
                                children: [
                                  Icon(Icons.description_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('Mis Contratos'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'logout') {
                              await ref.read(authProvider.notifier).logout();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sesión cerrada correctamente')),
                                );
                                context.go('/');
                              }
                            } else if (value == 'profile') {
                              context.push('/profile');
                            } else if (value == 'my-properties') {
                              context.push('/profile?tab=1');
                            } else if (value == 'contracts') {
                              context.push('/contracts');
                            }
                          },
                          child: _buildUserAvatar(ref, authenticated: true),
                        );
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
          if (prevPropertyId != null)
            Positioned(
              left: 16,
              top: 0, bottom: 0,
              child: Center(
                child: _NavigationArrow(
                  icon: Icons.chevron_left, 
                  label: 'Anterior',
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
                  label: 'Siguiente',
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
                      _OwnerCard(),
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

class _HeroImageSection extends StatelessWidget {

  const _HeroImageSection({required this.property, this.isMobile = false, required this.isFavorite, required this.onToggleFavorite});
  final Property property; // [FIX] Receive full property to check fields
  final bool isMobile;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

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
                ),),
              ),
            ),
          ),
        ),
      ],
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
                property.formattedPrice,
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
          _OwnerCard(),
          const SizedBox(height: 24),
          // Action buttons
          _ActionBar(property: property, ref: ref, context: context, vertical: true),
        ],
      ),
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
            : 'Debes estar registrado para hacer una oferta por esta propiedad.',
        icon: Icons.person_outline,
        cta: 'Iniciar sesión',
        onCta: () { Navigator.of(context).pop(); context.pushNamed('login'); },
      );
      return false;
    }
    final dniStatus = auth.user?.dniStatus ?? '';
    final isVerified = dniStatus == 'approved';
    if (!isVerified) {
      _dialog(
        title: 'Verificación requerida',
        message: action == 'visit'
            ? 'Solo los usuarios con identidad verificada pueden solicitar visitas. Completa tu verificación KYC para continuar.'
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
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            onPressed: onCta,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          ],
        ],
      ),
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
                 const Text('Ricardo M. Blanco', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
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
                       Text('IDENTIDAD VERIFICADA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.green[600], letterSpacing: 0.5)),
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

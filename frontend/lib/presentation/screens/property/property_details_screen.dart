import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../domain/entities/property.dart';
import '../../widgets/common/report_button.dart';
import '../../widgets/common/share_bottom_sheet.dart';
import '../../../domain/entities/property_type.dart'; // [FIX] Import added
// import '../../providers/property_provider.dart'; // TODO: Implement specific provider
import '../../providers/search_provider.dart';
import '../../providers/favorites_provider.dart'; // [NEW] Favorites Logic
import '../../providers/auth_provider.dart';
import '../../providers/offers_provider.dart';
import '../../providers/solvency_provider.dart' as solvency_prov;
import '../../providers/property_form_provider.dart';
import '../../providers/property_analytics_provider.dart';
import '../../widgets/common/price_tag.dart';
import '../../widgets/common/time_badge.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import '../../widgets/common/demo_banner.dart';
import '../../widgets/property/document_status_section.dart';
import '../../widgets/property/comfort_radar_chart.dart';
// DESHACER: import '../../widgets/property/market_price_widget.dart';
// import '../../widgets/property/urban_growth_widget.dart'; // DESHACER: kept for future use
// import '../../widgets/property/legal_guide_button.dart'; // DESHACER: kept for future use
import '../../providers/visits_provider.dart';

String _obfuscateAddress(String address) {
  if (RegExp(r'^-?\d+\.\d+,\s*-?\d+\.\d+$').hasMatch(address.trim())) {
    return 'property.obfuscated_address'.tr();
  }
  final parts = address.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) {
    return parts.sublist(1).join(', ');
  }
  return address;
}

class PropertyDetailsScreen extends ConsumerStatefulWidget {

  const PropertyDetailsScreen({super.key, required this.propertyId});
  final String propertyId;

  @override
  ConsumerState<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends ConsumerState<PropertyDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Log view once after first frame (fire-and-forget)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(logPropertyViewProvider(widget.propertyId));
      }
    });
  }

  bool _canMakeOffer(BuildContext ctx) {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('property.account_required_title'.tr(), textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          content: Text('property.account_required_offer'.tr(),
              textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(),
                child: Text('common.cancel'.tr())),
            FilledButton(
              onPressed: () { Navigator.of(ctx).pop(); ctx.pushNamed('login'); },
              child: Text('property.login_cta'.tr()),
            ),
          ],
        ),
      );
      return false;
    }
    final dniStatus = (auth.user?.dniStatus ?? '').toUpperCase();
    if (dniStatus != 'VALIDADO') {
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('property.verification_required_title'.tr(), textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          content: Text('property.verification_required_offer'.tr(),
              textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(),
                child: Text('common.cancel'.tr())),
            FilledButton(
              onPressed: () { Navigator.of(ctx).pop(); ctx.push('/verify-identity'); },
              child: Text('property.verify_identity_cta'.tr()),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Try search cache first (fast path)
    final properties = ref.watch(searchProvider).filteredProperties;
    final Property? cachedProperty = properties
        .cast<Property?>()
        .firstWhere((p) => p?.id == widget.propertyId, orElse: () => null);

    // 2. Always watch direct-fetch provider (Riverpod requires unconditional watches).
    //    Result is only used when not in cache (e.g. just created / just edited).
    final directFetchAsync = ref.watch(propertyByIdProvider(widget.propertyId));

    // Show spinner while fetching from API (cache miss path)
    if (cachedProperty == null && directFetchAsync.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final property = cachedProperty ??
        directFetchAsync.value ??
        Property.empty();

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

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
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
                        TextSpan(text: 'Inmu', style: TextStyle(color: Color(0xFF135BEC))),
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
          Builder(
            builder: (context) {
              final isMobile = MediaQuery.of(context).size.width < 650;
              final isAuthenticated = ref.watch(authProvider).isAuthenticated;
              final avatarWidget = isAuthenticated
                  ? const UserAvatarMenu()
                  : InkWell(
                      onTap: () => context.pushNamed('login'),
                      borderRadius: BorderRadius.circular(20),
                      child: _buildUserAvatar(ref, authenticated: false),
                    );

              if (isMobile) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
                        onSelected: (value) {
                          if (value == 'list') {
                            final allFiltered = ref.read(searchProvider).filteredProperties;
                            final ipp = ref.read(searchProvider).itemsPerPage;
                            final idx = allFiltered.indexWhere((p) => p.id == widget.propertyId);
                            if (idx >= 0) {
                              final page = (idx ~/ ipp) + 1;
                              ref.read(searchProvider.notifier).setPage(page);
                            }
                            context.go('/search?highlight=${widget.propertyId}');
                          } else if (value == 'offer') {
                            if (_canMakeOffer(context)) context.push('/property/${widget.propertyId}/offer?price=${property.price}');
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'list', child: Row(children: [const Icon(Icons.format_list_bulleted, size: 18), const SizedBox(width: 8), Text('property.view_listings'.tr())])),
                          if (!isOwner) PopupMenuItem(value: 'offer', child: Row(children: [const Icon(Icons.gavel_rounded, size: 18), const SizedBox(width: 8), Text('property.make_offer'.tr())])),
                        ],
                      ),
                      avatarWidget,
                      const SizedBox(width: 8),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        final allFiltered = ref.read(searchProvider).filteredProperties;
                        final ipp = ref.read(searchProvider).itemsPerPage;
                        final idx = allFiltered.indexWhere((p) => p.id == widget.propertyId);
                        if (idx >= 0) {
                          final page = (idx ~/ ipp) + 1;
                          ref.read(searchProvider.notifier).setPage(page);
                        }
                        context.go('/search?highlight=${widget.propertyId}');
                      },
                      icon: const Icon(Icons.format_list_bulleted, size: 18, color: Color(0xFF135BEC)),
                      label: Text('property.view_listings'.tr(), style: const TextStyle(color: Color(0xFF135BEC), fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (!isOwner)
                      FilledButton.icon(
                        onPressed: () { if (_canMakeOffer(context)) context.push('/property/${widget.propertyId}/offer?price=${property.price}'); },
                        icon: const Icon(Icons.gavel_rounded, size: 18),
                        label: Text('property.make_offer'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF135BEC),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    const SizedBox(width: 12),
                    avatarWidget,
                  ],
                ),
              );
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(29),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [DemoBanner()],
          ),
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
                return _buildMobileLayout(context, property, isFavorite, ref, isOwner);
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
                  label: 'property.previous'.tr(),
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
                  label: 'property.next_property'.tr(),
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
                    _MortgageCard(price: property.price),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, Property property, bool isFavorite, WidgetRef ref, bool isOwner) {
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
                      PriceTag(
                        price: property.price,
                        previousPrice: property.previousPrice,
                        large: true,
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
                      if (property.energyCertification != null) ...[
                        const SizedBox(height: 12),
                        _EnergyCertBadge(rating: property.energyCertification!),
                      ],
                      const SizedBox(height: 24),
                      Divider(color: Theme.of(context).colorScheme.outlineVariant),
                      const SizedBox(height: 24),
                      _DescriptionSection(property: property),
                      const SizedBox(height: 32),
                      _LocationSection(location: property.location), // Passing location
                      ...[
                        const SizedBox(height: 32),
                        ComfortRadarChart(propertyId: property.id),
                      ],
                      // DESHACER: MarketPriceWidget removed from property details UI.
                      const SizedBox(height: 32),
                      _OwnerCard(property: property, isOwner: isOwner),
                      const SizedBox(height: 24),
                      _SellerMetricsCard(propertyId: property.id, status: property.status),
                      if (isOwner) ...[
                        const SizedBox(height: 24),
                        DocumentStatusSection(
                          postalCode: _extractPostalCode(property.address),
                        ),
                      ],
                      if (!isOwner) ...[
                        const SizedBox(height: 16),
                        _PropertyViabilityCard(propertyId: property.id, ref: ref),
                      ],
                      const SizedBox(height: 80), // space for bottom bar
                   ],
                 ),
               ),
            ],
          ),
        ),
        // Mobile fixed bottom action bar
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _ActionBar(property: property, context: context),
        ),
      ],
    );
  }

  String _extractPostalCode(String address) {
    final match = RegExp(r'\b(\d{5})\b').firstMatch(address);
    return match?.group(1) ?? '';
  }


  Widget _buildUserAvatar(WidgetRef ref, {required bool authenticated}) {
    if (!authenticated) {
      final cs = Theme.of(context).colorScheme;
      return CircleAvatar(
        radius: 18,
        backgroundColor: cs.surfaceContainerHighest,
        child: Icon(Icons.person, color: cs.onSurfaceVariant, size: 20),
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
            backgroundColor: Color(0xFF135BEC),
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      );
    }
    return const CircleAvatar(
      radius: 18,
      backgroundColor: Color(0xFF135BEC),
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

class _HeroImageSectionState extends State<_HeroImageSection>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _heartController;
  late final Animation<double> _heartScale;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  void _onToggleFavorite() {
    _heartController.forward(from: 0.0);
    widget.onToggleFavorite();
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.image_not_supported, color: Theme.of(context).colorScheme.outline, size: 48),
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
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.broken_image, color: Theme.of(context).colorScheme.outline, size: 48),
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
                _CircleButton(icon: Icons.share_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant, onPressed: () => showShareBottomSheet(context, widget.property)),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _heartScale,
                  builder: (_, child) => Transform.scale(
                    scale: _heartScale.value,
                    child: child,
                  ),
                  child: _CircleButton(
                    icon: widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: widget.isFavorite ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                    onPressed: _onToggleFavorite,
                  ),
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
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _DescriptionSection extends StatefulWidget {
  const _DescriptionSection({required this.property});
  final Property property;

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  bool _expanded = false;
  static const int _previewLines = 3;

  @override
  Widget build(BuildContext context) {
    final text = widget.property.description.isNotEmpty
        ? widget.property.description
        : 'property.no_description'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'property.about_property'.tr(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 12),
        Text(
          text,
          maxLines: _expanded ? null : _previewLines,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(fontSize: 16, height: 1.6, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            foregroundColor: const Color(0xFF135bec),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _expanded ? 'property.read_less'.tr() : 'property.read_more'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('property.approx_location'.tr(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('property.protected_location'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary)),
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
            border: Border.all(color: colorScheme.outlineVariant),
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
                       color: colorScheme.surface.withValues(alpha: 0.95),
                       borderRadius: BorderRadius.circular(8),
                       boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Text(
                      'property.privacy_notice'.tr(),
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
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
    final currentUserId = ref.watch(authProvider).user?.id;
    final isOwner = property.ownerId != null &&
        currentUserId != null &&
        property.ownerId == currentUserId;

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.surfaceContainerLow),
        boxShadow: [
          BoxShadow(color: Colors.blue.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PriceTag(
                price: property.price,
                previousPrice: property.previousPrice,
                large: true,
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                'property.vat_included'.tr(),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant),
              ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            property.title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _obfuscateAddress(property.address),
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
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
          Divider(color: colorScheme.surfaceContainerLow),
          const SizedBox(height: 16),
          _PropertyStatsGrid(property: property),
          if (property.energyCertification != null) ...[
            const SizedBox(height: 12),
            _EnergyCertBadge(rating: property.energyCertification!),
          ],
          const SizedBox(height: 16),
          _OwnerCard(property: property, isOwner: isOwner),
          const SizedBox(height: 24),
          _SellerMetricsCard(propertyId: property.id, status: property.status),
          const SizedBox(height: 16),
          // Viability widget — only shown to non-owners (buyers)
          if (!isOwner) ...[
            _PropertyViabilityCard(propertyId: property.id, ref: ref),
            const SizedBox(height: 16),
          ],
          // Comfort Radar Chart — zona analysis
          Column(
            children: [
              ComfortRadarChart(propertyId: property.id),
              const SizedBox(height: 16),
            ],
          ),
          // DESHACER: MarketPriceWidget removed from property details UI.
          // Action buttons
          _ActionBar(property: property, context: context, vertical: true),
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

        final cs = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        Color bg;
        Color border;
        Color textColor;
        IconData icon;

        switch (viability.verdict) {
          case 'green':
            bg = isDark ? const Color(0xFF052E16) : const Color(0xFFF0FDF4);
            border = isDark ? const Color(0xFF166534) : const Color(0xFF86EFAC);
            textColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534);
            icon = Icons.check_circle_outline;
            break;
          case 'amber':
            bg = isDark ? const Color(0xFF2A1500) : const Color(0xFFFFFBEB);
            border = isDark ? const Color(0xFF92400E) : const Color(0xFFFBBF24);
            textColor = isDark ? const Color(0xFFFB923C) : const Color(0xFF92400E);
            icon = Icons.warning_amber_outlined;
            break;
          case 'red':
            bg = cs.errorContainer;
            border = cs.error.withOpacity(0.4);
            textColor = cs.onErrorContainer;
            icon = Icons.cancel_outlined;
            break;
          default: // insufficient_data
            bg = cs.surfaceContainerHighest;
            border = cs.outlineVariant;
            textColor = cs.onSurfaceVariant;
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
                    'property.viability_title'.tr(),
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
                        label: 'property.debt_income_ratio'.tr(),
                        value: '${(viability.dtiRatio! * 100).toStringAsFixed(0)}%',
                        color: textColor,
                      ),
                    ),
                    if (viability.monthlyMortgageEstimate != null)
                      Expanded(
                        child: _ViabilityMetric(
                          label: 'property.monthly_mortgage_estimate'.tr(),
                          value: '${viability.monthlyMortgageEstimate} ${'property.eur_per_month'.tr()}',
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
                      'property.complete_financial_dna'.tr(),
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

class _ActionBar extends ConsumerWidget {
  const _ActionBar({
    required this.property,
    required this.context,
    this.vertical = false,
  });
  final Property property;
  final BuildContext context;
  final bool vertical;

  // ── guard: returns true if the action can proceed ──
  bool _canAct(String action, WidgetRef ref) {
    final auth = ref.read(authProvider);
    final isLoggedIn = auth.isAuthenticated;
    if (!isLoggedIn) {
      _dialog(
        title: 'property.account_required_title'.tr(),
        message: action == 'visit'
            ? 'property.account_required_visit'.tr()
            : action == 'contact'
                ? 'property.account_required_contact'.tr()
                : 'property.account_required_offer'.tr(),
        icon: Icons.person_outline,
        cta: 'property.login_cta'.tr(),
        onCta: () { Navigator.of(context).pop(); context.pushNamed('login'); },
      );
      return false;
    }
    final dniStatus = (auth.user?.dniStatus ?? '').toUpperCase();
    final isVerified = dniStatus == 'VALIDADO';
    if (!isVerified) {
      _dialog(
        title: 'property.verification_required_title'.tr(),
        message: action == 'visit'
            ? 'property.verification_required_visit'.tr()
            : action == 'contact'
                ? 'property.verification_required_contact'.tr()
                : 'property.verification_required_offer'.tr(),
        icon: Icons.verified_user_outlined,
        cta: 'property.verify_identity_cta'.tr(),
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
        icon: Builder(
          builder: (ctx) {
            final cs = Theme.of(ctx).colorScheme;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: cs.onPrimaryContainer, size: 28),
            );
          },
        ),
        title: Text(title, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Builder(
          builder: (ctx) => Text(message, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Builder(
              builder: (ctx) => Text('common.cancel'.tr(),
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            ),
          ),
          FilledButton(
            onPressed: onCta,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(cta),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context2, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final currentUserId = auth.user?.id;
    final isOwner = property.ownerId != null &&
        currentUserId != null &&
        property.ownerId == currentUserId;
    final activeVisitAsync = auth.isAuthenticated && !isOwner
        ? ref.watch(activeVisitForPropertyProvider(property.id))
        : null;
    final activeVisit = activeVisitAsync?.value;

    if (vertical) {
      // Desktop: vertical stack
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activeVisit != null)
            _VisitStatusBanner(visit: activeVisit, propertyId: property.id),
          if (!isOwner) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: activeVisit != null
                        ? null
                        : () { if (_canAct('visit', ref)) context.push('/property/${property.id}/visit'); },
                    icon: const Icon(Icons.calendar_month_outlined, size: 20),
                    label: Text(activeVisit != null ? 'property.visit_scheduled'.tr() : 'property.request_visit'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () { if (_canAct('offer', ref)) context.push('/property/${property.id}/offer?price=${property.price}'); },
                    icon: const Icon(Icons.gavel_rounded, size: 20),
                    label: Text('property.make_offer'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF135BEC),
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
              label: Text('property.manage_offers'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF135BEC),
                side: const BorderSide(color: Color(0xFF135BEC)),
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
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
          if (activeVisit != null)
            _VisitStatusBanner(visit: activeVisit, propertyId: property.id),
          if (!isOwner) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () { if (_canAct('offer', ref)) context.push('/property/${property.id}/offer?price=${property.price}'); },
                icon: const Icon(Icons.gavel_rounded),
                label: Text('property.make_offer'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: activeVisit != null
                    ? null
                    : () { if (_canAct('visit', ref)) context.push('/property/${property.id}/visit'); },
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(activeVisit != null ? 'property.visit_scheduled'.tr() : 'property.request_visit'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0f172a),
                  side: const BorderSide(color: Color(0xFF0f172a), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
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
                label: Text('property.manage_offers'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF135BEC),
                  side: const BorderSide(color: Color(0xFF135BEC)),
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

class _VisitStatusBanner extends StatelessWidget {
  const _VisitStatusBanner({required this.visit, required this.propertyId});
  final MyVisit visit;
  final String propertyId;

  @override
  Widget build(BuildContext context) {
    final isPending = visit.status == 'requested';
    final color = isPending ? const Color(0xFFF59E0B) : const Color(0xFF16A34A);
    final bgColor = isPending ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4);
    final borderColor = isPending ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0);
    final icon = isPending ? Icons.hourglass_top_rounded : Icons.check_circle_outline;
    final label = isPending ? 'property.visit_pending'.tr() : 'property.visit_confirmed'.tr();
    final hour = '${visit.startTime.hour.toString().padLeft(2, '0')}:${visit.startTime.minute.toString().padLeft(2, '0')}';
    final day = '${visit.startTime.day}/${visit.startTime.month}/${visit.startTime.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  'property.visit_date_time'.tr(namedArgs: {'day': day, 'hour': hour}),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.push('/profile?tab=3'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'property.view_visit'.tr(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
              ),
            ),
          ),
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
      title: Text('property.allow_visits'.tr(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(
        _allowVisits ? 'property.visits_enabled'.tr() : 'property.visits_disabled'.tr(),
        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
        _StatItem(icon: Icons.bed, label: 'property.bedrooms_count'.tr(namedArgs: {'count': '${property.bedrooms}'})),
        _StatItem(icon: Icons.bathtub_outlined, label: 'property.bathrooms_count'.tr(namedArgs: {'count': '${property.bathrooms}'})),
        _StatItem(icon: Icons.square_foot, label: 'property.surface_count'.tr(namedArgs: {'count': '${property.squareMeters}'})), // [FIX] Getter is 'squareMeters'
        _StatItem(icon: Icons.layers_outlined, label: property.floor ?? 'property.floor_default'.tr()), // [FIX] Use real floor data
        _StatItem(icon: Icons.wb_sunny_outlined, label: 'property.exterior'.tr()), // Mock
        _StatItem(icon: Icons.elevator_outlined, label: 'property.elevator'.tr()), // Mock
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
            color: _isHovered ? const Color(0xFF135bec) : Theme.of(context).colorScheme.surface.withValues(alpha: 0.9), // Brand Blue on hover
            shape: BoxShape.circle,
            boxShadow: [
               BoxShadow(
                 color: _isHovered ? const Color(0xFF135bec).withOpacity(0.4) : Colors.black.withOpacity(0.1), 
                 blurRadius: 12, 
                 offset: const Offset(0, 4),
               ),
            ],
            border: Border.all(
              color: _isHovered ? const Color(0xFF135bec) : Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: _isHovered ? Colors.white : Theme.of(context).colorScheme.onSurface,
            size: isSmall ? 24 : 32,
          ),
        ),
      ),
    );
  }
}

// ─── Energy Certification Badge ───────────────────────────────────────────────

class _EnergyCertBadge extends StatelessWidget {
  const _EnergyCertBadge({required this.rating});
  final String rating;

  static const Map<String, Color> _colors = {
    'A': Color(0xFF16A34A),
    'B': Color(0xFF4ADE80),
    'C': Color(0xFFBEF264),
    'D': Color(0xFFFACC15),
    'E': Color(0xFFFB923C),
    'F': Color(0xFFF87171),
    'G': Color(0xFFEF4444),
  };

  @override
  Widget build(BuildContext context) {
    final upperRating = rating.toUpperCase();
    final isTramite = upperRating == 'EN_TRAMITE' || upperRating == 'EN TRAMITE';
    final color = isTramite ? const Color(0xFF94A3B8) : (_colors[upperRating] ?? const Color(0xFF94A3B8));
    final label = isTramite ? 'property.energy_cert_in_progress'.tr() : 'property.energy_cert_rating'.tr(namedArgs: {'rating': upperRating});

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: colorScheme.onSurfaceVariant, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Seller Metrics Card (V32) ────────────────────────────────────────────────

class _SellerMetricsCard extends ConsumerWidget {
  const _SellerMetricsCard({required this.propertyId, this.status});
  final String propertyId;
  final String? status;

  static const _blue = Color(0xFF135BEC);
  static const _green = Color(0xFF16A34A);

  String _badgeLabel() {
    switch (status) {
      case 'published': return 'property.status_active'.tr();
      case 'draft':     return 'property.status_draft'.tr();
      case 'reserved':  return 'property.status_reserved'.tr();
      case 'sold':      return 'property.status_sold'.tr();
      default:          return 'property.status_inactive'.tr();
    }
  }

  Color get _badgeColor {
    switch (status) {
      case 'published': return _green;
      case 'reserved':  return const Color(0xFFF59E0B);
      case 'sold':      return const Color(0xFF6366F1);
      default:          return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(propertyAnalyticsProvider(propertyId));

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.bar_chart_outlined, color: colorScheme.onPrimaryContainer, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'property.ad_performance'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _badgeLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          analyticsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _blue,
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (analytics) {
              final data = analytics ??
                  const PropertyAnalytics(views: 0, favorites: 0, offers: 0);
              return Row(
                children: [
                  _MetricCell(
                    value: data.views,
                    label: 'property.metric_views'.tr(),
                    icon: Icons.remove_red_eye_outlined,
                    color: _blue,
                  ),
                  _MetricDivider(),
                  _MetricCell(
                    value: data.favorites,
                    label: 'property.metric_favorites'.tr(),
                    icon: Icons.favorite_border_outlined,
                    color: const Color(0xFFDC2626),
                  ),
                  _MetricDivider(),
                  _MetricCell(
                    value: data.offers,
                    label: 'property.metric_offers'.tr(),
                    icon: Icons.payments_outlined,
                    color: _green,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final int value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 50,
        color: Theme.of(context).colorScheme.outlineVariant,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.property, this.isOwner = false});
  final Property property;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final name = property.ownerName ?? 'property.owner_default_name'.tr();
    final isVerified = property.ownerIsVerified;
    final photoUrl = property.ownerPhotoUrl;

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
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
                            color: const Color(0xFF135BEC),
                            alignment: Alignment.center,
                            child: const Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF135BEC),
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
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const SizedBox(height: 2),
                if (isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 10, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text('property.identity_verified'.tr(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF16A34A), letterSpacing: 0.5)),
                      ],
                    ),
                  )
                else
                  Text('property.identity_pending'.tr(), style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (!isOwner && property.ownerId != null)
            ReportButton(reportedUserId: int.tryParse(property.ownerId!) ?? 0),
        ],
      ),
    );
  }
}

class _MortgageCard extends StatelessWidget {
  const _MortgageCard({required this.price});
  final double price;

  int _computeMonthly() {
    if (price <= 0) return 0;
    const double ltvRatio = 0.80;
    const double annualRate = 0.035;
    const int years = 30;
    final double loan = price * ltvRatio;
    final double r = annualRate / 12;
    final int n = years * 12;
    final double factor = pow(1 + r, n).toDouble();
    return (loan * r * factor / (factor - 1)).round();
  }

  String _fmt(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final int monthly = _computeMonthly();
    final int loanAmount = (price * 0.80).round();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'property.mortgage_title'.tr(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '~${_fmt(monthly)} €',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'property.mortgage_per_month'.tr(),
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'property.mortgage_financing'.tr(namedArgs: {'amount': _fmt(loanAmount)}),
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            'property.mortgage_term'.tr(),
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              'property.mortgage_disclaimer'.tr(),
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
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
          title: Text('property.offer_first_title'.tr()),
          content: Text(
            'property.offer_first_message'.tr(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('property.understood'.tr()),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/property/${widget.propertyId}/offer');
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF135BEC)),
              child: Text('property.make_offer'.tr()),
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
        'property.contact_private'.tr(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF135BEC),
        side: const BorderSide(color: Color(0xFF135BEC)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// DESHACER: _LegalGuidesSection and _ccaaFromPostalCode removed from UI.
// Widget files and backend endpoints preserved for future reactivation.

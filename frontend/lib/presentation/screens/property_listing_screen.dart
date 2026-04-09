import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/property_listing/property_listing_item.dart';
import '../widgets/property_listing/filter_sidebar.dart';
import '../widgets/property/smart_explorer_card.dart';
import '../widgets/common/premium_button.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_type.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/app_bar_back_button.dart';
import '../widgets/common/user_avatar_menu.dart';
import '../widgets/common/demo_banner.dart';

class PropertyListingScreen extends ConsumerStatefulWidget {
  const PropertyListingScreen({super.key, this.highlightId, this.fromMap = false});

  /// If set, the listing will auto-scroll to the item with this property id
  /// and briefly highlight it. Set when navigating back from property details.
  final String? highlightId;

  /// When true, the listing respects the current map viewport bounds even if
  /// no explicit location search is active (user arrived via "Ver inmuebles").
  final bool fromMap;

  @override
  ConsumerState<PropertyListingScreen> createState() => _PropertyListingScreenState();
}

class _PropertyListingScreenState extends ConsumerState<PropertyListingScreen> {
  /// Maps property id -> GlobalKey so we can scroll to the highlighted item
  final Map<String, GlobalKey> _itemKeys = {};
  bool _didScroll = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    if (widget.highlightId != null) {
      // After the first frame, try to scroll to the highlighted property
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHighlight());
    }
  }

  void _scrollToHighlight() {
    if (_didScroll) return;
    final key = _itemKeys[widget.highlightId];
    if (key?.currentContext != null) {
      _didScroll = true;
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  GlobalKey _keyFor(String propertyId) {
    return _itemKeys.putIfAbsent(propertyId, () => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final favoriteIds = ref.watch(favoritesProvider);
    // When the user has searched an explicit location, apply the same geographic
    // filter as the home map (so "0 on map" also means "0 on listing").
    // When there is no active location (e.g. after reset to show all available),
    // bypass the geographic filter and show everything the backend loaded.
    final geoFiltered = ref.watch(filteredByMapPropertiesProvider);
    final lifestyleSorted = ref.watch(lifestyleSortedPropertiesProvider);
    var allFilteredProperties = (searchState.location.isNotEmpty || widget.fromMap)
        ? geoFiltered
        : lifestyleSorted;

    // Apply local Favorites Filter if active
    if (searchState.onlyFavorites) {
      allFilteredProperties = allFilteredProperties.where((p) => favoriteIds.contains(p.id)).toList();
    }

    // Apply local Verified Filter if active
    if (searchState.onlyVerified) {
      allFilteredProperties = allFilteredProperties.where((p) => p.isVerified).toList();
    }

    final paginatedProperties = _getPaginatedSlice(allFilteredProperties, searchState.currentPage, searchState.itemsPerPage);
    final theme = Theme.of(context);
    final navyColor = theme.colorScheme.onSurface;

    // Responsive helpers
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isMobileAppBar = screenWidth < 650;

    void handleProtectedAction(String route) {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      if (isAuthenticated) {
        context.push(route);
      } else {
        context.pushNamed('login');
      }
    }

    // Auth State for UI
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.isAuthenticated;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colorScheme.surface,
      // Mobile: Filter sidebar available as an end drawer
      endDrawer: !isDesktop
          ? Drawer(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: const FilterSidebar(),
                ),
              ),
            )
          : null,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
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
                  Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          children: [
                            TextSpan(text: 'Inmu', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                            TextSpan(text: 'Fácil', style: TextStyle(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          if (isMobileAppBar) ...[
            // Mobile: hamburger menu + avatar
            PopupMenuButton<String>(
              icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
              offset: const Offset(0, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                switch (value) {
                  case 'how':
                    context.push('/info/how-it-works');
                  case 'favorites':
                    ref.read(searchProvider.notifier).toggleOnlyFavorites();
                  case 'publish':
                    handleProtectedAction('/property/create');
                  case 'filters':
                    _scaffoldKey.currentState?.openEndDrawer();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'how',
                  child: Row(children: [const Icon(Icons.info_outline), const SizedBox(width: 8), const Text('Cómo funciona')]),
                ),
                PopupMenuItem(
                  value: 'favorites',
                  child: Row(children: [
                    Icon(searchState.onlyFavorites ? Icons.favorite : Icons.favorite_border,
                        color: searchState.onlyFavorites ? theme.colorScheme.error : null),
                    const SizedBox(width: 8),
                    Text('Favoritos', style: TextStyle(color: searchState.onlyFavorites ? theme.colorScheme.error : null)),
                  ]),
                ),
                if (!isDesktop)
                  PopupMenuItem(
                    value: 'filters',
                    child: Row(children: [const Icon(Icons.filter_list), const SizedBox(width: 8), const Text('Filtros')]),
                  ),
                PopupMenuItem(
                  value: 'publish',
                  child: Builder(builder: (context) => Row(children: [Icon(Icons.add_home_outlined, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Text('Publicar propiedad', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))])),
                ),
              ],
            ),
            if (isAuthenticated)
              const UserAvatarMenu()
            else
              InkWell(
                onTap: () => context.pushNamed('login'),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildUserAvatar(ref, authenticated: false),
                ),
              ),
            const SizedBox(width: 8),
          ] else ...[
            // Desktop: full action row
            Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => context.push('/info/how-it-works'),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cómo funciona', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                  ),
                  Container(height: 20, width: 1, color: theme.colorScheme.outlineVariant, margin: const EdgeInsets.symmetric(horizontal: 16)),
                  // Favorites Toggle
                  TextButton.icon(
                    onPressed: () => ref.read(searchProvider.notifier).toggleOnlyFavorites(),
                    icon: Icon(searchState.onlyFavorites ? Icons.favorite : Icons.favorite_border, color: searchState.onlyFavorites ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant, size: 20),
                    label: Text('Favoritos', style: TextStyle(color: searchState.onlyFavorites ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      backgroundColor: searchState.onlyFavorites ? theme.colorScheme.error.withOpacity(0.05) : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  PremiumButton(
                    label: 'Publicar propiedad',
                    onPressed: () => handleProtectedAction('/property/create'),
                    color: theme.colorScheme.primary,
                    fontSize: 13,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    fullWidth: false,
                  ),
                  const SizedBox(width: 16),
                  if (isAuthenticated)
                    const UserAvatarMenu()
                  else
                    InkWell(
                      onTap: () => context.pushNamed('login'),
                      borderRadius: BorderRadius.circular(20),
                      child: _buildUserAvatar(ref, authenticated: false),
                    ),
                ],
              ),
            ),
          ],
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(29),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DemoBanner(),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              children: [
                // Mobile: filter button above results
                if (!isDesktop)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                          icon: const Icon(Icons.filter_list, size: 18),
                          label: const Text('Filtros y búsqueda'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Breadcrumbs & Title Row
                _buildHeaderDetails(context, allFilteredProperties.length, searchState, ref),
                
                const SizedBox(height: 32),

                // Main Content Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sidebar (Filters) - Hidden on Mobile for now (todo: drawer)
                    if (isDesktop) 
                      const FilterSidebar(),
                    
                    // Property List
                    Expanded(
                      child: Column(
                        children: [
                          if (searchState.useLifestyleFilter)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.fromLTRB(0, 8, 0, 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLowest,
                                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.psychology_outlined, color: theme.colorScheme.primary, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Resultados ordenados por compatibilidad con tu estilo de vida',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (searchState.isLoading)
                             const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                          else if (paginatedProperties.isEmpty)
                             _buildEmptyState()
                          else if (searchState.viewMode == PropertyViewMode.list)
                            Column(
                              children: paginatedProperties.map((p) {
                                final isHighlighted = widget.highlightId == p.id;
                                return KeyedSubtree(
                                  key: _keyFor(p.id),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 600),
                                    margin: isHighlighted
                                        ? const EdgeInsets.symmetric(vertical: 4)
                                        : EdgeInsets.zero,
                                    decoration: isHighlighted
                                        ? BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.colorScheme.primary.withOpacity(0.25),
                                                blurRadius: 16,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          )
                                        : null,
                                    child: PropertyListingItem(property: p),
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 320,
                                  mainAxisExtent: 370,
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 24,
                                ),
                              itemCount: paginatedProperties.length,
                              itemBuilder: (context, index) {
                                final p = paginatedProperties[index];
                                final isHighlighted = widget.highlightId == p.id;
                                return KeyedSubtree(
                                  key: _keyFor(p.id),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 600),
                                    decoration: isHighlighted
                                        ? BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.colorScheme.primary.withOpacity(0.25),
                                                blurRadius: 16,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          )
                                        : null,
                                    child: SmartExplorerCard(
                                      propertyId: p.id,
                                      title: p.title,
                                      address: p.address,
                                      priceEur: p.price.round(),
                                      surfaceM2: p.squareMeters,
                                      bedrooms: p.bedrooms,
                                      bathrooms: p.bathrooms,
                                      description: p.description,
                                      imageUrl: p.imageUrl,
                                      imageCount: p.images.length,
                                      isVerified: p.isVerified,
                                      postalCode: RegExp(r'\b(\d{5})\b').firstMatch(p.address)?.group(1),
                                      onTap: () {
                                        context.pushNamed(
                                          'property-details',
                                          pathParameters: {'id': p.id},
                                        );
                                      },
                                      onContactTap: () {
                                        final auth = ref.read(authProvider);
                                        if (!auth.isAuthenticated) {
                                          context.pushNamed('login');
                                          return;
                                        }
                                        final dniStatus = (auth.user?.dniStatus ?? '').toUpperCase();
                                        if (dniStatus != 'VALIDADO') {
                                          context.push('/verify-identity');
                                          return;
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          
                          // Pagination
                          const SizedBox(height: 40),
                          _buildPagination(ref, searchState, allFilteredProperties.length),
                        ],
                      ),
                    ),
                  ],
                ),

                // Footer Area
                const SizedBox(height: 80),
                const Divider(),
                const SizedBox(height: 40),
                _buildSimpleFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderDetails(BuildContext context, int count, SearchState searchState, WidgetRef ref) {
    final theme = Theme.of(context);
    final navyColor = theme.colorScheme.onSurface;

    return Column(
      children: [
        // Top Row with Breadcrumbs and View Toggles
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   // Breadcrumbs (Mocked for now as we only have single string location)
                   Row(
                     children: [
                       Text('España', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                       Icon(Icons.chevron_right, size: 14, color: theme.colorScheme.onSurfaceVariant),
                       Text('Búsqueda', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                       Icon(Icons.chevron_right, size: 14, color: theme.colorScheme.onSurfaceVariant),
                       Text(searchState.location.isNotEmpty ? searchState.location : 'Todo',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),),
                     ],
                   ),
                   const SizedBox(height: 8),
                   Wrap( // Wrap to handle long location names
                     crossAxisAlignment: WrapCrossAlignment.center,
                     children: [
                       Text(
                         searchState.location.isEmpty ? 'Todas las propiedades' : 'Propiedades en ${searchState.location}',
                         style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: navyColor, letterSpacing: -0.5),
                       ),
                       const SizedBox(width: 12),
                       Text(
                         '$count resultados',
                         style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: theme.colorScheme.onSurfaceVariant),
                       ),
                     ],
                   ),
                 ],
               ),
             ),
             
             // View Controls
             if (MediaQuery.of(context).size.width > 600) // Hide on very small screens
             Row(
               children: [
                 SizedBox(
                   height: 42,
                   child: Container(
                     padding: const EdgeInsets.all(4),
                     decoration: BoxDecoration(
                       color: theme.colorScheme.surface,
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(color: theme.colorScheme.outlineVariant),
                     ),
                      child: Row(
                        children: [
                          _buildViewButton(Icons.list, 'Lista', searchState.viewMode == PropertyViewMode.list, () {
                             ref.read(searchProvider.notifier).updateViewMode(PropertyViewMode.list);
                          }),
                          _buildViewButton(Icons.grid_view_rounded, 'Cuadrícula', searchState.viewMode == PropertyViewMode.grid, () {
                             ref.read(searchProvider.notifier).updateViewMode(PropertyViewMode.grid);
                          }),
                          _buildViewButton(Icons.map_outlined, 'Mapa', false, () => context.go('/')),
                        ],
                      ),
                   ),
                 ),
                  const SizedBox(width: 12),
                  _buildSortingDropdown(context, searchState, ref),
               ],
             ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewButton(IconData icon, String label, bool isActive, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.search_off, size: 64, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'No encontramos propiedades en esta zona.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar los filtros o buscar en otra ubicación.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(WidgetRef ref, SearchState searchState, int totalFilteredCount) {
    final totalPages = (totalFilteredCount / searchState.itemsPerPage).ceil();
    final currentPage = searchState.currentPage;
    
    if (totalPages <= 1) return const SizedBox.shrink();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous button
        InkWell(
          onTap: currentPage > 1 ? () => ref.read(searchProvider.notifier).setPage(currentPage - 1) : null,
          child: _buildPageBtn(Icons.chevron_left, null, false, enabled: currentPage > 1),
        ),
        const SizedBox(width: 8),
        
        // Page numbers
        ...List.generate(totalPages, (index) {
          final pageNum = index + 1;
          // Show first 3, last 1, and current +/- 1
          if (pageNum <= 3 || pageNum == totalPages || (pageNum >= currentPage - 1 && pageNum <= currentPage + 1)) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => ref.read(searchProvider.notifier).setPage(pageNum),
                child: _buildPageBtn(null, '$pageNum', pageNum == currentPage),
              ),
            );
          } else if (pageNum == 4 && currentPage > 5) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Builder(builder: (context) => Text('...', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
            );
          }
          return const SizedBox.shrink();
        }),
        
        const SizedBox(width: 8),
        // Next button
        InkWell(
          onTap: currentPage < totalPages ? () => ref.read(searchProvider.notifier).setPage(currentPage + 1) : null,
          child: _buildPageBtn(Icons.chevron_right, null, false, enabled: currentPage < totalPages),
        ),
      ],
    );
  }

  Widget _buildPageBtn(IconData? icon, String? text, bool isActive, {bool enabled = true}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? null : Border.all(color: colorScheme.outlineVariant),
      ),
      child: icon != null
        ? Icon(icon, color: enabled ? colorScheme.onSurfaceVariant : colorScheme.outlineVariant, size: 20)
        : Text(
            text!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
          ),
    );
  }
  
  Widget _buildSortingDropdown(BuildContext context, SearchState searchState, WidgetRef ref) {
    final sortOptions = {
      SortOption.newest: 'Más recientes',
      SortOption.relevance: 'Relevancia',
      SortOption.priceLowToHigh: 'Precio: menor a mayor',
      SortOption.priceHighToLow: 'Precio: mayor a menor',
    };

    final currentLabel = sortOptions[searchState.sortBy] ?? 'Ordenar';

    return PopupMenuButton<SortOption>(
      onSelected: (value) => ref.read(searchProvider.notifier).setSortBy(value),
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (_) => sortOptions.entries
          .map(
            (e) => PopupMenuItem<SortOption>(
              value: e.key,
              child: Row(
                children: [
                  Builder(builder: (context) {
                    final cs = Theme.of(context).colorScheme;
                    return Icon(
                      Icons.check,
                      size: 15,
                      color: e.key == searchState.sortBy
                          ? cs.onPrimaryContainer
                          : Colors.transparent,
                    );
                  }),
                  const SizedBox(width: 8),
                  Builder(builder: (context) {
                    final cs = Theme.of(context).colorScheme;
                    return Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: e.key == searchState.sortBy
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: e.key == searchState.sortBy
                            ? cs.onPrimaryContainer
                            : cs.onSurface,
                      ),
                    );
                  }),
                ],
              ),
            ),
          )
          .toList(),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  currentLabel,
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 4),
                Icon(Icons.expand_more, size: 14, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// Helper method to paginate a list of properties manually
  List<Property> _getPaginatedSlice(List<Property> properties, int page, int itemsPerPage) {
    final startIndex = (page - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    
    if (startIndex >= properties.length) return [];
    
    return properties.sublist(
      startIndex,
      endIndex > properties.length ? properties.length : endIndex,
    );
  }
  
  Widget _buildSimpleFooter() {
     return Column(
       children: [
         Builder(builder: (context) => Text('© 2026 InmuFácil. Todos los derechos reservados.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12))),
       ],
     );
  }

  Widget _buildUserAvatar(WidgetRef ref, {required bool authenticated}) {
    if (!authenticated) {
      return Builder(builder: (context) => CircleAvatar(
        radius: 18,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
      ));
    }
    final photoUrl = ref.watch(authProvider).user?.profilePhotoUrl;
    if (photoUrl != null) {
      return Builder(builder: (context) => ClipOval(
        child: Image.network(
          '$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}',
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimary, size: 20),
          ),
        ),
      ));
    }
    return Builder(builder: (context) => CircleAvatar(
      radius: 18,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimary, size: 20),
    ));
  }
}

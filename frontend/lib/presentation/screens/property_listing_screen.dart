import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/property_listing/property_listing_item.dart';
import '../widgets/property_listing/filter_sidebar.dart';
import '../widgets/map/property_floating_card.dart';
import '../widgets/common/premium_button.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_type.dart';
import '../providers/auth_provider.dart';

class PropertyListingScreen extends ConsumerWidget {
  const PropertyListingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);
    final favoriteIds = ref.watch(favoritesProvider);
    var allFilteredProperties = ref.watch(filteredByMapPropertiesProvider);
    
    // Apply local Favorites Filter if active
    if (searchState.onlyFavorites) {
      allFilteredProperties = allFilteredProperties.where((p) => favoriteIds.contains(p.id)).toList();
    }

    // Apply local Verified Filter if active
    if (searchState.onlyVerified) {
      allFilteredProperties = allFilteredProperties.where((p) => p.isVerified).toList();
    }

    final paginatedProperties = _getPaginatedSlice(allFilteredProperties, searchState.currentPage, searchState.itemsPerPage);
    final theme = Theme.of(context); // Added
    final navyColor = theme.colorScheme.onSurface; // Changed to use theme
    const bgLight = Color(0xFFF8FAFC);

    // Responsive helper
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

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
      backgroundColor: bgLight,
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
                  onPressed: () => context.push('/404-buy'), 
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Comprar', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => handleProtectedAction('/404-sell'), 
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Vender', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => context.push('/404-how-it-works'),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cómo funciona', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ),
                Container(height: 20, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 16)),
                // Favorites Toggle
                TextButton.icon(
                  onPressed: () => ref.read(searchProvider.notifier).toggleOnlyFavorites(), 
                  icon: Icon(searchState.onlyFavorites ? Icons.favorite : Icons.favorite_border, color: searchState.onlyFavorites ? Colors.red : Colors.grey[600], size: 20),
                  label: Text('Favoritos', style: TextStyle(color: searchState.onlyFavorites ? Colors.red : Colors.grey[700], fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    backgroundColor: searchState.onlyFavorites ? Colors.red.withOpacity(0.05) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Publicar Propiedad
                PremiumButton(
                  label: 'Publicar propiedad',
                  onPressed: () => handleProtectedAction('/404-publish'),
                  color: const Color(0xFF2563EB),
                  fontSize: 13,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  fullWidth: false,
                ),
                const SizedBox(width: 16),
                
                // AUTH LOGIC (Unified with HomeScreen _MapNavigationBar)
                if (isAuthenticated)
                  PopupMenuButton<String>(
                    offset: const Offset(0, 40),
                    tooltip: 'Menú de usuario',
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                         value: 'profile',
                         child: Row(children: [Icon(Icons.person_outline, size: 20), SizedBox(width: 8), Text('Mi Perfil')]),
                      ),
                      const PopupMenuItem(
                         value: 'my-properties',
                         child: Row(children: [Icon(Icons.home_work_outlined, size: 20), SizedBox(width: 8), Text('Mis Propiedades')]),
                      ),
                      const PopupMenuItem(
                         value: 'contracts',
                         child: Row(children: [Icon(Icons.description_outlined, size: 20), SizedBox(width: 8), Text('Mis Contratos')]),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(children: [Icon(Icons.logout, color: Colors.red, size: 20), SizedBox(width: 8), Text('Cerrar Sesión', style: TextStyle(color: Colors.red))]),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesión cerrada')));
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
                  )
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              children: [
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
                          if (searchState.isLoading)
                             const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                          else if (paginatedProperties.isEmpty)
                             _buildEmptyState()
                          else if (searchState.viewMode == PropertyViewMode.list)
                            Column(children: paginatedProperties.map((p) => PropertyListingItem(property: p)).toList())
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 320,
                                  mainAxisExtent: 370, // Tight fit to remove bottom whitespace
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 24,
                                ),
                              itemCount: paginatedProperties.length,
                              itemBuilder: (context, index) {
                                final p = paginatedProperties[index];
                                return PropertyFloatingCard(
                                  property: p,
                                  onTap: () {
                                    context.pushNamed(
                                      'property-details', 
                                      pathParameters: {'id': p.id},
                                    );
                                  },
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
                       Text('España', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                       Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
                       Text('Búsqueda', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                       Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
                       Text(searchState.location.isNotEmpty ? searchState.location : 'Todo', 
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),),
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
                         style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: Colors.grey.shade400),
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
                       border: Border.all(color: Colors.grey.shade200),
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
    const primaryBlue = Color(0xFF2563EB);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? primaryBlue.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? primaryBlue : Colors.grey.shade400),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryBlue)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Container(
       padding: const EdgeInsets.all(40),
       alignment: Alignment.center,
       child: Column(
         children: [
           Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
           const SizedBox(height: 16),
           const Text(
             'No encontramos propiedades en esta zona.',
             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
           ),
           const SizedBox(height: 8),
           Text(
             'Intenta cambiar los filtros o buscar en otra ubicación.',
             style: TextStyle(color: Colors.grey.shade500),
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
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('...', style: TextStyle(color: Colors.grey)),
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
    const primaryBlue = Color(0xFF2563EB);
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? primaryBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: icon != null 
        ? Icon(icon, color: enabled ? Colors.grey.shade600 : Colors.grey.shade300, size: 20)
        : Text(
            text!, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
          ),
    );
  }
  
  Widget _buildSortingDropdown(BuildContext context, SearchState searchState, WidgetRef ref) {
    final theme = Theme.of(context);
    final navyColor = theme.colorScheme.onSurface;
    
    final sortOptions = {
      SortOption.relevance: 'Relevancia',
      SortOption.priceLowToHigh: 'Precio: Menor a Mayor',
      SortOption.priceHighToLow: 'Precio: Mayor a Menor',
      SortOption.newest: 'Más recientes',
    };
    
    return SizedBox(
      height: 42,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButton<SortOption>(
        value: searchState.sortBy,
        underline: const SizedBox.shrink(),
        icon: Icon(Icons.expand_more, color: Colors.grey.shade400),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: navyColor),
        items: sortOptions.entries.map((entry) {
          return DropdownMenuItem(
            value: entry.key,
            child: Text('Ordenar: ${entry.value}'),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            ref.read(searchProvider.notifier).setSortBy(value);
          }
        },
      ),
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
     return const Column(
       children: [
         Text('© 2026 InmuFácil. Todos los derechos reservados.', style: TextStyle(color: Colors.grey, fontSize: 12)),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_provider.dart';
import '../widgets/property_listing/property_listing_item.dart';
import '../widgets/property_listing/filter_sidebar.dart';

class PropertyListingScreen extends ConsumerWidget {
  const PropertyListingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);
    final properties = searchState.filteredProperties;
    const navyColor = Color(0xFF0F172A);
    const bgLight = Color(0xFFF8FAFC);

    // Responsive helper
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        // Using a custom title to match the design's header roughly.
        // In a real app, `AppBar` might be the Global Header.
        // For this page, we assume the Global Header is part of the layout or this AppBar acts as it.
        // The design shows a specific header. Let's try to mimic the "InmuFácil" header here or assume it's global.
        // I'll stick to a simple AppBar that fits the context.
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: InkWell(
            onTap: () => context.go('/'),
            child: Row(
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
        actions: [
           Padding(
             padding: const EdgeInsets.only(right: 24.0),
             child: Row(
               children: [
                  TextButton(
                    onPressed: () {}, 
                    child: const Text('Comprar', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold))
                  ),
                  TextButton(
                    onPressed: () {}, 
                    child: const Text('Vender', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))
                  ),
                  Container(height: 20, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 16)),
                  TextButton(
                    onPressed: () {}, 
                    child: const Text('Mis favoritos', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold))
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Publicar Gratis'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              children: [
                // Breadcrumbs & Title Row
                _buildHeaderDetails(context, properties.length, searchState),
                
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
                          else if (properties.isEmpty)
                             _buildEmptyState()
                          else
                            ...properties.map((p) => PropertyListingItem(property: p)),
                          
                          // Pagination
                          const SizedBox(height: 40),
                          _buildPagination(),
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

  Widget _buildHeaderDetails(BuildContext context, int count, SearchState searchState) {
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
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
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
                 Container(
                   padding: const EdgeInsets.all(4),
                   decoration: BoxDecoration(
                     color: theme.colorScheme.surface,
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: Colors.grey.shade200),
                   ),
                   child: Row(
                     children: [
                       _buildViewButton(Icons.list, 'Lista', true, () {}),
                       _buildViewButton(Icons.map_outlined, 'Mapa', false, () => context.go('/')),
                     ],
                   ),
                 ),
                 const SizedBox(width: 12),
                 InkWell(
                   onTap: () => context.push('/404-sort'),
                   borderRadius: BorderRadius.circular(8),
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                     decoration: BoxDecoration(
                       color: theme.colorScheme.surface,
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(color: Colors.grey.shade200),
                     ),
                     child: Row(
                       children: [
                         Text('Ordenar: Relevancia', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: navyColor)),
                         const SizedBox(width: 4),
                         Icon(Icons.expand_more, color: Colors.grey.shade400),
                       ],
                     ),
                   ),
                 )
               ],
             )
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
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryBlue)),
            ]
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

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPageBtn(Icons.chevron_left, null, false),
        const SizedBox(width: 8),
        _buildPageBtn(null, '1', true),
        const SizedBox(width: 8),
        _buildPageBtn(null, '2', false),
        const SizedBox(width: 8),
        _buildPageBtn(null, '3', false),
        const SizedBox(width: 8),
        const Text('...', style: TextStyle(color: Colors.grey)),
        const SizedBox(width: 8),
        _buildPageBtn(null, '12', false),
        const SizedBox(width: 8),
        _buildPageBtn(Icons.chevron_right, null, false),
      ],
    );
  }

  Widget _buildPageBtn(IconData? icon, String? text, bool isActive) {
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
        ? Icon(icon, color: Colors.grey.shade400, size: 20)
        : Text(
            text!, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isActive ? Colors.white : Colors.grey.shade600
            )
          ),
    );
  }
  
  Widget _buildSimpleFooter() {
     return const Column(
       children: [
         Text('© 2024 InmuFácil. Todos los derechos reservados.', style: TextStyle(color: Colors.grey, fontSize: 12)),
       ],
     );
  }
}

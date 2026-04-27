import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:inmufacil_frontend/domain/entities/property_type.dart';
import 'package:inmufacil_frontend/presentation/providers/search_provider.dart';
import 'package:inmufacil_frontend/presentation/providers/map_state_provider.dart';
import 'package:inmufacil_frontend/presentation/providers/hover_provider.dart';
import 'package:inmufacil_frontend/presentation/widgets/map/property_floating_card.dart';
import 'package:inmufacil_frontend/presentation/widgets/open_street_map_widget.dart';
import 'package:inmufacil_frontend/presentation/widgets/common/premium_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/offers_provider.dart';
import '../../providers/urgency_provider.dart';
import '../../widgets/common/user_avatar_menu.dart';
import '../../widgets/common/demo_banner.dart';
import '../../widgets/common/language_selector_widget.dart';
import '../info/info_screen.dart';

/// Home/Landing Screen with Google Maps Integration
/// 
/// Desktop: Split screen (Search Panel | Google Maps)
/// Mobile: Stack (Map background + Floating search card)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _locationInitialized = false;

  @override
  void dispose() {
    // Clear search error when leaving the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(searchProvider.notifier).clearError();
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize location after first build
    if (!_locationInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchProvider.notifier).initLocation();
      });
      _locationInitialized = true;
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
  // DEBUG: Check Layout Mode
          // print("LayoutBuilder constraints: ${constraints.maxWidth}");
          final isDesktop = constraints.maxWidth >= 768;
          // print("isDesktop: $isDesktop");
          
          return isDesktop
              ? _DesktopLayout()
              : _MobileLayout();
        },
      ),
    );
  }
}

// Desktop layout - Resizable Split screen (Starts at 50/50)
class _DesktopLayout extends StatefulWidget {
  @override
  State<_DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<_DesktopLayout> {
  double? _leftPanelWidth; // Null initially to trigger 50/50 logic
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Initialize to 50% if first build
        _leftPanelWidth ??= constraints.maxWidth * 0.5;
        
        return Stack(
          fit: StackFit.expand, // [FIX] Ensure Stack fills the screen
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch, // [FIX] Force children to fill vertical space
              children: [
                // Left: Search Panel (Resizable)
                SizedBox(
                  width: _leftPanelWidth,
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none, 
                    children: [
                      _SearchPanel(),
                    ],
                  ),
                ),
                
                // Resizer Handle
                MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        final newWidth = (_leftPanelWidth ?? 0) + details.delta.dx;
                        // Constraints: Min 300, Max 70% of screen
                        if (newWidth >= 350 && newWidth <= constraints.maxWidth * 0.7) {
                          _leftPanelWidth = newWidth;
                        }
                      });
                    },
                    child: Container(
                      width: 8,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.outline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Right: Map with overlays
                const Expanded(
                  child: _MapSection(),
                ),
              ],
            ),

            // GLOBAL FLOATING CARD OVERLAY
            Consumer(
              builder: (context, ref, _) {
                final hoveredProperty = ref.watch(hoveredPropertyProvider);
                final selectedProperty = ref.watch(selectedPropertyProvider);
                // Priority: Hover > Selected > Null
                final displayProperty = hoveredProperty ?? selectedProperty;
                
                if (displayProperty == null) return const SizedBox.shrink();

                // Position: Inside the left panel (Search Panel), aligned to its right edge
                // User Request: "quiero que salga en la parte subrayado de naranja"
                // Logic: Panel Width - Card Width (300) - Padding (32)
                final leftPos = (_leftPanelWidth ?? 0) - 300 - 32.0;

                return Positioned(
                  top: 120, // Adjusted to align with "Sin intermediarios" text area
                  left: leftPos, 
                  child: MouseRegion(
                    onEnter: (_) {
                       // Keep card alive when hovering IT (stop the hide timer from map marker exit)
                       ref.read(hoveredPropertyProvider.notifier).cancelHideTimer();
                    },
                    onExit: (_) {
                       // Allow card to hide if mouse leaves it (and doesn't go back to a marker)
                       ref.read(hoveredPropertyProvider.notifier).startHideTimer();
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: PropertyFloatingCard(
                        property: displayProperty,
                        width: 300,
                        onTap: () {
                          ref.read(searchProvider.notifier).clearError();
                          context.pushNamed(
                            'property-details', 
                            pathParameters: {'id': displayProperty.id},
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}



/// Mobile layout - Stack with floating search
class _MobileLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _MapSection(isMobile: true);
  }
}

/// Map section with overlays (navigation bar, stats card, search form)
class _MapSection extends ConsumerWidget {
  const _MapSection({this.isMobile = false});
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);
    final mapState = ref.watch(mapStateProvider);
    final theme = Theme.of(context);
    // Dynamic Filtering: Usage of new provider
    final filteredProperties = ref.watch(filteredByMapPropertiesProvider);
    final propertyCount = filteredProperties.length;
    
    // Show FAB only if there are Visible/Filtered results
    // AND we are not in initial inactive search state (optional, but requested logic is dynamic count)
    final showFab = propertyCount > 0;

    return Stack(
      fit: StackFit.expand, // [FIX] Ensure Map Section fills the Expanded/SizedBox parent
      children: [
        // Background: OpenStreetMap - MUST use Positioned.fill to fill entire Stack
        const Positioned.fill(
          child: OpenStreetMapWidget(),
        ),
        
        // Navigation bar + DemoBanner + (mobile) search trigger, all in one Column
        // so the search bar is always naturally below the banner with no hardcoded offset.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapNavigationBar(),
              const DemoBanner(),
              if (isMobile)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (ctx) => SizedBox(
                            height: MediaQuery.of(context).size.height * 0.92,
                            child: _SearchPanel(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Buscar por ciudad, zona...',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Icon(Icons.tune, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Conditional "Ver Inmuebles" Button
        if (showFab)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: _PremiumGlowButton(
                label: 'Ver $propertyCount Inmuebles',
                onPressed: () {
                  ref.read(searchProvider.notifier).clearError();
                  context.pushNamed('search', queryParameters: {'fromMap': 'true'});
                },
                color: theme.colorScheme.primary,
                icon: Icons.list,
                fullWidth: false,
              ),
            ),
          ),

        // [Removed] StatsCard per user request (Step 15713)
        // User wants "Clean Filters" button in the left panel instead.
        
        // UX REFINEMENT: Map Empty State Chip (Small, Pill-shaped)
        if (propertyCount == 0 && !searchState.isLoading)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     const Icon(Icons.info_outline, size: 18, color: Colors.red),
                     const SizedBox(width: 8),
                     Flexible(
                       child: Text(
                        '0 inmuebles encontrados',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Search panel with hero section and search form
class _SearchPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // [Fix] Defined for property count label usage below
    final filteredProperties = ref.watch(filteredByMapPropertiesProvider);
    final searchState = ref.watch(searchProvider);

    // Check filters for button visibility
    final bool hasFilters = searchState.propertyType != PropertyType.all ||
                            searchState.priceRange.start > 0 ||
                            searchState.priceRange.end < 1000000 || 
                            searchState.minBedrooms > 0 ||
                            searchState.selectedExtras.isNotEmpty;
    
    return Container(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              // [UX Refinement] Use Center + ShrinkWrap to avoid scrollbar when content fits screen
              child: Center(
                child: SingleChildScrollView(
                   padding: const EdgeInsets.all(32),
                   physics: const ClampingScrollPhysics(), // Prevent bounce on desktop
                   // shrinkWrap: true makes the scroll view only as tall as its children
                   // If content fits vertically, Center takes care of positioning.
                   // If content overflows, it scrolls normally.
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     mainAxisSize: MainAxisSize.min, // Important for Center
                     children: [
                        // [Header & Logo]
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/logo_inmufacil.png',
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            Text.rich(
                              TextSpan(
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                                children: [
                                  TextSpan(text: 'Inmu', style: TextStyle(color: theme.colorScheme.primary)),
                                  TextSpan(text: 'Fácil', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8), // Justo debajo del logo per user request
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: 'home.tagline_part1'.tr(), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
                              TextSpan(text: 'home.tagline_part2'.tr(), style: TextStyle(color: theme.colorScheme.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32), // Espacio con Sin intermediarios per user request
                        
                        // [HERO SECTION] - Specific Design Implementation (Step 16268)
                        // Title: "Sin intermediarios. 0% comisiones."
                         Text.rich(
                          TextSpan(
                            style: theme.textTheme.displaySmall?.copyWith( 
                              fontSize: 52, // Increased size per green highlighter feedback
                              fontWeight: FontWeight.w900, // font-black
                              height: 1.1, // leading-[1.1]
                              color: theme.colorScheme.onSurface, // Adapts to dark mode
                              letterSpacing: -1.0, // tracking-tight
                            ),
                            children: [
                              const TextSpan(text: 'Sin intermediarios.\n'),
                              TextSpan(
                                text: '0% comisiones.',
                                style: TextStyle(color: theme.colorScheme.primary), // text-primary #2563EB specified
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24), // mb-6 equivalent
                        
                        // Subtitle: "Compra y vende sin comisiones."
                        Text(
                          'Compra y vende sin comisiones.',
                          style: theme.textTheme.titleLarge?.copyWith( // ~ text-lg
                            fontWeight: FontWeight.bold, // font-bold
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        
                        const SizedBox(height: 16), // mb-4 equivalent
                        
                        // List of Checkmarks
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBenefitItem(context, 'De la búsqueda a la notaría en pasos seguros.'),
                            const SizedBox(height: 12), // space-y-3
                            _buildBenefitItem(context, 'Elimina la incertidumbre.'),
                          ],
                        ),
                        
                        const SizedBox(height: 24), // Spacing (Yellow): Normalized to 24px per user request
                        
                         // [Search Form]
                         _SearchForm(),
                         
                         const SizedBox(height: 32),

                         // [TRUST BADGES] Relocated below the form per user request v5
                         Center(
                           child: Wrap(
                             spacing: 48, // gap-12
                             runSpacing: 24,
                             alignment: WrapAlignment.center,
                             children: [
                               // Badge 1: Green Shield
                               _buildTrustBadgeItem(
                                 context,
                                 icon: Icons.shield,
                                 iconColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                                 bgColor: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)).withOpacity(0.12),
                                 label: 'GARANTÍA INMUFÁCIL',
                                 title: 'Tu venta tranquila',
                               ),

                               // Badge 2: Blue Lock
                               _buildTrustBadgeItem(
                                 context,
                                 icon: Icons.lock,
                                 iconColor: theme.colorScheme.primary,
                                 bgColor: theme.colorScheme.primary.withOpacity(0.12),
                                 label: 'P2P VERIFICADO',
                                 title: 'Tu compra segura',
                               ),
                             ],
                           ),
                         ),

                         
                         // [Lifestyle CTA] — "Descubre tu barrio ideal"
                         const SizedBox(height: 24),
                         SizedBox(
                           width: double.infinity,
                           child: OutlinedButton.icon(
                             onPressed: () => context.push('/lifestyle/questionnaire'),
                             icon: const Icon(Icons.explore_outlined, size: 20),
                             label: const Text(
                               'Descubre tu barrio ideal',
                               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                             ),
                             style: OutlinedButton.styleFrom(
                               foregroundColor: theme.colorScheme.primary,
                               side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                               padding: const EdgeInsets.symmetric(vertical: 16),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                           ),
                         ),

                         // [Clean Filters Button] Moved inside _SearchForm

                         // Removed excessive bottom padding/space as requested
                         const SizedBox(height: 16),
                     ],
                   ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }

  Widget _buildBenefitItem(BuildContext context, String text) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.primary, // Azul corporativo
          size: 20,
        ),
        const SizedBox(width: 12), // gap-3
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w500, // font-medium
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadgeItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String title,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40, // size-10
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24, // text-2xl
          ),
        ),
        const SizedBox(width: 12), // gap-3
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10, // text-[10px]
                fontWeight: FontWeight.w900, // font-black
                color: Theme.of(context).colorScheme.onSurfaceVariant, // text-slate-400
                letterSpacing: 1.5, // tracking-widest (approx)
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14, // text-sm
                fontWeight: FontWeight.bold, // font-bold
                color: Theme.of(context).colorScheme.onSurfaceVariant, // text-slate-700
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// RESTORED: Property Results View with UX Improvements
class _PropertyResultsView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);
    final theme = Theme.of(context);
    final filteredProperties = ref.watch(filteredByMapPropertiesProvider);

    if (searchState.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }

    // UX: Red Counter logic
    final isEmpty = filteredProperties.isEmpty;

    // UX REFINEMENT: Only show this view if EMPTY (hide list if results exist)
    if (!isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
           // Stack Implementation
             const Icon(Icons.info_outline, size: 48, color: Colors.red), // Request: "i de informacion en rojo papelera"
             const SizedBox(height: 16),
             Text(
               'home.no_results_found'.tr(),
               style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
             ),
             const SizedBox(height: 8),
             TextButton.icon(
                onPressed: () {
                   ref.read(searchProvider.notifier).resetFilters();
                },
                icon: const Icon(Icons.refresh),
                label: Text('home.clear_filters'.tr()),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
             ),
           ],
         ),
       );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
     final theme = Theme.of(context);
     return Center(
       child: Padding(
         padding: const EdgeInsets.symmetric(vertical: 40),
         child: Column(
           children: [
           // Stack Implementation
             const Icon(Icons.info_outline, size: 48, color: Colors.red), // Request: "i de informacion en rojo papelera"
             const SizedBox(height: 16),
             Text(
               'home.no_results_found'.tr(),
               style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
             ),
             const SizedBox(height: 8),
             TextButton.icon(
                onPressed: () {
                   ref.read(searchProvider.notifier).resetFilters();
                },
                icon: const Icon(Icons.refresh),
                label: Text('home.clear_filters'.tr()),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
             ),
           ],
         ),
       ),
     );
  }
}

/// Feature item with icon and text (with glow effect)
class _FeatureItem extends StatelessWidget {
  
  const _FeatureItem({
    required this.icon,
    required this.text,
  });
  final IconData icon;
  final String text;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Icon(
            Icons.check_circle,
            color: primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

/// Search form with filters
/// Search form with filters
class _SearchForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends ConsumerState<_SearchForm> {
  final TextEditingController _locationController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchProvider);
    
    // Sync controller with state location if needed (optional, depends on UX preference)
    // If we want the box to show 'Madrid' if state has 'Madrid'
    if (searchState.location.isNotEmpty && _locationController.text.isEmpty && !searchState.isLoading) {
       // Only sync if empty to avoid fighting user input
       // actually, let's just let the user drive the input.
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // [LAYOUT REFACTOR] Row for Type & Location (Step 16144)
          LayoutBuilder(
            builder: (context, constraints) {
              // On very narrow screens, stack them. On > 350px, use Row.
              final isNarrow = constraints.maxWidth < 350;
              
              if (isNarrow) {
                 return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeDropdown(context, ref, searchState),
                    const SizedBox(height: 16),
                    _buildLocationInput(context, ref, _locationController),
                  ],
                 );
              }
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Dropdown (Expanded)
                  Expanded(
                     flex: 4, // 40% width
                     child: _buildTypeDropdown(context, ref, searchState),
                  ),
                  
                  const SizedBox(width: 16), // Space between inputs
                  
                  // Location Input (Expanded)
                  Expanded(
                    flex: 6, // 60% width
                    child: _buildLocationInput(context, ref, _locationController),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Price range slider with dynamic max
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'home.price_range_label'.tr(),
                style: theme.textTheme.labelLarge,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => _showCustomPriceDialog(context, ref),
                tooltip: 'Precio máximo personalizado',
              ),
            ],
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: searchState.priceRange,
            min: 0,
            max: searchState.currentMaxPriceLimit,
            // No divisions - continuous slider for smooth visual feedback
            divisions: null,
            activeColor: theme.colorScheme.primary, // [BRAND COLOR] Updated
            labels: RangeLabels(
              _formatPrice(searchState.priceRange.start),
              _formatPrice(searchState.priceRange.end),
            ),
            onChanged: (range) {
               ref.read(searchProvider.notifier).updatePriceRange(
                RangeValues(range.start, range.end),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'home.price_from'.tr()}: ${_formatPrice(searchState.priceRange.start)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${'home.price_to'.tr()}: ${_formatPrice(searchState.priceRange.end)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          
          const SizedBox(height: 20),

          // ROOMS SELECTOR (Segmented buttons)
          Text(
            'Habitaciones',
             style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [1, 2, 3, 4, 5].map((count) {
              final String label = count == 5 ? '5+' : (count >= 3 ? '$count+' : '$count');
              final bool isSelected = searchState.minBedrooms == count;
              
              return InkWell(
                onTap: () => ref.read(searchProvider.notifier).updateMinBedrooms(isSelected ? 0 : count),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),

          // EXTRAS SECTION
          Text(
            'Extras',
             style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Terraza', 'Ascensor', 'Garaje', 'Piscina', 'Jardín',
              'Aire Acondicionado', 'Calefacción', 'Trastero', 
              'Armarios Empotrados', 'Exterior', 'Acceso movilidad reducida',
            ].map((extra) {
              final isSelected = searchState.selectedExtras.contains(extra);
              return FilterChip(
                label: Text(extra),
                selected: isSelected,
                onSelected: (_) {
                   ref.read(searchProvider.notifier).toggleExtra(extra);
                },
                selectedColor: theme.colorScheme.primary.withOpacity(0.1),
                checkmarkColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Search button
          _PremiumGlowButton(
            label: 'home.search_button'.tr(),
            onPressed: () {
              if (_locationController.text.isNotEmpty) {
                 ref.read(searchProvider.notifier).searchCity(_locationController.text);
              } else {
                 ref.read(searchProvider.notifier).search();
              }
            },
            color: theme.colorScheme.primary,
            icon: Icons.search, // Keep Lupita as requested
          ),

          // [Clean Filters Button] - MOVED INSIDE FORM CARD (User Request Step 15757)
          Consumer(
            builder: (context, ref, child) {
               final searchState = ref.watch(searchProvider);
               final bool hasFilters = searchState.propertyType != PropertyType.all ||
                                       searchState.priceRange.start > 0 ||
                                       searchState.priceRange.end < 1000000 || 
                                       searchState.minBedrooms > 0 ||
                                       searchState.selectedExtras.isNotEmpty;

               if (!hasFilters) return const SizedBox.shrink();

               return Padding(
                 padding: const EdgeInsets.only(top: 12),
                 child: _PremiumGlowButton(
                   label: 'Limpiar Filtros',
                   onPressed: () => ref.read(searchProvider.notifier).resetFilters(),
                   color: const Color(0xFFB91C1C), // Shadow will be red too
                   icon: Icons.refresh,
                 ),
               );
            },
          ),
          
          // Results count (Only show if NOT empty)
          // Dynamic Filtering: Use filteredByMapPropertiesProvider
          Consumer(
            builder: (context, ref, child) {
              final filteredProperties = ref.watch(filteredByMapPropertiesProvider);
              if (filteredProperties.isEmpty) return const SizedBox.shrink();
              
              return Column(
                children: [
                   const SizedBox(height: 16),
                   Center(
                    child: Text(
                      '${filteredProperties.length} ${'home.properties_today'.tr()}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          

          const SizedBox(height: 12),

        ],
      ),
    );
  }
  
  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '€${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '€${(price / 1000).toStringAsFixed(0)}K';
    }
    return '€${price.toStringAsFixed(0)}';
  }
  
  /// Show dialog for custom price limit
  void _showCustomPriceDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('home.custom_price_title'.tr()),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'home.custom_price_label'.tr(),
            hintText: '15000000',
            prefixText: '€',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Builder(builder: (context) => Text('common.cancel'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                ref.read(searchProvider.notifier).updateMaxPriceLimit(value);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('home.apply'.tr()),
          ),
        ],
      ),
    );
  }
  
  /// Snap price value to variable steps based on current value position
  /// Step size depends on WHERE the value is, not the max limit
  /// 0-300k: 1k steps, 300k-1M: 10k steps, 1M-10M: 50k steps, >10M: 100k steps
  double _snapToStep(double value) {
    if (value < 300000) {
      // De 0 a 300k -> Pasos de 1k
      return (value / 1000).round() * 1000;
    } else if (value < 1000000) {
      // De 300k a 1M -> Pasos de 10k
      return (value / 10000).round() * 10000;
    } else if (value < 10000000) {
      // De 1M a 10M -> Pasos de 50k
      return (value / 50000).round() * 50000;
    } else {
      // > 10M -> Pasos de 100k
      return (value / 100000).round() * 100000;
    }
  }

  // [HELPER METHODS] for Row Layout (Step 16144)
  
  Widget _buildTypeDropdown(BuildContext context, WidgetRef ref, SearchState searchState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de inmueble',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56, // Fixed height for symmetry
          child: DropdownButtonFormField<PropertyType>(
            initialValue: searchState.propertyType,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none, // Cleaner look
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            isExpanded: true, // Prevent overflow
            items: PropertyType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type.translationKey.tr(),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(searchProvider.notifier).updatePropertyType(value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(BuildContext context, String text) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12), // gap-3
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w500, // font-medium
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildLocationInput(BuildContext context, WidgetRef ref, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'home.search_location_label'.tr(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56, // Fixed height matching dropdown
          child: TextField(
            controller: controller,
            textAlignVertical: TextAlignVertical.center, // Center text vertically
            decoration: InputDecoration(
              hintText: 'home.location_placeholder'.tr(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
              prefixIcon: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onSubmitted: (value) {
              ref.read(searchProvider.notifier).searchCity(value);
            },
          ),
        ),
      ],
    );
  }

}

/// Trust badge widget
class _TrustBadge extends StatelessWidget {
  
  const _TrustBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine colors based on icon type - exact colors from reference
    final bool isShield = icon == Icons.verified || icon == Icons.shield;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color iconColor = isShield
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
        : Theme.of(context).colorScheme.primary;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Transparent background for dark mode compatibility
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        // Colored border matching the badge type
        border: Border.all(
          color: iconColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface, // Adapts to theme
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant, // Adapts to theme
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}



/// Navigation bar overlay for map section
class _MapNavigationBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    final receivedOffers = ref.watch(receivedOffersProvider).asData?.value;
    final sentOffers = ref.watch(sentOffersProvider).asData?.value;
    final hasOffers = isAuthenticated &&
        ((receivedOffers?.isNotEmpty ?? false) || (sentOffers?.isNotEmpty ?? false));
    
    void handleProtectedAction(String route) {
      ref.read(searchProvider.notifier).clearError();
      if (isAuthenticated) {
        context.push(route);
      } else {
        context.pushNamed('login'); // Better UX: Push instead of Go allows implicit back button
      }
    }

    final navTextStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          if (isNarrow) {
            // Mobile: compact nav with logo image + text + hamburger + avatar
            return Row(
              children: [
                Image.asset('assets/images/logo_inmufacil.png', height: 28),
                const SizedBox(width: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Inmu', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 18)),
                      TextSpan(text: 'Fácil', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A), fontWeight: FontWeight.w800, fontSize: 18)),
                    ],
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (key) {
                    ref.read(searchProvider.notifier).clearError();
                    switch (key) {
                      case 'buy':
                        final visible = ref.read(filteredByMapPropertiesProvider);
                        if (visible.isEmpty) ref.read(searchProvider.notifier).reset();
                        context.go('/search');
                      case 'sell':
                        if (isAuthenticated) {
                          context.push('/property/create');
                        } else {
                          context.pushNamed('login');
                        }
                      case 'how':
                        context.push('/info/how-it-works');
                      case 'what-is':
                        context.push(InfoScreen.routeFor(InfoPageType.whatIsInmufacil));
                      case 'buyer-guide':
                        context.push(InfoScreen.routeFor(InfoPageType.buyerGuide));
                      case 'seller-guide':
                        context.push(InfoScreen.routeFor(InfoPageType.sellerGuide));
                      case 'contact':
                        context.push(InfoScreen.routeFor(InfoPageType.contact));
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'buy', child: Row(children: [const Icon(Icons.search), const SizedBox(width: 8), const Text('Comprar')])),
                    PopupMenuItem(value: 'sell', child: Row(children: [const Icon(Icons.add_business_outlined), const SizedBox(width: 8), const Text('Vender')])),
                    PopupMenuItem(value: 'how', child: Row(children: [const Icon(Icons.help_outline), const SizedBox(width: 8), const Text('Cómo funciona')])),
                    PopupMenuItem(value: 'what-is', child: Row(children: [const Icon(Icons.info_outline), const SizedBox(width: 8), const Text('Qué es InmuFácil')])),
                    PopupMenuItem(value: 'buyer-guide', child: Row(children: [const Icon(Icons.shopping_bag_outlined), const SizedBox(width: 8), const Text('Guía del Comprador')])),
                    PopupMenuItem(value: 'seller-guide', child: Row(children: [const Icon(Icons.sell_outlined), const SizedBox(width: 8), const Text('Guía del Vendedor')])),
                    PopupMenuItem(value: 'contact', child: Row(children: [const Icon(Icons.support_agent_outlined), const SizedBox(width: 8), const Text('Contacto')])),
                  ],
                ),
                const LanguageSelectorWidget(compact: true),
                if (isAuthenticated) ...[
                  const UserAvatarMenu(),
                ] else
                  InkWell(
                    onTap: () {
                      ref.read(searchProvider.notifier).clearError();
                      context.pushNamed('login');
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant, size: 20),
                    ),
                  ),
              ],
            );
          }

          // Desktop: full nav
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // --- Info links ---
                  TextButton(
                    onPressed: () {
                      ref.read(searchProvider.notifier).clearError();
                      context.push('/info/how-it-works');
                    },
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cómo funciona',
                      style: navTextStyle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    offset: const Offset(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'what-is',
                        child: Text('Qué es InmuFácil',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontSize: 14)),
                      ),
                      PopupMenuItem(
                        value: 'buyer-guide',
                        child: Text('Guía del Comprador',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontSize: 14)),
                      ),
                      PopupMenuItem(
                        value: 'seller-guide',
                        child: Text('Guía del Vendedor',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontSize: 14)),
                      ),
                    ],
                    onSelected: (key) {
                      ref.read(searchProvider.notifier).clearError();
                      switch (key) {
                        case 'what-is':
                          context.push(InfoScreen.routeFor(InfoPageType.whatIsInmufacil));
                        case 'buyer-guide':
                          context.push(InfoScreen.routeFor(InfoPageType.buyerGuide));
                        case 'seller-guide':
                          context.push(InfoScreen.routeFor(InfoPageType.sellerGuide));
                      }
                    },
                    child: TextButton(
                      onPressed: null,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Guías',
                            style: navTextStyle,
                          ),
                          Icon(Icons.arrow_drop_down,
                              size: 18, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () {
                      ref.read(searchProvider.notifier).clearError();
                      context.push(InfoScreen.routeFor(InfoPageType.contact));
                    },
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Contacto',
                      style: navTextStyle,
                    ),
                  ),

                  // --- Separator ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      height: 20,
                      child: VerticalDivider(
                        color: theme.colorScheme.outlineVariant,
                        thickness: 1,
                        width: 1,
                      ),
                    ),
                  ),

                  // --- Action buttons ---
                  PremiumButton(
                    label: 'Comprar',
                    onPressed: () {
                      ref.read(searchProvider.notifier).clearError();
                      final visible = ref.read(filteredByMapPropertiesProvider);
                      if (visible.isEmpty) ref.read(searchProvider.notifier).reset();
                      context.go('/search');
                    },
                    color: theme.colorScheme.primary,
                    fontSize: 13,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    fullWidth: false,
                  ),
                  const SizedBox(width: 8),
                  PremiumButton(
                    label: 'Vender',
                    onPressed: () {
                      ref.read(searchProvider.notifier).clearError();
                      if (isAuthenticated) {
                        context.push('/property/create');
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            icon: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLowest,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.home_work_outlined, color: theme.colorScheme.primary, size: 28),
                            ),
                            title: const Text(
                              'Cuenta requerida',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            content: Builder(builder: (context) => Text(
                              'Para publicar y vender una propiedad necesitas una cuenta en InmuFácil. Es gratis y solo toma unos minutos.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                            )),
                            actionsAlignment: MainAxisAlignment.center,
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('common.cancel'.tr(), style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  context.pushNamed('login');
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('auth.login_button'.tr()),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    color: theme.colorScheme.primary,
                    fontSize: 13,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    fullWidth: false,
                  ),
                  const SizedBox(width: 12),
                  const LanguageSelectorWidget(compact: true),

                  // [AUTH STATE LOGIC]
                  if (isAuthenticated)
                    const UserAvatarMenu()
                  else
                    InkWell(
                      onTap: () {
                        ref.read(searchProvider.notifier).clearError();
                        context.pushNamed('login');
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: CircleAvatar(
                         radius: 18,
                         backgroundColor: theme.colorScheme.surfaceContainerHighest,
                         child: Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant, size: 20),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


/// Floating statistics card
class _StatsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // [Fix] Defined for property listing logic usage below (hasFilters)
    final searchState = ref.watch(searchProvider);
    // Dynamic Filtering: Usage of new provider
    final filteredProperties = ref.watch(filteredByMapPropertiesProvider);
    final count = filteredProperties.length;
    final bool isEmpty = count == 0;
    
    // COLORS: Red if empty, Blue if normal (per user request "rojo papelera")
    final Color primaryColor = isEmpty ? theme.colorScheme.error : theme.colorScheme.primary;
    final Color lightColor = isEmpty ? theme.colorScheme.error.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.1);
    final IconData icon = isEmpty ? Icons.info_outline : Icons.hub_outlined;

    // Check if any filters are active (besides location which is default)
    final bool hasFilters = searchState.propertyType != PropertyType.all ||
                            searchState.priceRange.start > 0 ||
                            searchState.priceRange.end < 1000000 || 
                            searchState.minBedrooms > 0 ||
                            searchState.selectedExtras.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Text and progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count', // Dynamic Count
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isEmpty ? theme.colorScheme.error : theme.colorScheme.primary, // Official Blue if not empty
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEmpty ? '0 PROPIEDADES' : 'PROPIEDADES HOY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary, // Always blue branding as requested
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isEmpty) ...[ // Only show verify stats if NOT empty
                  const SizedBox(height: 12),
                  // Progress bar
                  SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.68,
                            backgroundColor: theme.colorScheme.surfaceContainerLowest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Verificadas esta semana',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+84',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
              
              // USER REQUEST: Always show "Limpiar filtros" if active (or empty)
              if (isEmpty || hasFilters) ...[
                 const SizedBox(height: 8),
                 InkWell(
                   onTap: () {
                      ref.read(searchProvider.notifier).resetFilters();
                   },
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       const Icon(Icons.refresh, size: 14, color: Colors.red),
                       const SizedBox(width: 4),
                       Text(
                         'Limpiar filtros',
                         style: theme.textTheme.labelSmall?.copyWith(
                           color: Colors.red,
                           fontWeight: FontWeight.bold,
                           decoration: TextDecoration.underline,
                         ),
                       ),
                     ],
                   ),
                 ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Premium button with colored glow shadow (Visual Design V7)
class _PremiumGlowButton extends StatelessWidget {

  const _PremiumGlowButton({
    required this.label,
    required this.onPressed,
    required this.color,
    this.icon,
    this.fullWidth = true,
  });
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 18,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22),
              const SizedBox(width: 12),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Campana de notificaciones ─────────────────────────────────────────────────

/// Icono de campana con badge de no leidos.
/// Se muestra a la izquierda del UserAvatarMenu cuando el usuario esta autenticado.
class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return InkWell(
      onTap: () => context.push('/notifications'),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                Icons.notifications_none_rounded,
                size: 22,
                color: unreadCount > 0
                    ? const Color(kUrgencyGreen)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: const Color(kUrgencyGreen),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}




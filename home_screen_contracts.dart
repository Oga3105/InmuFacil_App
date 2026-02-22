import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:easy_localization/easy_localization.dart'; // TEMP DISABLED

import 'package:inmufacil_frontend/domain/entities/property_type.dart';
import 'package:inmufacil_frontend/presentation/providers/search_provider.dart';
import 'package:inmufacil_frontend/presentation/widgets/open_street_map_widget.dart';
import 'package:inmufacil_frontend/core/utils/temp_translations.dart'; // TEMP REPLACEMENT

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
          final isDesktop = constraints.maxWidth >= 768;
          
          return isDesktop
              ? _DesktopLayout()
              : _MobileLayout();
        },
      ),
    );
  }
}

/// Desktop layout - Split screen 50/50
class _DesktopLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: Search Panel
        Expanded(
          child: _SearchPanel(),
        ),
        
        // Right: Map with overlays (navigation bar + stats card)
        Expanded(
          child: _MapSection(),
        ),
      ],
    );
  }
}

/// Mobile layout - Stack with floating search
class _MobileLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _MapSection();
  }
}

/// Map section with overlays (navigation bar, stats card, search form)
class _MapSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background: OpenStreetMap - MUST use Positioned.fill to fill entire Stack
        const Positioned.fill(
          child: OpenStreetMapWidget(),
        ),
        
        // Navigation bar at top (fixed to top edge, not floating)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _MapNavigationBar(),
        ),
      ],
    );
  }
}

/// Search panel with hero section and search form
class _SearchPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'app.name'.tr(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Tagline Bicolor con i18n
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "home.tagline_part1".tr(), // "Inmueble fácil "
                      style: TextStyle(
                        color: Colors.grey[600], // Gris suave
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: "home.tagline_part2".tr(), // "entre particulares"
                      style: const TextStyle(
                        color: Color(0xFF2563EB), // Azul Corporativo exacto
                        fontSize: 14,
                        fontWeight: FontWeight.bold, // Negrita para énfasis
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Hero badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'home.hero_badge'.tr(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Hero title
              Text(
                'home.hero_title_line1'.tr(),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              Text(
                'home.hero_title_line2'.tr(),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  height: 1.1,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Hero subtitle
              Text(
                'home.hero_subtitle'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Features
              _FeatureItem(
                icon: Icons.verified_user,
                text: 'home.hero_feature_1'.tr(),
              ),
              const SizedBox(height: 12),
              _FeatureItem(
                icon: Icons.shield,
                text: 'home.hero_feature_2'.tr(),
              ),
              
              const SizedBox(height: 48),
              
              // Search form
              _SearchForm(),
              
              const SizedBox(height: 32),
              
              // Trust badges
              Row(
                children: [
                  Expanded(
                    child: _TrustBadge(
                      icon: Icons.verified,
                      title: 'home.guarantee_title'.tr(),
                      subtitle: 'home.guarantee_subtitle'.tr(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TrustBadge(
                      icon: Icons.security,
                      title: 'home.verified_title'.tr(),
                      subtitle: 'home.verified_subtitle'.tr(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Feature item with icon and text (with glow effect)
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  
  const _FeatureItem({
    required this.icon,
    required this.text,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF2563EB); // Exact blue from reference
    
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
class _SearchForm extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchProvider);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property type dropdown
          Text(
            'home.search_what_label'.tr(),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<PropertyType>(
            value: searchState.propertyType,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: PropertyType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.translationKey.tr()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(searchProvider.notifier).updatePropertyType(value);
              }
            },
          ),
          
          const SizedBox(height: 20),
          
          // Location input (Kept functional as requested in previous turn)
          Text(
            'home.search_location_label'.tr(),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'home.location_placeholder'.tr(),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.location_on),
            ),
            onSubmitted: (value) {
              // Trigger geocoding search when user presses Enter
              ref.read(searchProvider.notifier).searchCity(value);
            },
          ),
          
          const SizedBox(height: 20),
          
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
            activeColor: theme.colorScheme.primary,
            labels: RangeLabels(
              _formatPrice(searchState.priceRange.start),
              _formatPrice(searchState.priceRange.end),
            ),
            onChanged: (range) {
              // DEMO: Redirect to 404 for price change
              // Note: This makes slider unusable for demo purposes, 
              // ideally we'd keep it functional or use onChangeEnd
              // but user asked for "buttons that lead nowhere" to go to 404.
              // Letting slider move but redirecting on end might be better UX, 
              // but following strict instruction for 'interactions'.
              // For slider, actually let's keep it functional for UI feedback
              // and redirect on Search button instead.
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
          
          const SizedBox(height: 24),
          
          // Search button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                ref.read(searchProvider.notifier).search();
              },
              icon: const Icon(Icons.search),
              label: Text('home.search_button'.tr()),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          
          // Results count (dynamic)
          const SizedBox(height: 16),
          Center(
            child: Text(
              searchState.filteredProperties.isEmpty
                  ? '0 propiedades disponibles'
                  : '${searchState.filteredProperties.length} ${'home.properties_today'.tr()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: searchState.filteredProperties.isEmpty
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
        title: const Text('Precio máximo personalizado'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Precio máximo (€)',
            hintText: '15000000',
            prefixText: '€',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                ref.read(searchProvider.notifier).updateMaxPriceLimit(value);
                Navigator.pop(context);
              }
            },
            child: const Text('Aplicar'),
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
}

/// Trust badge widget
class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  
  const _TrustBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine colors based on icon type - exact colors from reference
    final bool isShield = icon == Icons.verified || icon == Icons.shield;
    final Color iconColor = isShield 
        ? const Color(0xFF16A34A) // Green for shield/verified
        : const Color(0xFF2563EB); // Blue for security/lock
    
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
class _MapNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Match left panel background
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Flexible spacer to prevent overflow
          const Spacer(),
          
          TextButton(
            onPressed: () => context.push('/404-buy'),
            child: Text(
              'Comprar',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => context.push('/404-sell'),
            child: Text(
              'Vender',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => context.push('/404-how-it-works'),
            child: Text(
              'Cómo funciona',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => context.push('/404-publish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Publicar propiedad',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => context.push('/404-profile'),
            borderRadius: BorderRadius.circular(16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Icon(
                Icons.person,
                color: Colors.grey[700],
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// Floating statistics card
class _StatsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchProvider);
    final propertyCount = searchState.filteredProperties.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: const Color(0xFF2563EB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hub_outlined,
              color: Color(0xFF2563EB),
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
                '1,240+',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PROPIEDADES HOY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2563EB),
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
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+84',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF16A34A),
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
          ),
        ],
      ),
    );
  }
}

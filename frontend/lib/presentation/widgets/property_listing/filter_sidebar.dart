import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/search_provider.dart';
import '../../../domain/entities/property_type.dart';
import 'package:easy_localization/easy_localization.dart';
import '../common/premium_button.dart'; // Corrected Import

class FilterSidebar extends ConsumerStatefulWidget {
  const FilterSidebar({super.key});

  @override
  ConsumerState<FilterSidebar> createState() => _FilterSidebarState();
}

class _FilterSidebarState extends ConsumerState<FilterSidebar> {
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Sync initial location if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchState = ref.read(searchProvider);
      if (searchState.location.isNotEmpty) {
        _locationController.text = searchState.location;
      }
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the text field in sync when a geocoding result updates state.location
    // (e.g. after a successful search the provider normalises the location name).
    ref.listen<SearchState>(searchProvider, (prev, next) {
      if (prev?.location != next.location && next.location.isNotEmpty) {
        if (_locationController.text != next.location) {
          _locationController.text = next.location;
        }
      }
    });

    final searchState = ref.watch(searchProvider);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    const primaryBlue = Color(0xFF135BEC); // User Brand Blue

    return Container(
      width: 300,
      padding: const EdgeInsets.only(right: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Box
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtros',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      // "Limpiar" removed per user request
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Location Search
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Ciudad, zona...',
                      hintStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                      prefixIcon: const Icon(Icons.location_on, size: 18, color: primaryBlue),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primaryBlue),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        ref.read(searchProvider.notifier).searchCityNow(value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: PremiumButton(
                      label: 'Buscar propiedades',
                      icon: Icons.search,
                      color: primaryBlue,
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      onPressed: () {
                        if (_locationController.text.isNotEmpty) {
                          ref.read(searchProvider.notifier).searchCityNow(_locationController.text);
                        } else {
                          ref.read(searchProvider.notifier).search();
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                
                // Price Range
                _buildSectionTitle('Rango de Precio'),
                const SizedBox(height: 8),
                // Display current range values
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '€${_formatPrice(searchState.priceRange.start)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurface),
                    ),
                    Text(
                      '€${_formatPrice(searchState.priceRange.end)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // RangeSlider
                RangeSlider(
                  values: searchState.priceRange,
                  min: 0,
                  max: searchState.currentMaxPriceLimit,
                  divisions: 100,
                  activeColor: primaryBlue,
                  labels: RangeLabels(
                    '€${_formatPrice(searchState.priceRange.start)}',
                    '€${_formatPrice(searchState.priceRange.end)}',
                  ),
                  onChanged: (RangeValues values) {
                    ref.read(searchProvider.notifier).updatePriceRange(values);
                  },
                ),

                const SizedBox(height: 24),

                // Rooms (matching Home screen)
                _buildSectionTitle('Habitaciones'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: DropdownButton<int>(
                    value: searchState.minBedrooms > 0 ? searchState.minBedrooms : null,
                    hint: Text('home.bedrooms_filter_label'.tr(), style: const TextStyle(fontSize: 13)),
                    underline: Container(),
                    icon: const Icon(Icons.arrow_drop_down),
                    isExpanded: true,
                    items: [1, 2, 3, 4, 5].map((e) {
                      final label = (e >= 3) ? '$e+ Hab.' : '$e Hab.';
                      return DropdownMenuItem(
                        value: e,
                        child: Text(label, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(searchProvider.notifier).updateMinBedrooms(val);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Property Type (matching Home screen)
                _buildSectionTitle('Tipo de inmueble'),
                const SizedBox(height: 8),
                DropdownButtonFormField<PropertyType>(
                  initialValue: searchState.propertyType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                  items: PropertyType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.translationKey.tr(),
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(searchProvider.notifier).updatePropertyType(value);
                    }
                  },
                ),

                const SizedBox(height: 24),

                // Extras (matching Home screen)
                _buildSectionTitle('Extras'),
                const SizedBox(height: 8),
                _buildCheckbox(context, ref, 'Piscina', searchState.selectedExtras.contains('Piscina')),
                _buildCheckbox(context, ref, 'Garaje', searchState.selectedExtras.contains('Garaje')),
                _buildCheckbox(context, ref, 'Terraza', searchState.selectedExtras.contains('Terraza')),
                _buildCheckbox(context, ref, 'Jardín', searchState.selectedExtras.contains('Jardín')),
                _buildCheckbox(context, ref, 'Ascensor', searchState.selectedExtras.contains('Ascensor')),
                _buildCheckbox(context, ref, 'Aire Acondicionado', searchState.selectedExtras.contains('Aire Acondicionado')),
                _buildCheckbox(context, ref, 'Calefacción', searchState.selectedExtras.contains('Calefacción')),
                _buildCheckbox(context, ref, 'Trastero', searchState.selectedExtras.contains('Trastero')),
                _buildCheckbox(context, ref, 'Armarios Empotrados', searchState.selectedExtras.contains('Armarios Empotrados')),
                _buildCheckbox(context, ref, 'Exterior', searchState.selectedExtras.contains('Exterior')),
                _buildCheckbox(context, ref, 'Acceso movilidad reducida', searchState.selectedExtras.contains('Acceso movilidad reducida')),

                // Conditional "Limpiar Filtros" Button (Red)
                if (searchState.propertyType != PropertyType.all ||
                    searchState.priceRange.start > 0 ||
                    searchState.priceRange.end < 1000000 || 
                    searchState.minBedrooms > 0 ||
                    searchState.selectedExtras.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      PremiumButton(
                        label: 'Limpiar filtros',
                        icon: Icons.refresh,
                        color: const Color(0xFFB91C1C), // Red
                        fontSize: 14,
                        onPressed: () => ref.read(searchProvider.notifier).resetFilters(),
                      ),
                ],

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Lifestyle Filter Section
                _buildSectionTitle('lifestyle.lifestyle_filter_title'.tr()),
                const SizedBox(height: 8),
                Text(
                  'lifestyle.lifestyle_filter_description'.tr(),
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.psychology_outlined, color: Color(0xFF135BEC), size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'lifestyle.lifestyle_filter_title'.tr(),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF135BEC)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      alignment: Alignment.centerRight,
                      child: Switch(
                        value: searchState.useLifestyleFilter,
                        onChanged: (_) => ref.read(searchProvider.notifier).toggleLifestyleFilter(),
                        activeThumbColor: const Color(0xFF135BEC),
                        activeTrackColor: const Color(0xFF135BEC).withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => context.push('/lifestyle/questionnaire'),
                  child: const Text(
                    'Editar mi perfil de estilo de vida →',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF135BEC),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Verified Toggle
                Row(
                  children: [
                    const Icon(Icons.verified_user, color: Color(0xFF16A34A), size: 20),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Verificado InmuFácil',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      alignment: Alignment.centerRight,
                      child: Switch(
                        value: searchState.onlyVerified,
                        onChanged: (val) => ref.read(searchProvider.notifier).toggleOnlyVerified(),
                        activeThumbColor: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Promo Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.inverseSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vende directo.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sin comisiones, sin intermediarios. Todo legal, todo seguro.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => context.push('/info/how-it-works'),
                  child: const Row(
                    children: [
                      Text(
                        'Saber más',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 14, color: primaryBlue),
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

  Widget _buildSectionTitle(String title) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInput(String placeholder) {
    return TextField(
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF135BEC)),
        ),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildRoomButton(BuildContext context, WidgetRef ref, String label, int value, bool isSelected) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => ref.read(searchProvider.notifier).updateMinBedrooms(value),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF135BEC) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF135BEC) : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context, WidgetRef ref, String label, bool isChecked, {bool isDeadLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: isChecked,
              onChanged: isDeadLink 
                ? (val) => context.push('/404') 
                : (val) => ref.read(searchProvider.notifier).toggleExtra(label),
              activeColor: const Color(0xFF135BEC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }
}

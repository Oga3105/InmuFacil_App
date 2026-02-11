import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/search_provider.dart';
import '../../../domain/entities/property_type.dart';
import '../../../core/utils/temp_translations.dart';

class FilterSidebar extends ConsumerWidget {
  const FilterSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);
    const navyColor = Color(0xFF0F172A);
    const primaryBlue = Color(0xFF2563EB); // User Brand Blue

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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: navyColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/404'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: primaryBlue,
                      ),
                      child: const Text('Limpiar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
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
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: navyColor),
                    ),
                    Text(
                      '€${_formatPrice(searchState.priceRange.end)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: navyColor),
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

                // Rooms
                _buildSectionTitle('Habitaciones'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRoomButton(context, ref, '1', 1, searchState.minBedrooms == 1),
                    const SizedBox(width: 8),
                    _buildRoomButton(context, ref, '2', 2, searchState.minBedrooms == 2),
                    const SizedBox(width: 8),
                    _buildRoomButton(context, ref, '3+', 3, searchState.minBedrooms == 3),
                    const SizedBox(width: 8),
                    _buildRoomButton(context, ref, '4+', 4, searchState.minBedrooms == 4),
                  ],
                ),

                const SizedBox(height: 24),

                // Property Type (matching Home screen)
                _buildSectionTitle('¿Qué buscas?'),
                const SizedBox(height: 8),
                DropdownButtonFormField<PropertyType>(
                  value: searchState.propertyType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade200),
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

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Verified Toggle
                Row(
                  children: [
                    const Icon(Icons.verified_user, color: Color(0xFF16A34A), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Verificado InmuFácil',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                    const Spacer(),
                    Switch(
                      value: false, 
                      onChanged: (val) => context.push('/404'),
                      activeColor: const Color(0xFF16A34A),
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
              color: navyColor,
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
                  onTap: () => context.push('/404'),
                  child: Row(
                    children: [
                      Text(
                        'Saber más',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                       Icon(Icons.arrow_forward, size: 14, color: primaryBlue),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
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
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildRoomButton(BuildContext context, WidgetRef ref, String label, int value, bool isSelected) {
    return InkWell(
      onTap: () => ref.read(searchProvider.notifier).updateMinBedrooms(value),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
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
              activeColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
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

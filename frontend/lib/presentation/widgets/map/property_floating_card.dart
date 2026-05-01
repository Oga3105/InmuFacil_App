import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmufacil_frontend/domain/entities/property.dart';
import 'package:inmufacil_frontend/presentation/providers/favorites_provider.dart';
import '../common/price_tag.dart';

class PropertyFloatingCard extends ConsumerWidget {

  const PropertyFloatingCard({
    super.key,
    required this.property,
    required this.onTap,
    this.width,
    this.height,
    this.ownerMode = false,
  });
  final Property property;
  final VoidCallback onTap;

  final double? width;
  final double? height;
  final bool ownerMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider).contains(property.id);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image Section
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  property.imageUrl != null ? property.imageUrl! : 'https://via.placeholder.com/280x176',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.image_not_supported, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              // Verified Tag
              if (property.isVerified)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.verified, color: Color(0xFF16A34A), size: 16),
                  ),
                ),
              // Status badge (owner mode only)
              if (ownerMode && property.status != null)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: _buildStatusBadge(context, property.status!),
                ),
              // Favorite Button
              Positioned(
                top: 12,
                right: 12,
                child: InkWell(
                  onTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(property.id),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: isFavorite ? Colors.red : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PriceTag(
                  price: property.price,
                  previousPrice: property.previousPrice,
                  large: true,
                ),
                const SizedBox(height: 2),
                Text(
                  property.title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                Builder(
                  builder: (context) {
                    final List<Widget> items = [
                      _buildFeature(context, Icons.bed, '${property.bedrooms} Hab'),
                      _buildFeature(context, Icons.bathroom_outlined, '${property.bathrooms} Baño'),
                      _buildFeature(context, Icons.square_foot, '${property.squareMeters}m²'),
                      if (property.floor != null)
                        _buildFeature(context, Icons.layers, '${property.floor}'),
                    ];

                    List<Widget> rows = [];
                    for (int i = 0; i < items.length; i += 2) {
                      rows.add(
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(child: items[i]),
                              const SizedBox(width: 8),
                              if (i + 1 < items.length)
                                Expanded(child: items[i + 1])
                              else
                                const Spacer(),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(children: rows);
                  },
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('property.view_detail'.tr(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    final IconData icon;
    final String label;

    switch (status) {
      case 'published':
        bg = colorScheme.secondaryContainer;
        fg = colorScheme.onSecondaryContainer;
        icon = Icons.check_circle_outline;
        label = 'Publicado';
        break;
      case 'draft':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        icon = Icons.edit_note;
        label = 'Borrador';
        break;
      default:
        bg = colorScheme.surfaceContainerHighest;
        fg = colorScheme.onSurfaceVariant;
        icon = Icons.visibility_off_outlined;
        label = 'No publicado';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFeature(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

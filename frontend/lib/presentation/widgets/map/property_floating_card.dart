import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmufacil_frontend/domain/entities/property.dart';
// For .tr() if needed
import 'package:inmufacil_frontend/presentation/providers/favorites_provider.dart';

class PropertyFloatingCard extends ConsumerWidget {

  const PropertyFloatingCard({
    super.key,
    required this.property,
    required this.onTap,
    this.width,
    this.height,
  });
  final Property property;
  final VoidCallback onTap;

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Favorites Logic
    final isFavorite = ref.watch(favoritesProvider).contains(property.id);
    
    // Design Reference: card_details_property.html
    // Font: Public Sans (using system default or theme)
    // Colors: Primary #2563EB, Success #16A34A, Text Slate-800
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // rounded-card
        boxShadow: [
          BoxShadow( // shadow-soft
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image Section
          Stack(
            children: [
              Container(
                height: 160, // Reduced from 176 to fit 400px grid
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  property.imageUrl != null ? property.imageUrl! : 'https://via.placeholder.com/280x176',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
              // Destacado Tag
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB), // primary
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                       BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
                    ],
                  ),
                  child: const Text(
                    'DESTACADO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              // Verified Tag
              if (property.isVerified)
                Positioned(
                  top: 12,
                  left: 95, // Positioned after DESTACADO
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                         BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.verified, color: Color(0xFF16A34A), size: 16),
                  ),
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
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: isFavorite ? Colors.red : Colors.black45, // text-slate-400
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
                // Price & Title
                Text(
                  property.formattedPrice,
                  style: const TextStyle(
                    color: Color(0xFF2563EB), // primary
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  property.title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B), // text-slate-800
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Features Layout
                Builder(
                  builder: (context) {
                    final List<Widget> items = [
                      _buildFeature(Icons.bed, '${property.bedrooms} Hab'),
                      _buildFeature(Icons.bathroom_outlined, '${property.bathrooms} Baño'),
                      _buildFeature(Icons.square_foot, '${property.squareMeters}m²'),
                      if (property.floor != null)
                        _buildFeature(Icons.layers, '${property.floor}'),
                    ];

                    // Chunk items into pairs for 2-column layout
                      List<Widget> rows = [];
                      for (int i = 0; i < items.length; i += 2) {
                        rows.add(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(child: items[i]), // First item takes 50%
                                const SizedBox(width: 8), 
                                if (i + 1 < items.length)
                                  Expanded(child: items[i + 1]) // Second item takes 50%
                                else
                                  const Spacer(), // Empty space if odd number, keeping first item at 50%
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: rows,
                      );
                  },
                ),
                
                const SizedBox(height: 16), // Reduced from 24
                
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A), // success
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ver detalle',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black26), // text-slate-400
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569), // text-slate-600
          ),
        ),
      ],
    );
  }
}

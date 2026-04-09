import 'package:flutter/material.dart';
import '../../../../domain/entities/property.dart';
import '../common/demo_banner.dart';

class PropertyCard extends StatelessWidget {

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
  });
  final Property property;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (property.imageUrl != null)
                    Image.network(
                      property.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),
                    
                  // Demo Badge (Top Left)
                  const Positioned(
                    top: 12,
                    left: 12,
                    child: DemoBadge(),
                  ),

                  // Price Badge (Top Right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                      ),
                      child: Text(
                        property.formattedPrice,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Details Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Address
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Features Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFeature(Icons.bed, '${property.bedrooms} Hab.'),
                      _buildFeature(Icons.bathtub_outlined, '${property.bathrooms} Baños'),
                      _buildFeature(Icons.square_foot, '${property.squareMeters.toStringAsFixed(0)} m²'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          color: colorScheme.surfaceContainerHighest,
          child: Center(
            child: Icon(Icons.image_not_supported, size: 48, color: colorScheme.onSurfaceVariant),
          ),
        );
      },
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(text, style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
          ],
        );
      },
    );
  }
}

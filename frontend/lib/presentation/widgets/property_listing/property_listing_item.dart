import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inmufacil_frontend/presentation/providers/favorites_provider.dart';
import '../../../../domain/entities/property.dart';
import '../common/premium_button.dart';
import '../common/time_badge.dart';

class PropertyListingItem extends ConsumerWidget {
  final Property property;

  const PropertyListingItem({super.key, required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Favorites Logic
    final isFavorite = ref.watch(favoritesProvider).contains(property.id);
    // Brand Colors
    const brandBlue = Color(0xFF2563EB); // Corporate blue specified
    const navyColor = Color(0xFF0F172A); // Keep dark for text contrast
    const successGreen = Color(0xFF16A34A);

    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed('property-details', pathParameters: {'id': property.id}),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section (Left - 300px fixed)
              SizedBox(
                width: 300,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      property.imageUrl ?? 'https://placehold.co/600x400/png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    ),
                    if (property.price > 500000)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'TOP CHOICE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: navyColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey.shade400,
                          ),
                          onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(property.id),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          iconSize: 20,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                       child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.camera_alt, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              '1', // Single image for now based on Entity
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section (Right)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Title & Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: navyColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  property.address,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormat.format(property.price),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: navyColor,
                                ),
                              ),
                              Text(
                                '${(property.price / (property.squareMeters > 0 ? property.squareMeters : 1)).toStringAsFixed(0)} €/m²',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                       // Stats Row
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(color: Colors.grey.shade100),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildStat(Icons.bed, '${property.bedrooms} Hab.', navyColor),
                            const SizedBox(width: 24),
                            _buildStat(Icons.bathtub_outlined, '${property.bathrooms} Baños', navyColor),
                            const SizedBox(width: 24),
                            _buildStat(Icons.square_foot, '${property.squareMeters} m²', navyColor),
                            if (property.floor != null) ...[
                              const SizedBox(width: 24),
                              _buildStat(Icons.apartment, '${property.floor}', navyColor),
                            ],
                          ],
                        ),
                      ),

                      // Description Snippet (Mocked as entity lacks description)
                      const SizedBox(height: 16),
                      Text(
                        'Magnífica oportunidad en ${property.address}. Vivienda luminosa con excelentes calidades, lista para entrar a vivir. Zona consolidada con todos los servicios.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Time Badge
                      const SizedBox(height: 12),
                      PropertyTimeBadge(
                        createdAt: property.createdAt,
                        updatedAt: property.updatedAt,
                      ),

                      const Spacer(),

                      // Footer: Tags & CTA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Verified Tag
                          if (property.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: successGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: successGreen.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified, size: 16, color: successGreen),
                                  const SizedBox(width: 6),
                                  Text(
                                    'VENDEDOR VERIFICADO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: successGreen.withOpacity(0.9),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const SizedBox.shrink(),

                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share_outlined),
                                color: Colors.grey.shade400,
                                onPressed: () {},
                                tooltip: 'Compartir',
                              ),
                              const SizedBox(width: 8),
                              const SizedBox(width: 8),
                              PremiumButton(
                                label: 'Contactar Particular',
                                icon: Icons.chat_bubble_outline,
                                color: brandBlue,
                                fullWidth: false,
                                fontSize: 13,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                onPressed: () {},
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}


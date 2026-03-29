import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inmufacil_frontend/presentation/providers/favorites_provider.dart';
import '../../../../domain/entities/property.dart';
import '../common/premium_button.dart';
import '../common/time_badge.dart';
import '../../providers/auth_provider.dart';

class PropertyListingItem extends ConsumerWidget {

  const PropertyListingItem({super.key, required this.property});
  final Property property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFavorite = ref.watch(favoritesProvider).contains(property.id);
    const brandBlue = Color(0xFF135BEC);
    const successGreen = Color(0xFF16A34A);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 0);

    Widget buildImageStack() => Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          property.imageUrl ?? 'https://placehold.co/600x400/png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: theme.colorScheme.surfaceContainerHigh,
              child: Icon(Icons.broken_image, color: theme.colorScheme.onSurfaceVariant),
            );
          },
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
        if (property.images.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${property.images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    Widget buildContentSection({required bool isMobile}) {
      return Padding(
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _obfuscateAddress(property.address),
                        style: TextStyle(
                          fontSize: 13,
                          color: onSurfaceVariant,
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
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w900,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Stats Row (uses Wrap to avoid overflow on mobile)
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildStat(Icons.bed, '${property.bedrooms} Hab.', onSurface, onSurfaceVariant),
                  _buildStat(Icons.bathtub_outlined, '${property.bathrooms} Baños', onSurface, onSurfaceVariant),
                  _buildStat(Icons.square_foot, '${property.squareMeters} m²', onSurface, onSurfaceVariant),
                  if (property.floor != null)
                    _buildStat(Icons.apartment, '${property.floor}', onSurface, onSurfaceVariant),
                ],
              ),
            ),

            // Description Snippet
            const SizedBox(height: 16),
            if (property.description.isNotEmpty)
              Text(
                property.description,
                style: TextStyle(
                  fontSize: 13,
                  color: onSurfaceVariant,
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

            // Spacer only works in desktop (bounded via IntrinsicHeight)
            if (!isMobile) const Spacer(),
            if (isMobile) const SizedBox(height: 16),

            // Footer: Tags & CTA
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (property.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: successGreen.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 16, color: successGreen),
                        SizedBox(width: 6),
                        Text(
                          'VENDEDOR VERIFICADO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: successGreen,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      color: onSurfaceVariant,
                      onPressed: () {},
                      tooltip: 'Compartir',
                    ),
                    const SizedBox(width: 8),
                    PremiumButton(
                      label: 'Contactar Particular',
                      icon: Icons.chat_bubble_outline,
                      color: brandBlue,
                      fullWidth: false,
                      fontSize: 13,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      onPressed: () => _handleContactAction(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
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
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isMobile = constraints.maxWidth < 560;
            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 200,
                    child: buildImageStack(),
                  ),
                  buildContentSection(isMobile: true),
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 300,
                    child: buildImageStack(),
                  ),
                  Expanded(
                    child: buildContentSection(isMobile: false),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _obfuscateAddress(String address) {
    if (RegExp(r'^-?\d+\.\d+,\s*-?\d+\.\d+$').hasMatch(address.trim())) {
      return 'Ubicación protegida';
    }
    final parts = address.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return parts.sublist(1).join(', ');
    }
    return address;
  }

  Widget _buildStat(IconData icon, String label, Color textColor, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  void _showRequirementsDialog(BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required String cta,
    required VoidCallback onCta,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF135BEC), size: 28),
        ),
        title: Text(title, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Text(message, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            onPressed: onCta,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF135BEC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(cta),
          ),
        ],
      ),
    );
  }

  void _handleContactAction(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider);
    final isLoggedIn = auth.isAuthenticated;
    if (!isLoggedIn) {
      _showRequirementsDialog(
        context,
        title: 'Cuenta requerida',
        message: 'Debes estar registrado para contactar con el propietario de esta propiedad.',
        icon: Icons.person_outline,
        cta: 'Iniciar sesión',
        onCta: () { Navigator.of(context).pop(); context.pushNamed('login'); },
      );
      return;
    }
    final dniStatus = (auth.user?.dniStatus ?? '').toUpperCase();
    final isVerified = dniStatus == 'VALIDADO';
    if (!isVerified) {
      _showRequirementsDialog(
        context,
        title: 'Verificación requerida',
        message: 'Solo los usuarios con identidad verificada pueden contactar con particulares. Completa tu verificación KYC para continuar.',
        icon: Icons.verified_user_outlined,
        cta: 'Verificar identidad',
        onCta: () { Navigator.of(context).pop(); context.push('/verify-identity'); },
      );
      return;
    }
    // Proceed with contact action (e.g. open chat)
    // context.push('/chat/${property.ownerId}');
  }
}

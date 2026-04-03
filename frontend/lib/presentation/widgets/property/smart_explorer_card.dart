import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/favorites_provider.dart';

class SmartExplorerCard extends ConsumerWidget {
  const SmartExplorerCard({
    super.key,
    required this.propertyId,
    required this.title,
    required this.address,
    required this.priceEur,
    required this.surfaceM2,
    this.bedrooms,
    this.bathrooms,
    this.description,
    this.imageUrl,
    this.imageCount,
    this.isVerified = false,
    this.postalCode,
    this.onTap,
    this.onContactTap,
  });

  final String propertyId;
  final String title;
  final String address;
  final int priceEur;
  final double surfaceM2;
  final int? bedrooms;
  final int? bathrooms;
  final String? description;
  final String? imageUrl;
  final int? imageCount;
  final bool isVerified;
  final String? postalCode;
  final VoidCallback? onTap;
  final VoidCallback? onContactTap;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider).contains(propertyId);
    const successGreen = Color(0xFF16A34A);
    const brandBlue = Color(0xFF135BEC);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _PlaceholderImage(),
                        )
                      : const _PlaceholderImage(),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _OverlayButton(
                        icon: Icons.share_outlined,
                        color: colorScheme.onSurfaceVariant,
                        onPressed: () {},
                      ),
                      const SizedBox(width: 6),
                      _OverlayButton(
                        icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : colorScheme.onSurfaceVariant,
                        onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(propertyId),
                      ),
                    ],
                  ),
                ),
                if (imageCount != null && imageCount! > 0)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '$imageCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isVerified) ...[
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withOpacity(0.92),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                          ),
                          child: const Icon(Icons.verified, size: 14, color: successGreen),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withOpacity(0.92),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.chat_bubble_outline, color: colorScheme.primary),
                          onPressed: onContactTap,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(7),
                          iconSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Content ────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Address
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _obfuscateAddress(address),
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Price + m²
                    Row(
                      children: [
                        Text(_formatPrice(priceEur), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandBlue)),
                        const Spacer(),
                        Text('${surfaceM2.toStringAsFixed(0)} m\u00b2', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    // Stats
                    if (bedrooms != null || bathrooms != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (bedrooms != null) ...[
                            Icon(Icons.bed, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Text('$bedrooms Hab.', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            const SizedBox(width: 10),
                          ],
                          if (bathrooms != null) ...[
                            Icon(Icons.bathtub_outlined, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Text('$bathrooms Baños', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ],
                      ),
                    ],
                    // Description (fills remaining space)
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          description!,
                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(int price) {
    final s = price.toString();
    final buffer = StringBuffer();
    int counter = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (counter > 0 && counter % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
      counter++;
    }
    return '${String.fromCharCodes(buffer.toString().codeUnits.reversed)} \u20ac';
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({required this.icon, required this.color, required this.onPressed});
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
        iconSize: 17,
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 160,
      width: double.infinity,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.home_outlined, size: 48, color: colorScheme.outlineVariant),
    );
  }
}

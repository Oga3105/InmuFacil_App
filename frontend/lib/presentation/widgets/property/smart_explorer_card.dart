import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/lifestyle_provider.dart';

class SmartExplorerCard extends ConsumerWidget {
  const SmartExplorerCard({
    super.key,
    required this.propertyId,
    required this.title,
    required this.address,
    required this.priceEur,
    required this.surfaceM2,
    this.imageUrl,
    this.postalCode,
    this.onTap,
  });

  final String propertyId;
  final String title;
  final String address;
  final int priceEur;
  final double surfaceM2;
  final String? imageUrl;
  final String? postalCode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(lifestyleProfileProvider);
    final matchScore = profile != null ? _computeMatchScore(postalCode) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                if (matchScore != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _MatchBadge(score: matchScore),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(address, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(_formatPrice(priceEur), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      const Spacer(),
                      Text('${surfaceM2.toStringAsFixed(0)} m\u00b2', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  if (profile != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'lifestyle.profile_match_hint'.tr(args: [profile.profileName]),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _computeMatchScore(String? postalCode) {
    if (postalCode == null || postalCode.isEmpty) return 60;
    final digits = postalCode.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 60;
    final seed = digits.codeUnits.fold(0, (a, b) => a + b);
    return 55 + (seed % 40);
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

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.score});
  final int score;

  Color get _color {
    if (score >= 80) return const Color(0xFF16A34A);
    if (score >= 60) return const Color(0xFF2563EB);
    return const Color(0xFFF59E0B);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, size: 12, color: _color),
          const SizedBox(width: 4),
          Text('$score%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _color)),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      color: const Color(0xFFF1F5F9),
      child: const Icon(Icons.home_outlined, size: 48, color: Color(0xFFCBD5E1)),
    );
  }
}

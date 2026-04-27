import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../providers/neighborhood_twins_provider.dart';

/// Displays a panel of "barrios gemelos" (twin neighborhoods) below search
/// results when a postal code is available for the current search.
class NeighborhoodTwinsPanel extends ConsumerWidget {
  const NeighborhoodTwinsPanel({
    super.key,
    required this.postalCode,
    this.city,
  });

  final String postalCode;
  final String? city;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (postalCode.isEmpty) return const SizedBox.shrink();

    final key = TwinsRequestKey(postalCode: postalCode, city: city);
    final asyncResult = ref.watch(neighborhoodTwinsProvider(key));

    return asyncResult.when(
      loading: () => _LoadingState(),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        if (result == null || result.twins.isEmpty || result.lowData) {
          return const SizedBox.shrink();
        }
        return _TwinsContent(twins: result.twins, disclaimer: result.disclaimer);
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Text(
            'discovery.twins.loading'.tr(),
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _TwinsContent extends StatelessWidget {
  const _TwinsContent({required this.twins, required this.disclaimer});

  final List<NeighborhoodTwin> twins;
  final String disclaimer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // Section header
        Row(
          children: [
            Expanded(child: Divider(color: cs.outlineVariant, height: 1)),
            const SizedBox(width: 12),
            Icon(Icons.auto_awesome, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              'discovery.twins.section_title'.tr(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.primary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: cs.outlineVariant, height: 1)),
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'discovery.twins.section_subtitle'.tr(),
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),
        // Twin cards
        ...twins.map((twin) => _TwinNeighborhoodCard(twin: twin)),
        // Disclaimer
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            disclaimer,
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withOpacity(0.6)),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _TwinNeighborhoodCard extends StatelessWidget {
  const _TwinNeighborhoodCard({required this.twin});

  final NeighborhoodTwin twin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scorePct = twin.similarityScore;
    final scoreColor = scorePct >= 80
        ? const Color(0xFF16A34A)
        : scorePct >= 60
            ? const Color(0xFFF59E0B)
            : cs.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withOpacity(0.5)
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: name + score
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      twin.neighborhoodName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${twin.city} - ${twin.postalCode}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$scorePct%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          // Vibe
          if (twin.vibe.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              twin.vibe,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          // Price
          if (twin.avgPriceSqm != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.euro, size: 13, color: cs.primary),
                const SizedBox(width: 4),
                Text(
                  '${_formatNumber(twin.avgPriceSqm!)} EUR/m2',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ],
          // Similarities
          if (twin.keySimilarities.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: twin.keySimilarities.map((s) {
                return _Chip(label: s, color: const Color(0xFF16A34A));
              }).toList(),
            ),
          ],
          // Differences
          if (twin.keyDifferences.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: twin.keyDifferences.map((d) {
                return _Chip(label: d, color: const Color(0xFFF59E0B));
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

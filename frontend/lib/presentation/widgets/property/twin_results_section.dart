import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Renders search results with smart twin-zone interleaving.
///
/// - If [directResults] has 5 or more items: twin results appear at the bottom
///   after a labelled divider.
/// - If [directResults] has fewer than 5 items: twin results are interleaved
///   into the list to fill it out.
///
/// Each twin result entry in [twinResults] may contain:
///   - 'property'           (dynamic)  — the property object
///   - 'lifestyle_score'    (num?)     — LifestyleMatchScore 0-100 (optional)
///   - 'match_reason'       (String?)  — short reason label (optional)
///
/// The actual property card rendering is delegated to [itemBuilder], which
/// receives the property object. Pass the same card widget used in the main list.
class TwinResultsSection extends StatelessWidget {
  const TwinResultsSection({
    super.key,
    required this.directResults,
    required this.twinResults,
    required this.itemBuilder,
  });

  final List<dynamic> directResults;
  final List<Map<String, dynamic>> twinResults;

  /// Builds a single property card widget from a property object.
  final Widget Function(dynamic property) itemBuilder;

  static const int _threshold = 5;

  @override
  Widget build(BuildContext context) {
    final hasDirectResults = directResults.isNotEmpty;
    final hasTwinResults = twinResults.isNotEmpty;

    if (!hasDirectResults && !hasTwinResults) {
      return const SizedBox.shrink();
    }

    if (directResults.length >= _threshold) {
      return _SeparatedLayout(
        directResults: directResults,
        twinResults: twinResults,
        itemBuilder: itemBuilder,
      );
    }

    return _InterleavedLayout(
      directResults: directResults,
      twinResults: twinResults,
      itemBuilder: itemBuilder,
    );
  }
}

// ---------------------------------------------------------------------------
// Separated layout — twin results appended at the bottom after a divider
// ---------------------------------------------------------------------------

class _SeparatedLayout extends StatelessWidget {
  const _SeparatedLayout({
    required this.directResults,
    required this.twinResults,
    required this.itemBuilder,
  });

  final List<dynamic> directResults;
  final List<Map<String, dynamic>> twinResults;
  final Widget Function(dynamic property) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...directResults.map(itemBuilder),
        if (twinResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          _TwinSectionHeader(
            label: 'discovery.twins.header_bottom'.tr(),
          ),
          const SizedBox(height: 8),
          ...twinResults.map(
            (twin) => _TwinResultCard(
              twin: twin,
              itemBuilder: itemBuilder,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Interleaved layout — twins mixed into direct results
// ---------------------------------------------------------------------------

class _InterleavedLayout extends StatelessWidget {
  const _InterleavedLayout({
    required this.directResults,
    required this.twinResults,
    required this.itemBuilder,
  });

  final List<dynamic> directResults;
  final List<Map<String, dynamic>> twinResults;
  final Widget Function(dynamic property) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];
    int twinIndex = 0;

    for (int i = 0; i < directResults.length; i++) {
      items.add(itemBuilder(directResults[i]));
      // Interleave one twin result after every direct result when twins remain
      if (twinIndex < twinResults.length) {
        items.add(
          _TwinResultCard(
            twin: twinResults[twinIndex],
            itemBuilder: itemBuilder,
          ),
        );
        twinIndex++;
      }
    }

    // Append any remaining twin results
    while (twinIndex < twinResults.length) {
      items.add(
        _TwinResultCard(
          twin: twinResults[twinIndex],
          itemBuilder: itemBuilder,
        ),
      );
      twinIndex++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }
}

// ---------------------------------------------------------------------------
// Twin result card wrapper
// ---------------------------------------------------------------------------

class _TwinResultCard extends StatelessWidget {
  const _TwinResultCard({
    required this.twin,
    required this.itemBuilder,
  });

  final Map<String, dynamic> twin;
  final Widget Function(dynamic property) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final property = twin['property'];
    final lifestyleScore = twin['lifestyle_score'] as num?;
    final matchReason = twin['match_reason'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (matchReason != null || lifestyleScore != null)
              _TwinMatchBadge(
                score: lifestyleScore,
                reason: matchReason,
              ),
            itemBuilder(property),
          ],
        ),
      ),
    );
  }
}

class _TwinMatchBadge extends StatelessWidget {
  const _TwinMatchBadge({this.score, this.reason});

  final num? score;
  final String? reason;

  static const _orange = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: _orange.withValues(alpha: 0.10),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 14, color: _orange),
          const SizedBox(width: 6),
          if (reason != null)
            Expanded(
              child: Text(
                reason!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _orange,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (score != null) ...[
            const Spacer(),
            Text(
              'discovery.twins.match_score'
                  .tr(namedArgs: {'score': score!.toString()}),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _orange,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Divider header for the "zones similares" section
// ---------------------------------------------------------------------------

class _TwinSectionHeader extends StatelessWidget {
  const _TwinSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
        ],
      ),
    );
  }
}

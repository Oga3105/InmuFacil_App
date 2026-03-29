import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/formatters/currency_input_formatter.dart';

/// Digital solvency certificate card shown to the buyer after AI document analysis.
///
/// Displays:
///   - Solvency level badge (bronze / silver / gold / platinum)
///   - Progress bar representing solvency level
///   - Maximum offer capacity in EUR
///   - PII anonymization disclaimer
///   - Message visible to the seller
class SolvencyPassportCard extends StatelessWidget {
  const SolvencyPassportCard({
    super.key,
    required this.solvencyLevel,
    required this.maxOfferCapacity,
    required this.piiAnonymized,
  });

  final String solvencyLevel;
  final int maxOfferCapacity;
  final bool piiAnonymized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelColor = _levelColor(solvencyLevel);
    final progressValue = _levelProgress(solvencyLevel);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar
          Container(
            color: const Color(0xFF135BEC),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'solvency_passport.title'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (piiAnonymized)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'solvency_passport.verified'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level badge
                Row(
                  children: [
                    _LevelBadge(level: solvencyLevel, color: levelColor),
                    const SizedBox(width: 12),
                    Text(
                      'solvency_passport.level_label'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress bar
                Text(
                  'solvency_passport.solvency_level'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey.shade200,
                    color: levelColor,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),

                // Max offer capacity
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF16A34A).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'solvency_passport.max_capacity_label'.tr(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'solvency_passport.capacity_prefix'.tr()}'
                        '${CurrencyInputFormatter.format(maxOfferCapacity)} '
                        '${'solvency_passport.currency_suffix'.tr()}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Disclaimer
                Text(
                  'solvency_passport.disclaimer'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Seller message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF135BEC).withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    '${'solvency_passport.seller_message_prefix'.tr()}'
                    ' ${_levelDisplayName(solvencyLevel)})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF135BEC),
                      height: 1.4,
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

  static Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'platinum':
        return const Color(0xFF135BEC);
      case 'gold':
        return const Color(0xFFF59E0B);
      case 'silver':
        return const Color(0xFF9CA3AF);
      case 'bronze':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  static double _levelProgress(String level) {
    switch (level.toLowerCase()) {
      case 'platinum':
        return 1.0;
      case 'gold':
        return 0.75;
      case 'silver':
        return 0.50;
      case 'bronze':
      default:
        return 0.25;
    }
  }

  static String _levelDisplayName(String level) {
    switch (level.toLowerCase()) {
      case 'platinum':
        return 'Platinum';
      case 'gold':
        return 'Gold';
      case 'silver':
        return 'Silver';
      case 'bronze':
      default:
        return 'Bronze';
    }
  }
}

// ---------------------------------------------------------------------------
// Level badge
// ---------------------------------------------------------------------------

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.color});

  final String level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

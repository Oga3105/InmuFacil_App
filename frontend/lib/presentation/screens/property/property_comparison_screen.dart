import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import '../../../core/formatters/currency_input_formatter.dart';

/// Side-by-side property comparison screen.
///
/// Shows two properties in a scrollable table of metric rows.
/// The "winning" value in each row is highlighted in green; the other in
/// normal weight. Missing data is shown as "Sin datos".
class PropertyComparisonScreen extends ConsumerStatefulWidget {
  const PropertyComparisonScreen({
    super.key,
    required this.propertyAId,
    required this.propertyBId,
  });

  final String propertyAId;
  final String propertyBId;

  @override
  ConsumerState<PropertyComparisonScreen> createState() =>
      _PropertyComparisonScreenState();
}

class _PropertyComparisonScreenState
    extends ConsumerState<PropertyComparisonScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _green = Color(0xFF16A34A);
  static const _labelGrey = Color(0xFF64748B);
  static const _dividerGrey = Color(0xFFE2E8F0);

  // ---------------------------------------------------------------------------
  // Mock data loader — replace with real provider when available
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _mockProperty(String id) {
    // Deterministic mock based on id hash so A and B look different
    final seed = id.hashCode.abs() % 100;
    return {
      'id': id,
      'address': 'Calle de Ejemplo ${seed + 1}, Madrid',
      'price': 200000 + seed * 3000,
      'surface_m2': 70 + seed,
      'year_built': 1990 + (seed % 35),
      'floor': seed % 10 == 0 ? null : '${seed % 8 + 1}',
      'has_elevator': seed % 3 != 0,
      'needs_renovation': seed % 4 == 0,
      'ici_silence': seed > 50 ? (seed % 5 + 1).toDouble() : null,
      'ici_security': seed > 50 ? (seed % 5 + 2).toDouble() : null,
      'ici_air': seed > 50 ? (seed % 5 + 1).toDouble() : null,
      'ici_activity': seed > 50 ? (seed % 5 + 3).toDouble() : null,
    };
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final propA = _mockProperty(widget.propertyAId);
    final propB = _mockProperty(widget.propertyBId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
        ),
        title: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo_inmufacil.png', height: 28),
                const SizedBox(width: 8),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: 'Inmu', style: TextStyle(color: Color(0xFF2563EB))),
                      TextSpan(text: 'Fácil', style: TextStyle(color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Text('Inicio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const UserAvatarMenu(),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderRow(propA: propA, propB: propB),
            const SizedBox(height: 16),
            _ComparisonTable(propA: propA, propB: propB),
            const SizedBox(height: 24),
            const _AiVerdictSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header row — property address labels
// ---------------------------------------------------------------------------

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.propA, required this.propB});

  final Map<String, dynamic> propA;
  final Map<String, dynamic> propB;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 110),
        Expanded(
          child: _HeaderCell(
            label: 'A',
            address: propA['address'] as String? ?? '',
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HeaderCell(
            label: 'B',
            address: propB['address'] as String? ?? '',
            color: const Color(0xFF7C3AED),
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.address,
    required this.color,
  });

  final String label;
  final String address;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'property.comparison.property_label'
                  .tr(namedArgs: {'label': label}),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            address,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comparison table
// ---------------------------------------------------------------------------

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.propA, required this.propB});

  final Map<String, dynamic> propA;
  final Map<String, dynamic> propB;

  @override
  Widget build(BuildContext context) {
    final priceA = propA['price'] as int?;
    final priceB = propB['price'] as int?;
    final surfaceA = propA['surface_m2'] as int?;
    final surfaceB = propB['surface_m2'] as int?;

    final priceM2A = (priceA != null && surfaceA != null && surfaceA > 0)
        ? (priceA ~/ surfaceA)
        : null;
    final priceM2B = (priceB != null && surfaceB != null && surfaceB > 0)
        ? (priceB ~/ surfaceB)
        : null;

    final mortgageA = priceA != null ? (priceA * 0.004 / 12).toInt() : null;
    final mortgageB = priceB != null ? (priceB * 0.004 / 12).toInt() : null;

    final escrituracionA = priceA != null ? (priceA * 0.115).toInt() : null;
    final escrituracionB = priceB != null ? (priceB * 0.115).toInt() : null;

    final rows = <_RowData>[
      _RowData(
        label: 'property.comparison.row.price'.tr(),
        valueA: _formatCurrency(priceA),
        valueB: _formatCurrency(priceB),
        winnerIsA: _lowerWins(priceA, priceB),
      ),
      _RowData(
        label: 'property.comparison.row.price_m2'.tr(),
        valueA: _formatCurrency(priceM2A, suffix: '/m²'),
        valueB: _formatCurrency(priceM2B, suffix: '/m²'),
        winnerIsA: _lowerWins(priceM2A, priceM2B),
      ),
      _RowData(
        label: 'property.comparison.row.surface'.tr(),
        valueA: surfaceA != null ? '$surfaceA m²' : null,
        valueB: surfaceB != null ? '$surfaceB m²' : null,
        winnerIsA: _higherWins(surfaceA, surfaceB),
      ),
      _RowData(
        label: 'property.comparison.row.year'.tr(),
        valueA: propA['year_built']?.toString(),
        valueB: propB['year_built']?.toString(),
        winnerIsA: _higherWins(
          propA['year_built'] as num?,
          propB['year_built'] as num?,
        ),
      ),
      _RowData(
        label: 'property.comparison.row.floor'.tr(),
        valueA: propA['floor'] as String?,
        valueB: propB['floor'] as String?,
        winnerIsA: null, // subjective — no winner
      ),
      _RowData(
        label: 'property.comparison.row.elevator'.tr(),
        valueA: _boolLabel(propA['has_elevator'] as bool?),
        valueB: _boolLabel(propB['has_elevator'] as bool?),
        winnerIsA: _boolWin(propA['has_elevator'], propB['has_elevator']),
      ),
      _RowData(
        label: 'property.comparison.row.condition'.tr(),
        valueA: _conditionLabel(propA['needs_renovation'] as bool?),
        valueB: _conditionLabel(propB['needs_renovation'] as bool?),
        winnerIsA: _conditionWin(
          propA['needs_renovation'],
          propB['needs_renovation'],
        ),
      ),
      _RowData(
        label: 'property.comparison.row.ici_silence'.tr(),
        valueA: _formatIci(propA['ici_silence'] as double?),
        valueB: _formatIci(propB['ici_silence'] as double?),
        winnerIsA: _higherWins(
          propA['ici_silence'] as num?,
          propB['ici_silence'] as num?,
        ),
      ),
      _RowData(
        label: 'property.comparison.row.ici_security'.tr(),
        valueA: _formatIci(propA['ici_security'] as double?),
        valueB: _formatIci(propB['ici_security'] as double?),
        winnerIsA: _higherWins(
          propA['ici_security'] as num?,
          propB['ici_security'] as num?,
        ),
      ),
      _RowData(
        label: 'property.comparison.row.ici_air'.tr(),
        valueA: _formatIci(propA['ici_air'] as double?),
        valueB: _formatIci(propB['ici_air'] as double?),
        winnerIsA: _higherWins(
          propA['ici_air'] as num?,
          propB['ici_air'] as num?,
        ),
      ),
      _RowData(
        label: 'property.comparison.row.ici_activity'.tr(),
        valueA: _formatIci(propA['ici_activity'] as double?),
        valueB: _formatIci(propB['ici_activity'] as double?),
        winnerIsA: _higherWins(
          propA['ici_activity'] as num?,
          propB['ici_activity'] as num?,
        ),
      ),
      _RowData(
        label: 'property.comparison.row.mortgage'.tr(),
        valueA: _formatCurrency(mortgageA, suffix: '/mes'),
        valueB: _formatCurrency(mortgageB, suffix: '/mes'),
        winnerIsA: _lowerWins(mortgageA, mortgageB),
      ),
      _RowData(
        label: 'property.comparison.row.escrituracion'.tr(),
        valueA: _formatCurrency(escrituracionA),
        valueB: _formatCurrency(escrituracionB),
        winnerIsA: _lowerWins(escrituracionA, escrituracionB),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _ComparisonRow(data: rows[i]),
            if (i < rows.length - 1)
              const Divider(
                height: 1,
                color: Color(0xFFE2E8F0),
                indent: 16,
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }

  static String _noData(String? v) => v?.isNotEmpty == true ? v! : 'Sin datos';

  static String _formatCurrency(int? value, {String suffix = ''}) {
    if (value == null) return 'Sin datos';
    return '${CurrencyInputFormatter.format(value)} €$suffix';
  }

  static String _formatIci(double? value) {
    if (value == null) return 'N/A';
    return value.toStringAsFixed(1);
  }

  static String _boolLabel(bool? value) {
    if (value == null) return 'Sin datos';
    return value ? 'Si' : 'No';
  }

  static String _conditionLabel(bool? needsRenovation) {
    if (needsRenovation == null) return 'Sin datos';
    return needsRenovation ? 'Reforma' : 'Listo';
  }

  // Returns true if A wins, false if B wins, null if tie or missing data.
  static bool? _lowerWins(num? a, num? b) {
    if (a == null || b == null) return null;
    if (a == b) return null;
    return a < b;
  }

  static bool? _higherWins(num? a, num? b) {
    if (a == null || b == null) return null;
    if (a == b) return null;
    return a > b;
  }

  static bool? _boolWin(dynamic a, dynamic b) {
    if (a == null || b == null) return null;
    if (a == b) return null;
    // Having elevator wins
    return a == true;
  }

  static bool? _conditionWin(dynamic needsA, dynamic needsB) {
    if (needsA == null || needsB == null) return null;
    if (needsA == needsB) return null;
    // Not needing renovation wins
    return needsA == false;
  }
}

class _RowData {
  const _RowData({
    required this.label,
    required this.valueA,
    required this.valueB,
    required this.winnerIsA,
  });

  final String label;
  final String? valueA;
  final String? valueB;
  final bool? winnerIsA; // true = A wins, false = B wins, null = no winner

  static const _noData = 'Sin datos';

  String get displayA => valueA?.isNotEmpty == true ? valueA! : _noData;
  String get displayB => valueB?.isNotEmpty == true ? valueB! : _noData;
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.data});

  final _RowData data;

  static const _green = Color(0xFF16A34A);
  static const _labelGrey = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final aIsWinner = data.winnerIsA == true;
    final bIsWinner = data.winnerIsA == false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              data.label,
              style: const TextStyle(
                fontSize: 12,
                color: _labelGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: _ValueCell(
              value: data.displayA,
              isWinner: aIsWinner,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ValueCell(
              value: data.displayB,
              isWinner: bIsWinner,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({required this.value, required this.isWinner});

  final String value;
  final bool isWinner;

  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 13,
        fontWeight: isWinner ? FontWeight.w700 : FontWeight.w400,
        color: isWinner ? _green : const Color(0xFF334155),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ---------------------------------------------------------------------------
// AI Verdict section
// ---------------------------------------------------------------------------

class _AiVerdictSection extends StatelessWidget {
  const _AiVerdictSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              Text(
                'property.comparison.ai_verdict.title'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _VerdictItem(
            label: 'property.comparison.ai_verdict.property_a'.tr(),
            body: 'property.comparison.ai_verdict.property_a_body'.tr(),
          ),
          const SizedBox(height: 8),
          _VerdictItem(
            label: 'property.comparison.ai_verdict.property_b'.tr(),
            body: 'property.comparison.ai_verdict.property_b_body'.tr(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'property.comparison.ai_verdict.recommendation'.tr(),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0369A1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'property.comparison.ai_verdict.disclaimer'.tr(),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerdictItem extends StatelessWidget {
  const _VerdictItem({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: body),
        ],
      ),
    );
  }
}

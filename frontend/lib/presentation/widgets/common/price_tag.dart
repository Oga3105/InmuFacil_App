import 'package:flutter/material.dart';

/// Displays a property price with optional strikethrough previous price
/// and a discount badge when a price reduction has been recorded.
///
/// Usage (card, compact):
///   PriceTag(price: 185000, previousPrice: 200000)
///
/// Usage (detail screen, large):
///   PriceTag(price: 185000, previousPrice: 200000, large: true)
class PriceTag extends StatelessWidget {
  const PriceTag({
    super.key,
    required this.price,
    this.previousPrice,
    this.large = false,
  });

  final double price;
  final double? previousPrice;

  /// If true, renders at a larger size for detail screens.
  final bool large;

  bool get _hasDiscount =>
      previousPrice != null && previousPrice! > price;

  int get _discountPct =>
      (((previousPrice! - price) / previousPrice!) * 100).round();

  String _format(double v) {
    final int rounded = v.round();
    final String digits = rounded.toString();
    final StringBuffer buf = StringBuffer();
    final int len = digits.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return '${buf.toString()} \u20AC';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentSize = large ? 28.0 : 16.0;
    final previousSize = large ? 15.0 : 12.0;
    const discountColor = Color(0xFF16A34A);
    const previousColor = Color(0xFF94A3B8);

    if (!_hasDiscount) {
      return Text(
        _format(price),
        style: TextStyle(
          fontSize: currentSize,
          fontWeight: FontWeight.w900,
          color: cs.onSurface,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current price + discount badge inline
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _format(price),
              style: TextStyle(
                fontSize: currentSize,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: discountColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: discountColor.withValues(alpha: 0.30)),
              ),
              child: Text(
                '-$_discountPct%',
                style: TextStyle(
                  fontSize: large ? 13.0 : 11.0,
                  fontWeight: FontWeight.w700,
                  color: discountColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Previous price strikethrough
        Text(
          _format(previousPrice!),
          style: TextStyle(
            fontSize: previousSize,
            fontWeight: FontWeight.w500,
            color: previousColor,
            decoration: TextDecoration.lineThrough,
            decorationColor: previousColor,
            decorationThickness: 1.5,
          ),
        ),
      ],
    );
  }
}

// Monetary amount input formatter — project-wide rule:
//   - Integers only. No decimals allowed.
//   - Automatic thousands separator (dot, Spanish convention: 1.000.000).
//   - Stores raw digits in the controller value; the visible text is formatted.
//
// Usage:
//   inputFormatters: [CurrencyInputFormatter()],
//   keyboardType: TextInputType.number,
//
// To parse the raw integer back from the controller:
//   CurrencyInputFormatter.parse(controller.text)  // returns int? (null if empty)

import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  static const String _sep = '.';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip everything that is not a digit.
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    // Prevent leading zeros (e.g. "007" → "7").
    final noLeadingZero =
        digits.replaceFirst(RegExp(r'^0+(?=[1-9])'), '');
    final cleaned = noLeadingZero.isEmpty ? '0' : noLeadingZero;

    final formatted = _addThousandSeparators(cleaned);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _addThousandSeparators(String digits) {
    final buffer = StringBuffer();
    final length = digits.length;
    for (int i = 0; i < length; i++) {
      final remaining = length - i;
      if (i > 0 && remaining % 3 == 0) {
        buffer.write(_sep);
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Parses a formatted string (e.g. "1.250.000") back to an [int].
  /// Returns null if the string is empty or not a valid integer.
  static int? parse(String formattedText) {
    final raw = formattedText.replaceAll(_sep, '');
    return int.tryParse(raw);
  }

  /// Formats an integer value for display (e.g. 1250000 → "1.250.000").
  static String format(int value) => _addThousandSeparators(value.toString());
}

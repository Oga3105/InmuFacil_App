import '../../presentation/providers/verification_provider.dart';

/// Result of a document number validation attempt.
class DocumentValidationResult {
  const DocumentValidationResult({
    required this.isValid,
    this.isCif = false,
    this.errorKey,
    this.errorArgs,
  });

  final bool isValid;

  /// True when the input matches a CIF pattern (empresa).
  final bool isCif;

  /// easy_localization translation key. Null when [isValid] is true.
  final String? errorKey;

  /// Named arguments for the translation key (e.g. {"letter": "Z"}).
  final Map<String, String>? errorArgs;
}

/// Validates Spanish document numbers: DNI, NIE, and Pasaporte.
/// Also detects CIF (empresa) and returns a specific flag.
///
/// Error messages are returned as easy_localization keys under the namespace
/// `kyc.doc_number_dialog.*` so the UI can call `.tr()` on them.
class DocumentNumberValidator {
  DocumentNumberValidator._();

  // Standard DNI/NIE check-letter sequence (modulo 23)
  static const String _letters = 'TRWAGMYFPDXBNJZSQVHLCKE';

  // DNI: exactly 8 digits + 1 uppercase letter
  static final RegExp _dniRe = RegExp(r'^[0-9]{8}[A-Z]$');

  // NIE: X/Y/Z + 7 digits + 1 uppercase letter
  static final RegExp _nieRe = RegExp(r'^[XYZ][0-9]{7}[A-Z]$');

  // CIF: letra A-H/J/N/P/Q/R/S/U/V/W + 7 digits + digit or A-J
  static final RegExp _cifRe =
      RegExp(r'^[ABCDEFGHJNPQRSUVW][0-9]{7}[0-9A-J]$');

  static const String _ns = 'kyc.doc_number_dialog';

  /// Validates [rawValue] according to [type].
  /// Input is trimmed, uppercased and stripped of spaces/hyphens internally.
  static DocumentValidationResult validate(
    String rawValue,
    DocumentType? type,
  ) {
    final v = rawValue.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

    if (v.isEmpty) {
      return const DocumentValidationResult(
        isValid: false,
        errorKey: '$_ns.error_empty',
      );
    }

    // CIF check first — before type-specific checks
    if (_looksLikeCif(v)) {
      return const DocumentValidationResult(
        isValid: false,
        isCif: true,
      );
    }

    switch (type) {
      case DocumentType.nie:
        return _validateNie(v);
      case DocumentType.pasaporte:
        return _validatePasaporte(v);
      case DocumentType.dni:
      default:
        return _validateDni(v);
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static bool _looksLikeCif(String v) {
    if (!_cifRe.hasMatch(v)) return false;
    // Exclude values that also match DNI or NIE to avoid false positives
    if (_dniRe.hasMatch(v) || _nieRe.hasMatch(v)) return false;
    return true;
  }

  static DocumentValidationResult _validateDni(String v) {
    if (!_dniRe.hasMatch(v)) {
      return const DocumentValidationResult(
        isValid: false,
        errorKey: '$_ns.error_dni_format',
      );
    }

    final number = int.parse(v.substring(0, 8));
    final expected = _letters[number % 23];
    final provided = v[8];

    if (provided != expected) {
      return DocumentValidationResult(
        isValid: false,
        errorKey: '$_ns.error_dni_letter',
        errorArgs: {'letter': expected},
      );
    }

    return const DocumentValidationResult(isValid: true);
  }

  static DocumentValidationResult _validateNie(String v) {
    if (!_nieRe.hasMatch(v)) {
      return const DocumentValidationResult(
        isValid: false,
        errorKey: '$_ns.error_nie_format',
      );
    }

    const Map<String, String> prefixMap = {'X': '0', 'Y': '1', 'Z': '2'};
    final dniEquiv = prefixMap[v[0]]! + v.substring(1);
    final number = int.parse(dniEquiv.substring(0, 8));
    final expected = _letters[number % 23];
    final provided = v[8];

    if (provided != expected) {
      return DocumentValidationResult(
        isValid: false,
        errorKey: '$_ns.error_nie_letter',
        errorArgs: {'letter': expected},
      );
    }

    return const DocumentValidationResult(isValid: true);
  }

  static DocumentValidationResult _validatePasaporte(String v) {
    if (v.length < 6 || v.length > 12) {
      return const DocumentValidationResult(
        isValid: false,
        errorKey: '$_ns.error_passport_length',
      );
    }

    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(v)) {
      return const DocumentValidationResult(
        isValid: false,
        errorKey: '$_ns.error_passport_chars',
      );
    }

    return const DocumentValidationResult(isValid: true);
  }
}

import 'dart:collection';
import 'package:easy_localization/easy_localization.dart';

enum ComunidadAutonoma {
  andalucia,
  aragon,
  asturias,
  baleares,
  canarias,
  cantabria,
  castillaLaMancha,
  castillaYLeon,
  cataluna,
  extremadura,
  galicia,
  larioja,
  madrid,
  murcia,
  navarra,
  paisVasco,
  cValenciana,
  ceuta,
  melilla,
  desconocida,
}

extension ComunidadAutonomaX on ComunidadAutonoma {
  String get displayName => 'ccaa.$name'.tr();
}

/// Helper for backward compatibility (prefer using .displayName extension)
Map<ComunidadAutonoma, String> get ccaaDisplayName => {
      for (var val in ComunidadAutonoma.values) val: val.displayName,
    };

const Map<int, ComunidadAutonoma> _postalPrefixToCcaa = {
  1: ComunidadAutonoma.paisVasco,
  2: ComunidadAutonoma.castillaLaMancha,
  3: ComunidadAutonoma.cValenciana,
  4: ComunidadAutonoma.andalucia,
  5: ComunidadAutonoma.castillaYLeon,
  6: ComunidadAutonoma.extremadura,
  7: ComunidadAutonoma.baleares,
  8: ComunidadAutonoma.cataluna,
  9: ComunidadAutonoma.castillaYLeon,
  10: ComunidadAutonoma.extremadura,
  11: ComunidadAutonoma.andalucia,
  12: ComunidadAutonoma.cValenciana,
  13: ComunidadAutonoma.castillaLaMancha,
  14: ComunidadAutonoma.andalucia,
  15: ComunidadAutonoma.galicia,
  16: ComunidadAutonoma.castillaLaMancha,
  17: ComunidadAutonoma.cataluna,
  18: ComunidadAutonoma.andalucia,
  19: ComunidadAutonoma.castillaLaMancha,
  20: ComunidadAutonoma.paisVasco,
  21: ComunidadAutonoma.andalucia,
  22: ComunidadAutonoma.aragon,
  23: ComunidadAutonoma.andalucia,
  24: ComunidadAutonoma.castillaYLeon,
  25: ComunidadAutonoma.cataluna,
  26: ComunidadAutonoma.larioja,
  27: ComunidadAutonoma.galicia,
  28: ComunidadAutonoma.madrid,
  29: ComunidadAutonoma.andalucia,
  30: ComunidadAutonoma.murcia,
  31: ComunidadAutonoma.navarra,
  32: ComunidadAutonoma.galicia,
  33: ComunidadAutonoma.asturias,
  34: ComunidadAutonoma.castillaYLeon,
  35: ComunidadAutonoma.canarias,
  36: ComunidadAutonoma.galicia,
  37: ComunidadAutonoma.castillaYLeon,
  38: ComunidadAutonoma.canarias,
  39: ComunidadAutonoma.cantabria,
  40: ComunidadAutonoma.castillaYLeon,
  41: ComunidadAutonoma.andalucia,
  42: ComunidadAutonoma.castillaYLeon,
  43: ComunidadAutonoma.cataluna,
  44: ComunidadAutonoma.aragon,
  45: ComunidadAutonoma.castillaLaMancha,
  46: ComunidadAutonoma.cValenciana,
  47: ComunidadAutonoma.castillaYLeon,
  48: ComunidadAutonoma.paisVasco,
  49: ComunidadAutonoma.castillaYLeon,
  50: ComunidadAutonoma.aragon,
  51: ComunidadAutonoma.ceuta,
  52: ComunidadAutonoma.melilla,
};

ComunidadAutonoma ccaaFromPostalCode(String postalCode) {
  if (postalCode.length < 2) return ComunidadAutonoma.desconocida;
  final prefix = int.tryParse(postalCode.substring(0, 2));
  if (prefix == null) return ComunidadAutonoma.desconocida;
  return _postalPrefixToCcaa[prefix] ?? ComunidadAutonoma.desconocida;
}

/// Devuelve el tipo ITP aplicable (2026) o null si los datos son ambiguos
/// o el territorio tiene regimen foral especial que requiere consulta a gestor.
/// CLAUSULA DE VERACIDAD FISCAL: fuente Ley ITP y AJD vigente 2026.
double? itpRateForCcaa(ComunidadAutonoma ccaa) {
  switch (ccaa) {
    case ComunidadAutonoma.andalucia:
      return 0.07;
    case ComunidadAutonoma.aragon:
      return 0.08;
    case ComunidadAutonoma.asturias:
      return 0.08;
    case ComunidadAutonoma.baleares:
      return 0.08;
    case ComunidadAutonoma.canarias:
      return null;
    case ComunidadAutonoma.cantabria:
      return 0.10;
    case ComunidadAutonoma.castillaLaMancha:
      return 0.09;
    case ComunidadAutonoma.castillaYLeon:
      return 0.08;
    case ComunidadAutonoma.cataluna:
      return 0.10;
    case ComunidadAutonoma.extremadura:
      return 0.07;
    case ComunidadAutonoma.galicia:
      return 0.10;
    case ComunidadAutonoma.larioja:
      return 0.07;
    case ComunidadAutonoma.madrid:
      return 0.06;
    case ComunidadAutonoma.murcia:
      return 0.08;
    case ComunidadAutonoma.navarra:
      return null;
    case ComunidadAutonoma.paisVasco:
      return null;
    case ComunidadAutonoma.cValenciana:
      return 0.10;
    case ComunidadAutonoma.ceuta:
      return 0.06;
    case ComunidadAutonoma.melilla:
      return 0.06;
    case ComunidadAutonoma.desconocida:
      return null;
  }
}

const Set<ComunidadAutonoma> ccaaRequieresCedula = {
  ComunidadAutonoma.cataluna,
  ComunidadAutonoma.cValenciana,
  ComunidadAutonoma.baleares,
  ComunidadAutonoma.cantabria,
  ComunidadAutonoma.asturias,
  ComunidadAutonoma.murcia,
  ComunidadAutonoma.larioja,
  ComunidadAutonoma.canarias,
};

bool ccaaRequiereCedula(ComunidadAutonoma ccaa) =>
    ccaaRequieresCedula.contains(ccaa);

String arrasLegalReference(ComunidadAutonoma ccaa) {
  if (ccaa == ComunidadAutonoma.cataluna) {
    return 'arras_contract.legal_ref_cataluna'.tr();
  }
  return 'arras_contract.legal_ref_general'.tr();
}

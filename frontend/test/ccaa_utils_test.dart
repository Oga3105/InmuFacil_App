import 'package:flutter_test/flutter_test.dart';
import 'package:inmufacil_frontend/core/utils/ccaa_utils.dart';

void main() {
  group('CcaaUtils — deteccion por codigo postal', () {
    test('Madrid (28xxx) devuelve madrid', () {
      expect(ccaaFromPostalCode('28001'), ComunidadAutonoma.madrid);
    });

    test('Barcelona (08xxx) devuelve cataluna', () {
      expect(ccaaFromPostalCode('08001'), ComunidadAutonoma.cataluna);
    });

    test('Valencia (46xxx) devuelve cValenciana', () {
      expect(ccaaFromPostalCode('46001'), ComunidadAutonoma.cValenciana);
    });

    test('Postal code vacio devuelve desconocida', () {
      expect(ccaaFromPostalCode(''), ComunidadAutonoma.desconocida);
    });

    test('Sevilla (41xxx) devuelve andalucia', () {
      expect(ccaaFromPostalCode('41001'), ComunidadAutonoma.andalucia);
    });

    test('Palma (07xxx) devuelve baleares', () {
      expect(ccaaFromPostalCode('07001'), ComunidadAutonoma.baleares);
    });

    test('Las Palmas (35xxx) devuelve canarias', () {
      expect(ccaaFromPostalCode('35001'), ComunidadAutonoma.canarias);
    });

    test('Bilbao (48xxx) devuelve paisVasco', () {
      expect(ccaaFromPostalCode('48001'), ComunidadAutonoma.paisVasco);
    });

    test('Ceuta (51xxx) devuelve ceuta', () {
      expect(ccaaFromPostalCode('51001'), ComunidadAutonoma.ceuta);
    });

    test('Melilla (52xxx) devuelve melilla', () {
      expect(ccaaFromPostalCode('52001'), ComunidadAutonoma.melilla);
    });

    test('Codigo postal con letras devuelve desconocida', () {
      expect(ccaaFromPostalCode('ABCDE'), ComunidadAutonoma.desconocida);
    });

    test('Codigo postal de un solo digito devuelve desconocida', () {
      expect(ccaaFromPostalCode('2'), ComunidadAutonoma.desconocida);
    });
  });

  group('cedula de habitabilidad', () {
    test('Madrid NO requiere cedula', () {
      expect(ccaaRequiereCedula(ComunidadAutonoma.madrid), isFalse);
    });

    test('Barcelona SI requiere cedula', () {
      expect(ccaaRequiereCedula(ComunidadAutonoma.cataluna), isTrue);
    });

    test('Cataluna SI requiere cedula', () {
      expect(ccaaRequiereCedula(ComunidadAutonoma.cataluna), isTrue);
    });

    test('Valencia SI requiere cedula', () {
      expect(ccaaRequiereCedula(ComunidadAutonoma.cValenciana), isTrue);
    });

    test('Baleares SI requiere cedula', () {
      expect(ccaaRequiereCedula(ComunidadAutonoma.baleares), isTrue);
    });

    test('Andalucia NO requiere cedula', () {
      expect(ccaaRequiereCedula(ComunidadAutonoma.andalucia), isFalse);
    });

    test('Desconocida NO requiere cedula', () {
      expect(ccaaRequiereCedula(ComunidadAutonoma.desconocida), isFalse);
    });
  });

  group('ITP rates', () {
    test('Madrid ITP es 6%', () {
      expect(itpRateForCcaa(ComunidadAutonoma.madrid), closeTo(0.06, 0.001));
    });

    test('Cataluna ITP es 10%', () {
      expect(itpRateForCcaa(ComunidadAutonoma.cataluna), closeTo(0.10, 0.001));
    });

    test('Pais Vasco devuelve null (regimen foral)', () {
      expect(itpRateForCcaa(ComunidadAutonoma.paisVasco), isNull);
    });

    test('Canarias devuelve null (IGIC)', () {
      expect(itpRateForCcaa(ComunidadAutonoma.canarias), isNull);
    });

    test('Navarra devuelve null (regimen foral)', () {
      expect(itpRateForCcaa(ComunidadAutonoma.navarra), isNull);
    });

    test('Andalucia ITP es 7%', () {
      expect(itpRateForCcaa(ComunidadAutonoma.andalucia), closeTo(0.07, 0.001));
    });

    test('Cantabria ITP es 10%', () {
      expect(itpRateForCcaa(ComunidadAutonoma.cantabria), closeTo(0.10, 0.001));
    });

    test('Desconocida devuelve null', () {
      expect(itpRateForCcaa(ComunidadAutonoma.desconocida), isNull);
    });
  });

  group('arras legal reference', () {
    test('Cataluna cita Art 621-8 Codigo Civil Catalan', () {
      expect(
        arrasLegalReference(ComunidadAutonoma.cataluna),
        contains('621-8'),
      );
    });

    test('Madrid cita Art 1454 Codigo Civil', () {
      expect(
        arrasLegalReference(ComunidadAutonoma.madrid),
        contains('1454'),
      );
    });

    test('Andalucia cita Art 1454 Codigo Civil', () {
      expect(
        arrasLegalReference(ComunidadAutonoma.andalucia),
        contains('1454'),
      );
    });

    test('Pais Vasco cita Art 1454 Codigo Civil', () {
      expect(
        arrasLegalReference(ComunidadAutonoma.paisVasco),
        contains('1454'),
      );
    });
  });

  group('ccaaDisplayName', () {
    test('Madrid tiene nombre correcto', () {
      expect(ccaaDisplayName[ComunidadAutonoma.madrid], equals('Madrid'));
    });

    test('Cataluna tiene nombre correcto', () {
      expect(ccaaDisplayName[ComunidadAutonoma.cataluna], equals('Cataluna'));
    });

    test('Todos los valores del enum tienen nombre', () {
      for (final ccaa in ComunidadAutonoma.values) {
        expect(
          ccaaDisplayName.containsKey(ccaa),
          isTrue,
          reason: 'Falta nombre para $ccaa',
        );
      }
    });
  });
}

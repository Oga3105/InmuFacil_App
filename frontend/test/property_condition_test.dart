import 'package:flutter_test/flutter_test.dart';
import 'package:inmufacil_frontend/domain/entities/property_condition.dart';

void main() {
  test('PropertyCondition tiene 6 valores', () {
    expect(PropertyCondition.values.length, 6);
  });

  test('backendValue de obraNew es obra_nueva', () {
    expect(PropertyCondition.obraNew.backendValue, 'obra_nueva');
  });

  test('displayLabel no esta vacio para ningun valor', () {
    for (final c in PropertyCondition.values) {
      expect(c.displayLabel.isNotEmpty, isTrue);
    }
  });

  test('sublabel no esta vacio para ningun valor', () {
    for (final c in PropertyCondition.values) {
      expect(c.sublabel.isNotEmpty, isTrue);
    }
  });

  test('backendValue es unico para cada valor', () {
    final values = PropertyCondition.values.map((c) => c.backendValue).toList();
    final unique = values.toSet();
    expect(values.length, unique.length);
  });

  test('backendValues conocidos son correctos', () {
    expect(PropertyCondition.goodState.backendValue, 'buen_estado');
    expect(PropertyCondition.reformed.backendValue, 'reformado');
    expect(PropertyCondition.toReform.backendValue, 'a_reformar');
    expect(PropertyCondition.underConstruction.backendValue, 'en_construccion');
    expect(PropertyCondition.toDemolish.backendValue, 'para_derribar');
  });
}

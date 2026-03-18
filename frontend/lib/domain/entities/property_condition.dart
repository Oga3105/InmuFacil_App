enum PropertyCondition {
  obraNew,
  goodState,
  reformed,
  toReform,
  underConstruction,
  toDemolish,
}

extension PropertyConditionX on PropertyCondition {
  String get backendValue {
    switch (this) {
      case PropertyCondition.obraNew:
        return 'obra_nueva';
      case PropertyCondition.goodState:
        return 'buen_estado';
      case PropertyCondition.reformed:
        return 'reformado';
      case PropertyCondition.toReform:
        return 'a_reformar';
      case PropertyCondition.underConstruction:
        return 'en_construccion';
      case PropertyCondition.toDemolish:
        return 'para_derribar';
    }
  }

  String get displayLabel {
    switch (this) {
      case PropertyCondition.obraNew:
        return 'Obra Nueva';
      case PropertyCondition.goodState:
        return 'Buen Estado';
      case PropertyCondition.reformed:
        return 'Reformado';
      case PropertyCondition.toReform:
        return 'A Reformar';
      case PropertyCondition.underConstruction:
        return 'En Construccion';
      case PropertyCondition.toDemolish:
        return 'Para Derribar';
    }
  }

  String get sublabel {
    switch (this) {
      case PropertyCondition.obraNew:
        return 'Inmueble a estrenar';
      case PropertyCondition.goodState:
        return 'Listo para entrar a vivir';
      case PropertyCondition.reformed:
        return 'Recientemente actualizado';
      case PropertyCondition.toReform:
        return 'Necesita mejoras estructurales o esteticas';
      case PropertyCondition.underConstruction:
        return 'Proyecto en ejecucion';
      case PropertyCondition.toDemolish:
        return 'Solo valor de suelo/estructura';
    }
  }
}

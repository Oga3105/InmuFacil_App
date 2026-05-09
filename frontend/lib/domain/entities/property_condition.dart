import 'package:easy_localization/easy_localization.dart';
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
        return 'property_wizard.condition_new'.tr();
      case PropertyCondition.goodState:
        return 'property_wizard.condition_good'.tr();
      case PropertyCondition.reformed:
        return 'property_wizard.condition_reformed'.tr();
      case PropertyCondition.toReform:
        return 'property_wizard.condition_to_reform'.tr();
      case PropertyCondition.underConstruction:
        return 'property_wizard.condition_construction'.tr();
      case PropertyCondition.toDemolish:
        return 'property_wizard.condition_demolish'.tr();
    }
  }

  String get sublabel {
    switch (this) {
      case PropertyCondition.obraNew:
        return 'property_wizard.condition_new_sub'.tr();
      case PropertyCondition.goodState:
        return 'property_wizard.condition_good_sub'.tr();
      case PropertyCondition.reformed:
        return 'property_wizard.condition_reformed_sub'.tr();
      case PropertyCondition.toReform:
        return 'property_wizard.condition_to_reform_sub'.tr();
      case PropertyCondition.underConstruction:
        return 'property_wizard.condition_construction_sub'.tr();
      case PropertyCondition.toDemolish:
        return 'property_wizard.condition_demolish_sub'.tr();
    }
  }
}

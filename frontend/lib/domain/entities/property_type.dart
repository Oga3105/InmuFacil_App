/// Property types available in the platform
enum PropertyType {
  all,
  apartment,
  house,
  land,
  office;
  
  /// Get translation key for this property type
  String get translationKey {
    switch (this) {
      case PropertyType.all:
        return 'home.property_type_all';
      case PropertyType.apartment:
        return 'home.property_type_apartment';
      case PropertyType.house:
        return 'home.property_type_house';
      case PropertyType.land:
        return 'home.property_type_land';
      case PropertyType.office:
        return 'home.property_type_office';
    }
  }
}

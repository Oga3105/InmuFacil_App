/// Property types available in the platform
enum PropertyType {
  all,
  piso,
  atico,
  duplex,
  chalet,
  casaRustica,
  casaSingular,
  local,
  oficina,
  nave,
  edificio,
  garaje,
  terreno,
  fincaRustica;
  
  /// Get translation key for this property type
  String get translationKey {
    switch (this) {
      case PropertyType.all:
        return 'home.property_type_all';
      case PropertyType.piso:
        return 'home.property_type_apartment';
      case PropertyType.atico:
        return 'home.property_type_atico';
      case PropertyType.duplex:
        return 'home.property_type_duplex';
      case PropertyType.chalet:
        return 'home.property_type_house';
      case PropertyType.casaRustica:
        return 'home.property_type_rustic_house';
      case PropertyType.casaSingular:
        return 'home.property_type_singular_house';
      case PropertyType.local:
        return 'home.property_type_local';
      case PropertyType.oficina:
        return 'home.property_type_office';
      case PropertyType.nave:
        return 'home.property_type_industrial';
      case PropertyType.edificio:
        return 'home.property_type_building';
      case PropertyType.garaje:
        return 'home.property_type_garage';
      case PropertyType.terreno:
        return 'home.property_type_land';
      case PropertyType.fincaRustica:
        return 'home.property_type_rustic_land';
    }
  }
  
  /// Get backend enum value (string)
  String get backendValue {
     switch (this) {
      case PropertyType.all: return 'all';
      case PropertyType.piso: return 'piso';
      case PropertyType.atico: return 'atico';
      case PropertyType.duplex: return 'duplex';
      case PropertyType.chalet: return 'chalet';
      case PropertyType.casaRustica: return 'casa_rustica';
      case PropertyType.casaSingular: return 'casa_singular';
      case PropertyType.local: return 'local';
      case PropertyType.oficina: return 'oficina';
      case PropertyType.nave: return 'nave';
      case PropertyType.edificio: return 'edificio';
      case PropertyType.garaje: return 'garaje';
      case PropertyType.terreno: return 'terreno';
      case PropertyType.fincaRustica: return 'finca_rustica';
    }
  }
}

import 'package:latlong2/latlong.dart';
import 'package:inmufacil_frontend/domain/entities/property.dart';
import 'package:inmufacil_frontend/domain/entities/property_type.dart';

/// Mock property data for development
class MockPropertyData {
  static final _now = DateTime.now();

  static final List<Property> madridProperties = [
    // Centro - Sol: NUEVO (hace 2 horas)
    Property(
      id: '1',
      title: 'Piso céntrico en Sol',
      type: PropertyType.piso,
      price: 450000,
      location: const LatLng(40.4168, -3.7038),
      address: 'Puerta del Sol, Madrid',
      bedrooms: 2,
      bathrooms: 1,
      squareMeters: 75,
      features: const ['lift'],
      floor: '3',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),

    // Salamanca: NUEVO (hace 10 horas) + actualizado
    Property(
      id: '2',
      title: 'Ático de lujo en Salamanca',
      type: PropertyType.atico,
      price: 890000,
      location: const LatLng(40.4304, -3.6809),
      address: 'Barrio Salamanca, Madrid',
      bedrooms: 3,
      bathrooms: 2,
      squareMeters: 120,
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),

    // Chamberí: RECIENTE (hace 3 días)
    Property(
      id: '3',
      title: 'Piso reformado en Chamberí',
      type: PropertyType.piso,
      price: 520000,
      location: const LatLng(40.4378, -3.7036),
      address: 'Chamberí, Madrid',
      bedrooms: 2,
      bathrooms: 2,
      squareMeters: 85,
      features: const ['lift', 'terrace'],
      floor: '1',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),

    // Retiro: RECIENTE (hace 6 días) + actualizado
    Property(
      id: '4',
      title: 'Casa con jardín cerca del Retiro',
      type: PropertyType.chalet,
      price: 1200000,
      location: const LatLng(40.4153, -3.6838),
      address: 'Cerca Parque del Retiro, Madrid',
      bedrooms: 4,
      bathrooms: 3,
      squareMeters: 200,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),

    // Malasaña: hace 2 semanas (naranja)
    Property(
      id: '5',
      title: 'Loft moderno en Malasaña',
      type: PropertyType.piso,
      price: 380000,
      location: const LatLng(40.4267, -3.7033),
      address: 'Malasaña, Madrid',
      bedrooms: 1,
      bathrooms: 1,
      squareMeters: 60,
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),

    // Chueca: hace 25 días (naranja) + actualizado
    Property(
      id: '6',
      title: 'Estudio en Chueca',
      type: PropertyType.piso,
      price: 280000,
      location: const LatLng(40.4226, -3.6955),
      address: 'Chueca, Madrid',
      bedrooms: 1,
      bathrooms: 1,
      squareMeters: 45,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),

    // Moncloa: hace 2 meses (gris)
    Property(
      id: '7',
      title: 'Oficina en zona universitaria',
      type: PropertyType.oficina,
      price: 350000,
      location: const LatLng(40.4379, -3.7189),
      address: 'Moncloa, Madrid',
      bedrooms: 0,
      bathrooms: 2,
      squareMeters: 90,
      features: const ['ac', 'heating', 'accessible', 'lift'],
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),

    // Arganzuela: hace 3 meses (gris) + actualizado
    Property(
      id: '8',
      title: 'Piso familiar en Arganzuela',
      type: PropertyType.piso,
      price: 420000,
      location: const LatLng(40.3978, -3.6989),
      address: 'Arganzuela, Madrid',
      bedrooms: 3,
      bathrooms: 2,
      squareMeters: 95,
      features: const ['lift', 'garage'],
      floor: '4',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),

    // Las Rozas: sin fecha (sin badge)
    Property(
      id: '9',
      title: 'Chalet independiente',
      type: PropertyType.chalet,
      price: 750000,
      location: const LatLng(40.4933, -3.8736),
      address: 'Las Rozas, Madrid',
      bedrooms: 5,
      bathrooms: 3,
      squareMeters: 250,
    ),

    // Pozuelo: hace 45 días (gris)
    Property(
      id: '10',
      title: 'Terreno urbanizable',
      type: PropertyType.terreno,
      price: 500000,
      location: const LatLng(40.4358, -3.8147),
      address: 'Pozuelo de Alarcón, Madrid',
      bedrooms: 0,
      bathrooms: 0,
      squareMeters: 1000,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),

    // Chamartín: hace 5 días (reciente) + actualizado hace 2 horas
    Property(
      id: '11',
      title: 'Piso de lujo en Chamartín',
      type: PropertyType.piso,
      price: 680000,
      location: const LatLng(40.4652, -3.6781),
      address: 'Chamartín, Madrid',
      bedrooms: 3,
      bathrooms: 2,
      squareMeters: 110,
      features: const ['ac', 'storage_room', 'fitted_wardrobes', 'lift', 'exterior'],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),

    // Latina: hace 18 días (naranja)
    Property(
      id: '12',
      title: 'Piso económico en La Latina',
      type: PropertyType.piso,
      price: 320000,
      location: const LatLng(40.4089, -3.7142),
      address: 'La Latina, Madrid',
      bedrooms: 2,
      bathrooms: 1,
      squareMeters: 70,
      features: const ['fitted_wardrobes', 'heating', 'exterior'],
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
    ),
  ];

  /// Get Madrid city center coordinates
  static const LatLng madridCenter = LatLng(40.4168, -3.7038);
}

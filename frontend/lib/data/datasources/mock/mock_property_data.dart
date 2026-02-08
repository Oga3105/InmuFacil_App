import 'package:latlong2/latlong.dart';
import 'package:inmufacil_frontend/domain/entities/property.dart';
import 'package:inmufacil_frontend/domain/entities/property_type.dart';

/// Mock property data for development
class MockPropertyData {
  static final List<Property> madridProperties = [
    // Centro - Sol
    Property(
      id: '1',
      title: 'Piso céntrico en Sol',
      type: PropertyType.apartment,
      price: 450000,
      location: const LatLng(40.4168, -3.7038),
      address: 'Puerta del Sol, Madrid',
      bedrooms: 2,
      bathrooms: 1,
      squareMeters: 75,
    ),
    
    // Salamanca
    Property(
      id: '2',
      title: 'Ático de lujo en Salamanca',
      type: PropertyType.apartment,
      price: 890000,
      location: const LatLng(40.4304, -3.6809),
      address: 'Barrio Salamanca, Madrid',
      bedrooms: 3,
      bathrooms: 2,
      squareMeters: 120,
    ),
    
    // Chamberí
    Property(
      id: '3',
      title: 'Piso reformado en Chamberí',
      type: PropertyType.apartment,
      price: 520000,
      location: const LatLng(40.4378, -3.7036),
      address: 'Chamberí, Madrid',
      bedrooms: 2,
      bathrooms: 2,
      squareMeters: 85,
    ),
    
    // Retiro
    Property(
      id: '4',
      title: 'Casa con jardín cerca del Retiro',
      type: PropertyType.house,
      price: 1200000,
      location: const LatLng(40.4153, -3.6838),
      address: 'Cerca Parque del Retiro, Madrid',
      bedrooms: 4,
      bathrooms: 3,
      squareMeters: 200,
    ),
    
    // Malasaña
    Property(
      id: '5',
      title: 'Loft moderno en Malasaña',
      type: PropertyType.apartment,
      price: 380000,
      location: const LatLng(40.4267, -3.7033),
      address: 'Malasaña, Madrid',
      bedrooms: 1,
      bathrooms: 1,
      squareMeters: 60,
    ),
    
    // Chueca
    Property(
      id: '6',
      title: 'Estudio en Chueca',
      type: PropertyType.apartment,
      price: 280000,
      location: const LatLng(40.4226, -3.6955),
      address: 'Chueca, Madrid',
      bedrooms: 1,
      bathrooms: 1,
      squareMeters: 45,
    ),
    
    // Moncloa
    Property(
      id: '7',
      title: 'Oficina en zona universitaria',
      type: PropertyType.office,
      price: 350000,
      location: const LatLng(40.4379, -3.7189),
      address: 'Moncloa, Madrid',
      bedrooms: 0,
      bathrooms: 2,
      squareMeters: 90,
    ),
    
    // Arganzuela
    Property(
      id: '8',
      title: 'Piso familiar en Arganzuela',
      type: PropertyType.apartment,
      price: 420000,
      location: const LatLng(40.3978, -3.6989),
      address: 'Arganzuela, Madrid',
      bedrooms: 3,
      bathrooms: 2,
      squareMeters: 95,
    ),
    
    // Las Rozas (afueras)
    Property(
      id: '9',
      title: 'Chalet independiente',
      type: PropertyType.house,
      price: 750000,
      location: const LatLng(40.4933, -3.8736),
      address: 'Las Rozas, Madrid',
      bedrooms: 5,
      bathrooms: 3,
      squareMeters: 250,
    ),
    
    // Pozuelo
    Property(
      id: '10',
      title: 'Terreno urbanizable',
      type: PropertyType.land,
      price: 500000,
      location: const LatLng(40.4358, -3.8147),
      address: 'Pozuelo de Alarcón, Madrid',
      bedrooms: 0,
      bathrooms: 0,
      squareMeters: 1000,
    ),
    
    // Chamartín
    Property(
      id: '11',
      title: 'Piso de lujo en Chamartín',
      type: PropertyType.apartment,
      price: 680000,
      location: const LatLng(40.4652, -3.6781),
      address: 'Chamartín, Madrid',
      bedrooms: 3,
      bathrooms: 2,
      squareMeters: 110,
    ),
    
    // Latina
    Property(
      id: '12',
      title: 'Piso económico en La Latina',
      type: PropertyType.apartment,
      price: 320000,
      location: const LatLng(40.4089, -3.7142),
      address: 'La Latina, Madrid',
      bedrooms: 2,
      bathrooms: 1,
      squareMeters: 70,
    ),
  ];
  
  /// Get Madrid city center coordinates
  static const LatLng madridCenter = LatLng(40.4168, -3.7038);
}

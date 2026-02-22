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
      description: 'Hermoso piso reformado en el corazón de Madrid.',
      type: PropertyType.piso,
      price: 450000,
      location: const LatLng(40.4168, -3.7038),
      address: 'Puerta del Sol, Madrid',
      bedrooms: 2,
      bathrooms: 1,
      squareMeters: 75,
      images: const ['https://images.unsplash.com/photo-1522708323590-d24dbb6b0267'],
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    
    // Salamanca
    Property(
      id: '2',
      title: 'Ático de lujo en Salamanca',
      description: 'Lujoso ático con vistas espectaculares.',
      type: PropertyType.atico,
      price: 890000,
      location: const LatLng(40.4304, -3.6809),
      address: 'Barrio Salamanca, Madrid',
      bedrooms: 3,
      bathrooms: 2,
      squareMeters: 120,
      images: const ['https://images.unsplash.com/photo-1502672260266-1c1ef2d93688'],
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    
    // Chamberí
    Property(
      id: '3',
      title: 'Piso reformado en Chamberí',
      description: 'Elegante piso en uno de los mejores barrios.',
      type: PropertyType.piso,
      price: 520000,
      location: const LatLng(40.4378, -3.7036),
      address: 'Chamberí, Madrid',
      bedrooms: 2,
      bathrooms: 2,
      squareMeters: 85,
      images: const ['https://images.unsplash.com/photo-1484154218962-a197022b5858'],
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    
    // Retiro
    Property(
      id: '4',
      title: 'Casa con jardín cerca del Retiro',
      description: 'Oasis urbano junto al parque más famoso.',
      type: PropertyType.chalet,
      price: 1200000,
      location: const LatLng(40.4153, -3.6838),
      address: 'Cerca Parque del Retiro, Madrid',
      bedrooms: 4,
      bathrooms: 3,
      squareMeters: 200,
      images: const ['https://images.unsplash.com/photo-1512917774080-9991f1c4c750'],
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    
    // Malasaña
    Property(
      id: '5',
      title: 'Loft moderno en Malasaña',
      description: 'Ideal para jóvenes profesionales y artistas.',
      type: PropertyType.piso,
      price: 380000,
      location: const LatLng(40.4267, -3.7033),
      address: 'Malasaña, Madrid',
      bedrooms: 1,
      bathrooms: 1,
      squareMeters: 60,
      images: const ['https://images.unsplash.com/photo-1536376074432-bf12177d4f4f'],
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    
    // Chueca
    Property(
      id: '6',
      title: 'Estudio en Chueca',
      description: 'Estudio acogedor en zona vibrante.',
      type: PropertyType.piso,
      price: 280000,
      location: const LatLng(40.4226, -3.6955),
      address: 'Chueca, Madrid',
      bedrooms: 1,
      bathrooms: 1,
      squareMeters: 45,
      images: const ['https://images.unsplash.com/photo-1493809842364-78817add7ffb'],
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    
    // Moncloa
    Property(
      id: '7',
      title: 'Oficina en zona universitaria',
      description: 'Espacio versátil ideal para co-working.',
      type: PropertyType.oficina,
      price: 350000,
      location: const LatLng(40.4379, -3.7189),
      address: 'Moncloa, Madrid',
      bedrooms: 0,
      bathrooms: 2,
      squareMeters: 90,
      images: const ['https://images.unsplash.com/photo-1497366216548-37526070297c'],
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    
    // Arganzuela
    Property(
      id: '8',
      title: 'Piso familiar en Arganzuela',
      description: 'Tranquilidad y servicios para toda la familia.',
      type: PropertyType.piso,
      price: 420000,
      location: const LatLng(40.3978, -3.6989),
      address: 'Arganzuela, Madrid',
      bedrooms: 3,
      bathrooms: 2,
      squareMeters: 95,
      images: const ['https://images.unsplash.com/photo-1560448204-e02f11c3d0e2'],
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    
    // Las Rozas (afueras)
    Property(
      id: '9',
      title: 'Chalet independiente',
      description: 'Vivir rodeado de naturaleza a un paso de la ciudad.',
      type: PropertyType.chalet,
      price: 750000,
      location: const LatLng(40.4933, -3.8736),
      address: 'Las Rozas, Madrid',
      bedrooms: 5,
      bathrooms: 3,
      squareMeters: 250,
      images: const ['https://images.unsplash.com/photo-1518780664697-55e3ad937233'],
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    
    // Pozuelo
    Property(
      id: '10',
      title: 'Terreno urbanizable',
      description: 'Oportunidad de inversión en zona exclusiva.',
      type: PropertyType.terreno,
      price: 500000,
      location: const LatLng(40.4358, -3.8147),
      address: 'Pozuelo de Alarcón, Madrid',
      bedrooms: 0,
      bathrooms: 0,
      squareMeters: 1000,
      images: const ['https://images.unsplash.com/photo-1500382017468-9049fed747ef'],
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    
    // Chamartín
    Property(
      id: '11',
      title: 'Piso de lujo en Chamartín',
      description: 'Diseño vanguardista y calidades premium.',
      type: PropertyType.piso,
      price: 680000,
      location: const LatLng(40.4652, -3.6781),
      address: 'Chamartín, Madrid',
      bedrooms: 3,
      bathrooms: 2,
      squareMeters: 110,
      images: const ['https://images.unsplash.com/photo-1493238792000-8113da705763'],
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    
    // Latina
    Property(
      id: '12',
      title: 'Piso económico en La Latina',
      description: 'Excelente oportunidad de inversión para alquilar.',
      type: PropertyType.piso,
      price: 320000,
      location: const LatLng(40.4089, -3.7142),
      address: 'La Latina, Madrid',
      bedrooms: 2,
      bathrooms: 1,
      squareMeters: 70,
      images: const ['https://images.unsplash.com/photo-1502672023488-70e25813eb80'],
      isVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
  
  /// Get Madrid city center coordinates
  static const LatLng madridCenter = LatLng(40.4168, -3.7038);
}

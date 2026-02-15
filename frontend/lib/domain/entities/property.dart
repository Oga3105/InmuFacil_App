import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:inmufacil_frontend/domain/entities/property_type.dart';

/// Property entity for real estate listings
class Property {
  final String id;
  final String title;
  final PropertyType type;
  final double price;
  final LatLng location;
  final String address;
  final int bedrooms;
  final int bathrooms;
  final double squareMeters;
  final String? imageUrl;
  final String? floor; // [NEW] Optional floor info (e.g., "Bajo", "2")
  
  const Property({
    required this.id,
    required this.title,
    required this.type,
    required this.price,
    required this.location,
    required this.address,
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.squareMeters = 0,
    this.imageUrl,
    this.floor,
    this.features = const [],
  });

  final List<String> features;
  
  /// Format price as currency string (e.g., 380.000 €)
  String get formattedPrice {
    final formatter = NumberFormat.decimalPattern('es_ES');
    return '${formatter.format(price.toInt())} €';
  }
}

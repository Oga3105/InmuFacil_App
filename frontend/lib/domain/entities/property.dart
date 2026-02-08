import 'package:latlong2/latlong.dart';
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
  });
  
  /// Format price as currency string
  String get formattedPrice {
    if (price >= 1000000) {
      return '€${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '€${(price / 1000).toStringAsFixed(0)}K';
    }
    return '€${price.toStringAsFixed(0)}';
  }
}

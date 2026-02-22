import 'package:latlong2/latlong.dart';
import 'package:inmufacil_frontend/domain/entities/property_type.dart';

/// Property entity for real estate listings
class Property {
  final String id;
  final String title;
  final String description; // Added
  final PropertyType type;
  final double price;
  final LatLng location;
  final String address;
  final int bedrooms;
  final int bathrooms;
  final String? floor; // Added
  final double squareMeters;
  final List<String> images; // Added - Replaces single imageUrl
  final bool isVerified; // Added
  final DateTime createdAt; // Added
  final DateTime updatedAt; // Added
  
  const Property({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    required this.location,
    required this.address,
    required this.bedrooms,
    required this.bathrooms,
    this.floor,
    required this.squareMeters,
    required this.images,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Compatibility getter for legacy code
  String? get imageUrl => images.isNotEmpty ? images.first : null;
  
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

import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'package:inmufacil_frontend/domain/entities/property.dart';
import 'package:inmufacil_frontend/domain/entities/property_type.dart';

part 'property_model.g.dart';

/// Data model for Property with JSON serialization
@JsonSerializable()
class PropertyModel {
  final int id;
  final String title;
  final String type;
  final double price;
  final double latitude;
  final double longitude;
  final String address;
  final int bedrooms;
  final int bathrooms;
  @JsonKey(name: 'square_meters')
  final double squareMeters;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  
  const PropertyModel({
    required this.id,
    required this.title,
    required this.type,
    required this.price,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareMeters,
    this.imageUrl,
  });
  
  /// Convert from JSON
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    // Parse Location "lat, lng" -> latitude, longitude
    double lat = 0.0;
    double lng = 0.0;
    
    if (json.containsKey('location') && json['location'] is String) {
      final locParts = (json['location'] as String).split(',');
      if (locParts.length == 2) {
        lat = double.tryParse(locParts[0].trim()) ?? 0.0;
        lng = double.tryParse(locParts[1].trim()) ?? 0.0;
      }
    } else {
      // Fallback if backend sends separate fields
      lat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
      lng = (json['longitude'] as num?)?.toDouble() ?? 0.0;
    }

    return PropertyModel(
      id: json['id'] as int,
      title: json['title'] as String,
      type: json['property_type'] as String? ?? 'piso', // Backend uses property_type
      price: (json['price'] as num).toDouble(),
      latitude: lat,
      longitude: lng,
      address: json['address'] as String? ?? '',
      bedrooms: (json['features']?['bedrooms'] as int?) ?? 0, // Access nested features
      bathrooms: (json['features']?['bathrooms'] as int?) ?? 0,
      squareMeters: (json['surface_area'] as num?)?.toDouble() ?? 0.0, // Backend uses surface_area
      imageUrl: _parseFirstImage(json['media']),
    );
  }
  
  static String? _parseFirstImage(dynamic mediaList) {
    if (mediaList is List && mediaList.isNotEmpty) {
      return mediaList[0]['file_path'] as String?;
    }
    return null;
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() => _$PropertyModelToJson(this);
  
  /// Convert to domain entity
  Property toEntity() {
    return Property(
      id: id.toString(),
      title: title,
      type: _parsePropertyType(type),
      price: price,
      location: LatLng(latitude, longitude),
      address: address,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      squareMeters: squareMeters,
      imageUrl: imageUrl,
    );
  }
  
  /// Parse property type from string
  PropertyType _parsePropertyType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'apartment':
      case 'piso': // Backend value
        return PropertyType.apartment;
      case 'house':
      case 'chalet': // Backend value
      case 'casa':
        return PropertyType.house;
      case 'land':
      case 'terreno':
      case 'solar':
        return PropertyType.land;
      case 'office':
      case 'oficina': // Backend value
      case 'local':
        return PropertyType.office;
      default:
        return PropertyType.apartment;
    }
  }
  
  /// Create from domain entity
  factory PropertyModel.fromEntity(Property property) {
    return PropertyModel(
      id: int.parse(property.id),
      title: property.title,
      type: _propertyTypeToString(property.type),
      price: property.price,
      latitude: property.location.latitude,
      longitude: property.location.longitude,
      address: property.address,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      squareMeters: property.squareMeters,
      imageUrl: property.imageUrl,
    );
  }
  
  /// Convert PropertyType to string
  static String _propertyTypeToString(PropertyType type) {
    switch (type) {
      case PropertyType.apartment:
        return 'piso';
      case PropertyType.house:
        return 'chalet';
      case PropertyType.land:
        return 'terreno';
      case PropertyType.office:
        return 'oficina';
      case PropertyType.all:
        return 'all';
    }
  }
}

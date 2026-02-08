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
  factory PropertyModel.fromJson(Map<String, dynamic> json) =>
      _$PropertyModelFromJson(json);
  
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
        return PropertyType.apartment;
      case 'house':
        return PropertyType.house;
      case 'land':
        return PropertyType.land;
      case 'office':
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
        return 'apartment';
      case PropertyType.house:
        return 'house';
      case PropertyType.land:
        return 'land';
      case PropertyType.office:
        return 'office';
      case PropertyType.all:
        return 'all';
    }
  }
}

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
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  
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
    this.floor,
    this.isVerified = true,
    this.features = const [],
    this.createdAt,
    this.updatedAt,
  });
  
  @JsonKey(includeFromJson: false)
  final String? floor;

  @JsonKey(includeFromJson: false) // Not serialized by default json_serializable unless updated
  final List<String> features;
  
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
      isVerified: json['is_verified'] as bool? ?? true,
      floor: json['features']?['floor'] as String?,
      features: _parseFeatures(json['features']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
  
  static List<String> _parseFeatures(Map<String, dynamic>? featuresJson) {
    if (featuresJson == null) return [];
    
    final List<String> list = [];
    if (featuresJson['has_pool'] == true) list.add('pool');
    if (featuresJson['has_terrace'] == true) list.add('terrace');
    if (featuresJson['has_garden'] == true) list.add('garden');
    if (featuresJson['has_lift'] == true) list.add('lift');
    if (featuresJson['has_ac'] == true) list.add('ac');
    if (featuresJson['has_heating'] == true) list.add('heating');
    if (featuresJson['has_storage_room'] == true) list.add('storage_room');
    if (featuresJson['has_fitted_wardrobes'] == true) list.add('fitted_wardrobes');
    if (featuresJson['is_exterior'] == true) list.add('exterior');
    if (featuresJson['is_accessible'] == true) list.add('accessible');
    // Garage is not in backend yet as feature, handled by description/type
    return list;
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
      floor: floor,
      isVerified: isVerified,
      features: features,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  
  /// Parse property type from string
  PropertyType _parsePropertyType(String typeStr) {
    try {
      final normalized = typeStr.toLowerCase().trim();
      return PropertyType.values.firstWhere(
        (e) => e.backendValue == normalized,
        orElse: () {
          // Fallback legacy mapping if needed, or default
          if (normalized == 'apartment') return PropertyType.piso;
          if (normalized == 'house') return PropertyType.chalet;
          if (normalized == 'land') return PropertyType.terreno;
          if (normalized == 'office') return PropertyType.oficina; 
          return PropertyType.piso; // Default fallback
        },
      );
    } catch (_) {
      return PropertyType.piso;
    }
  }
  
  /// Create from domain entity
  factory PropertyModel.fromEntity(Property property) {
    return PropertyModel(
      id: int.parse(property.id),
      title: property.title,
      type: property.type.backendValue,
      price: property.price,
      latitude: property.location.latitude,
      longitude: property.location.longitude,
      address: property.address,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      squareMeters: property.squareMeters,
      imageUrl: property.imageUrl,
      floor: property.floor,
      isVerified: property.isVerified,
    );
  }
  
  /// Convert PropertyType to string
  static String _propertyTypeToString(PropertyType type) {
    return type.backendValue;
  }
}

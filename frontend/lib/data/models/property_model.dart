import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'package:inmufacil_frontend/core/config/env_config.dart';
import 'package:inmufacil_frontend/domain/entities/property.dart';
import 'package:inmufacil_frontend/domain/entities/property_type.dart';

part 'property_model.g.dart';

/// Data model for Property with manual JSON mapping to handle nested structures
@JsonSerializable(explicitToJson: true)
class PropertyModel {
  
  const PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.bedrooms,
    required this.bathrooms,
    this.floor,
    required this.squareMeters,
    required this.images,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    this.ownerId,
    this.allowVisits = true,
    this.ownerName,
    this.ownerIsVerified = false,
    this.ownerPhotoUrl,
    this.hideExactLocation = false,
    this.energyCertification,
  });

  /// Safely parse dynamic value to int regardless of whether backend sends int, num or String.
  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// Convert from JSON (Manual Mapping for Nested Backend Data)
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    // Extract nested features
    final features = json['features'] as Map<String, dynamic>? ?? {};
    // Extract nested legal
    final legal = json['legal'] as Map<String, dynamic>? ?? {};
    
    // Extract nested media (images only) and build full URLs
    final mediaList = json['media'] as List? ?? [];
    final String _staticBase = EnvConfig.apiBaseUrl.replaceAll(RegExp(r'/api/v\d+/?$'), '');
    final List<String> imageUrls = mediaList
        .where((m) => m['media_type'] == 'image')
        .map((m) {
          final path = (m['file_path'] as String?) ?? (m['url'] as String?) ?? '';
          if (path.startsWith('http')) return path;
          return '$_staticBase/${path.startsWith('/') ? path.substring(1) : path}';
        })
        .toList();

    // Handle Coordinate extraction if location is a single string or separate fields
    // Based on backend/src/models/properties.py, 'location' is a String.
    // However, PropertyModel previously used latitude/longitude fields.
    // Mapping logic must match actual API behavior. 
    // If backend sends latitude/longitude separately:
    double lat = (json['latitude'] ?? 0.0).toDouble();
    double lon = (json['longitude'] ?? 0.0).toDouble();

    // Fix for Backend format: Sometimes coords are sent as "lat, lng" in 'location' 
    // while 'latitude' and 'longitude' are null.
    final locationStr = json['location'] as String? ?? '';
    if (lat == 0.0 && lon == 0.0 && locationStr.contains(',')) {
      final parts = locationStr.split(',');
      if (parts.length == 2) {
        lat = double.tryParse(parts[0].trim()) ?? 0.0;
        lon = double.tryParse(parts[1].trim()) ?? 0.0;
      }
    }

    return PropertyModel(
      id: _parseInt(json['id']) ?? 0,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      type: json['property_type'] as String? ?? 'piso',
      price: (json['price'] ?? 0.0).toDouble(),
      latitude: lat,
      longitude: lon,
      address: json['location'] as String? ?? '',
      bedrooms: _parseInt(features['bedrooms']) ?? 0,
      bathrooms: _parseInt(features['bathrooms']) ?? 0,
      floor: features['floor']?.toString(),
      squareMeters: (json['surface_area'] ?? 0.0).toDouble(),
      images: imageUrls,
      isVerified: json['is_verified'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      ownerId: (json['seller_id'] ?? json['owner_id'])?.toString(),
      allowVisits: json['allow_visits'] as bool? ?? true,
      ownerName: json['owner_name'] as String?,
      ownerIsVerified: json['owner_is_verified'] as bool? ?? false,
      ownerPhotoUrl: json['owner_photo_url'] as String?,
      hideExactLocation: json['hide_exact_location'] as bool? ?? false,
      energyCertification: legal['energy_certification'] as String?,
    );
  }
  final int id;
  final String title;
  final String description;
  final String type;
  final double price;
  final double latitude;
  final double longitude;
  final String address;
  final int bedrooms;
  final int bathrooms;
  final String? floor;
  final double squareMeters;
  final List<String> images;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? ownerId;
  final bool allowVisits;
  final String? ownerName;
  final bool ownerIsVerified;
  final String? ownerPhotoUrl;
  final bool hideExactLocation;
  final String? energyCertification;

  /// Convert to domain entity
  Property toEntity() {
    return Property(
      id: id.toString(),
      title: title,
      description: description,
      type: _parsePropertyType(type),
      price: price,
      location: LatLng(latitude, longitude),
      address: address,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      floor: floor,
      squareMeters: squareMeters,
      images: images,
      isVerified: isVerified,
      createdAt: createdAt,
      updatedAt: updatedAt,
      ownerId: ownerId,
      allowVisits: allowVisits,
      ownerName: ownerName,
      ownerIsVerified: ownerIsVerified,
      ownerPhotoUrl: ownerPhotoUrl,
      hideExactLocation: hideExactLocation,
      energyCertification: energyCertification,
    );
  }
  
  /// Parse property type from string
  PropertyType _parsePropertyType(String typeStr) {
    final lower = typeStr.toLowerCase();
    
    // Check direct matching with backendValue
    try {
      return PropertyType.values.firstWhere((e) => e.backendValue == lower);
    } catch (_) {
      // Fallbacks just in case
      if (lower == 'apartment') return PropertyType.piso;
      if (lower == 'house') return PropertyType.chalet;
      if (lower == 'office') return PropertyType.oficina;
      if (lower == 'land') return PropertyType.terreno;
      
      return PropertyType.piso;
    }
  }

  // toJSON manually for now to support the transition if needed for PUT/POST
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'property_type': type,
      'price': price,
      'latitude': latitude,
      'longitude': longitude,
      'location': address,
      'features': {
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'floor': floor,
      },
      'surface_area': squareMeters,
      'is_verified': isVerified,
    };
  }
}

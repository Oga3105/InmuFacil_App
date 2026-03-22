import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/env_config.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_type.dart';

final myPropertiesProvider =
    AsyncNotifierProvider<MyPropertiesNotifier, List<Property>>(
  MyPropertiesNotifier.new,
);

class MyPropertiesNotifier extends AsyncNotifier<List<Property>> {
  final _storage = const FlutterSecureStorage();
  late Dio _dio;

  @override
  Future<List<Property>> build() async {
    _dio = Dio(BaseOptions(baseUrl: EnvConfig.apiBaseUrl));
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    return _fetchMyProperties();
  }

  Future<List<Property>> _fetchMyProperties() async {
    final resp = await _dio.get('/properties/me/all');
    final List<dynamic> data = resp.data is List ? resp.data : [];
    return data.map((item) => _mapProperty(item as Map<String, dynamic>)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchMyProperties);
  }

  Future<void> updateStatus(String propertyId, String newStatus) async {
    // Re-read token on every authenticated call (build() may have run before login)
    final token = await _storage.read(key: 'auth_token');
    if (token != null) _dio.options.headers['Authorization'] = 'Bearer $token';
    await _dio.patch('/properties/$propertyId/status', data: {'status': newStatus});
    await refresh();
  }

  Future<void> deleteProperty(String propertyId) async {
    await _dio.delete('/properties/$propertyId');
    await refresh();
  }

  Property _mapProperty(Map<String, dynamic> data) {
    final features = data['features'] as Map<String, dynamic>? ?? {};

    PropertyType propType = PropertyType.piso;
    final typeStr = data['property_type'] as String?;
    if (typeStr != null) {
      propType = PropertyType.values.firstWhere(
        (t) => t.backendValue == typeStr,
        orElse: () => PropertyType.piso,
      );
    }

    double lat = ((data['latitude'] ?? 0) as num).toDouble();
    double lng = ((data['longitude'] ?? 0) as num).toDouble();
    if (lat == 0.0 && lng == 0.0) {
      final locStr = data['location'] as String? ?? '';
      if (locStr.contains(',')) {
        final parts = locStr.split(',');
        if (parts.length == 2) {
          lat = double.tryParse(parts[0].trim()) ?? 0.0;
          lng = double.tryParse(parts[1].trim()) ?? 0.0;
        }
      }
    }

    final mediaList = data['media'] as List<dynamic>? ?? [];
    final staticBase = EnvConfig.apiBaseUrl.replaceAll(RegExp(r'/api/v\d+/?$'), '');
    final images = mediaList
        .cast<Map<String, dynamic>>()
        .where((m) => m['media_type'] == 'image')
        .map((m) {
          final path = (m['file_path'] as String?) ?? (m['url'] as String?) ?? '';
          if (path.isEmpty) return '';
          if (path.startsWith('http')) return path;
          return '$staticBase/${path.startsWith('/') ? path.substring(1) : path}';
        })
        .where((url) => url.isNotEmpty)
        .toList();

    return Property(
      id: (data['id'] ?? '').toString(),
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: propType,
      price: ((data['price'] ?? 0) as num).toDouble(),
      location: LatLng(lat, lng),
      address: data['location'] as String? ?? '',
      bedrooms: (features['bedrooms'] as int?) ?? 0,
      bathrooms: (features['bathrooms'] as int?) ?? 0,
      floor: data['floor'] as String?,
      squareMeters: ((data['surface_area'] ?? features['surface'] ?? 0) as num).toDouble(),
      images: images,
      isVerified: false,
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updated_at'] as String? ?? '') ?? DateTime.now(),
      status: data['status'] as String?,
      ownerId: (data['seller_id'] ?? data['owner_id'])?.toString(),
      ownerName: data['owner_name'] as String?,
      ownerIsVerified: data['owner_is_verified'] as bool? ?? false,
      ownerPhotoUrl: data['owner_photo_url'] as String?,
      hideExactLocation: data['hide_exact_location'] as bool? ?? false,
    );
  }
}

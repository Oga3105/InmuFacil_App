import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/property_type.dart';

const String _kApiBaseUrl = 'http://localhost:8000/api/v1';

/// Max photos per listing and max file size (5 MB)
const int kMaxPhotos = 50;
const int kMaxPhotoBytes = 5 * 1024 * 1024; // 5 MB

// ---------------------------------------------------------------------------
// Enums & Data classes
// ---------------------------------------------------------------------------

enum PropertyFormStatus {
  idle,
  loadingForEdit,
  submitting,
  savingDraft,
  uploadingImages,
  success,
  error,
}

class PropertyMediaItem {
  const PropertyMediaItem({
    required this.localId,
    this.xFile,
    this.previewBytes,
    this.remoteUrl,
    this.remoteMediaId,
    this.markedForDeletion = false,
  });

  final String localId;
  final XFile? xFile;
  final Uint8List? previewBytes; // web preview
  final String? remoteUrl;       // edit mode remote image
  final int? remoteMediaId;
  final bool markedForDeletion;

  bool get isLocal => xFile != null;
  bool get isRemote => remoteUrl != null;

  PropertyMediaItem copyWith({
    String? localId,
    XFile? xFile,
    Uint8List? previewBytes,
    String? remoteUrl,
    int? remoteMediaId,
    bool? markedForDeletion,
  }) {
    return PropertyMediaItem(
      localId: localId ?? this.localId,
      xFile: xFile ?? this.xFile,
      previewBytes: previewBytes ?? this.previewBytes,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      remoteMediaId: remoteMediaId ?? this.remoteMediaId,
      markedForDeletion: markedForDeletion ?? this.markedForDeletion,
    );
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class PropertyFormState {
  const PropertyFormState({
    this.currentStep = 0,
    // Step 1
    this.selectedType,
    this.addressText = '',
    this.selectedLocation,
    this.floorText = '',
    this.hideExactLocation = false,
    // Structured address
    this.streetText = '',
    this.streetNumberText = '',
    this.cityText = '',
    this.provinceText = '',
    this.postalCodeText = '',
    this.isGeocodingAddress = false,
    // Step 2
    this.priceText = '',
    this.surfaceText = '',
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.titleText = '',
    this.descriptionText = '',
    // Step 3
    this.mediaItems = const [],
    this.hasLift = false,
    this.hasGarage = false,
    this.hasPool = false,
    this.hasTerrace = false,
    this.hasGarden = false,
    this.hasAC = false,
    this.hasHeating = false,
    this.hasStorage = false,
    this.hasWardrobes = false,
    this.hasExterior = false,
    this.hasAccessibility = false,
    // Meta
    this.status = PropertyFormStatus.idle,
    this.errorMessage,
    this.successPropertyId,
    this.editingPropertyId,
    // Validation errors
    this.step1Error,
    this.step2Error,
    this.step3Error,
  });

  final int currentStep;
  // Step 1
  final PropertyType? selectedType;
  final String addressText;
  final LatLng? selectedLocation;
  final String floorText;
  final bool hideExactLocation;
  // Structured address
  final String streetText;
  final String streetNumberText;
  final String cityText;
  final String provinceText;
  final String postalCodeText;
  final bool isGeocodingAddress;
  // Step 2
  final String priceText;
  final String surfaceText;
  final int bedrooms;
  final int bathrooms;
  final String titleText;
  final String descriptionText;
  // Step 3
  final List<PropertyMediaItem> mediaItems;
  final bool hasLift;
  final bool hasGarage;
  final bool hasPool;
  final bool hasTerrace;
  final bool hasGarden;
  final bool hasAC;
  final bool hasHeating;
  final bool hasStorage;
  final bool hasWardrobes;
  final bool hasExterior;
  final bool hasAccessibility;
  // Meta
  final PropertyFormStatus status;
  final String? errorMessage;
  final String? successPropertyId;
  final String? editingPropertyId;
  // Validation
  final String? step1Error;
  final String? step2Error;
  final String? step3Error;

  bool get isEditMode => editingPropertyId != null;

  /// Photos not marked for deletion
  List<PropertyMediaItem> get visibleMedia =>
      mediaItems.where((m) => !m.markedForDeletion).toList();

  int get remainingPhotoSlots => kMaxPhotos - visibleMedia.length;

  PropertyFormState copyWith({
    int? currentStep,
    PropertyType? selectedType,
    bool clearSelectedType = false,
    String? addressText,
    LatLng? selectedLocation,
    bool clearSelectedLocation = false,
    String? floorText,
    bool? hideExactLocation,
    String? streetText,
    String? streetNumberText,
    String? cityText,
    String? provinceText,
    String? postalCodeText,
    bool? isGeocodingAddress,
    String? priceText,
    String? surfaceText,
    int? bedrooms,
    int? bathrooms,
    String? titleText,
    String? descriptionText,
    List<PropertyMediaItem>? mediaItems,
    bool? hasLift,
    bool? hasGarage,
    bool? hasPool,
    bool? hasTerrace,
    bool? hasGarden,
    bool? hasAC,
    bool? hasHeating,
    bool? hasStorage,
    bool? hasWardrobes,
    bool? hasExterior,
    bool? hasAccessibility,
    PropertyFormStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successPropertyId,
    String? editingPropertyId,
    bool clearEditingPropertyId = false,
    String? step1Error,
    bool clearStep1Error = false,
    String? step2Error,
    bool clearStep2Error = false,
    String? step3Error,
    bool clearStep3Error = false,
  }) {
    return PropertyFormState(
      currentStep: currentStep ?? this.currentStep,
      selectedType:
          clearSelectedType ? null : (selectedType ?? this.selectedType),
      addressText: addressText ?? this.addressText,
      selectedLocation: clearSelectedLocation
          ? null
          : (selectedLocation ?? this.selectedLocation),
      floorText: floorText ?? this.floorText,
      hideExactLocation: hideExactLocation ?? this.hideExactLocation,
      streetText: streetText ?? this.streetText,
      streetNumberText: streetNumberText ?? this.streetNumberText,
      cityText: cityText ?? this.cityText,
      provinceText: provinceText ?? this.provinceText,
      postalCodeText: postalCodeText ?? this.postalCodeText,
      isGeocodingAddress: isGeocodingAddress ?? this.isGeocodingAddress,
      priceText: priceText ?? this.priceText,
      surfaceText: surfaceText ?? this.surfaceText,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      titleText: titleText ?? this.titleText,
      descriptionText: descriptionText ?? this.descriptionText,
      mediaItems: mediaItems ?? this.mediaItems,
      hasLift: hasLift ?? this.hasLift,
      hasGarage: hasGarage ?? this.hasGarage,
      hasPool: hasPool ?? this.hasPool,
      hasTerrace: hasTerrace ?? this.hasTerrace,
      hasGarden: hasGarden ?? this.hasGarden,
      hasAC: hasAC ?? this.hasAC,
      hasHeating: hasHeating ?? this.hasHeating,
      hasStorage: hasStorage ?? this.hasStorage,
      hasWardrobes: hasWardrobes ?? this.hasWardrobes,
      hasExterior: hasExterior ?? this.hasExterior,
      hasAccessibility: hasAccessibility ?? this.hasAccessibility,
      status: status ?? this.status,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successPropertyId: successPropertyId ?? this.successPropertyId,
      editingPropertyId: clearEditingPropertyId
          ? null
          : (editingPropertyId ?? this.editingPropertyId),
      step1Error: clearStep1Error ? null : (step1Error ?? this.step1Error),
      step2Error: clearStep2Error ? null : (step2Error ?? this.step2Error),
      step3Error: clearStep3Error ? null : (step3Error ?? this.step3Error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class PropertyFormNotifier extends Notifier<PropertyFormState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio _dio;
  final ImagePicker _picker = ImagePicker();
  int _mediaIdCounter = 0;

  @override
  PropertyFormState build() {
    _dio = Dio(BaseOptions(
      baseUrl: _kApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));
    return const PropertyFormState();
  }

  Future<void> _ensureAuth() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  bool nextStep() {
    if (!_validateCurrentStep()) return false;
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
    return true;
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  // ---------------------------------------------------------------------------
  // Step 1 mutators
  // ---------------------------------------------------------------------------

  void selectType(PropertyType type) {
    state = state.copyWith(selectedType: type, clearStep1Error: true);
  }

  void setAddress(String address) {
    state = state.copyWith(addressText: address, clearStep1Error: true);
  }

  void setLocation(LatLng location) {
    final coordStr =
        '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
    state = state.copyWith(
      selectedLocation: location,
      addressText: coordStr,
      clearStep1Error: true,
    );
    _reverseGeocode(location);
  }

  void setFloor(String floor) {
    state = state.copyWith(floorText: floor);
  }

  void toggleHideExactLocation() {
    state = state.copyWith(hideExactLocation: !state.hideExactLocation);
  }

  void setStreet(String v) => state = state.copyWith(streetText: v, clearStep1Error: true);
  void setStreetNumber(String v) => state = state.copyWith(streetNumberText: v);
  void setCity(String v) => state = state.copyWith(cityText: v, clearStep1Error: true);
  void setProvince(String v) => state = state.copyWith(provinceText: v);
  void setPostalCode(String v) => state = state.copyWith(postalCodeText: v);

  /// Forward geocode: address fields → LatLng via Nominatim
  Future<void> geocodeAddress() async {
    final street = state.streetText.trim();
    final city = state.cityText.trim();
    if (street.isEmpty || city.isEmpty) return;

    final query = [
      street,
      if (state.streetNumberText.trim().isNotEmpty) state.streetNumberText.trim(),
      city,
      if (state.provinceText.trim().isNotEmpty) state.provinceText.trim(),
      if (state.postalCodeText.trim().isNotEmpty) state.postalCodeText.trim(),
      'España',
    ].join(', ');

    state = state.copyWith(isGeocodingAddress: true);
    try {
      final dio = Dio();
      final resp = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 1,
          'addressdetails': 1,
        },
        options: Options(headers: {'User-Agent': 'InmuFacil/1.0'}),
      );
      final results = resp.data as List<dynamic>;
      if (results.isNotEmpty) {
        final lat = double.tryParse(results[0]['lat'] as String? ?? '') ?? 0;
        final lng = double.tryParse(results[0]['lon'] as String? ?? '') ?? 0;
        if (lat != 0 || lng != 0) {
          state = state.copyWith(
            selectedLocation: LatLng(lat, lng),
            addressText: query,
            isGeocodingAddress: false,
          );
          return;
        }
      }
    } catch (_) {}
    state = state.copyWith(isGeocodingAddress: false);
  }

  /// Reverse geocode: LatLng → address fields via Nominatim
  Future<void> _reverseGeocode(LatLng location) async {
    state = state.copyWith(isGeocodingAddress: true);
    try {
      final dio = Dio();
      final resp = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': location.latitude,
          'lon': location.longitude,
          'format': 'json',
          'addressdetails': 1,
        },
        options: Options(headers: {'User-Agent': 'InmuFacil/1.0'}),
      );
      final data = resp.data as Map<String, dynamic>;
      final addr = data['address'] as Map<String, dynamic>? ?? {};

      final road = (addr['road'] ?? addr['pedestrian'] ?? addr['footway'] ?? '') as String;
      final houseNumber = (addr['house_number'] ?? '') as String;
      final city = (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['municipality'] ?? '') as String;
      final province = (addr['province'] ?? addr['state'] ?? '') as String;
      final postcode = (addr['postcode'] ?? '') as String;

      state = state.copyWith(
        streetText: road,
        streetNumberText: houseNumber,
        cityText: city,
        provinceText: province,
        postalCodeText: postcode,
        addressText: data['display_name'] as String? ?? state.addressText,
        isGeocodingAddress: false,
      );
    } catch (_) {
      state = state.copyWith(isGeocodingAddress: false);
    }
  }

  // ---------------------------------------------------------------------------
  // Step 2 mutators
  // ---------------------------------------------------------------------------

  void setPrice(String price) {
    state = state.copyWith(priceText: price, clearStep2Error: true);
  }

  void setSurface(String surface) {
    state = state.copyWith(surfaceText: surface, clearStep2Error: true);
  }

  void incrementBedrooms() {
    state = state.copyWith(bedrooms: state.bedrooms + 1);
  }

  void decrementBedrooms() {
    if (state.bedrooms > 0) state = state.copyWith(bedrooms: state.bedrooms - 1);
  }

  void incrementBathrooms() {
    state = state.copyWith(bathrooms: state.bathrooms + 1);
  }

  void decrementBathrooms() {
    if (state.bathrooms > 0)
      state = state.copyWith(bathrooms: state.bathrooms - 1);
  }

  void setTitle(String title) {
    state = state.copyWith(titleText: title, clearStep2Error: true);
  }

  void setDescription(String description) {
    state = state.copyWith(descriptionText: description, clearStep2Error: true);
  }

  // ---------------------------------------------------------------------------
  // Step 3 mutators
  // ---------------------------------------------------------------------------

  Future<void> pickImages() async {
    final remaining = state.remainingPhotoSlots;
    if (remaining <= 0) return;

    try {
      final List<XFile> picked = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked.isEmpty) return;

      // Limit to remaining slots
      final toAdd = picked.take(remaining).toList();
      final newItems = <PropertyMediaItem>[];

      for (final xFile in toAdd) {
        Uint8List bytes;
        try {
          bytes = await xFile.readAsBytes();
        } catch (_) {
          continue;
        }
        // Skip files over 5 MB
        if (bytes.length > kMaxPhotoBytes) continue;

        _mediaIdCounter++;
        newItems.add(PropertyMediaItem(
          localId: 'local_$_mediaIdCounter',
          xFile: xFile,
          previewBytes: kIsWeb ? bytes : null,
        ));
      }

      state = state.copyWith(
        mediaItems: [...state.mediaItems, ...newItems],
        clearStep3Error: true,
      );
    } catch (_) {
      // Picker cancellation — silently ignore
    }
  }

  void removeLocalImage(String localId) {
    final updated =
        state.mediaItems.where((m) => m.localId != localId).toList();
    state = state.copyWith(mediaItems: updated);
  }

  void markRemoteImageForDeletion(String localId) {
    final updated = state.mediaItems.map((m) {
      if (m.localId == localId) return m.copyWith(markedForDeletion: true);
      return m;
    }).toList();
    state = state.copyWith(mediaItems: updated);
  }

  void reorderMedia(int oldIndex, int newIndex) {
    final visible = state.mediaItems
        .where((m) => !m.markedForDeletion)
        .toList();
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= visible.length ||
        newIndex >= visible.length) return;
    final item = visible.removeAt(oldIndex);
    visible.insert(newIndex, item);
    final deleted =
        state.mediaItems.where((m) => m.markedForDeletion).toList();
    state = state.copyWith(mediaItems: [...visible, ...deleted]);
  }

  void toggleAmenity(String amenity) {
    switch (amenity) {
      case 'lift':
        state = state.copyWith(hasLift: !state.hasLift);
      case 'garage':
        state = state.copyWith(hasGarage: !state.hasGarage);
      case 'pool':
        state = state.copyWith(hasPool: !state.hasPool);
      case 'terrace':
        state = state.copyWith(hasTerrace: !state.hasTerrace);
      case 'garden':
        state = state.copyWith(hasGarden: !state.hasGarden);
      case 'ac':
        state = state.copyWith(hasAC: !state.hasAC);
      case 'heating':
        state = state.copyWith(hasHeating: !state.hasHeating);
      case 'storage':
        state = state.copyWith(hasStorage: !state.hasStorage);
      case 'wardrobes':
        state = state.copyWith(hasWardrobes: !state.hasWardrobes);
      case 'exterior':
        state = state.copyWith(hasExterior: !state.hasExterior);
      case 'accessibility':
        state = state.copyWith(hasAccessibility: !state.hasAccessibility);
    }
  }

  // ---------------------------------------------------------------------------
  // Load for edit
  // ---------------------------------------------------------------------------

  Future<void> loadPropertyForEdit(String propertyId) async {
    state = state.copyWith(
      status: PropertyFormStatus.loadingForEdit,
      editingPropertyId: propertyId,
      clearErrorMessage: true,
    );

    try {
      await _ensureAuth();
      final response = await _dio.get('/properties/$propertyId');
      final data = response.data as Map<String, dynamic>;
      final features = data['features'] as Map<String, dynamic>? ?? {};

      // Parse property type
      PropertyType? propType;
      final typeStr = data['property_type'] as String?;
      if (typeStr != null) {
        propType = PropertyType.values.firstWhere(
          (t) => t.backendValue == typeStr,
          orElse: () => PropertyType.piso,
        );
      }

      // Parse coordinates — backend sends latitude/longitude at top level,
      // or embedded as "lat, lng" inside the location string (see PropertyModel).
      LatLng? location;
      double lat = ((data['latitude'] ?? data['lat'] ?? 0) as num).toDouble();
      double lng = ((data['longitude'] ?? data['lng'] ?? 0) as num).toDouble();
      if (lat == 0.0 && lng == 0.0) {
        // Try parsing from location string "lat, lng"
        final locStr = data['location'] as String? ?? '';
        if (locStr.contains(',')) {
          final parts = locStr.split(',');
          if (parts.length == 2) {
            lat = double.tryParse(parts[0].trim()) ?? 0.0;
            lng = double.tryParse(parts[1].trim()) ?? 0.0;
          }
        }
      }
      if (lat != 0.0 || lng != 0.0) {
        location = LatLng(lat, lng);
      }

      // Parse media items
      final mediaList = data['media'] as List<dynamic>? ?? [];
      final mediaItems = mediaList.map<PropertyMediaItem>((m) {
        _mediaIdCounter++;
        return PropertyMediaItem(
          localId: 'remote_$_mediaIdCounter',
          remoteUrl: (m['file_path'] ?? m['url']) as String?,
          remoteMediaId: m['id'] as int?,
        );
      }).toList();

      state = state.copyWith(
        status: PropertyFormStatus.idle,
        selectedType: propType,
        addressText: data['location'] as String? ?? '',
        selectedLocation: location,
        floorText: (data['floor'] ?? features['floor'] ?? '') as String? ?? '',
        hideExactLocation: (data['hide_exact_location'] as bool?) ?? false,
        streetText: data['street'] as String? ?? '',
        streetNumberText: data['street_number'] as String? ?? '',
        cityText: data['city'] as String? ?? '',
        provinceText: data['province'] as String? ?? '',
        postalCodeText: data['postal_code'] as String? ?? '',
        priceText: (data['price'] ?? '').toString(),
        surfaceText: _formatNumeric(
            data['surface_area'] ?? features['surface'] ?? features['area']),
        bedrooms: (features['bedrooms'] as int?) ?? 1,
        bathrooms: (features['bathrooms'] as int?) ?? 1,
        titleText: data['title'] as String? ?? '',
        descriptionText: data['description'] as String? ?? '',
        mediaItems: mediaItems,
        hasLift: (features['has_lift'] as bool?) ?? false,
        hasGarage: (features['has_garage'] as bool?) ?? false,
        hasPool: (features['has_pool'] as bool?) ?? false,
        hasTerrace: (features['has_terrace'] as bool?) ?? false,
        hasGarden: (features['has_garden'] as bool?) ?? false,
        hasAC: (features['has_ac'] as bool?) ?? false,
        hasHeating: (features['has_heating'] as bool?) ?? false,
        hasStorage: (features['has_storage'] as bool?) ?? false,
        hasWardrobes: (features['has_wardrobes'] as bool?) ?? false,
        hasExterior: (features['has_exterior'] as bool?) ?? false,
        hasAccessibility: (features['has_accessibility'] as bool?) ?? false,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Error al cargar la propiedad';
      state = state.copyWith(
        status: PropertyFormStatus.error,
        errorMessage: msg is String ? msg : 'Error al cargar la propiedad',
      );
    } catch (_) {
      state = state.copyWith(
        status: PropertyFormStatus.error,
        errorMessage: 'Error inesperado al cargar la propiedad',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> submit(BuildContext context) async {
    // Validate all steps
    if (!_validateStep(0) || !_validateStep(1) || !_validateStep(2)) {
      if (state.step1Error != null) {
        state = state.copyWith(currentStep: 0);
      } else if (state.step2Error != null) {
        state = state.copyWith(currentStep: 1);
      }
      return;
    }

    state = state.copyWith(
        status: PropertyFormStatus.submitting, clearErrorMessage: true);

    try {
      await _ensureAuth();
      final body = _buildRequestBody();
      String propertyId;

      if (state.isEditMode) {
        await _dio.put('/properties/${state.editingPropertyId}', data: body);
        propertyId = state.editingPropertyId!;

        // Delete marked remote images
        for (final item in state.mediaItems) {
          if (item.markedForDeletion && item.remoteMediaId != null) {
            try {
              await _dio.delete('/properties/media/${item.remoteMediaId}');
            } catch (_) {}
          }
        }
      } else {
        final createResp = await _dio.post('/properties/', data: body);
        propertyId =
            (createResp.data['id'] ?? createResp.data['_id'] ?? '').toString();
      }

      // Upload new local images
      final localImages = state.mediaItems
          .where((m) => m.isLocal && !m.markedForDeletion)
          .toList();
      if (localImages.isNotEmpty) {
        state = state.copyWith(status: PropertyFormStatus.uploadingImages);
        final formData = FormData();
        for (final item in localImages) {
          if (kIsWeb) {
            final bytes =
                item.previewBytes ?? await item.xFile!.readAsBytes();
            formData.files.add(MapEntry(
              'files',
              MultipartFile.fromBytes(bytes, filename: item.xFile!.name),
            ));
          } else {
            formData.files.add(MapEntry(
              'files',
              await MultipartFile.fromFile(item.xFile!.path,
                  filename: item.xFile!.name),
            ));
          }
        }
        await _dio.post('/properties/$propertyId/media/upload', data: formData);
      }

      state = state.copyWith(
        status: PropertyFormStatus.success,
        successPropertyId: propertyId,
      );

      if (context.mounted) {
        context.pushReplacement('/property/$propertyId');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        state = state.copyWith(
          status: PropertyFormStatus.error,
          errorMessage: '__session_expired__',
        );
        return;
      }
      final msg =
          e.response?.data?['detail'] ?? 'Error al publicar la propiedad';
      state = state.copyWith(
        status: PropertyFormStatus.error,
        errorMessage: msg is String ? msg : 'Error al publicar la propiedad',
      );
    } catch (_) {
      state = state.copyWith(
        status: PropertyFormStatus.error,
        errorMessage: 'Error inesperado al publicar la propiedad',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Save Draft
  // ---------------------------------------------------------------------------

  Future<void> saveDraft(BuildContext context) async {
    if (state.selectedType == null) {
      state = state.copyWith(
        step1Error: 'Selecciona el tipo de propiedad para guardar el borrador',
        currentStep: 0,
      );
      return;
    }

    state = state.copyWith(
      status: PropertyFormStatus.savingDraft,
      clearErrorMessage: true,
    );

    try {
      await _ensureAuth();

      final body = <String, dynamic>{
        'status': 'draft',
        'property_type': state.selectedType?.backendValue ?? 'piso',
        'operation_type': 'venta',
        if (state.titleText.isNotEmpty) 'title': state.titleText,
        if (state.descriptionText.isNotEmpty) 'description': state.descriptionText,
        if (state.priceText.isNotEmpty) 'price': double.tryParse(state.priceText) ?? 0,
        if (state.surfaceText.isNotEmpty) 'surface_area': double.tryParse(state.surfaceText) ?? 0,
        if (state.addressText.isNotEmpty) 'location': _buildLocationString(),
        if (state.streetText.isNotEmpty) 'street': state.streetText,
        if (state.streetNumberText.isNotEmpty) 'street_number': state.streetNumberText,
        if (state.floorText.isNotEmpty) 'floor': state.floorText,
        if (state.cityText.isNotEmpty) 'city': state.cityText,
        if (state.provinceText.isNotEmpty) 'province': state.provinceText,
        if (state.postalCodeText.isNotEmpty) 'postal_code': state.postalCodeText,
        'hide_exact_location': state.hideExactLocation,
        if (state.selectedLocation != null) 'latitude': state.selectedLocation!.latitude,
        if (state.selectedLocation != null) 'longitude': state.selectedLocation!.longitude,
      };

      String propertyId;
      if (state.isEditMode) {
        // In edit mode: just mark the existing property as draft
        await _dio.patch(
          '/properties/${state.editingPropertyId}/status',
          data: {'status': 'draft'},
        );
        propertyId = state.editingPropertyId!;
      } else {
        final resp = await _dio.post('/properties/draft', data: body);
        propertyId = (resp.data['id'] ?? resp.data['_id'] ?? '').toString();
      }

      state = state.copyWith(
        status: PropertyFormStatus.success,
        successPropertyId: propertyId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Borrador guardado correctamente'),
            backgroundColor: Color(0xFFCA8A04),
          ),
        );
        context.go('/profile');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        state = state.copyWith(
          status: PropertyFormStatus.error,
          errorMessage: '__session_expired__',
        );
        return;
      }
      final msg = e.response?.data?['detail'] ?? 'Error al guardar el borrador';
      state = state.copyWith(
        status: PropertyFormStatus.error,
        errorMessage: msg is String ? msg : 'Error al guardar el borrador',
      );
    } catch (_) {
      state = state.copyWith(
        status: PropertyFormStatus.error,
        errorMessage: 'Error inesperado al guardar el borrador',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _buildLocationString() {
    final parts = <String>[
      if (state.streetText.isNotEmpty) state.streetText,
      if (state.streetNumberText.isNotEmpty) state.streetNumberText,
      if (state.cityText.isNotEmpty) state.cityText,
      if (state.postalCodeText.isNotEmpty) state.postalCodeText,
    ];
    return parts.isNotEmpty ? parts.join(', ') : state.addressText;
  }

  Map<String, dynamic> _buildRequestBody() {
    final price = double.tryParse(state.priceText) ?? 0;
    final surface = double.tryParse(state.surfaceText) ?? 0;

    return {
      'title': state.titleText,
      'description': state.descriptionText,
      'property_type': state.selectedType?.backendValue ?? 'piso',
      'operation_type': 'venta',
      'location': _buildLocationString(),
      'street': state.streetText.isEmpty ? null : state.streetText,
      'street_number': state.streetNumberText.isEmpty ? null : state.streetNumberText,
      'floor': state.floorText.isEmpty ? null : state.floorText,
      'city': state.cityText.isEmpty ? null : state.cityText,
      'province': state.provinceText.isEmpty ? null : state.provinceText,
      'postal_code': state.postalCodeText.isEmpty ? null : state.postalCodeText,
      'price': price,
      'surface_area': surface,
      'hide_exact_location': state.hideExactLocation,
      'latitude': state.selectedLocation?.latitude,
      'longitude': state.selectedLocation?.longitude,
      'features': {
        'bedrooms': state.bedrooms,
        'bathrooms': state.bathrooms,
        'has_lift': state.hasLift,
        'has_garage': state.hasGarage,
        'has_pool': state.hasPool,
        'has_terrace': state.hasTerrace,
        'has_garden': state.hasGarden,
        'has_ac': state.hasAC,
        'has_heating': state.hasHeating,
        'has_storage': state.hasStorage,
        'has_wardrobes': state.hasWardrobes,
        'has_exterior': state.hasExterior,
        'has_accessibility': state.hasAccessibility,
      },
    };
  }

  bool _validateCurrentStep() => _validateStep(state.currentStep);

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (state.selectedType == null) {
          state = state.copyWith(step1Error: 'Selecciona el tipo de propiedad');
          return false;
        }
        if (state.streetText.length < 3) {
          state = state.copyWith(step1Error: 'Introduce el nombre de la calle (mínimo 3 caracteres)');
          return false;
        }
        if (state.cityText.length < 2) {
          state = state.copyWith(step1Error: 'Introduce la ciudad (mínimo 2 caracteres)');
          return false;
        }
        if (state.selectedLocation == null) {
          state = state.copyWith(step1Error: 'Toca el mapa o escribe la dirección para fijar la ubicación GPS');
          return false;
        }
        state = state.copyWith(clearStep1Error: true);
        return true;
      case 1:
        final price = double.tryParse(state.priceText) ?? 0;
        final surface = double.tryParse(state.surfaceText) ?? 0;
        if (price <= 0) {
          state = state.copyWith(step2Error: 'Introduce un precio válido');
          return false;
        }
        if (surface <= 0) {
          state =
              state.copyWith(step2Error: 'Introduce una superficie válida');
          return false;
        }
        if (state.titleText.length < 5) {
          state = state.copyWith(
              step2Error: 'El título debe tener al menos 5 caracteres');
          return false;
        }
        if (state.descriptionText.length < 20) {
          state = state.copyWith(
              step2Error:
                  'La descripción debe tener al menos 20 caracteres');
          return false;
        }
        state = state.copyWith(clearStep2Error: true);
        return true;
      case 2:
        if (state.visibleMedia.isEmpty) {
          state = state.copyWith(step3Error: 'Añade al menos una foto');
          return false;
        }
        state = state.copyWith(clearStep3Error: true);
        return true;
      default:
        return true;
    }
  }

  void reset() {
    state = const PropertyFormState();
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Formats a numeric value from the backend as a clean string (no trailing .0)
String _formatNumeric(dynamic val) {
  if (val == null) return '';
  if (val is int) return val.toString();
  if (val is double) {
    return val == val.truncateToDouble()
        ? val.truncate().toString()
        : val.toString();
  }
  return val.toString();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final propertyFormProvider =
    NotifierProvider<PropertyFormNotifier, PropertyFormState>(
        PropertyFormNotifier.new);

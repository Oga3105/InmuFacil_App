import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

const String _kApiBaseUrl = 'http://localhost:8000/api/v1';

enum VerificationStep { documentType, documentScan, selfie, review }
enum DocumentType { dni, nie, pasaporte }
enum UploadStatus { idle, picking, success, error }

class VerificationState {

  VerificationState({
    this.currentStepIndex = 0,
    this.selectedDocumentType,
    this.frontImage,
    this.backImage,
    this.selfieImage,
    this.frontBytes,
    this.backBytes,
    this.selfieBytes,
    this.frontXFile,
    this.backXFile,
    this.selfieXFile,
    this.isLoading = false,
    this.frontStatus = UploadStatus.idle,
    this.backStatus = UploadStatus.idle,
    this.selfieStatus = UploadStatus.idle,
    this.kycStatus,
    this.rejectionReason,
    this.uploadDate,
    this.errorMessage,
    this.submissionSuccess = false,
  });
  final int currentStepIndex;
  final DocumentType? selectedDocumentType;
  // Native (mobile/desktop)
  final File? frontImage;
  final File? backImage;
  final File? selfieImage;
  // Web preview bytes
  final Uint8List? frontBytes;
  final Uint8List? backBytes;
  final Uint8List? selfieBytes;
  // XFile kept for multipart upload on all platforms
  final XFile? frontXFile;
  final XFile? backXFile;
  final XFile? selfieXFile;
  final bool isLoading;
  final UploadStatus frontStatus;
  final UploadStatus backStatus;
  final UploadStatus selfieStatus;
  final String? kycStatus;
  final String? rejectionReason;
  final DateTime? uploadDate;
  final String? errorMessage;
  final bool submissionSuccess;

  bool get hasFront => frontBytes != null || frontImage != null;
  bool get hasBack => backBytes != null || backImage != null;
  bool get hasSelfie => selfieBytes != null || selfieImage != null;

  VerificationState copyWith({
    int? currentStepIndex,
    DocumentType? selectedDocumentType,
    File? frontImage,
    File? backImage,
    File? selfieImage,
    Uint8List? frontBytes,
    Uint8List? backBytes,
    Uint8List? selfieBytes,
    XFile? frontXFile,
    XFile? backXFile,
    XFile? selfieXFile,
    bool? isLoading,
    UploadStatus? frontStatus,
    UploadStatus? backStatus,
    UploadStatus? selfieStatus,
    String? kycStatus,
    String? rejectionReason,
    DateTime? uploadDate,
    String? errorMessage,
    bool? submissionSuccess,
  }) {
    return VerificationState(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      selectedDocumentType: selectedDocumentType ?? this.selectedDocumentType,
      frontImage: frontImage ?? this.frontImage,
      backImage: backImage ?? this.backImage,
      selfieImage: selfieImage ?? this.selfieImage,
      frontBytes: frontBytes ?? this.frontBytes,
      backBytes: backBytes ?? this.backBytes,
      selfieBytes: selfieBytes ?? this.selfieBytes,
      frontXFile: frontXFile ?? this.frontXFile,
      backXFile: backXFile ?? this.backXFile,
      selfieXFile: selfieXFile ?? this.selfieXFile,
      isLoading: isLoading ?? this.isLoading,
      frontStatus: frontStatus ?? this.frontStatus,
      backStatus: backStatus ?? this.backStatus,
      selfieStatus: selfieStatus ?? this.selfieStatus,
      kycStatus: kycStatus ?? this.kycStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      uploadDate: uploadDate ?? this.uploadDate,
      errorMessage: errorMessage,
      submissionSuccess: submissionSuccess ?? this.submissionSuccess,
    );
  }
}

class VerificationNotifier extends Notifier<VerificationState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio _dio;

  @override
  VerificationState build() {
    _dio = Dio(BaseOptions(
      baseUrl: _kApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));
    return VerificationState();
  }

  Future<void> _ensureAuth() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  final ImagePicker _picker = ImagePicker();

  void selectDocumentType(DocumentType type) {
    state = state.copyWith(selectedDocumentType: type);
  }

  void setDocumentType(DocumentType type) {
    state = state.copyWith(selectedDocumentType: type);
    nextStep();
  }

  void nextStep() {
    if (state.currentStepIndex < 3) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex + 1);
    }
  }

  void prevStep() {
    if (state.currentStepIndex > 0) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex - 1);
    }
  }

  Future<void> pickFrontImage() async {
    state = state.copyWith(frontStatus: UploadStatus.picking);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          state = state.copyWith(
            frontBytes: bytes,
            frontXFile: image,
            frontStatus: UploadStatus.success,
          );
        } else {
          state = state.copyWith(
            frontImage: File(image.path),
            frontXFile: image,
            frontStatus: UploadStatus.success,
          );
        }
      } else {
        state = state.copyWith(frontStatus: UploadStatus.idle);
      }
    } catch (e) {
      state = state.copyWith(frontStatus: UploadStatus.error);
    }
  }

  Future<void> pickBackImage() async {
    state = state.copyWith(backStatus: UploadStatus.picking);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          state = state.copyWith(
            backBytes: bytes,
            backXFile: image,
            backStatus: UploadStatus.success,
          );
        } else {
          state = state.copyWith(
            backImage: File(image.path),
            backXFile: image,
            backStatus: UploadStatus.success,
          );
        }
      } else {
        state = state.copyWith(backStatus: UploadStatus.idle);
      }
    } catch (e) {
      state = state.copyWith(backStatus: UploadStatus.error);
    }
  }

  Future<void> pickSelfie() async {
    state = state.copyWith(selfieStatus: UploadStatus.picking);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          state = state.copyWith(
            selfieBytes: bytes,
            selfieXFile: image,
            selfieStatus: UploadStatus.success,
          );
        } else {
          state = state.copyWith(
            selfieImage: File(image.path),
            selfieXFile: image,
            selfieStatus: UploadStatus.success,
          );
        }
      } else {
        state = state.copyWith(selfieStatus: UploadStatus.idle);
      }
    } catch (e) {
      state = state.copyWith(selfieStatus: UploadStatus.error);
    }
  }

  Future<bool> submitVerification() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _ensureAuth();

      final docType = state.selectedDocumentType?.name ?? 'dni';
      final formData = FormData.fromMap({
        'document_type': docType,
      });

      if (kIsWeb) {
        if (state.frontXFile != null) {
          final bytes = await state.frontXFile!.readAsBytes();
          formData.files.add(MapEntry(
            'front',
            MultipartFile.fromBytes(bytes, filename: 'front.jpg'),
          ));
        }
        if (state.backXFile != null) {
          final bytes = await state.backXFile!.readAsBytes();
          formData.files.add(MapEntry(
            'back',
            MultipartFile.fromBytes(bytes, filename: 'back.jpg'),
          ));
        }
        if (state.selfieXFile != null) {
          final bytes = await state.selfieXFile!.readAsBytes();
          formData.files.add(MapEntry(
            'selfie',
            MultipartFile.fromBytes(bytes, filename: 'selfie.jpg'),
          ));
        }
      } else {
        if (state.frontImage != null) {
          formData.files.add(MapEntry(
            'front',
            await MultipartFile.fromFile(state.frontImage!.path, filename: 'front.jpg'),
          ));
        }
        if (state.backImage != null) {
          formData.files.add(MapEntry(
            'back',
            await MultipartFile.fromFile(state.backImage!.path, filename: 'back.jpg'),
          ));
        }
        if (state.selfieImage != null) {
          formData.files.add(MapEntry(
            'selfie',
            await MultipartFile.fromFile(state.selfieImage!.path, filename: 'selfie.jpg'),
          ));
        }
      }

      await _dio.post('/kyc/upload', data: formData);

      state = state.copyWith(
        isLoading: false,
        submissionSuccess: true,
        kycStatus: 'pending',
      );
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Error al enviar documentos';
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg is String ? msg : 'Error al enviar documentos',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado al enviar verificación',
      );
      return false;
    }
  }

  Future<void> fetchKycStatus() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _ensureAuth();
      final response = await _dio.get('/kyc/status');
      final data = response.data;

      state = state.copyWith(
        isLoading: false,
        kycStatus: data['status'],
        rejectionReason: data['rejection_reason'],
        uploadDate: data['upload_date'] != null
            ? DateTime.tryParse(data['upload_date'])
            : null,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '__session_expired__',
        );
        return;
      }
      final msg = e.response?.data?['detail'] ?? 'Error al consultar estado';
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg is String ? msg : 'Error al consultar estado',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado',
      );
    }
  }

  /// Called when the camera dialog captures a photo directly as bytes.
  void setSelfieFromBytes(Uint8List bytes) {
    state = state.copyWith(
      selfieBytes: bytes,
      selfieStatus: UploadStatus.success,
    );
  }

  void reset() {
    state = VerificationState();
  }
}

final verificationProvider =
    NotifierProvider<VerificationNotifier, VerificationState>(
        VerificationNotifier.new);

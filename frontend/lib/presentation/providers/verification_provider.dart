import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/env_config.dart';
import '../../core/network/auth_interceptor.dart';

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
    // Document number confirmation state
    this.isExtractingDocNumber = false,
    this.extractedDocNumber,
    this.documentNumberConfirmed = false,
    this.docReadAttempts = 0,
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

  // OCR pre-check state
  final bool isExtractingDocNumber;
  final String? extractedDocNumber;
  final bool documentNumberConfirmed;
  final int docReadAttempts;

  bool get hasFront => frontBytes != null || frontImage != null;
  bool get hasBack => backBytes != null || backImage != null;
  bool get hasSelfie => selfieBytes != null || selfieImage != null;
  bool get isDocumentScanDone => hasFront && hasBack && documentNumberConfirmed;

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
    bool? isExtractingDocNumber,
    Object? extractedDocNumber = _sentinel,
    bool? documentNumberConfirmed,
    int? docReadAttempts,
    // Nullability helpers for clearing images
    bool clearFrontImage = false,
    bool clearBackImage = false,
  }) {
    return VerificationState(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      selectedDocumentType: selectedDocumentType ?? this.selectedDocumentType,
      frontImage: clearFrontImage ? null : (frontImage ?? this.frontImage),
      backImage: clearBackImage ? null : (backImage ?? this.backImage),
      selfieImage: selfieImage ?? this.selfieImage,
      frontBytes: clearFrontImage ? null : (frontBytes ?? this.frontBytes),
      backBytes: clearBackImage ? null : (backBytes ?? this.backBytes),
      selfieBytes: selfieBytes ?? this.selfieBytes,
      frontXFile: clearFrontImage ? null : (frontXFile ?? this.frontXFile),
      backXFile: clearBackImage ? null : (backXFile ?? this.backXFile),
      selfieXFile: selfieXFile ?? this.selfieXFile,
      isLoading: isLoading ?? this.isLoading,
      frontStatus: clearFrontImage ? UploadStatus.idle : (frontStatus ?? this.frontStatus),
      backStatus: clearBackImage ? UploadStatus.idle : (backStatus ?? this.backStatus),
      selfieStatus: selfieStatus ?? this.selfieStatus,
      kycStatus: kycStatus ?? this.kycStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      uploadDate: uploadDate ?? this.uploadDate,
      errorMessage: errorMessage,
      submissionSuccess: submissionSuccess ?? this.submissionSuccess,
      isExtractingDocNumber: isExtractingDocNumber ?? this.isExtractingDocNumber,
      extractedDocNumber: extractedDocNumber == _sentinel
          ? this.extractedDocNumber
          : extractedDocNumber as String?,
      documentNumberConfirmed: documentNumberConfirmed ?? this.documentNumberConfirmed,
      docReadAttempts: docReadAttempts ?? this.docReadAttempts,
    );
  }
}

// Sentinel for nullable copyWith fields
const Object _sentinel = Object();

class VerificationNotifier extends Notifier<VerificationState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio _dio;

  @override
  VerificationState build() {
    _dio = Dio(BaseOptions(
      baseUrl: EnvConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _dio.interceptors.add(AuthInterceptor());
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

  /// Calls the backend to extract the document number from the front (and back) images.
  /// Sending the back image improves accuracy: Spanish DNI/NIE have an MRZ on the back
  /// that is more reliably OCR-readable than the printed number on the front.
  /// Returns the result map: {"doc_number": String?, "readable": bool}
  /// or null if the request failed unexpectedly.
  Future<Map<String, dynamic>?> extractDocNumber() async {
    state = state.copyWith(isExtractingDocNumber: true, errorMessage: null);
    try {
      await _ensureAuth();

      // Capture current state once after the async _ensureAuth to avoid TOCTOU
      final currentState = state;
      final docType = currentState.selectedDocumentType?.name ?? 'dni';
      final formData = FormData.fromMap({'document_type': docType});

      if (kIsWeb) {
        final frontXFile = currentState.frontXFile;
        if (frontXFile == null) {
          state = state.copyWith(isExtractingDocNumber: false);
          return null;
        }
        final frontBytes = await frontXFile.readAsBytes();
        formData.files.add(MapEntry(
          'front',
          MultipartFile.fromBytes(frontBytes, filename: 'front.jpg'),
        ));
        // Also send back for MRZ-based OCR
        final backXFile = currentState.backXFile;
        if (backXFile != null) {
          final backBytes = await backXFile.readAsBytes();
          formData.files.add(MapEntry(
            'back',
            MultipartFile.fromBytes(backBytes, filename: 'back.jpg'),
          ));
        }
      } else {
        final frontImage = currentState.frontImage;
        if (frontImage == null) {
          state = state.copyWith(isExtractingDocNumber: false);
          return null;
        }
        formData.files.add(MapEntry(
          'front',
          await MultipartFile.fromFile(frontImage.path, filename: 'front.jpg'),
        ));
        // Also send back for MRZ-based OCR
        final backImage = currentState.backImage;
        if (backImage != null) {
          formData.files.add(MapEntry(
            'back',
            await MultipartFile.fromFile(backImage.path, filename: 'back.jpg'),
          ));
        }
      }

      final response = await _dio.post('/kyc/extract-doc-number', data: formData);
      final data = response.data as Map<String, dynamic>;
      final docNumber = data['doc_number'] as String?;
      state = state.copyWith(
        isExtractingDocNumber: false,
        extractedDocNumber: docNumber,
      );
      return data;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      state = state.copyWith(
        isExtractingDocNumber: false,
        errorMessage: detail is String ? detail : 'kyc.error_reading_doc',
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isExtractingDocNumber: false,
        errorMessage: 'kyc.error_reading_doc',
      );
      return null;
    }
  }

  /// Called when the user confirms the extracted document number is correct.
  /// [confirmedNumber] is the OCR number or the manually-entered validated one.
  void confirmDocumentNumber(String confirmedNumber) {
    state = state.copyWith(
      documentNumberConfirmed: true,
      extractedDocNumber: confirmedNumber,
    );
  }

  /// Called when the user rejects the extracted number.
  /// Increments attempt count. After 2 rejections, resets document images.
  /// Returns true if images were reset (max attempts reached).
  bool rejectDocumentNumber() {
    final attempts = state.docReadAttempts + 1;
    if (attempts >= 2) {
      state = state.copyWith(
        docReadAttempts: 0,
        documentNumberConfirmed: false,
        extractedDocNumber: null,
        isExtractingDocNumber: false,
        clearFrontImage: true,
        clearBackImage: true,
        errorMessage: null,
      );
      return true; // images reset, ask user to re-upload
    }
    state = state.copyWith(
      docReadAttempts: attempts,
      documentNumberConfirmed: false,
      extractedDocNumber: null,
    );
    return false;
  }

  Future<bool> submitVerification() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _ensureAuth();

      final docType = state.selectedDocumentType?.name ?? 'dni';
      final formData = FormData.fromMap({
        'document_type': docType,
        // Send the user-confirmed document number so the backend can perform
        // a synchronous duplicate check before any AI processing starts.
        if (state.documentNumberConfirmed && state.extractedDocNumber != null)
          'confirmed_doc_number': state.extractedDocNumber!,
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
        // selfieXFile may be null when selfie was captured via camera (setSelfieFromBytes)
        if (state.selfieXFile != null) {
          final bytes = await state.selfieXFile!.readAsBytes();
          formData.files.add(MapEntry(
            'selfie',
            MultipartFile.fromBytes(bytes, filename: 'selfie.jpg'),
          ));
        } else if (state.selfieBytes != null) {
          formData.files.add(MapEntry(
            'selfie',
            MultipartFile.fromBytes(state.selfieBytes!, filename: 'selfie.jpg'),
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
      final msg = e.response?.data?['detail'] ?? 'kyc.error_submitting';
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg is String ? msg : 'kyc.error_submitting',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'kyc.error_unexpected',
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
      final msg = e.response?.data?['detail'] ?? 'kyc.error_status';
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg is String ? msg : 'kyc.error_status',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'kyc.error_unexpected',
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

  void resetDocumentImages() {
    state = state.copyWith(
      clearFrontImage: true,
      clearBackImage: true,
      documentNumberConfirmed: false,
      extractedDocNumber: null,
      docReadAttempts: 0,
      isExtractingDocNumber: false,
      errorMessage: null,
    );
  }
}

final verificationProvider =
    NotifierProvider<VerificationNotifier, VerificationState>(
        VerificationNotifier.new);

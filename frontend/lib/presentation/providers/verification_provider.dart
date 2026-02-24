import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
    this.isLoading = false,
    this.frontStatus = UploadStatus.idle,
    this.backStatus = UploadStatus.idle,
    this.selfieStatus = UploadStatus.idle,
  });
  final int currentStepIndex;
  final DocumentType? selectedDocumentType;
  final File? frontImage;
  final File? backImage;
  final File? selfieImage;
  final bool isLoading;
  final UploadStatus frontStatus;
  final UploadStatus backStatus;
  final UploadStatus selfieStatus;

  VerificationState copyWith({
    int? currentStepIndex,
    DocumentType? selectedDocumentType,
    File? frontImage,
    File? backImage,
    File? selfieImage,
    bool? isLoading,
    UploadStatus? frontStatus,
    UploadStatus? backStatus,
    UploadStatus? selfieStatus,
  }) {
    return VerificationState(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      selectedDocumentType: selectedDocumentType ?? this.selectedDocumentType,
      frontImage: frontImage ?? this.frontImage,
      backImage: backImage ?? this.backImage,
      selfieImage: selfieImage ?? this.selfieImage,
      isLoading: isLoading ?? this.isLoading,
      frontStatus: frontStatus ?? this.frontStatus,
      backStatus: backStatus ?? this.backStatus,
      selfieStatus: selfieStatus ?? this.selfieStatus,
    );
  }
}

class VerificationNotifier extends Notifier<VerificationState> {
  @override
  VerificationState build() => VerificationState();

  final ImagePicker _picker = ImagePicker();

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
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        state = state.copyWith(
          frontImage: File(image.path),
          frontStatus: UploadStatus.success,
        );
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
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        state = state.copyWith(
            backImage: File(image.path), backStatus: UploadStatus.success,);
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
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (image != null) {
        state = state.copyWith(
            selfieImage: File(image.path), selfieStatus: UploadStatus.success,);
      } else {
        state = state.copyWith(selfieStatus: UploadStatus.idle);
      }
    } catch (e) {
      state = state.copyWith(selfieStatus: UploadStatus.error);
    }
  }

  Future<bool> submitVerification() async {
    state = state.copyWith(isLoading: true);
    // TODO: Implement actual API call
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isLoading: false);
    return true; // Mock success
  }

}

final verificationProvider = NotifierProvider<VerificationNotifier, VerificationState>(VerificationNotifier.new);

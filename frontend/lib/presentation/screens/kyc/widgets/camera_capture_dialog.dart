import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Full-screen camera dialog.
/// Returns [Uint8List] of the captured image or null if cancelled.
class CameraCaptureDialog extends StatefulWidget {
  const CameraCaptureDialog({super.key, this.preferFront = true});

  final bool preferFront;

  static Future<Uint8List?> show(BuildContext context,
      {bool preferFront = true}) {
    return showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CameraCaptureDialog(preferFront: preferFront),
    );
  }

  @override
  State<CameraCaptureDialog> createState() => _CameraCaptureDialogState();
}

class _CameraCaptureDialogState extends State<CameraCaptureDialog> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _loading = true;
  String? _error;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _error = 'kyc.no_camera'.tr();
          _loading = false;
        });
        return;
      }

      // Prefer front camera for selfie, else first available
      CameraDescription chosen = _cameras.first;
      if (widget.preferFront) {
        for (final cam in _cameras) {
          if (cam.lensDirection == CameraLensDirection.front) {
            chosen = cam;
            break;
          }
        }
      }

      _controller = CameraController(
        chosen,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'kyc.camera_access_error'.tr(namedArgs: {'error': e.toString()});
          _loading = false;
        });
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final xfile = await _controller!.takePicture();
      final bytes = await xfile.readAsBytes();
      if (mounted) Navigator.of(context).pop(bytes);
    } catch (e) {
      setState(() => _capturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('kyc.camera_error'.tr(namedArgs: {'error': e.toString()}))),
        );
      }
    }
  }

  void _switchCamera() async {
    if (_cameras.length < 2 || _controller == null) return;
    final currentDir = _controller!.description.lensDirection;
    CameraDescription next = _cameras.firstWhere(
      (c) => c.lensDirection != currentDir,
      orElse: () => _cameras.first,
    );
    await _controller!.dispose();
    _controller = CameraController(
      next,
      kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // ── Camera preview ──
            if (_loading)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text('kyc.camera_activating'.tr(),
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.no_photography_outlined,
                          color: Colors.white54, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              )
            else
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              ),

            // ── Top bar ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(null),
                        tooltip: 'common.cancel'.tr(),
                      ),
                      Expanded(
                        child: Text(
                          'solvency.center_face_hint'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_cameras.length > 1)
                        IconButton(
                          icon: const Icon(Icons.flip_camera_ios_outlined,
                              color: Colors.white),
                          onPressed: _switchCamera,
                          tooltip: 'kyc.switch_camera'.tr(),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom: capture button ──
            if (!_loading && _error == null)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _capturing ? null : _takePicture,
                      child: Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Center(
                          child: Container(
                            height: 56,
                            width: 56,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: _capturing
                                ? const CircularProgressIndicator(
                                    color: Colors.black)
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'solvency.capture_btn'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/ai_consent_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/verification_provider.dart';
import '../../widgets/ai/ai_consent_dialog.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import 'widgets/camera_capture_dialog.dart';
import 'widgets/document_number_confirmation_dialog.dart';
import 'widgets/document_upload_card.dart';

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen> {

  @override
  void initState() {
    super.initState();
    // Show AI consent dialog on page entry, before the user does anything.
    // If they decline, navigate back immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestAiConsent());
  }

  Future<void> _requestAiConsent() async {
    if (!mounted) return;
    final accepted = await AiConsentDialog.show(
      context: context,
      config: AiConsentConfig.kycVerification,
    );
    if (!mounted) return;
    if (!accepted) {
      context.pop();
    }
  }

  /// Called after each document image pick. Triggers OCR when both are ready.
  Future<void> _onDocumentImagePicked(VerificationNotifier notifier) async {
    final state = ref.read(verificationProvider);
    if (state.hasFront && state.hasBack && !state.documentNumberConfirmed) {
      await _runOcrFlow(notifier);
    }
  }

  /// Full OCR confirmation flow. Shows the dialog, handles retry and reset.
  Future<void> _runOcrFlow(VerificationNotifier notifier) async {
    if (!mounted) return;

    final state = ref.read(verificationProvider);
    final isSecondAttempt = state.docReadAttempts > 0;
    final docLabel = _docTypeLabel(state.selectedDocumentType);


    // Show loading dialog. Track whether it was actually pushed so we only pop
    // exactly that dialog (avoids popping the wrong route on fast responses).
    bool loadingDialogShown = false;
    if (mounted) {
      loadingDialogShown = true;
      DocumentNumberConfirmationDialog.show(
        context: context,
        isLoading: true,
        docNumber: null,
        readable: false,
        isSecondAttempt: isSecondAttempt,
        documentType: state.selectedDocumentType,
        documentTypeLabel: docLabel,
        onConfirm: (_) {},
        onReject: () {},
        onReupload: () {},
      );
    }

    // Call backend OCR
    final result = await notifier.extractDocNumber();

    // Close loading dialog only if we opened it
    if (loadingDialogShown && mounted) Navigator.of(context, rootNavigator: true).pop();
    if (!mounted) return;

    // Handle network/auth error (result is null).
    // Still show the dialog in unreadable mode so the user can enter the
    // document number manually and continue without being blocked.
    if (result == null) {
      final currentState = ref.read(verificationProvider);
      await DocumentNumberConfirmationDialog.show(
        context: context,
        isLoading: false,
        docNumber: null,
        readable: false,
        isSecondAttempt: isSecondAttempt,
        documentType: currentState.selectedDocumentType,
        documentTypeLabel: docLabel,
        onConfirm: (confirmedNumber) {
          notifier.confirmDocumentNumber(confirmedNumber);
          _showSnackBar('Numero de documento confirmado correctamente.');
        },
        onReject: () {},
        onReupload: () {
          notifier.resetDocumentImages();
        },
      );
      return;
    }

    final readable = result['readable'] == true;
    final docNumber = result['doc_number'] as String?;

    final currentState = ref.read(verificationProvider);

    if (!readable || docNumber == null) {
      // Unreadable — show error dialog with manual entry fallback
      await DocumentNumberConfirmationDialog.show(
        context: context,
        isLoading: false,
        docNumber: null,
        readable: false,
        isSecondAttempt: isSecondAttempt,
        documentType: currentState.selectedDocumentType,
        documentTypeLabel: docLabel,
        onConfirm: (confirmedNumber) {
          notifier.confirmDocumentNumber(confirmedNumber);
          _showSnackBar('Numero de documento confirmado correctamente.');
        },
        onReject: () {},
        onReupload: () {
          notifier.resetDocumentImages();
        },
      );
      return;
    }

    // Show confirmation dialog
    await DocumentNumberConfirmationDialog.show(
      context: context,
      isLoading: false,
      docNumber: docNumber,
      readable: true,
      isSecondAttempt: isSecondAttempt,
      documentType: currentState.selectedDocumentType,
      documentTypeLabel: docLabel,
      onConfirm: (confirmedNumber) {
        notifier.confirmDocumentNumber(confirmedNumber);
        _showSnackBar('Numero de documento confirmado correctamente.');
      },
      onReject: () async {
        final imagesReset = notifier.rejectDocumentNumber();
        if (imagesReset) {
          if (mounted) {
            _showSnackBar(
              'La imagen no es reconocible. Por favor, sube el documento de nuevo.',
              isError: true,
            );
          }
        } else {
          // Second attempt — re-run OCR
          await _runOcrFlow(notifier);
        }
      },
      onReupload: () {
        notifier.resetDocumentImages();
      },
    );
  }

  String _docTypeLabel(DocumentType? type) {
    switch (type) {
      case DocumentType.nie:
        return 'NIE';
      case DocumentType.pasaporte:
        return 'Pasaporte';
      default:
        return 'DNI';
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Opens the camera dialog and stores the captured bytes as the selfie.
  Future<void> _openCamera(VerificationNotifier notifier) async {
    final bytes =
        await CameraCaptureDialog.show(context, preferFront: true);
    if (bytes == null || !mounted) return;
    notifier.setSelfieFromBytes(bytes);
  }

  /// Returns true if the user has started filling anything
  bool _hasProgress(VerificationState state) {
    return state.selectedDocumentType != null ||
        state.hasFront ||
        state.hasBack ||
        state.hasSelfie ||
        state.documentNumberConfirmed;
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('kyc.discard_title'.tr()),
        content: const Text(
          'Si sales ahora, los documentos subidos no se guardarán y tendrás que empezar de nuevo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('kyc.stay_here'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('kyc.confirm_cancel'.tr()),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _tryNavigateAway(String destination) async {
    final state = ref.read(verificationProvider);
    if (_hasProgress(state)) {
      final confirmed = await _confirmDiscard();
      if (!confirmed) return;
      ref.read(verificationProvider.notifier).reset();
    }
    if (mounted) context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_hasProgress(state)) {
          final confirmed = await _confirmDiscard();
          if (confirmed) {
            notifier.reset();
            if (mounted) context.pop();
          }
        } else {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _buildAppBar(context),
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card principal horizontal
                    _buildMainCard(context, state, notifier),
                    const SizedBox(height: 16),
                    // RGPD footer
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Cumplimos estrictamente con el RGPD. Tus documentos y datos biométricos se cifran '
                        'bajo el estándar AES-256 y se utilizan exclusivamente para la verificación legal '
                        'de identidad en transacciones P2P.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _footerLink('Términos de Servicio'),
                        const SizedBox(width: 16),
                        _footerLink('Privacidad'),
                        const SizedBox(width: 16),
                        _footerLink('Ayuda'),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // AppBar (mismo estilo que UserProfileScreen)
  // ──────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppBarBackButton(
          onPressed: () async {
            final state = ref.read(verificationProvider);
            if (_hasProgress(state)) {
              final confirmed = await _confirmDiscard();
              if (!confirmed) return;
              ref.read(verificationProvider.notifier).reset();
            }
            if (mounted) context.pop();
          },
        ),
      ),
      title: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _tryNavigateAway('/'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo_inmufacil.png', height: 32),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(
                        text: 'Inmu',
                        style: TextStyle(color: colorScheme.primary)),
                    TextSpan(
                        text: 'Fácil',
                        style: TextStyle(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
      ),
      actions: [
        // Botón Inicio
        if (MediaQuery.sizeOf(context).width >= 650)
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _tryNavigateAway('/'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_rounded, size: 18, color: colorScheme.onPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'Inicio',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const UserAvatarMenu(),
        const SizedBox(width: 16),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Card principal (layout horizontal)
  // ──────────────────────────────────────────────
  Widget _buildMainCard(
      BuildContext context, VerificationState state, VerificationNotifier notifier) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verifica tu Identidad',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Confirmación de seguridad para transacciones P2P seguras.',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Security badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_outlined,
                          size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('verified_user',
                              style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                          Text('kyc.badge_encrypted'.tr(),
                              style: TextStyle(
                                  color: Colors.blue.shade400,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Progress bar ──
            _buildProgressBar(state),

            const SizedBox(height: 24),

            // ── 3 columnas horizontales ──
            LayoutBuilder(builder: (context, constraints) {
              final step1Done = state.selectedDocumentType != null;
              final step2Done = state.isDocumentScanDone;
              final isWide = constraints.maxWidth > 500;
              if (isWide) {
                return IntrinsicHeight(
                  child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Col 1+2: Doc type + scan
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('1', 'Tipo de documento'),
                          const SizedBox(height: 12),
                          _buildDocumentTypeSelector(state, notifier),
                          const SizedBox(height: 24),
                          _buildSectionLabel(
                            '2',
                            'Escaneo de Documento',
                            locked: !step1Done,
                            confirmed: state.documentNumberConfirmed,
                          ),
                          const SizedBox(height: 12),
                          _lockedWrapper(
                            locked: !step1Done,
                            child: Row(
                              children: [
                                Expanded(
                                  child: DocumentUploadCard(
                                    title: 'Parte Frontal',
                                    onTap: () async {
                                      await notifier.pickFrontImage();
                                      await _onDocumentImagePicked(notifier);
                                    },
                                    imageFile:
                                        kIsWeb ? null : state.frontImage,
                                    imageBytes:
                                        kIsWeb ? state.frontBytes : null,
                                    status: state.frontStatus,
                                    compact: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DocumentUploadCard(
                                    title: 'Parte Trasera',
                                    onTap: () async {
                                      await notifier.pickBackImage();
                                      await _onDocumentImagePicked(notifier);
                                    },
                                    imageFile:
                                        kIsWeb ? null : state.backImage,
                                    imageBytes:
                                        kIsWeb ? state.backBytes : null,
                                    status: state.backStatus,
                                    compact: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Col 3: Selfie
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          _buildSectionLabel('3', 'Prueba de vida',
                              locked: !step2Done),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _lockedWrapper(
                              locked: !step2Done,
                              child: _buildSelfieSection(state, notifier),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ));
              } else {
                // Mobile: vertical stack
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('1', 'Tipo de documento'),
                    const SizedBox(height: 12),
                    _buildDocumentTypeSelector(state, notifier),
                    const SizedBox(height: 24),
                    _buildSectionLabel(
                      '2',
                      'Escaneo de Documento',
                      locked: !step1Done,
                      confirmed: state.documentNumberConfirmed,
                    ),
                    const SizedBox(height: 12),
                    _lockedWrapper(
                      locked: !step1Done,
                      child: Row(
                        children: [
                          Expanded(
                            child: DocumentUploadCard(
                              title: 'Parte Frontal',
                              onTap: () async {
                                await notifier.pickFrontImage();
                                await _onDocumentImagePicked(notifier);
                              },
                              imageFile: kIsWeb ? null : state.frontImage,
                              imageBytes: kIsWeb ? state.frontBytes : null,
                              status: state.frontStatus,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DocumentUploadCard(
                              title: 'Parte Trasera',
                              onTap: () async {
                                await notifier.pickBackImage();
                                await _onDocumentImagePicked(notifier);
                              },
                              imageFile: kIsWeb ? null : state.backImage,
                              imageBytes: kIsWeb ? state.backBytes : null,
                              status: state.backStatus,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionLabel('3', 'Prueba de vida',
                        locked: !step2Done),
                    const SizedBox(height: 12),
                    _lockedWrapper(
                      locked: !step2Done,
                      child: _buildSelfieSection(state, notifier),
                    ),
                  ],
                );
              }
            }),

            const SizedBox(height: 28),

            // ── Error ──
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Footer: SSL + botones ──
            Row(
              children: [
                // SSL badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'SSL SECURE',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Botón Cancelar — mismo estilo que en Seguridad y Privacidad
                OutlinedButton(
                  onPressed: () async {
                    final state = ref.read(verificationProvider);
                    if (_hasProgress(state)) {
                      final confirmed = await _confirmDiscard();
                      if (!confirmed) return;
                      ref.read(verificationProvider.notifier).reset();
                    }
                    if (mounted) context.pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('common.cancel'.tr(),
                      style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 12),
                // Botón Enviar — mismo estilo que en Seguridad y Privacidad
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _canSubmit(state)
                        ? () => _submit(notifier)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canSubmit(state)
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.12),
                      foregroundColor: colorScheme.surface,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text(
                      'Enviar Verificación',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Progress bar
  // ──────────────────────────────────────────────
  Widget _buildProgressBar(VerificationState state) {
    // Count completed steps: docType, front, back, selfie
    int completed = 0;
    if (state.selectedDocumentType != null) completed++;
    if (state.hasFront) completed++;
    if (state.hasBack) completed++;
    if (state.hasSelfie) completed++;
    final progress = completed / 4.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 4,
        backgroundColor: Theme.of(context).colorScheme.outlineVariant,
        valueColor:
            AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Section label (with optional locked state)
  // ──────────────────────────────────────────────
  Widget _buildSectionLabel(String number, String text,
      {bool locked = false, bool confirmed = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = locked
        ? colorScheme.onSurface.withOpacity(0.12)
        : confirmed
            ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
            : colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: locked
                ? Icon(Icons.lock_outline, size: 13, color: Colors.grey.shade500)
                : confirmed
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: locked ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
          ),
        ),
        if (confirmed) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainer : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)).withOpacity(0.4)),
            ),
            child: Text(
              'Numero verificado',
              style: TextStyle(
                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Locked section overlay
  // ──────────────────────────────────────────────
  Widget _lockedWrapper({required bool locked, required Widget child}) {
    if (!locked) return child;
    return IgnorePointer(child: child);
  }

  // ──────────────────────────────────────────────
  // Document type chips
  // ──────────────────────────────────────────────
  Widget _buildDocumentTypeSelector(
      VerificationState state, VerificationNotifier notifier) {
    return Row(
      children: [
        _buildDocTypeChip('DNI', Icons.credit_card, DocumentType.dni,
            state.selectedDocumentType, notifier),
        const SizedBox(width: 8),
        _buildDocTypeChip('NIE', Icons.badge_outlined, DocumentType.nie,
            state.selectedDocumentType, notifier),
        const SizedBox(width: 8),
        _buildDocTypeChip('Pasap.', Icons.menu_book, DocumentType.pasaporte,
            state.selectedDocumentType, notifier),
      ],
    );
  }

  Widget _buildDocTypeChip(String label, IconData icon, DocumentType type,
      DocumentType? selected, VerificationNotifier notifier) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selected == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => notifier.selectDocumentType(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Selfie section
  // ──────────────────────────────────────────────
  Widget _buildSelfieSection(
      VerificationState state, VerificationNotifier notifier) {
    final hasSelfie = state.hasSelfie;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Face circle
          GestureDetector(
            onTap: notifier.pickSelfie,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surface,
                border: Border.all(
                  color: hasSelfie
                      ? greenColor
                      : colorScheme.outlineVariant,
                  width: hasSelfie ? 3 : 2,
                ),
                image: hasSelfie
                    ? DecorationImage(
                        image: kIsWeb && state.selfieBytes != null
                            ? MemoryImage(state.selfieBytes!)
                            : (!kIsWeb && state.selfieImage != null
                                ? FileImage(state.selfieImage!)
                                : const AssetImage('assets/images/logo_inmufacil.png'))
                                    as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasSelfie
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.face,
                            size: 36, color: Colors.blue.shade200),
                        const SizedBox(height: 2),
                        Text(
                          'face',
                          style: TextStyle(
                              color: Colors.blue.shade200,
                              fontSize: 10,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Centra tu rostro',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Iluminación uniforme, sin accesorios',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
          const SizedBox(height: 12),
          if (state.selfieStatus == UploadStatus.picking)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            OutlinedButton.icon(
              onPressed: () => _openCamera(notifier),
              style: OutlinedButton.styleFrom(
                foregroundColor: hasSelfie
                    ? greenColor
                    : colorScheme.primary,
                side: BorderSide(
                    color: hasSelfie
                        ? greenColor
                        : colorScheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
              ),
              icon: Icon(
                  hasSelfie ? Icons.check_circle_outline : Icons.camera_alt,
                  size: 16),
              label: Text(
                hasSelfie ? 'Repetir foto' : 'Iniciar Cámara',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Footer link
  // ──────────────────────────────────────────────
  Widget _footerLink(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 12,
          decoration: TextDecoration.underline,
          decorationColor: colorScheme.primary,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────
  bool _canSubmit(VerificationState state) {
    return state.selectedDocumentType != null &&
        state.hasFront &&
        state.hasBack &&
        state.documentNumberConfirmed &&
        state.hasSelfie;
  }

  Future<void> _submit(VerificationNotifier notifier) async {
    final success = await notifier.submitVerification();
    if (success && mounted) {
      // Refresh auth state so the profile banner reflects the new KYC status
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) context.go('/verification-status');
    }
  }
}

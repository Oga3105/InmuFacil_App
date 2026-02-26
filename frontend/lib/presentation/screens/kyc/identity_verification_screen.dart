import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/verification_provider.dart';
import '../../widgets/common/premium_button.dart';
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
  Widget build(BuildContext context) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Verifica tu Identidad',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      // Header
                      const Text(
                        'Verifica tu Identidad',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sube tus documentos para activar tu cuenta y publicar inmuebles.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                      const SizedBox(height: 12),

                      // Security badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline,
                                size: 14, color: Colors.blue.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Cifrado AES-256 · Datos protegidos',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Step 1: Document type
                      _buildSectionLabel('1', 'Tipo de documento'),
                      const SizedBox(height: 12),
                      _buildDocumentTypeSelector(state, notifier),

                      const SizedBox(height: 28),

                      // Step 2: Document scan
                      _buildSectionLabel('2', 'Escanea tu documento'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DocumentUploadCard(
                              title: 'Frente',
                              onTap: notifier.pickFrontImage,
                              imageFile: state.frontImage,
                              status: state.frontStatus,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DocumentUploadCard(
                              title: 'Reverso',
                              onTap: notifier.pickBackImage,
                              imageFile: state.backImage,
                              status: state.backStatus,
                              compact: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Step 3: Selfie
                      _buildSectionLabel('3', 'Prueba de vida'),
                      const SizedBox(height: 12),
                      _buildSelfieSection(state, notifier),

                      const SizedBox(height: 32),

                      // Error message
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
                                        color: Colors.red.shade700,
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Submit button
                      if (state.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        PremiumButton(
                          label: 'Enviar Verificación',
                          icon: Icons.lock_outline,
                          color: _canSubmit(state)
                              ? const Color(0xFF2563EB)
                              : Colors.grey,
                          onPressed: _canSubmit(state)
                              ? () => _submit(notifier)
                              : () {},
                        ),

                      const SizedBox(height: 20),

                      // RGPD footer
                      Center(
                        child: Text(
                          'Tus datos se tratan conforme al RGPD y se cifran en tránsito y reposo. '
                          'Solo se usan para verificar tu identidad.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF2563EB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentTypeSelector(
      VerificationState state, VerificationNotifier notifier) {
    return Row(
      children: [
        _buildDocTypeChip(
          'DNI',
          Icons.credit_card,
          DocumentType.dni,
          state.selectedDocumentType,
          notifier,
        ),
        const SizedBox(width: 8),
        _buildDocTypeChip(
          'NIE',
          Icons.badge_outlined,
          DocumentType.nie,
          state.selectedDocumentType,
          notifier,
        ),
        const SizedBox(width: 8),
        _buildDocTypeChip(
          'Pasaporte',
          Icons.menu_book,
          DocumentType.pasaporte,
          state.selectedDocumentType,
          notifier,
        ),
      ],
    );
  }

  Widget _buildDocTypeChip(String label, IconData icon, DocumentType type,
      DocumentType? selected, VerificationNotifier notifier) {
    final isSelected = selected == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => notifier.selectDocumentType(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                  size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelfieSection(
      VerificationState state, VerificationNotifier notifier) {
    final hasSelfie = state.selfieImage != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: notifier.pickSelfie,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: hasSelfie ? Colors.green : const Color(0xFFCBD5E1),
                  width: hasSelfie ? 3 : 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
                image: hasSelfie
                    ? DecorationImage(
                        image: FileImage(state.selfieImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasSelfie
                  ? Icon(Icons.face, size: 48, color: Colors.blue.shade300)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          if (state.selfieStatus == UploadStatus.picking)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton.icon(
              onPressed: notifier.pickSelfie,
              icon: Icon(Icons.camera_alt,
                  size: 18,
                  color: hasSelfie ? Colors.green : const Color(0xFF2563EB)),
              label: Text(
                hasSelfie ? 'Cambiar selfie' : 'Tomar selfie',
                style: TextStyle(
                  color: hasSelfie ? Colors.green : const Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _canSubmit(VerificationState state) {
    return state.selectedDocumentType != null &&
        state.frontImage != null &&
        state.backImage != null &&
        state.selfieImage != null;
  }

  Future<void> _submit(VerificationNotifier notifier) async {
    final success = await notifier.submitVerification();
    if (success && mounted) {
      context.go('/verification-status');
    }
  }
}

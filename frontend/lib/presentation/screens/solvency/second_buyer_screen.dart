import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/solvency_provider.dart' as solvency_prov;
import '../../providers/verification_provider.dart' show UploadStatus;
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import '../kyc/widgets/camera_capture_dialog.dart';
import '../kyc/widgets/document_upload_card.dart';

class SecondBuyerScreen extends ConsumerStatefulWidget {
  const SecondBuyerScreen({super.key});

  @override
  ConsumerState<SecondBuyerScreen> createState() => _SecondBuyerScreenState();
}

class _SecondBuyerScreenState extends ConsumerState<SecondBuyerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String? _documentType;
  Uint8List? _frontBytes;
  Uint8List? _backBytes;
  Uint8List? _selfieBytes;
  bool _frontPicking = false;
  bool _backPicking = false;
  bool _selfiePicking = false;
  bool _submitting = false;
  bool _done = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _hasFront => _frontBytes != null;
  bool get _hasBack => _backBytes != null;
  bool get _hasSelfie => _selfieBytes != null;

  bool _hasProgress() =>
      _documentType != null || _hasFront || _hasBack || _hasSelfie;

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Cancelar verificación?'),
        content: const Text(
          'Si sales ahora, los documentos subidos no se guardarán y tendrás que empezar de nuevo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Seguir aquí'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _tryNavigateAway(String destination) async {
    if (_hasProgress()) {
      final confirmed = await _confirmDiscard();
      if (!confirmed) return;
      _resetImages();
    }
    if (mounted) context.go(destination);
  }

  void _resetImages() {
    setState(() {
      _documentType = null;
      _frontBytes = null;
      _backBytes = null;
      _selfieBytes = null;
    });
  }

  Future<void> _openCamera() async {
    setState(() => _selfiePicking = true);
    final bytes = await CameraCaptureDialog.show(context, preferFront: true);
    if (!mounted) return;
    setState(() {
      _selfieBytes = bytes;
      _selfiePicking = false;
    });
  }

  Future<void> _pickDocument(String slot) async {
    setState(() {
      if (slot == 'front') _frontPicking = true;
      if (slot == 'back') _backPicking = true;
    });
    final file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (!mounted) return;
    if (file == null) {
      setState(() {
        if (slot == 'front') _frontPicking = false;
        if (slot == 'back') _backPicking = false;
      });
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      if (slot == 'front') {
        _frontBytes = bytes;
        _frontPicking = false;
      }
      if (slot == 'back') {
        _backBytes = bytes;
        _backPicking = false;
      }
    });
  }

  bool _canSubmit() =>
      _documentType != null && _hasFront && _hasSelfie && !_submitting;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      await ref.read(solvency_prov.secondBuyerNotifierProvider.notifier).submit(
            fullName: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            frontBytes: _frontBytes!,
            backBytes: _backBytes,
            selfieBytes: _selfieBytes!,
            documentType: _documentType!,
          );
      if (mounted) context.go('/solvency/second-buyer/status');
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_hasProgress()) {
          final confirmed = await _confirmDiscard();
          if (confirmed) {
            _resetImages();
            if (mounted) context.pop();
          }
        } else {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(context),
        body: _done
            ? _buildSuccess()
            : SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Extra: datos del 2.º comprador
                            _buildPersonalDataCard(),
                            const SizedBox(height: 16),
                            // Mismo card que verify-identity
                            _buildMainCard(context),
                            const SizedBox(height: 16),
                            // RGPD footer
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                'Cumplimos estrictamente con el RGPD. Tus documentos y datos biométricos se cifran '
                                'bajo el estándar AES-256 y se utilizan exclusivamente para la verificación legal '
                                'de identidad en transacciones P2P.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 11),
                              ),
                            ),
                            const SizedBox(height: 24),
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

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppBarBackButton(
          onPressed: () async {
            if (_hasProgress()) {
              final confirmed = await _confirmDiscard();
              if (!confirmed) return;
              _resetImages();
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
              const Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(
                        text: 'Inmu',
                        style: TextStyle(color: Color(0xFF2563EB))),
                    TextSpan(
                        text: 'Fácil',
                        style: TextStyle(color: Color(0xFF16A34A))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Verificar Identidad',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
      actions: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _tryNavigateAway('/'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Inicio',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const UserAvatarMenu(),
        const SizedBox(width: 16),
      ],
    );
  }

  // ── Personal data card (extra, not in verify-identity) ────────────────────

  Widget _buildPersonalDataCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datos del 2.º Comprador',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Introduce los datos del segundo titular de la compra.',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_alt_1_outlined,
                        size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Co-titular',
                            style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        Text('AES-256 Encrypted',
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
          _textField(
            controller: _nameCtrl,
            label: 'Nombre completo',
            hint: 'Nombre y apellidos',
            icon: Icons.person_outline,
            validator: (v) => (v == null || v.trim().length < 2)
                ? 'Introduce el nombre completo'
                : null,
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _emailCtrl,
            label: 'Correo electrónico',
            hint: 'correo@ejemplo.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Introduce un correo válido'
                : null,
          ),
        ],
      ),
    );
  }

  // ── Main card (idéntico a verify-identity) ────────────────────────────────

  Widget _buildMainCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                      const Text(
                        'Verifica tu Identidad',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
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
                          Text('AES-256 Encrypted',
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
            _buildProgressBar(),

            const SizedBox(height: 24),

            // ── 3 columnas / vertical ──
            LayoutBuilder(builder: (context, constraints) {
              final step1Done = _documentType != null;
              final step2Done = _hasFront;
              final isWide = constraints.maxWidth > 500;

              if (isWide) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Col 1+2: doc type + scan
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('1', 'Tipo de documento'),
                            const SizedBox(height: 12),
                            _buildDocumentTypeSelector(),
                            const SizedBox(height: 24),
                            _buildSectionLabel('2', 'Escaneo de Documento',
                                locked: !step1Done),
                            const SizedBox(height: 12),
                            _lockedWrapper(
                              locked: !step1Done,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: DocumentUploadCard(
                                      title: 'Parte Frontal',
                                      onTap: () => _pickDocument('front'),
                                      imageBytes: _frontBytes,
                                      status: _frontPicking
                                          ? UploadStatus.picking
                                          : (_hasFront
                                              ? UploadStatus.success
                                              : UploadStatus.idle),
                                      compact: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DocumentUploadCard(
                                      title: 'Parte Trasera',
                                      onTap: () => _pickDocument('back'),
                                      imageBytes: _backBytes,
                                      status: _backPicking
                                          ? UploadStatus.picking
                                          : (_hasBack
                                              ? UploadStatus.success
                                              : UploadStatus.idle),
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
                      // Col 3: selfie
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
                                child: _buildSelfieSection(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // Mobile: vertical
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('1', 'Tipo de documento'),
                    const SizedBox(height: 12),
                    _buildDocumentTypeSelector(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('2', 'Escaneo de Documento',
                        locked: !step1Done),
                    const SizedBox(height: 12),
                    _lockedWrapper(
                      locked: !step1Done,
                      child: Row(
                        children: [
                          Expanded(
                            child: DocumentUploadCard(
                              title: 'Parte Frontal',
                              onTap: () => _pickDocument('front'),
                              imageBytes: _frontBytes,
                              status: _frontPicking
                                  ? UploadStatus.picking
                                  : (_hasFront
                                      ? UploadStatus.success
                                      : UploadStatus.idle),
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DocumentUploadCard(
                              title: 'Parte Trasera',
                              onTap: () => _pickDocument('back'),
                              imageBytes: _backBytes,
                              status: _backPicking
                                  ? UploadStatus.picking
                                  : (_hasBack
                                      ? UploadStatus.success
                                      : UploadStatus.idle),
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
                      child: _buildSelfieSection(),
                    ),
                  ],
                );
              }
            }),

            const SizedBox(height: 28),

            // ── Footer: SSL + Cancelar + Enviar ──
            Row(
              children: [
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
                OutlinedButton(
                  onPressed: () async {
                    if (_hasProgress()) {
                      final confirmed = await _confirmDiscard();
                      if (!confirmed) return;
                      _resetImages();
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
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 12),
                if (_submitting)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _canSubmit() ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canSubmit()
                          ? const Color(0xFF0F172A)
                          : Colors.grey.shade300,
                      foregroundColor: Colors.white,
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

  // ── Progress bar ───────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    int completed = 0;
    if (_documentType != null) completed++;
    if (_hasFront) completed++;
    if (_hasBack) completed++;
    if (_hasSelfie) completed++;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: completed / 4.0,
        minHeight: 4,
        backgroundColor: const Color(0xFFE2E8F0),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String number, String text, {bool locked = false}) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: locked ? Colors.grey.shade300 : const Color(0xFF2563EB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: locked
                ? Icon(Icons.lock_outline,
                    size: 13, color: Colors.grey.shade500)
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
            color: locked ? Colors.grey.shade400 : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _lockedWrapper({required bool locked, required Widget child}) {
    if (!locked) return child;
    return IgnorePointer(child: child);
  }

  // ── Document type chips ────────────────────────────────────────────────────

  Widget _buildDocumentTypeSelector() {
    return Row(
      children: [
        _buildDocTypeChip('DNI', Icons.credit_card, 'dni'),
        const SizedBox(width: 8),
        _buildDocTypeChip('NIE', Icons.badge_outlined, 'nie'),
        const SizedBox(width: 8),
        _buildDocTypeChip('Pasap.', Icons.menu_book, 'pasaporte'),
      ],
    );
  }

  Widget _buildDocTypeChip(String label, IconData icon, String type) {
    final isSelected = _documentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _documentType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                  size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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

  // ── Selfie section ─────────────────────────────────────────────────────────

  Widget _buildSelfieSection() {
    final hasSelfie = _hasSelfie;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          GestureDetector(
            onTap: _openCamera,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: hasSelfie ? Colors.green : const Color(0xFFCBD5E1),
                  width: hasSelfie ? 3 : 2,
                ),
                image: hasSelfie
                    ? DecorationImage(
                        image: MemoryImage(_selfieBytes!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasSelfie
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.face, size: 36, color: Colors.blue.shade200),
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
          const Text(
            'Centra tu rostro',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Iluminación uniforme, sin accesorios',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
          const SizedBox(height: 12),
          if (_selfiePicking)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            OutlinedButton.icon(
              onPressed: _openCamera,
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    hasSelfie ? Colors.green : const Color(0xFF2563EB),
                side: BorderSide(
                    color: hasSelfie ? Colors.green : const Color(0xFF2563EB)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: Icon(
                  hasSelfie ? Icons.check_circle_outline : Icons.camera_alt,
                  size: 16),
              label: Text(
                hasSelfie ? 'Repetir foto' : 'Iniciar Cámara',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  // ── Success state ──────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF16A34A), width: 2),
              ),
              child: const Icon(Icons.verified_user_outlined,
                  size: 44, color: Color(0xFF16A34A)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Identidad Verificada',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'La identidad del segundo comprador ha sido verificada y sus datos guardados de forma segura (AES-256).',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Volver al timeline',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Text field helper ──────────────────────────────────────────────────────

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

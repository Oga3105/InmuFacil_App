import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/solvency_provider.dart' as solvency_prov;
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import '../info/info_screen.dart';
import '../kyc/widgets/document_upload_card.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const _kBlue = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);
const _kGrey = Color(0xFF64748B);
const _kSlate = Color(0xFF1E293B);

// ─── Screen ──────────────────────────────────────────────────────────────────

class SecondBuyerScreen extends ConsumerStatefulWidget {
  const SecondBuyerScreen({super.key});

  @override
  ConsumerState<SecondBuyerScreen> createState() => _SecondBuyerScreenState();
}

class _SecondBuyerScreenState extends ConsumerState<SecondBuyerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String? _documentType; // null = not yet selected
  XFile? _frontImage;
  XFile? _backImage;
  XFile? _selfieImage;
  bool _consentAccepted = false;
  bool _submitting = false;
  bool _done = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // How many of the 4 verification steps are done (for the progress bar).
  int get _completedSteps {
    int n = 0;
    if (_documentType != null) n++;
    if (_frontImage != null) n++;
    if (_backImage != null) n++;
    if (_selfieImage != null) n++;
    return n;
  }

  bool get _canSubmit =>
      _documentType != null &&
      _frontImage != null &&
      _selfieImage != null &&
      _consentAccepted &&
      !_submitting;

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> _pickImage(String slot) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _kBlue),
              title: const Text(
                'Camara',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _kBlue),
              title: const Text(
                'Galeria',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() {
      if (slot == 'front') _frontImage = file;
      if (slot == 'back') _backImage = file;
      if (slot == 'selfie') _selfieImage = file;
    });
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_documentType == null) {
      _showError('Selecciona el tipo de documento.');
      return;
    }
    if (_frontImage == null) {
      _showError('Captura el frente del documento.');
      return;
    }
    if (_selfieImage == null) {
      _showError('Captura la selfie del segundo comprador.');
      return;
    }
    if (!_consentAccepted) {
      _showError('Debes aceptar los terminos para continuar.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(solvency_prov.secondBuyerNotifierProvider.notifier)
          .submit(
            fullName: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            frontPath: _frontImage!.path,
            backPath: _backImage?.path,
            selfiePath: _selfieImage!.path,
            documentType: _documentType!,
          );
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(onPressed: () => context.pop()),
        ),
        title: GestureDetector(
          onTap: () => context.go('/'),
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
                      style: TextStyle(color: Color(0xFF2563EB)),
                    ),
                    TextSpan(
                      text: 'Facil',
                      style: TextStyle(color: Color(0xFF16A34A)),
                    ),
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
                  'Segundo Comprador',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
        actions: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          const SizedBox(width: 12),
          const UserAvatarMenu(),
          const SizedBox(width: 16),
        ],
      ),
      body: _done ? _buildSuccess() : _buildForm(),
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
                border: Border.all(color: _kGreen, width: 2),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                size: 44,
                color: _kGreen,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Identidad Verificada',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _kSlate,
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
                  backgroundColor: _kGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Volver al timeline',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main form ──────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPersonalDataCard(),
            const SizedBox(height: 16),
            _buildVerificationCard(),
            const SizedBox(height: 16),
            _buildConsentSection(),
            const SizedBox(height: 16),
            _buildSubmitSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Personal data card ─────────────────────────────────────────────────────

  Widget _buildPersonalDataCard() {
    return _card(
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _kSlate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Introduce los datos del segundo titular de la compra.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add_alt_1_outlined,
                      size: 14,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Co-titular',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'AES-256 Encrypted',
                          style: TextStyle(
                            color: Colors.blue.shade400,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
            validator: (v) {
              if (v == null || v.trim().length < 2) {
                return 'Introduce el nombre completo';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _textField(
            controller: _emailCtrl,
            label: 'Correo electronico',
            hint: 'correo@ejemplo.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || !v.contains('@')) {
                return 'Introduce un correo valido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ── Verification card ──────────────────────────────────────────────────────

  Widget _buildVerificationCard() {
    final step1Done = _documentType != null;
    final step2Done = _frontImage != null;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verificar Identidad',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _kSlate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Escanea el documento y realiza la prueba de vida.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'verified_user',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'AES-256 Encrypted',
                          style: TextStyle(
                            color: Colors.blue.shade400,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _completedSteps / 4.0,
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
            ),
          ),

          const SizedBox(height: 24),

          // Step 1: Document type
          _sectionLabel('1', 'Tipo de documento'),
          const SizedBox(height: 12),
          _buildDocumentTypeSelector(),

          const SizedBox(height: 24),

          // Step 2: Document scan
          _sectionLabel('2', 'Escaneo de Documento', locked: !step1Done),
          const SizedBox(height: 12),
          _lockedWrapper(
            locked: !step1Done,
            child: Row(
              children: [
                Expanded(
                  child: _SecondBuyerDocCard(
                    title: 'Parte Frontal',
                    subtitle: 'Requerido',
                    image: _frontImage,
                    onTap: () => _pickImage('front'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SecondBuyerDocCard(
                    title: 'Parte Trasera',
                    subtitle: 'Opcional',
                    image: _backImage,
                    onTap: () => _pickImage('back'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Step 3: Selfie
          _sectionLabel('3', 'Prueba de vida', locked: !step2Done),
          const SizedBox(height: 12),
          _lockedWrapper(
            locked: !step2Done,
            child: _buildSelfieSection(),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String number, String text, {bool locked = false}) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: locked ? Colors.grey.shade300 : _kBlue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: locked
                ? Icon(Icons.lock_outline,
                    size: 13, color: Colors.grey.shade500,)
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
            color: locked ? Colors.grey.shade400 : _kSlate,
          ),
        ),
      ],
    );
  }

  Widget _lockedWrapper({required bool locked, required Widget child}) {
    if (!locked) return child;
    return Opacity(opacity: 0.4, child: IgnorePointer(child: child));
  }

  Widget _buildDocumentTypeSelector() {
    return Row(
      children: [
        _docTypeChip('DNI', Icons.credit_card, 'dni'),
        const SizedBox(width: 8),
        _docTypeChip('NIE', Icons.badge_outlined, 'nie'),
        const SizedBox(width: 8),
        _docTypeChip('Pasap.', Icons.menu_book, 'pasaporte'),
      ],
    );
  }

  Widget _docTypeChip(String label, IconData icon, String type) {
    final isSelected = _documentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _documentType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _kBlue : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? _kBlue : const Color(0xFF94A3B8),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _kBlue : _kGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelfieSection() {
    final hasSelfie = _selfieImage != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _pickImage('selfie'),
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
                        image: FileImage(File(_selfieImage!.path)),
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
                            fontWeight: FontWeight.w500,
                          ),
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
              color: _kSlate,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Iluminacion uniforme, sin accesorios',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pickImage('selfie'),
            style: OutlinedButton.styleFrom(
              foregroundColor: hasSelfie ? Colors.green : _kBlue,
              side: BorderSide(color: hasSelfie ? Colors.green : _kBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: Icon(
              hasSelfie ? Icons.check_circle_outline : Icons.camera_alt,
              size: 16,
            ),
            label: Text(
              hasSelfie ? 'Repetir foto' : 'Tomar foto',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Consent section ────────────────────────────────────────────────────────

  Widget _buildConsentSection() {
    return _card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                'SSL SECURE · AES-256',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _consentAccepted,
                  onChanged: (v) =>
                      setState(() => _consentAccepted = v ?? false),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: _kBlue,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text:
                        'Al enviar, confirmo que el segundo comprador acepta los ',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: 'Terminos y Condiciones',
                        style: const TextStyle(
                          color: _kBlue,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: _kBlue,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context
                              .push(InfoScreen.routeFor(InfoPageType.terms)),
                      ),
                      TextSpan(
                        text: ' y la ',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      TextSpan(
                        text: 'Politica de Privacidad',
                        style: const TextStyle(
                          color: _kBlue,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: _kBlue,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.push(
                              InfoScreen.routeFor(InfoPageType.privacy),),
                      ),
                      const TextSpan(
                        text:
                            '. Sus datos biometricos y documentales se cifran con AES-256 y se usan exclusivamente para verificacion de identidad.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Submit section ─────────────────────────────────────────────────────────

  Widget _buildSubmitSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: _submitting
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit
                        ? const Color(0xFF0F172A)
                        : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text(
                    'Enviar Verificacion',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
        ),
        if (!_canSubmit && !_submitting) ...[
          const SizedBox(height: 8),
          Text(
            _documentType == null
                ? 'Selecciona el tipo de documento.'
                : _frontImage == null
                    ? 'Captura el frente del documento.'
                    : _selfieImage == null
                        ? 'Captura la selfie para continuar.'
                        : 'Acepta los terminos para continuar.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ── Reusable widgets ───────────────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
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
      padding: padding ?? const EdgeInsets.all(24),
      child: child,
    );
  }

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
        prefixIcon: Icon(icon, size: 20, color: _kGrey),
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
          borderSide: const BorderSide(color: _kBlue, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ─── Document capture card ────────────────────────────────────────────────────
// Visually identical to DocumentUploadCard (same DashedBorderPainter +
// CornerMarkPainter) but driven by image_picker's XFile instead of UploadStatus.

class _SecondBuyerDocCard extends StatelessWidget {
  const _SecondBuyerDocCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final XFile? image;
  final VoidCallback onTap;

  bool get _hasImage => image != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _hasImage
            ? null
            : DashedBorderPainter(
                color: const Color(0xFFCBD5E1),
                radius: 12,
              ),
        child: CustomPaint(
          painter: _hasImage ? null : CornerMarkPainter(),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: _hasImage ? null : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: _hasImage
                  ? Border.all(color: Colors.green.shade400, width: 2)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(image!.path),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (!_hasImage)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 36,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Toca para escanear',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                if (_hasImage)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

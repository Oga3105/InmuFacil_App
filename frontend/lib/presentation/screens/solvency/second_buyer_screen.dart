import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/solvency_provider.dart' as solvency_prov;
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

const _kGreen = Color(0xFF16A34A);
const _kNavy = Color(0xFF2563EB);
const _kGrey = Color(0xFF64748B);

class SecondBuyerScreen extends ConsumerStatefulWidget {
  const SecondBuyerScreen({super.key});

  @override
  ConsumerState<SecondBuyerScreen> createState() => _SecondBuyerScreenState();
}

class _SecondBuyerScreenState extends ConsumerState<SecondBuyerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _documentType = 'dni';
  XFile? _frontImage;
  XFile? _backImage;
  XFile? _selfieImage;

  bool _submitting = false;
  bool _done = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _frontImage != null && _selfieImage != null && !_submitting;

  Future<void> _pickImage(String slot) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() {
      if (slot == 'front') _frontImage = file;
      if (slot == 'back') _backImage = file;
      if (slot == 'selfie') _selfieImage = file;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_frontImage == null) {
      _showError('Debes capturar el frente del documento.');
      return;
    }
    if (_selfieImage == null) {
      _showError('Debes capturar la selfie del segundo comprador.');
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
            documentType: _documentType,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBarBackButton(onPressed: () => context.pop()),
        title: const Text(
          'Segundo Comprador',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: const [UserAvatarMenu(), SizedBox(width: 8)],
      ),
      body: _done ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_outlined, size: 64, color: _kGreen),
            const SizedBox(height: 20),
            const Text(
              'Identidad verificada',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'La identidad del segundo comprador ha sido verificada y sus datos guardados de forma segura (AES-256).',
              style: TextStyle(fontSize: 14, color: _kGrey),
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

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF93C5FD)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.person_add_alt_1_outlined,
                      color: _kNavy, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Identifica al segundo titular mediante verificacion de identidad. El DNI se extrae automaticamente del documento. Sus datos se guardan cifrados y se usan para la firma del contrato de arras.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF1D4ED8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Personal data fields
            const Text(
              'Datos del segundo comprador',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            _buildTextField(
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
            _buildTextField(
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
            const SizedBox(height: 28),

            // Document type selector
            const Text(
              'Tipo de documento',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final entry in const {
                  'dni': 'DNI',
                  'nie': 'NIE',
                  'pasaporte': 'Pasaporte'
                }.entries)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _DocTypeChip(
                        label: entry.value,
                        selected: _documentType == entry.key,
                        onTap: () =>
                            setState(() => _documentType = entry.key),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Document capture
            const Text(
              'Verificacion de identidad',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'El numero de documento se extrae automaticamente. No es necesario introducirlo manualmente.',
              style: TextStyle(fontSize: 12, color: _kGrey),
            ),
            const SizedBox(height: 16),
            _ImageCaptureCard(
              label: 'Frente del documento',
              sublabel: 'Requerido',
              icon: Icons.badge_outlined,
              image: _frontImage,
              required: true,
              onTap: () => _pickImage('front'),
            ),
            const SizedBox(height: 12),
            _ImageCaptureCard(
              label: 'Reverso del documento',
              sublabel: 'Recomendado',
              icon: Icons.flip_outlined,
              image: _backImage,
              required: false,
              onTap: () => _pickImage('back'),
            ),
            const SizedBox(height: 12),
            _ImageCaptureCard(
              label: 'Selfie del segundo comprador',
              sublabel: 'Requerido',
              icon: Icons.face_outlined,
              image: _selfieImage,
              required: true,
              onTap: () => _pickImage('selfie'),
            ),
            const SizedBox(height: 24),

            // GDPR notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: _kGreen),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Todos los datos se cifran con AES-256 antes de almacenarse. Cumplimiento GDPR.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canSubmit ? _submit : null,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.verified_user_outlined, size: 18),
                label: Text(
                  _submitting
                      ? 'Verificando identidad...'
                      : 'Verificar identidad',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _canSubmit ? _kGreen : _kGrey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (!_canSubmit && !_submitting)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Captura el frente del documento y la selfie para continuar.',
                  style: TextStyle(fontSize: 11, color: _kGrey),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
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
        fillColor: Colors.white,
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
          borderSide: const BorderSide(color: _kNavy, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _DocTypeChip extends StatelessWidget {
  const _DocTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _kNavy : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _kNavy : const Color(0xFFCBD5E1),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : _kGrey,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageCaptureCard extends StatelessWidget {
  const _ImageCaptureCard({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.image,
    required this.required,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final XFile? image;
  final bool required;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final captured = image != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: captured ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: captured
                ? _kGreen
                : required
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: captured
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: captured
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(image!.path),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(icon, color: _kGrey, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    captured ? 'Capturado' : sublabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: captured ? _kGreen : _kGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              captured ? Icons.check_circle_outlined : Icons.camera_alt_outlined,
              color: captured ? _kGreen : _kGrey,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

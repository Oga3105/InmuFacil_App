import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/solvency_provider.dart' as solvency_prov;
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

const _kGreen = Color(0xFF16A34A);
const _kNavy = Color(0xFF2563EB);

class SecondBuyerScreen extends ConsumerStatefulWidget {
  const SecondBuyerScreen({super.key});

  @override
  ConsumerState<SecondBuyerScreen> createState() => _SecondBuyerScreenState();
}

class _SecondBuyerScreenState extends ConsumerState<SecondBuyerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _submitting = false;
  bool _done = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dniCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await ref.read(solvency_prov.secondBuyerNotifierProvider.notifier).submit(
            fullName: _nameCtrl.text.trim(),
            dni: _dniCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
          );
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
            const Icon(Icons.verified_user_outlined,
                size: 64, color: _kGreen),
            const SizedBox(height: 20),
            const Text(
              'Datos guardados',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Los datos del segundo comprador han sido verificados y guardados de forma segura (cifrado AES-256).',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
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
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF93C5FD)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_add_alt_1_outlined,
                      color: _kNavy, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Identifica al segundo titular de la compra. Sus datos se guardan cifrados y se usan exclusivamente para la firma del contrato de arras.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF1D4ED8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Datos del segundo comprador',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            _buildField(
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
            _buildField(
              controller: _dniCtrl,
              label: 'DNI / NIE',
              hint: '12345678A',
              icon: Icons.badge_outlined,
              validator: (v) {
                if (v == null || v.trim().length < 5) {
                  return 'Introduce un DNI o NIE valido';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildField(
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
                      style:
                          TextStyle(fontSize: 11, color: Color(0xFF166534)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.verified_user_outlined, size: 18),
                label: const Text('Guardar y verificar identidad',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: _kGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
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

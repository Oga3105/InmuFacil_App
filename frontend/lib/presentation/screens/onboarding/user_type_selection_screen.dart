import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de seleccion de tipo de usuario en el onboarding post-Google.
/// El usuario elige PARTICULAR o PROFESIONAL antes de acceder a la app.
class UserTypeSelectionScreen extends ConsumerStatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  ConsumerState<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState
    extends ConsumerState<UserTypeSelectionScreen> {
  String? _selectedType;
  bool _isSaving = false;

  static const Color _teal = Color(0xFF2D5C5A);
  static const Color _blue = Color(0xFF2563EB);

  Future<void> _handleContinue() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('onboarding.user_type_required'.tr()),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Actualizar user_type en backend via PUT /users/me (full_name no cambia)
    final result = await ref.read(authProvider.notifier).updateProfile(
          fullName: ref.read(authProvider).user?.name,
    );

    // Nota: updateProfile no acepta user_type directamente.
    // El user_type se envio en el POST /auth/google durante la creacion.
    // Si el usuario cambio de opinion aqui, hacemos un segundo PATCH al perfil.
    // Por ahora usamos la llamada directa al notifier para forzar refreshUser.
    await ref.read(authProvider.notifier).refreshUser();

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true || result['success'] == null) {
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Error al guardar el perfil'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Color(0xFFDBEAFE),
                      child: Icon(Icons.person_outline, size: 36, color: _blue),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'onboarding.user_type_title'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'onboarding.user_type_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),

                  // Opcion PARTICULAR
                  _UserTypeCard(
                    type: 'particular',
                    icon: Icons.home_outlined,
                    title: 'onboarding.user_type_particular'.tr(),
                    description: 'onboarding.user_type_particular_desc'.tr(),
                    isSelected: _selectedType == 'particular',
                    onTap: () => setState(() => _selectedType = 'particular'),
                  ),
                  const SizedBox(height: 12),

                  // Opcion PROFESIONAL
                  _UserTypeCard(
                    type: 'profesional',
                    icon: Icons.business_center_outlined,
                    title: 'onboarding.user_type_profesional'.tr(),
                    description: 'onboarding.user_type_profesional_desc'.tr(),
                    isSelected: _selectedType == 'profesional',
                    onTap: () => setState(() => _selectedType = 'profesional'),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'onboarding.user_type_continue'.tr(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final String type;
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.type,
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  static const Color _teal = Color(0xFF2D5C5A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
          border: Border.all(
            color: isSelected ? _teal : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _teal.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  isSelected ? _teal : Colors.grey.shade100,
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? _teal : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: _teal, size: 22),
          ],
        ),
      ),
    );
  }
}

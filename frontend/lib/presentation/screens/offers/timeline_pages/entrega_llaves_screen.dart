import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/common/app_bar_back_button.dart';
import '../../../providers/offers_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/user_avatar_menu.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/dio_factory.dart';
const _kBlue    = Color(0xFF135BEC);
const _kGreen   = Color(0xFF16A34A);
const _kBg      = Color(0xFFF8FAFC);
const _kNavy    = Color(0xFF135BEC);
const _kStorage = FlutterSecureStorage();

/// Pantalla de Entrega de Llaves — hito final de cierre de la transaccion.
/// Ambas partes confirman la entrega. Documentacion pendiente adjunta.
class EntregaLlavesScreen extends ConsumerStatefulWidget {
  const EntregaLlavesScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  ConsumerState<EntregaLlavesScreen> createState() => _EntregaLlavesScreenState();
}

class _EntregaLlavesScreenState extends ConsumerState<EntregaLlavesScreen> {
  bool _sellerConfirmed = false;
  bool _buyerConfirmed  = false;
  bool _isLoading       = false;
  bool _isInitializing  = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final token = await _kStorage.read(key: 'auth_token');
      if (token == null) return;
      final resp = await buildAuthDio().get(
        '$EnvConfig.apiBaseUrl/entrega-llaves/${widget.offer.id}/status',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = resp.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _buyerConfirmed  = data['buyer_confirmed'] as bool? ?? false;
        _sellerConfirmed = data['seller_confirmed'] as bool? ?? false;
      });
    } catch (_) {
      // non-blocking — show empty state
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _confirm() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final token = await _kStorage.read(key: 'auth_token');
      final resp = await buildAuthDio().post(
        '$EnvConfig.apiBaseUrl/entrega-llaves/${widget.offer.id}/confirm',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = resp.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _buyerConfirmed  = data['buyer_confirmed'] as bool? ?? false;
        _sellerConfirmed = data['seller_confirmed'] as bool? ?? false;
      });
      if (data['offer_completed'] == true) {
        _showCompletionDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu confirmacion registrada. Esperando a la otra parte.'),
            backgroundColor: _kGreen,
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = (e.response?.data as Map?)?['detail'] as String?;
      setState(() => _errorMessage = detail ?? 'Error al confirmar. Intentalo de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.celebration_outlined,
                  color: _kGreen, size: 56),
            ),
            const SizedBox(height: 20),
            const Text(
              'Transaccion completada',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kNavy),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Felicidades. La compraventa ha finalizado con exito.\n'
              'Las llaves han sido entregadas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.5),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: _kBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final isBuyer    = currentUser?.id == widget.offer.buyerId;
    final isComplete = _buyerConfirmed && _sellerConfirmed;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
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
                      style: TextStyle(color: Color(0xFF135BEC)),
                    ),
                    TextSpan(
                      text: 'Fácil',
                      style: TextStyle(color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 650)
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF135BEC),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF135BEC).withValues(alpha: 0.25),
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
          Consumer(
            builder: (context, ref, _) {
              final isAuthenticated = ref.watch(authProvider).isAuthenticated;
              if (!isAuthenticated) return const SizedBox.shrink();
              return const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 12),
                  UserAvatarMenu(),
                  SizedBox(width: 16),
                ],
              );
            },
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _HeroCard(isComplete: isComplete),
                const SizedBox(height: 24),
                _ConfirmationCard(
                  label: 'Vendedor',
                  icon: Icons.home_outlined,
                  confirmed: _sellerConfirmed,
                  isCurrentUser: !isBuyer,
                  isLoading: _isLoading && !isBuyer,
                  onConfirm: _confirm,
                ),
                const SizedBox(height: 12),
                _ConfirmationCard(
                  label: 'Comprador',
                  icon: Icons.person_outline,
                  confirmed: _buyerConfirmed,
                  isCurrentUser: isBuyer,
                  isLoading: _isLoading && isBuyer,
                  onConfirm: _confirm,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(_errorMessage!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 24),
                const _PendingDocsCard(),
                const SizedBox(height: 20),
                const _TipsCard(),
              ],
            ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.isComplete});

  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isComplete
              ? [_kGreen, const Color(0xFF15803D)]
              : [const Color(0xFF135BEC), _kBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.vpn_key_outlined,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            isComplete
                ? 'Llaves entregadas'
                : 'Entrega de llaves pendiente',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isComplete
                ? 'La transaccion ha concluido exitosamente.'
                : 'Ambas partes deben confirmar la entrega\npara cerrar la transaccion.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({
    required this.label,
    required this.icon,
    required this.confirmed,
    required this.isCurrentUser,
    required this.isLoading,
    required this.onConfirm,
  });

  final String label;
  final IconData icon;
  final bool confirmed;
  final bool isCurrentUser;
  final bool isLoading;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: confirmed ? _kGreen.withOpacity(0.07) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: confirmed ? _kGreen.withOpacity(0.4) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: confirmed
                  ? _kGreen.withOpacity(0.15)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: confirmed ? _kGreen : Colors.grey.shade500, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: confirmed ? _kGreen : const Color(0xFF135BEC))),
                Text(
                  confirmed
                      ? 'Entrega confirmada'
                      : isCurrentUser
                          ? 'Confirma cuando hayas entregado/recibido las llaves'
                          : 'Esperando confirmacion',
                  style: TextStyle(
                      fontSize: 12,
                      color: confirmed ? _kGreen : Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (confirmed)
            const Icon(Icons.check_circle, color: _kGreen, size: 24)
          else if (isCurrentUser)
            FilledButton(
              onPressed: isLoading ? null : onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: _kBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirmar', style: TextStyle(fontSize: 13)),
            )
          else
            Icon(Icons.hourglass_empty, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }
}

class _PendingDocsCard extends StatelessWidget {
  const _PendingDocsCard();

  @override
  Widget build(BuildContext context) {
    const docs = [
      'Copia de las escrituras firmadas',
      'Certificado energetico (CEE)',
      'Manual de uso de la vivienda',
      'Llaves de todas las cerraduras',
      'Tarjeta de garantia de electrodomesticos',
      'Datos de la comunidad y administrador',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.folder_open_outlined, color: _kBlue, size: 20),
              SizedBox(width: 10),
              Text('Documentacion a entregar',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF135BEC))),
            ],
          ),
          const SizedBox(height: 14),
          ...docs.map((doc) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined,
                        color: _kBlue, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(doc,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade700)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    const tips = [
      'Revisa el estado de la vivienda antes de firmar la entrega',
      'Anota las lecturas de los contadores de agua, luz y gas',
      'Solicita el certificado de estar al corriente de pagos en la comunidad',
      'Cambia el cilindro de la cerradura por seguridad',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB8860B).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: Color(0xFFB8860B), size: 20),
              SizedBox(width: 10),
              Text('Consejos para la entrega',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF78350F))),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right,
                        color: Color(0xFFB8860B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(tip,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF78350F),
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

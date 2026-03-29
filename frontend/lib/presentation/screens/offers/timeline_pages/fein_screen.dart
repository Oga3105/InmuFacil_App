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

const _kBlue  = Color(0xFF135BEC);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);
const _kNavy  = Color(0xFF001F3F);
const _storage = FlutterSecureStorage();

/// Pagina de Formalizacion Bancaria (FEIN / FIPER).
/// El comprador confirma que el banco ha emitido la FEIN.
/// Gate: solo accesible si la tasacion esta COMPLETADA.
class FeinScreen extends ConsumerStatefulWidget {
  const FeinScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  ConsumerState<FeinScreen> createState() => _FeinScreenState();
}

class _FeinScreenState extends ConsumerState<FeinScreen> {
  bool _feinReceived    = false;
  bool _conditionsRead  = false;
  bool _isLoading       = false;
  bool _isInitializing  = true;
  bool _submitted       = false;
  String? _errorMessage;

  bool get _isBuyer =>
      ref.read(authProvider).user?.id.toString() == widget.offer.buyerId;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return;
      final resp = await Dio().get(
        '$EnvConfig.apiBaseUrl/fein/${widget.offer.id}/status',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = resp.data as Map<String, dynamic>;
      if (!mounted) return;
      final buyerConfirmed = data['buyer_confirmed'] as bool? ?? false;
      // FEIN is a buyer-bank process: process is complete when buyer confirms.
      // Both buyer and seller see the success view once buyer has confirmed.
      if (buyerConfirmed) {
        setState(() => _submitted = true);
      }
    } catch (_) {
      // non-blocking — show empty form
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _confirm() async {
    if (!_feinReceived || !_conditionsRead) return;
    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      final dio   = Dio();
      await dio.post(
        '$EnvConfig.apiBaseUrl/fein/${widget.offer.id}/confirm',
        data: {
          'role': _isBuyer ? 'BUYER' : 'SELLER',
          'notes': 'Confirmacion de FEIN desde la app.',
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (!mounted) return;
      setState(() => _submitted = true);
      // Invalidate offers lists so urgency provider reflects FEIN confirmed
      ref.invalidate(sentOffersProvider);
      ref.invalidate(receivedOffersProvider);
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = (e.response?.data as Map?)?['detail'] as String?;
      setState(() {
        _errorMessage = detail ??
            'Error al confirmar. Verifica que la tasacion este completada.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          : _submitted
          ? _buildSuccessView()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildInfoBanner(),
                const SizedBox(height: 20),
                _buildWhatIsFein(),
                const SizedBox(height: 20),
                _buildTimeline(),
                const SizedBox(height: 20),
                if (_isBuyer) _buildBuyerConfirmationForm() else _buildSellerWaitView(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildErrorBanner(),
                ],
                const SizedBox(height: 24),
                if (_isBuyer) _buildSubmitButton(),
              ],
            ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kBlue.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBlue.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.account_balance_outlined, color: _kBlue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Paso previo a la Notaria',
                    style: TextStyle(
                        color: _kBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  _isBuyer
                      ? 'Tu banco ha recibido el informe de tasacion y debe emitir la FEIN '
                        'al menos 10 dias antes de la firma. Confirma cuando la hayas recibido.'
                      : 'El banco del comprador esta procesando la FEIN. '
                        'Recibiras una notificacion cuando el comprador confirme.',
                  style: TextStyle(
                      color: _kBlue.withOpacity(0.85), fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatIsFein() {
    const items = [
      ('FEIN', 'Ficha Europea de Informacion Normalizada. Documento oficial del banco con las condiciones definitivas del prestamo.'),
      ('FIPER', 'Ficha de Informacion Personalizada. Version espanola equivalente a la FEIN para prestamos variables.'),
      ('10 dias', 'Plazo obligatorio entre la recepcion de la FEIN y la firma en notaria. Exigido por ley (LCCI 2019).'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Que es la FEIN?',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: _kNavy)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(item.$1,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _kBlue)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item.$2,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    const steps = [
      ('Tasacion completada', 'El banco recibe el informe del tasador', true),
      ('Banco estudia la operacion', 'Calcula riesgo con la tasacion oficial', true),
      ('Banco emite la FEIN', 'Te la envian por correo o app bancaria', false),
      ('Periodo de reflexion (10 dias)', 'Lee con calma todas las condiciones', false),
      ('Firma en Notaria', 'Con la FEIN aceptada, se puede firmar', false),
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
          const Text('Proceso bancario',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: _kNavy)),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((e) {
            final index = e.key;
            final step  = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: step.$3 ? _kGreen : _kBlue.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: step.$3
                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                              : Text('${index + 1}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _kBlue.withOpacity(0.7))),
                        ),
                      ),
                      if (index < steps.length - 1)
                        Container(
                          width: 2,
                          height: 20,
                          color: Colors.grey.shade200,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.$1,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: step.$3 ? _kGreen : _kNavy)),
                        Text(step.$2,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBuyerConfirmationForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirmar recepcion de la FEIN',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: _kNavy)),
          const SizedBox(height: 16),
          _CheckItem(
            value: _feinReceived,
            label: 'He recibido la FEIN/FIPER de mi banco con las condiciones definitivas.',
            onChanged: (v) => setState(() => _feinReceived = v ?? false),
          ),
          const SizedBox(height: 8),
          _CheckItem(
            value: _conditionsRead,
            label: 'He leido y entiendo las condiciones del prestamo (TAE, cuota, vinculaciones).',
            onChanged: (v) => setState(() => _conditionsRead = v ?? false),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tras confirmar, deberan pasar al menos 10 dias antes de poder '
                    'firmar en notaria. Este plazo es obligatorio por ley (LCCI 2019).',
                    style: TextStyle(
                        fontSize: 12, color: Colors.amber.shade900, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerWaitView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty, color: Colors.orange.shade700, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Esperando confirmacion del comprador',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  'El banco del comprador esta tramitando la FEIN. '
                  'Recibiras notificacion cuando el comprador la confirme.',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage!,
                style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _feinReceived && _conditionsRead;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: canSubmit && !_isLoading ? _confirm : null,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.verified_outlined),
        label: const Text('Confirmar recepcion de la FEIN'),
        style: FilledButton.styleFrom(
          backgroundColor: _kBlue,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: _kGreen, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'FEIN confirmada',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: _kNavy),
            ),
            const SizedBox(height: 12),
            Text(
              _isBuyer
                  ? 'Has confirmado la recepcion de la FEIN. El plazo de 10 dias '
                    'es informativo — ya puedes coordinar la cita en notaria.'
                  : 'El comprador ha confirmado la FEIN. Ya podeis coordinar '
                    'la cita en notaria para la firma final.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade600, height: 1.6),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La ley exige 10 dias entre la recepcion de la FEIN y la firma. '
                      'Asegurate de coordinar la cita con ese margen.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(
                  '/offers/${widget.offer.id}/notaria',
                  extra: widget.offer,
                ),
                icon: const Icon(Icons.gavel_outlined),
                label: const Text('Ir a Firma en Notaria'),
                style: FilledButton.styleFrom(
                  backgroundColor: _kBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver al timeline',
                  style: TextStyle(color: _kBlue)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: _kBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

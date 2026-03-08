import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/common/app_bar_back_button.dart';
import '../../../providers/offers_provider.dart';
import '../../../providers/auth_provider.dart';

const _kBlue  = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);
const _kNavy  = Color(0xFF1E3A5F);

/// Pagina de confirmacion de firma ante notario y entrega de llaves.
/// Ambas partes deben confirmar individualmente.
/// Tras la confirmacion del usuario activo, el timeline avanza a Post-Venta.
class NotarySigningPage extends ConsumerStatefulWidget {
  const NotarySigningPage({super.key, required this.offer});

  final OfferData offer;

  @override
  ConsumerState<NotarySigningPage> createState() => _NotarySigningPageState();
}

class _NotarySigningPageState extends ConsumerState<NotarySigningPage> {
  bool _signingConfirmed = false;
  bool _keysConfirmed    = false;
  bool _submitted        = false;
  bool _isLoading        = false;

  Future<void> _submit() async {
    if (!_signingConfirmed || !_keysConfirmed) return;
    setState(() => _isLoading = true);

    // Simulate brief async operation (real: POST /timeline/{step_id}/confirm)
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _submitted  = true;
      _isLoading  = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final isBuyer = currentUser?.id.toString() == widget.offer.buyerId;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBarBackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text(
          'Confirmar Firma y Llaves',
          style: TextStyle(
              color: _kNavy, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: _submitted
          ? _buildSuccessView(context, isBuyer)
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildInfoBanner(isBuyer),
                const SizedBox(height: 20),
                _buildStatusCard(isBuyer),
                const SizedBox(height: 20),
                _buildConfirmationForm(isBuyer),
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
    );
  }

  Widget _buildInfoBanner(bool isBuyer) {
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
          const Icon(Icons.gavel, color: _kBlue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cierre de la transaccion',
                  style: TextStyle(
                      color: _kBlue, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  isBuyer
                      ? 'Confirma que has firmado la escritura publica y '
                        'has recibido las llaves del inmueble.'
                      : 'Confirma que has firmado la escritura publica y '
                        'has entregado las llaves al nuevo propietario.',
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

  Widget _buildStatusCard(bool isBuyer) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Estado de confirmaciones',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: _kNavy),
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: isBuyer ? 'Tu confirmacion (Comprador)' : 'Tu confirmacion (Vendedor)',
            isPending: !_submitted,
            isCurrentUser: true,
          ),
          const SizedBox(height: 8),
          _StatusRow(
            label: isBuyer ? 'Confirmacion del Vendedor' : 'Confirmacion del Comprador',
            isPending: true,
            isCurrentUser: false,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationForm(bool isBuyer) {
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
          const Text(
            'Declaro bajo mi responsabilidad que:',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: _kNavy),
          ),
          const SizedBox(height: 16),
          _CheckItem(
            value: _signingConfirmed,
            label: 'He firmado la escritura publica de compraventa ante notario.',
            onChanged: (v) => setState(() => _signingConfirmed = v ?? false),
          ),
          const SizedBox(height: 12),
          _CheckItem(
            value: _keysConfirmed,
            label: isBuyer
                ? 'He recibido las llaves y tomo posesion del inmueble.'
                : 'He entregado las llaves al comprador y cedo la posesion.',
            onChanged: (v) => setState(() => _keysConfirmed = v ?? false),
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
                Icon(Icons.warning_amber_rounded,
                    color: Colors.amber.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta confirmacion tiene validez legal. '
                    'Solo confirma si la firma ya se ha realizado ante notario.',
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

  Widget _buildSubmitButton() {
    final canSubmit = _signingConfirmed && _keysConfirmed;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: canSubmit && !_isLoading ? _submit : null,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.verified_outlined),
        label: const Text('Confirmar firma y entrega de llaves'),
        style: FilledButton.styleFrom(
          backgroundColor: _kGreen,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, bool isBuyer) {
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
              'Confirmacion registrada',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: _kNavy),
            ),
            const SizedBox(height: 12),
            Text(
              isBuyer
                  ? 'Has confirmado la recepcion de llaves. '
                    'La transaccion avanzara a la fase de Post-Venta '
                    'cuando el vendedor tambien confirme.'
                  : 'Has confirmado la entrega de llaves. '
                    'La transaccion avanzara a la fase de Post-Venta '
                    'cuando el comprador tambien confirme.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade600, height: 1.6),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  context.go('/offers/${widget.offer.id}/post-venta',
                      extra: widget.offer);
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Ir a Post-Venta y Suministros'),
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

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.isPending,
    required this.isCurrentUser,
  });

  final String label;
  final bool isPending;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final color = isPending ? Colors.orange.shade600 : _kGreen;
    final icon  = isPending ? Icons.hourglass_empty : Icons.check_circle;
    final text  = isPending ? 'Pendiente' : 'Confirmado';

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: isCurrentUser ? _kNavy : Colors.grey.shade600)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(text,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ),
      ],
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
              activeColor: _kGreen,
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

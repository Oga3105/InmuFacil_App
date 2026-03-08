import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../widgets/common/app_bar_back_button.dart';
import '../../../providers/offers_provider.dart';
import '../../../providers/auth_provider.dart';

const _kBlue  = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);
const _kNavy  = Color(0xFF001F3F);
const _storage = FlutterSecureStorage();
const String _kApiBase = 'http://localhost:8000/api/v1';

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
  bool _submitted       = false;
  String? _errorMessage;

  bool get _isBuyer =>
      ref.read(authProvider).user?.id.toString() == widget.offer.buyerId;

  Future<void> _confirm() async {
    if (!_feinReceived || !_conditionsRead) return;
    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final dio   = Dio();
      await dio.post(
        '$_kApiBase/fein/${widget.offer.id}/confirm',
        data: {
          'role': _isBuyer ? 'BUYER' : 'SELLER',
          'notes': 'Confirmacion de FEIN desde la app.',
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted) setState(() => _submitted = true);
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBarBackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text(
          'Formalizacion Bancaria (FEIN)',
          style: TextStyle(
              color: _kNavy, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: _submitted
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
              'Has confirmado la recepcion de la FEIN. '
              'Recuerda que deberan pasar al menos 10 dias antes de la firma en notaria.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade600, height: 1.6),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kBlue.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: _kBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Proximo paso',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _kBlue,
                                fontSize: 13)),
                        Text('Coordina la cita en notaria cuando hayan pasado 10 dias.',
                            style: TextStyle(
                                fontSize: 12, color: _kBlue.withOpacity(0.8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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

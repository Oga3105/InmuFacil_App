import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/formatters/currency_input_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/offers_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBlue  = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);

// ── Provider ──────────────────────────────────────────────────────────────────
const String _kBase = 'http://localhost:8000/api/v1';

final _arrasProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, offerId) async {
  final token = await const FlutterSecureStorage().read(key: 'auth_token');
  if (token == null) return null;

  final dio = Dio();
  try {
    final resp = await dio.get(
      '$_kBase/arras/$offerId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return resp.data as Map<String, dynamic>;
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ArrasInterviewScreen extends ConsumerStatefulWidget {
  const ArrasInterviewScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  ConsumerState<ArrasInterviewScreen> createState() => _ArrasInterviewScreenState();
}

class _ArrasInterviewScreenState extends ConsumerState<ArrasInterviewScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // Form values
  int _depositPct = 10;
  int _deadlineDays = 60;
  String? _paymentMethod;
  String? _notaryCity;
  final _conditionsCtrl = TextEditingController();

  bool get _canConfirm =>
      _paymentMethod != null && _notaryCity != null && _notaryCity!.isNotEmpty;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _conditionsCtrl.dispose();
    super.dispose();
  }

  Future<Dio?> _buildDio() async {
    final token = await const FlutterSecureStorage().read(key: 'auth_token');
    if (token == null) return null;
    return Dio(BaseOptions(
      baseUrl: _kBase,
      headers: {'Authorization': 'Bearer $token'},
    ));
  }

  Future<void> _saveAndNext() async {
    final dio = await _buildDio();
    if (dio == null) return;
    try {
      await dio.post('/arras/${widget.offer.id}', data: {
        'deposit_percentage': _depositPct,
        'deadline_days': _deadlineDays,
        'payment_method': _paymentMethod,
        'notary_city': _notaryCity,
        'additional_conditions': _conditionsCtrl.text.isEmpty ? null : _conditionsCtrl.text,
      });
      ref.invalidate(_arrasProvider(widget.offer.id));
      if (mounted) {
        _pageCtrl.nextPage(
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar. Intenta de nuevo.')),
        );
      }
    }
  }

  Future<void> _confirm() async {
    final dio = await _buildDio();
    if (dio == null) return;
    try {
      await dio.post('/arras/${widget.offer.id}/confirm');
      ref.invalidate(_arrasProvider(widget.offer.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrevista confirmada. Se ha generado el borrador del contrato.'),
            backgroundColor: _kGreen,
          ),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al confirmar. Intenta de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final arrasAsync = ref.watch(_arrasProvider(widget.offer.id));
    final currentUser = ref.watch(authProvider).user;
    final isBuyer = currentUser?.id == widget.offer.buyerId;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBarBackButton(onPressed: () => context.pop()),
        title: const Text(
          'Entrevista de Arras',
          style: TextStyle(color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: arrasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (_, __) => _buildInterviewView(isBuyer, false, false, false),
        data: (data) {
          final d = data ?? {};
          final buyerConfirmed = d['buyer_confirmed'] == true;
          final sellerConfirmed = d['seller_confirmed'] == true;
          final myConfirmed = isBuyer ? buyerConfirmed : sellerConfirmed;
          final isComplete = d['is_complete'] == true;
          return isComplete
              ? _buildCompletedView(d)
              : _buildInterviewView(isBuyer, myConfirmed, buyerConfirmed, sellerConfirmed);
        },
      ),
    );
  }

  Widget _buildCompletedView(Map<String, dynamic> data) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: _kGreen, size: 56),
            ),
            const SizedBox(height: 24),
            const Text(
              'Acuerdo alcanzado',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
            ),
            const SizedBox(height: 12),
            Text(
              'Ambas partes han confirmado la entrevista.\nEl borrador del contrato de arras esta listo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            _SummaryCard(data: data, offerAmount: widget.offer.amount),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // TODO: download PDF via /arras/{offerId}/pdf
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Descargando borrador PDF...')),
                );
              },
              icon: const Icon(Icons.download_outlined),
              label: const Text('Descargar borrador PDF'),
              style: FilledButton.styleFrom(
                backgroundColor: _kBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewView(
      bool isBuyer, bool myConfirmed, bool buyerConfirmed, bool sellerConfirmed) {
    return Column(
      children: [
        // Status banner
        _StatusBanner(
          isBuyer: isBuyer,
          buyerConfirmed: buyerConfirmed,
          sellerConfirmed: sellerConfirmed,
        ),
        // Progress
        LinearProgressIndicator(
          value: (_page + 1) / 3,
          backgroundColor: Colors.grey.shade200,
          color: _kBlue,
          minHeight: 3,
        ),
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (p) => setState(() => _page = p),
            children: [
              _buildPage1(),
              _buildPage2(),
              _buildPage3(myConfirmed),
            ],
          ),
        ),
        _buildBottomBar(myConfirmed),
      ],
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            icon: Icons.payments_outlined,
            title: 'Cantidad de Arras',
            subtitle: 'Porcentaje del precio de la oferta',
          ),
          const SizedBox(height: 24),
          _InterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_depositPct%',
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold, color: _kBlue),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${CurrencyInputFormatter.format(widget.offer.amount * _depositPct ~/ 100)} EUR',
                        style: const TextStyle(
                            color: _kBlue, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Importe de las arras sobre ${CurrencyInputFormatter.format(widget.offer.amount)} EUR',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                Slider(
                  value: _depositPct.toDouble(),
                  min: 5,
                  max: 20,
                  divisions: 15,
                  activeColor: _kBlue,
                  inactiveColor: Colors.grey.shade200,
                  onChanged: (v) => setState(() => _depositPct = v.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('5%', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    Text('20%', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'El vendedor pierde el doble si se echa atras. El comprador pierde las arras si desiste.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            icon: Icons.calendar_month_outlined,
            title: 'Plazo y Condiciones',
            subtitle: 'Tiempo para formalizar en notaria',
          ),
          const SizedBox(height: 24),
          _InterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_deadlineDays dias',
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold, color: _kBlue),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '~${(_deadlineDays / 30).toStringAsFixed(1)} meses',
                        style: const TextStyle(
                            color: _kGreen, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _deadlineDays.toDouble(),
                  min: 15,
                  max: 180,
                  divisions: 11,
                  activeColor: _kBlue,
                  inactiveColor: Colors.grey.shade200,
                  onChanged: (v) => setState(() => _deadlineDays = v.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('15 dias', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    Text('180 dias', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Condiciones adicionales (opcional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A5F)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ej: Sujeto a hipoteca, libre de cargas, etc.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _conditionsCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Escribe aqui cualquier condicion especial...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kBlue, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3(bool myConfirmed) {
    final methods = [
      ('cash', 'Pago al contado', Icons.payments_outlined),
      ('mortgage_approved', 'Hipoteca aprobada', Icons.check_circle_outline),
      ('mortgage_pending', 'Hipoteca en tramitacion', Icons.hourglass_empty_outlined),
      ('house_to_sell', 'Venta de vivienda actual', Icons.home_outlined),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            icon: Icons.location_city_outlined,
            title: 'Resumen y Confirmacion',
            subtitle: 'Revisa los datos antes de confirmar',
          ),
          const SizedBox(height: 24),
          _InterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financiacion del comprador',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A5F)),
                ),
                const SizedBox(height: 12),
                ...methods.map((m) => _MethodTile(
                      value: m.$1,
                      label: m.$2,
                      icon: m.$3,
                      selected: _paymentMethod == m.$1,
                      onTap: () => setState(() => _paymentMethod = m.$1),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InterviewCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ciudad de la notaria (referencia)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A5F)),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _notaryCity = v),
                  decoration: InputDecoration(
                    hintText: 'Ej: Sevilla',
                    prefixIcon: const Icon(Icons.location_on_outlined, color: _kBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kBlue, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SummaryCard(
            data: {
              'deposit_percentage': _depositPct,
              'deposit_amount': widget.offer.amount * _depositPct ~/ 100,
              'deadline_days': _deadlineDays,
              'payment_method': _paymentMethod,
              'notary_city': _notaryCity,
            },
            offerAmount: widget.offer.amount,
          ),
          if (myConfirmed)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: _kGreen, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Has confirmado tu parte. Esperando confirmacion de la otra parte.',
                      style: TextStyle(color: _kGreen, fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool myConfirmed) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          if (_page > 0)
            OutlinedButton(
              onPressed: () => _pageCtrl.previousPage(
                  duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Atras', style: TextStyle(color: Colors.grey.shade700)),
            ),
          const Spacer(),
          if (_page < 2)
            FilledButton(
              onPressed: _saveAndNext,
              style: FilledButton.styleFrom(
                backgroundColor: _kBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              ),
              child: const Text('Continuar', style: TextStyle(color: Colors.white)),
            )
          else if (!myConfirmed)
            FilledButton.icon(
              onPressed: _canConfirm ? _confirm : null,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirmar mi parte'),
              style: FilledButton.styleFrom(
                backgroundColor: _kGreen,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _kBlue, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InterviewCard extends StatelessWidget {
  const _InterviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner(
      {required this.isBuyer,
      required this.buyerConfirmed,
      required this.sellerConfirmed});

  final bool isBuyer;
  final bool buyerConfirmed;
  final bool sellerConfirmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E3A5F),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _Badge(label: 'Comprador', confirmed: buyerConfirmed),
          const Spacer(),
          _Badge(label: 'Vendedor', confirmed: sellerConfirmed),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.confirmed});

  final String label;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          confirmed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: confirmed ? _kGreen : Colors.white38,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: confirmed ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: confirmed ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data, required this.offerAmount});

  final Map<String, dynamic> data;
  final int offerAmount;

  @override
  Widget build(BuildContext context) {
    final pct = data['deposit_percentage'];
    final days = data['deadline_days'];
    final method = data['payment_method'];
    final city = data['notary_city'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen del acuerdo',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          _SummaryRow(
              label: 'Precio oferta',
              value: '${CurrencyInputFormatter.format(offerAmount)} EUR'),
          if (pct != null)
            _SummaryRow(
                label: 'Arras ($pct%)',
                value: '${CurrencyInputFormatter.format(offerAmount * pct ~/ 100)} EUR'),
          if (days != null)
            _SummaryRow(label: 'Plazo', value: '$days dias'),
          if (method != null)
            _SummaryRow(label: 'Financiacion', value: _methodLabel(method)),
          if (city != null && city.isNotEmpty)
            _SummaryRow(label: 'Notaria', value: city),
        ],
      ),
    );
  }

  String _methodLabel(String key) {
    const map = {
      'cash': 'Contado',
      'mortgage_approved': 'Hipoteca aprobada',
      'mortgage_pending': 'Hipoteca en tramite',
      'house_to_sell': 'Venta vivienda actual',
    };
    return map[key] ?? key;
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _kBlue.withOpacity(0.06) : Colors.transparent,
          border: Border.all(
              color: selected ? _kBlue : Colors.grey.shade200, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? _kBlue : Colors.grey.shade400, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? _kBlue : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            if (selected) const Icon(Icons.check_circle, color: _kBlue, size: 18),
          ],
        ),
      ),
    );
  }
}

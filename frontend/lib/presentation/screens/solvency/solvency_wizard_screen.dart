import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatters/currency_input_formatter.dart';
import '../../providers/solvency_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kNavy     = Color(0xFF2563EB);
const _kGold     = Color(0xFFB8860B);
const _kGoldBg   = Color(0xFFFFF8E1);
const _kGreen    = Color(0xFF16A34A);
const _kAmber    = Color(0xFFD97706);

class SolvencyWizardScreen extends ConsumerStatefulWidget {
  const SolvencyWizardScreen({super.key});

  @override
  ConsumerState<SolvencyWizardScreen> createState() => _SolvencyWizardScreenState();
}

class _SolvencyWizardScreenState extends ConsumerState<SolvencyWizardScreen> {
  final _pageController = PageController();
  int _page = 0;

  // Layer 0 — Tipo de compra (Sprint V10)
  bool? _isMultiBuyer;

  // Layer 1 — Disclaimer
  bool _termsAccepted = false;

  // Layer 2 — Devil's Advocate
  bool? _knowsExtraCosts;
  double _debtRatio = 0.20;
  bool? _hasEmergencyFund;

  // Layer 3 — Solvency Declaration
  String? _paymentMethod;
  bool? _hasInitialSavings;
  bool? _hasPreApproval;

  // Layer 4 — ADN Financiero (optional quantitative fields; totals for all buyers)
  final _incomeCtrl  = TextEditingController();
  final _savingsCtrl = TextEditingController();
  final _debtCtrl    = TextEditingController();

  static const int _totalPages = 5;

  bool get _canNext {
    switch (_page) {
      case 0: return _isMultiBuyer != null;
      case 1: return _termsAccepted;
      case 2: return _knowsExtraCosts != null && _hasEmergencyFund != null;
      case 3: return _paymentMethod != null && _hasInitialSavings != null && _hasPreApproval != null;
      case 4: return true; // ADN Financiero is optional
      default: return true;
    }
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    final income = int.tryParse(_incomeCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    final savings = int.tryParse(_savingsCtrl.text.replaceAll('.', '').replaceAll(',', ''));
    final debt = int.tryParse(_debtCtrl.text.replaceAll('.', '').replaceAll(',', ''));

    try {
      await ref.read(solvencyNotifierProvider.notifier).submit(
        termsAccepted: _termsAccepted,
        knowsExtraCosts: _knowsExtraCosts!,
        debtRatio: _debtRatio,
        hasEmergencyFund: _hasEmergencyFund!,
        paymentMethod: _paymentMethod!,
        hasInitialSavings: _hasInitialSavings!,
        hasPreApproval: _hasPreApproval!,
        netMonthlyIncome: income,
        totalSavings: savings,
        totalMonthlyDebt: debt,
        isMultiBuyer: _isMultiBuyer ?? false,
      );
      if (mounted) context.go('/solvency/passport');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _incomeCtrl.dispose();
    _savingsCtrl.dispose();
    _debtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(solvencyNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarCloseButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
          ),
        ),
        title: GestureDetector(
          onTap: () => context.go('/'),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo_inmufacil.png', height: 28),
                const SizedBox(width: 8),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: 'Inmu', style: TextStyle(color: Color(0xFF2563EB))),
                      TextSpan(text: 'Facil', style: TextStyle(color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _kNavy,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _kNavy.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Text('Inicio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          const UserAvatarMenu(),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_page + 1) / _totalPages,
            backgroundColor: Colors.grey.shade200,
            color: _kNavy,
            minHeight: 4,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Paso ${_page + 1} de $_totalPages',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  ['Tipo de Compra', 'Aviso Legal', 'Conciencia Financiera', 'Declaracion', 'ADN Financiero'][_page],
                  style: const TextStyle(color: _kNavy, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (p) => setState(() => _page = p),
              children: [
                _buildPage0(),
                _buildPage1(),
                _buildPage2(),
                _buildPage3(),
                _buildPage4(),
              ],
            ),
          ),
          // Bottom nav
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_page > 0)
                  OutlinedButton(
                    onPressed: isLoading ? null : () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      side: const BorderSide(color: _kNavy),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Anterior', style: TextStyle(color: _kNavy)),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: (_canNext && !isLoading) ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kNavy,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isLoading && _page == _totalPages - 1
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _page < _totalPages - 1 ? 'Continuar' : 'Obtener mi Pasaporte',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Solvency preview (mirrors backend _compute_solvency) ─────────────────

  /// Returns ('gold'|'silver'|'bronze', score) based on current wizard state.
  (String, int) _previewSolvencyLevel() {
    int score = 0;
    if (_knowsExtraCosts == true) score += 1;
    if (_debtRatio < 0.35) score += 1;
    if (_hasEmergencyFund == true) score += 1;
    if (_hasInitialSavings == true) score += 1;
    if (_paymentMethod == 'cash' || _paymentMethod == 'mortgage_approved') {
      score += 2;
    } else if (_paymentMethod == 'mortgage_pending' || _paymentMethod == 'savings_plus_mortgage') {
      score += 1;
    }
    if (_hasPreApproval == true) score += 1;

    if (score >= 6) return ('gold', score);
    if (score >= 4) return ('silver', score);
    return ('bronze', score);
  }

  // ── Page 0: Tipo de compra ────────────────────────────────────────────────

  Widget _buildPage0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de compra',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kNavy),
          ),
          const SizedBox(height: 8),
          Text(
            'Para personalizar tu pasaporte necesitamos saber cuantos titulares participan en la compra.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 32),
          _BuyerTypeCard(
            selected: _isMultiBuyer == false,
            icon: Icons.person_outline,
            title: 'Solo yo',
            subtitle: 'Compra individual. Solo tu figura como titular.',
            onTap: () => setState(() => _isMultiBuyer = false),
          ),
          const SizedBox(height: 16),
          _BuyerTypeCard(
            selected: _isMultiBuyer == true,
            icon: Icons.group_outlined,
            title: 'Con alguien mas',
            subtitle: 'Compra conjunta: pareja, familiar u otro cotitular.',
            onTap: () => setState(() => _isMultiBuyer = true),
          ),
          if (_isMultiBuyer == true) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kNavy.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kNavy.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: _kNavy, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Perfecto. En los siguientes pasos introduce los datos financieros SUMADOS de ambos titulares. Mas adelante solicitaremos la verificacion de identidad del segundo titular.',
                      style: TextStyle(fontSize: 13, color: _kNavy, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Page 1: Disclaimer ────────────────────────────────────────────────────

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.gavel_outlined,
                title: 'Aviso de Responsabilidad Civil',
                subtitle: 'Lee atentamente antes de continuar',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kGoldBg,
                  border: Border.all(color: _kGold.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Este Pasaporte de Solvencia es una declaración voluntaria y veraz de tu situación '
                  'financiera. La información que proporciones no es verificada por InmuFácil y '
                  'su uso indebido puede acarrear responsabilidad civil.\n\n'
                  'InmuFácil actúa como plataforma neutral. La decisión final de aceptar o '
                  'rechazar una oferta basándose en este pasaporte corresponde exclusivamente '
                  'a cada vendedor.\n\n'
                  'Tus datos son procesados conforme al RGPD/LOPD y se eliminarán '
                  'automáticamente a los 90 días.',
                  style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF78350F)),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                      activeColor: _kNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'He leído y acepto los términos de responsabilidad. Declaro que la información que voy a proporcionar es veraz.',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Page 2: Financial Awareness ───────────────────────────────────────────

  Widget _buildPage2() {
    final stressLabel = _debtRatio > 0.38
        ? ('Alto riesgo', Colors.red)
        : _debtRatio > 0.35
            ? ('Riesgo medio', Colors.orange)
            : ('Bajo riesgo', _kGreen);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.psychology_outlined,
                title: 'Conciencia Financiera',
                subtitle: 'El "Abogado del Diablo" — seamos honestos',
              ),
              const SizedBox(height: 24),

              // Costs awareness
              _YesNoQuestion(
                question: _isMultiBuyer == true
                    ? '¿Habeis tenido en cuenta los gastos adicionales de la compra?\n(ITP/IVA, notaria, gestoria, registro...)'
                    : '¿Conoces los gastos adicionales de la compra?\n(ITP/IVA, notaria, gestoria, registro...)',
                hint: 'Generalmente un 10-15% adicional sobre el precio de compra.',
                value: _knowsExtraCosts,
                onChanged: (v) => setState(() => _knowsExtraCosts = v),
              ),
              const SizedBox(height: 24),

              // Debt ratio
              _WizardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ratio de endeudamiento mensual',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kNavy),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Deudas mensuales totales ÷ ingresos netos mensuales',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(_debtRatio * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _kNavy),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: stressLabel.$2.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            stressLabel.$1,
                            style: TextStyle(color: stressLabel.$2, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _debtRatio,
                      min: 0.0,
                      max: 0.80,
                      divisions: 80,
                      activeColor: _kNavy,
                      inactiveColor: Colors.grey.shade200,
                      onChanged: (v) => setState(() => _debtRatio = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0%', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        Text('80%', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_debtRatio > 0.35)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 16),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Los bancos generalmente no conceden hipotecas si superas el 35%.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Emergency fund
              _YesNoQuestion(
                question: _isMultiBuyer == true
                    ? '¿Contais con un fondo de emergencia de al menos 3-6 meses de gastos?'
                    : '¿Cuentas con un fondo de emergencia de al menos 3-6 meses de gastos?',
                hint: 'Independiente del dinero para la compra.',
                value: _hasEmergencyFund,
                onChanged: (v) => setState(() => _hasEmergencyFund = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Page 3: Solvency Declaration ──────────────────────────────────────────

  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.verified_user_outlined,
                title: 'Declaración de Solvencia',
                subtitle: 'Tu situación real de financiación',
              ),
              const SizedBox(height: 24),

              // Payment method
              _WizardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Cómo planeas financiar la compra?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kNavy),
                    ),
                    const SizedBox(height: 16),
                    ...[
                      ('cash', 'Pago al contado', Icons.payments_outlined),
                      ('mortgage_approved', 'Hipoteca aprobada', Icons.check_circle_outline),
                      ('mortgage_pending', 'Hipoteca en tramitacion', Icons.hourglass_empty_outlined),
                      ('savings_plus_mortgage', 'Ahorros + hipoteca', Icons.account_balance_outlined),
                      ('house_to_sell', 'Venta de vivienda actual', Icons.home_outlined),
                      ('bridge_mortgage', 'Hipoteca puente', Icons.swap_horiz_outlined),
                    ].map((opt) => _OptionTile(
                          value: opt.$1,
                          label: opt.$2,
                          icon: opt.$3,
                          selected: _paymentMethod == opt.$1,
                          onTap: () => setState(() => _paymentMethod = opt.$1),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _YesNoQuestion(
                question: _isMultiBuyer == true
                    ? '¿Disponeis de ahorros iniciales para la entrada y gastos?'
                    : '¿Dispones de ahorros iniciales para la entrada y gastos?',
                hint: 'Habitualmente entre un 20-30% del precio de la propiedad.',
                value: _hasInitialSavings,
                onChanged: (v) => setState(() => _hasInitialSavings = v),
              ),
              const SizedBox(height: 24),

              _YesNoQuestion(
                question: _isMultiBuyer == true
                    ? '¿Teneis una preaprobacion hipotecaria de un banco?'
                    : '¿Tienes una preaprobacion hipotecaria de un banco?',
                hint: 'Un documento oficial que confirma que el banco te prestaria el dinero.',
                value: _hasPreApproval,
                onChanged: (v) => setState(() => _hasPreApproval = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Page 4: ADN Financiero (optional) ───────────────────────────────────────

  Widget _buildPage4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.analytics_outlined,
                title: 'ADN Financiero',
                subtitle: 'Calculo personalizado de viabilidad — opcional y privado',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Estos datos se cifran con AES-256. El vendedor NUNCA ve tus ingresos ni deudas — solo recibe el resultado de viabilidad (Verde/Ambar/Rojo).',
                        style: TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SolvencyPreviewCard(level: _previewSolvencyLevel()),
              const SizedBox(height: 20),
              _MoneyField(
                controller: _incomeCtrl,
                label: _isMultiBuyer == true
                    ? 'Ingresos netos mensuales (total compradores)'
                    : 'Ingresos netos mensuales',
                hint: 'ej. 2.500',
                icon: Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(height: 16),
              _MoneyField(
                controller: _savingsCtrl,
                label: _isMultiBuyer == true
                    ? 'Ahorros liquidos totales (suma de compradores)'
                    : 'Ahorros liquidos totales',
                hint: 'ej. 50.000',
                icon: Icons.savings_outlined,
              ),
              const SizedBox(height: 16),
              _MoneyField(
                controller: _debtCtrl,
                label: _isMultiBuyer == true
                    ? 'Deudas mensuales actuales (total compradores)'
                    : 'Deudas mensuales actuales',
                hint: 'ej. 300 (prestamos, tarjetas...)',
                icon: Icons.credit_card_outlined,
              ),
              const SizedBox(height: 24),
              Text(
                'Si prefieres no rellenar estos campos ahora, puedes hacerlo mas adelante actualizando tu pasaporte.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title, required this.subtitle});

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
            color: _kNavy.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _kNavy, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kNavy)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _WizardCard extends StatelessWidget {
  const _WizardCard({required this.child});

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

class _YesNoQuestion extends StatelessWidget {
  const _YesNoQuestion({
    required this.question,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String question;
  final String hint;
  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _WizardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kNavy)),
          const SizedBox(height: 4),
          Text(hint, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ChoiceBtn(
                  label: 'Si',
                  selected: value == true,
                  selectedColor: _kGreen,
                  icon: Icons.check_circle_outline,
                  onTap: () => onChanged(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceBtn(
                  label: 'No',
                  selected: value == false,
                  selectedColor: Colors.red.shade600,
                  icon: Icons.cancel_outlined,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceBtn extends StatelessWidget {
  const _ChoiceBtn({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? selectedColor.withOpacity(0.1) : Colors.grey.shade50,
          border: Border.all(color: selected ? selectedColor : Colors.grey.shade300, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? selectedColor : Colors.grey.shade400, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? selectedColor : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
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
          color: selected ? _kNavy.withOpacity(0.06) : Colors.transparent,
          border: Border.all(color: selected ? _kNavy : Colors.grey.shade200, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? _kNavy : Colors.grey.shade400, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? _kNavy : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle, color: _kNavy, size: 18),
          ],
        ),
      ),
    );
  }
}


class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [CurrencyInputFormatter()],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _kNavy, size: 20),
        suffixText: 'EUR',
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kNavy, width: 2),
        ),
      ),
    );
  }
}

// ── Solvency preview semaphore ────────────────────────────────────────────────

class _SolvencyPreviewCard extends StatelessWidget {
  const _SolvencyPreviewCard({required this.level});

  final (String, int) level;

  @override
  Widget build(BuildContext context) {
    final (levelKey, score) = level;

    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final IconData icon;
    final String levelLabel;
    final String description;

    switch (levelKey) {
      case 'gold':
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFCD34D);
        iconColor = _kGold;
        icon = Icons.emoji_events_outlined;
        levelLabel = 'Oro';
        description = 'Perfil financiero solido. Destaca frente a otros compradores.';
      case 'silver':
        bgColor = const Color(0xFFF8FAFC);
        borderColor = const Color(0xFF94A3B8);
        iconColor = const Color(0xFF64748B);
        icon = Icons.verified_outlined;
        levelLabel = 'Plata';
        description = 'Buen perfil. Puedes mejorar con preaprobacion hipotecaria o menor endeudamiento.';
      default:
        bgColor = const Color(0xFFFFF7ED);
        borderColor = const Color(0xFFFDBA74);
        iconColor = _kAmber;
        icon = Icons.shield_outlined;
        levelLabel = 'Bronce';
        description = 'Perfil basico. Completar el ADN Financiero puede mejorar tu puntuacion.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Estimacion: ',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    Text(
                      'Nivel $levelLabel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$score/7 pts',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyerTypeCard extends StatelessWidget {
  const _BuyerTypeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? _kNavy.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _kNavy : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? _kNavy.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: selected ? _kNavy : Colors.grey.shade400, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: selected ? _kNavy : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: _kNavy, size: 20),
          ],
        ),
      ),
    );
  }
}

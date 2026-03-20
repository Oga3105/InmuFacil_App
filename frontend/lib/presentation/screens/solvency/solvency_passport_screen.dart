import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/solvency_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kNavy  = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);

class SolvencyPassportScreen extends ConsumerWidget {
  const SolvencyPassportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mySolvencyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
          ),
        ),
        title: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/'),
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
                      TextSpan(text: 'Fácil', style: TextStyle(color: Color(0xFF16A34A))),
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
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kNavy)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Error al cargar: $e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(mySolvencyProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (passport) {
          if (passport == null) return _buildEmpty(context);
          return _buildPassport(context, ref, passport);
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _kNavy.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, size: 56, color: _kNavy),
              ),
              const SizedBox(height: 24),
              const Text(
                'Aun no tienes un Pasaporte',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kNavy),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Completa el asistente para obtener tu nivel de solvencia y mostrar a los vendedores que eres un comprador serio.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.push('/solvency/wizard'),
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text('Completar el Asistente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassport(BuildContext context, WidgetRef ref, SolvencyPassport passport) {
    final level = passport.solvencyLevel ?? 'bronze';
    final levelCfg = _levelConfig(level);
    final stressLabel = _stressLabel(passport.stressIndex);

    final daysLeft = passport.expiresAt != null
        ? passport.expiresAt!.difference(DateTime.now()).inDays
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              // ── Main passport card ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [levelCfg.gradStart, levelCfg.gradEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: levelCfg.shadow,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_rounded, color: levelCfg.iconColor, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PASAPORTE DE SOLVENCIA',
                              style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Nivel ${levelCfg.label}',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            levelCfg.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Expiry
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          passport.expiresAt != null
                              ? 'Expira el ${_formatDate(passport.expiresAt!)} ($daysLeft dias)'
                              : 'Sin caducidad',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: daysLeft > 30 ? _kGreen : Colors.orange.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            daysLeft > 30 ? 'Valido' : 'Proxima caducidad',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Stress index ───────────────────────────────────────────────
              _InfoCard(
                title: 'Indice de Estres Financiero',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: stressLabel.$2.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stressLabel.$1,
                        style: TextStyle(color: stressLabel.$2, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Ratio de endeudamiento: ${((passport.debtRatio ?? 0) * 100).toStringAsFixed(0)}%',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Checklist ──────────────────────────────────────────────────
              _InfoCard(
                title: 'Resumen de Declaracion',
                child: Column(
                  children: [
                    _CheckRow('Conoce los gastos adicionales', passport.knowsExtraCosts == true),
                    _CheckRow('Tiene fondo de emergencia', passport.hasEmergencyFund == true),
                    _CheckRow('Tiene ahorros iniciales', passport.hasInitialSavings == true),
                    _CheckRow('Tiene preaprobacion hipotecaria', passport.hasPreApproval == true),
                    _CheckRow(
                      'Metodo de pago: ${_paymentLabel(passport.paymentMethod)}',
                      passport.paymentMethod != null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Actions ────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/solvency/wizard'),
                      icon: const Icon(Icons.refresh, size: 18, color: _kNavy),
                      label: const Text('Actualizar', style: TextStyle(color: _kNavy)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: _kNavy),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/profile'),
                      icon: const Icon(Icons.person_outline, size: 18, color: Colors.white),
                      label: const Text('Ir al perfil', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kNavy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                'Este pasaporte es visible de forma anonima para los vendedores de las propiedades a las que hayas hecho una oferta.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kNavy),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow(this.label, this.ok);

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: ok ? _kGreen : Colors.grey.shade400,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13, color: ok ? const Color(0xFF1E293B) : Colors.grey.shade500)),
          ),
        ],
      ),
    );
  }
}

// ── Config helpers ────────────────────────────────────────────────────────────

class _LevelConfig {
  const _LevelConfig({
    required this.label,
    required this.emoji,
    required this.gradStart,
    required this.gradEnd,
    required this.shadow,
    required this.iconColor,
  });

  final String label;
  final String emoji;
  final Color gradStart;
  final Color gradEnd;
  final Color shadow;
  final Color iconColor;
}

_LevelConfig _levelConfig(String level) {
  switch (level) {
    case 'gold':
      return _LevelConfig(
        label: 'Oro',
        emoji: 'Oro',
        gradStart: const Color(0xFFB8860B),
        gradEnd: const Color(0xFF996515),
        shadow: const Color(0xFFB8860B).withOpacity(0.4),
        iconColor: const Color(0xFFFFD700),
      );
    case 'silver':
      return _LevelConfig(
        label: 'Plata',
        emoji: 'Plata',
        gradStart: const Color(0xFF64748B),
        gradEnd: const Color(0xFF475569),
        shadow: const Color(0xFF64748B).withOpacity(0.3),
        iconColor: Colors.white,
      );
    default: // bronze
      return _LevelConfig(
        label: 'Bronce',
        emoji: 'Bronce',
        gradStart: const Color(0xFFCD7F32),
        gradEnd: const Color(0xFFAB6A2A),
        shadow: const Color(0xFFCD7F32).withOpacity(0.3),
        iconColor: Colors.white,
      );
  }
}

(String, Color) _stressLabel(String? index) {
  switch (index) {
    case 'low_risk':   return ('Bajo riesgo',   const Color(0xFF16A34A));
    case 'medium_risk': return ('Riesgo medio', Colors.orange);
    case 'high_risk':  return ('Alto riesgo',   Colors.red);
    default:           return ('Desconocido',   Colors.grey);
  }
}

String _paymentLabel(String? method) {
  switch (method) {
    case 'cash':                   return 'Pago al contado';
    case 'mortgage_approved':      return 'Hipoteca aprobada';
    case 'mortgage_pending':       return 'Hipoteca en tramite';
    case 'house_to_sell':          return 'Venta de vivienda';
    case 'savings_plus_mortgage':  return 'Ahorros + hipoteca';
    case 'bridge_mortgage':        return 'Hipoteca puente';
    default:                       return 'No especificado';
  }
}

String _formatDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

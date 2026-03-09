import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import '../../providers/auth_provider.dart';
import '../../providers/solvency_provider.dart' as solvency_prov;

const _kBlue  = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);
const _kNavy  = Color(0xFF2563EB);

// Nivel de confianza
enum _TrustLevel { bronze, silver, gold }

_TrustLevel _levelFromSolvency(String? level) {
  switch (level) {
    case 'gold':
      return _TrustLevel.gold;
    case 'silver':
      return _TrustLevel.silver;
    default:
      return _TrustLevel.bronze;
  }
}

class TrustDashboardScreen extends ConsumerWidget {
  const TrustDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).user;
    final solvencyAsync = ref.watch(solvency_prov.mySolvencyProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
        ),
        title: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
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
                      TextSpan(text: 'Inmu', style: TextStyle(color: _kBlue)),
                      TextSpan(text: 'Facil', style: TextStyle(color: _kGreen)),
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
                  color: _kBlue,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue.withOpacity(0.25),
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
      body: solvencyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (_, __) => _buildNoPassport(context),
        data: (passport) => passport == null
            ? _buildNoPassport(context)
            : _buildDashboard(context, passport, currentUser),
      ),
    );
  }

  Widget _buildNoPassport(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.workspace_premium_outlined,
                  size: 52, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sin pasaporte de solvencia',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: _kNavy),
            ),
            const SizedBox(height: 10),
            Text(
              'Completa el Pasaporte de Solvencia Consciente para obtener tu nivel de confianza.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.go('/solvency/wizard'),
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('Completar pasaporte'),
              style: FilledButton.styleFrom(
                backgroundColor: _kBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    solvency_prov.SolvencyPassport passport,
    dynamic user,
  ) {
    final level = _levelFromSolvency(passport.solvencyLevel);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _LevelHeroCard(level: level, userName: user?.fullName ?? 'Usuario'),
        const SizedBox(height: 24),
        _TrustFactorsCard(passport: passport),
        const SizedBox(height: 20),
        _LevelExplainerCard(),
        const SizedBox(height: 20),
        _BenefitsCard(level: level),
        const SizedBox(height: 20),
        _ExpiryCard(expiresAt: passport.expiresAt),
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _LevelHeroCard extends StatelessWidget {
  const _LevelHeroCard({required this.level, required this.userName});

  final _TrustLevel level;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final config = _levelConfig(level);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: config.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: config.gradient[0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(config.icon, color: Colors.white, size: 56),
          const SizedBox(height: 16),
          Text(
            config.label,
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Nivel de confianza de $userName',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            config.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white60, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _TrustFactorsCard extends StatelessWidget {
  const _TrustFactorsCard({required this.passport});

  final solvency_prov.SolvencyPassport passport;

  @override
  Widget build(BuildContext context) {
    final factors = [
      _Factor(
        label: 'Conoce los gastos adicionales',
        value: passport.knowsExtraCosts == true,
        icon: Icons.school_outlined,
      ),
      _Factor(
        label: 'Ratio de endeudamiento < 35%',
        value: (passport.debtRatio ?? 1.0) < 0.35,
        icon: Icons.trending_down_outlined,
      ),
      _Factor(
        label: 'Fondo de emergencia',
        value: passport.hasEmergencyFund == true,
        icon: Icons.savings_outlined,
      ),
      _Factor(
        label: 'Ahorros iniciales',
        value: passport.hasInitialSavings == true,
        icon: Icons.account_balance_wallet_outlined,
      ),
      _Factor(
        label: 'Preaprobacion hipotecaria',
        value: passport.hasPreApproval == true,
        icon: Icons.verified_outlined,
      ),
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
          const Text(
            'Factores de confianza',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: _kNavy),
          ),
          const SizedBox(height: 16),
          ...factors.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      f.value ? Icons.check_circle : Icons.cancel,
                      color: f.value ? _kGreen : Colors.red.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Icon(f.icon, color: Colors.grey.shade400, size: 18),
                    const SizedBox(width: 8),
                    Text(f.label,
                        style: TextStyle(
                            fontSize: 13,
                            color: f.value ? Colors.grey.shade800 : Colors.grey.shade500)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Factor {
  const _Factor({required this.label, required this.value, required this.icon});
  final String label;
  final bool value;
  final IconData icon;
}

class _LevelExplainerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final levels = [
      _LevelInfo(
        level: _TrustLevel.bronze,
        range: '0-3 puntos',
        description: 'Inicio del proceso. Completa mas factores para subir de nivel.',
      ),
      _LevelInfo(
        level: _TrustLevel.silver,
        range: '4-5 puntos',
        description: 'Buena solvencia. Los vendedores confian en tu capacidad de compra.',
      ),
      _LevelInfo(
        level: _TrustLevel.gold,
        range: '6-7 puntos',
        description: 'Maxima confianza. Hipoteca aprobada o pago al contado con todos los factores.',
      ),
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
          const Text(
            'Escala de confianza',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: _kNavy),
          ),
          const SizedBox(height: 16),
          ...levels.map((l) {
            final config = _levelConfig(l.level);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(config.icon, color: config.gradient[0], size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(config.label,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: config.gradient[0])),
                            const SizedBox(width: 8),
                            Text(l.range,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500)),
                          ],
                        ),
                        Text(l.description,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600)),
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
}

class _LevelInfo {
  const _LevelInfo(
      {required this.level, required this.range, required this.description});
  final _TrustLevel level;
  final String range;
  final String description;
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.level});

  final _TrustLevel level;

  @override
  Widget build(BuildContext context) {
    final allBenefits = {
      _TrustLevel.bronze: [
        'Puedes hacer ofertas en propiedades',
        'El vendedor ve tu nivel en el pasaporte',
      ],
      _TrustLevel.silver: [
        'Puedes hacer ofertas en propiedades',
        'El vendedor ve tu nivel en el pasaporte',
        'Mayor probabilidad de que el vendedor acepte',
        'Acceso a financiacion con condiciones preferentes',
      ],
      _TrustLevel.gold: [
        'Puedes hacer ofertas en propiedades',
        'El vendedor ve tu nivel en el pasaporte',
        'Mayor probabilidad de que el vendedor acepte',
        'Acceso a financiacion con condiciones preferentes',
        'Prioridad en las visitas solicitadas',
        'Insignia "Comprador Certificado" visible en tu perfil',
      ],
    };

    final benefits = allBenefits[level] ?? allBenefits[_TrustLevel.bronze]!;
    final config = _levelConfig(level);

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
          Text(
            'Ventajas de tu nivel ${config.label}',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: _kNavy),
          ),
          const SizedBox(height: 14),
          ...benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.star, color: config.gradient[0], size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(b,
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

class _ExpiryCard extends StatelessWidget {
  const _ExpiryCard({required this.expiresAt});

  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    if (expiresAt == null) return const SizedBox.shrink();

    final daysLeft = expiresAt!.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysLeft < 15;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpiringSoon ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpiringSoon
              ? Colors.red.shade200
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_outlined,
            color: isExpiringSoon ? Colors.red : Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isExpiringSoon
                  ? 'Tu pasaporte caduca en $daysLeft dias. Renuvalo para mantener tu nivel.'
                  : 'Pasaporte valido. Caduca en $daysLeft dias '
                      '(${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}).',
              style: TextStyle(
                fontSize: 13,
                color: isExpiringSoon ? Colors.red.shade700 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Config helpers ─────────────────────────────────────────────────────────────

class _LevelConfig {
  const _LevelConfig({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.description,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final String description;
}

_LevelConfig _levelConfig(_TrustLevel level) {
  switch (level) {
    case _TrustLevel.gold:
      return const _LevelConfig(
        label: 'Oro',
        icon: Icons.emoji_events,
        gradient: [Color(0xFFB8860B), Color(0xFFDAA520)],
        description: 'Maxima confianza. Financiacion solida y total conciencia financiera.',
      );
    case _TrustLevel.silver:
      return const _LevelConfig(
        label: 'Plata',
        icon: Icons.workspace_premium,
        gradient: [Color(0xFF64748B), Color(0xFF94A3B8)],
        description: 'Buena solvencia. Los vendedores valoraran positivamente tu oferta.',
      );
    case _TrustLevel.bronze:
      return const _LevelConfig(
        label: 'Bronce',
        icon: Icons.military_tech,
        gradient: [Color(0xFFB45309), Color(0xFFD97706)],
        description: 'Nivel inicial. Completa mas factores para mejorar tu nivel de confianza.',
      );
  }
}

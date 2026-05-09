import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';


import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import '../../providers/auth_provider.dart';
import '../../providers/solvency_provider.dart' as solvency_prov;

const _kBlue  = Color(0xFF135BEC);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);
const _kNavy  = Color(0xFF135BEC);

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                      TextSpan(text: 'Fácil', style: TextStyle(color: _kGreen)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 650)
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 5),
                    Text('transaction.home_btn'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),

              ),
            ),
          ),
          const SizedBox(width: 8),
          const UserAvatarMenu(),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _kBlue.withOpacity(0.07),
              border: Border(bottom: BorderSide(color: _kBlue.withOpacity(0.15))),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: _kBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'solvency_dashboard.buyer_exclusive'.tr(),
                    style: TextStyle(fontSize: 12, color: _kBlue, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: solvencyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: _kBlue)),
              error: (_, __) => _buildNoPassport(context),
              data: (passport) => passport == null
                  ? _buildNoPassport(context)
                  : _buildDashboard(context, passport, currentUser),
            ),
          ),
        ],
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.workspace_premium_outlined,
                  size: 52, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Text(
              'solvency_dashboard.no_passport_title'.tr(),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 10),
            Text(
              'solvency_dashboard.no_passport_desc'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.go('/solvency/wizard'),
              icon: const Icon(Icons.verified_user_outlined),
              label: Text('solvency_dashboard.complete_btn'.tr()),

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
        _LevelHeroCard(
          level: level,
          userName: user?.name ?? 'common.user'.tr(),
          isMultiBuyer: passport.isMultiBuyer,
        ),
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
  const _LevelHeroCard({
    required this.level,
    required this.userName,
    this.isMultiBuyer = false,
  });

  final _TrustLevel level;
  final String userName;
  final bool isMultiBuyer;

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
            'solvency_dashboard.level_trust_of'.tr(namedArgs: {'name': userName}),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (isMultiBuyer) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group, color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text('solvency_dashboard.joint_solvency'.tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
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
        label: 'transaction.solvency_knows_extra_costs'.tr(),
        value: passport.knowsExtraCosts == true,
        icon: Icons.school_outlined,
      ),
      _Factor(
        label: 'solvency_dashboard.debt_ratio'.tr(),
        value: (passport.debtRatio ?? 1.0) < 0.35,
        icon: Icons.trending_down_outlined,
      ),
      _Factor(
        label: 'solvency_dashboard.emergency_fund'.tr(),
        value: passport.hasEmergencyFund == true,
        icon: Icons.savings_outlined,
      ),
      _Factor(
        label: 'transaction.solvency_initial_savings'.tr(),
        value: passport.hasInitialSavings == true,
        icon: Icons.account_balance_wallet_outlined,
      ),
      _Factor(
        label: 'transaction.solvency_pre_approval'.tr(),
        value: passport.hasPreApproval == true,
        icon: Icons.verified_outlined,
      ),
    ];


    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'solvency_dashboard.trust_factors'.tr(),
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          ...factors.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      f.value ? Icons.check_circle : Icons.cancel,
                      color: f.value ? _kGreen : Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Icon(f.icon, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
                    const SizedBox(width: 8),
                    Text(f.label,
                        style: TextStyle(
                            fontSize: 13,
                            color: f.value ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant)),
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
        range: '0-3 points',
        description: 'solvency_dashboard.bronze_desc'.tr(),
      ),
      _LevelInfo(
        level: _TrustLevel.silver,
        range: '4-5 points',
        description: 'solvency_dashboard.silver_desc'.tr(),
      ),
      _LevelInfo(
        level: _TrustLevel.gold,
        range: '6-7 points',
        description: 'solvency_dashboard.gold_desc'.tr(),
      ),
    ];


    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'solvency_dashboard.trust_scale'.tr(),
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
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
                                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        Text(l.description,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
        'solvency_dashboard.benefit_make_offers'.tr(),
        'solvency_dashboard.benefit_seller_sees'.tr(),
      ],
      _TrustLevel.silver: [
        'solvency_dashboard.benefit_make_offers'.tr(),
        'solvency_dashboard.benefit_seller_sees'.tr(),
        'solvency_dashboard.benefit_higher_prob'.tr(),
        'solvency_dashboard.benefit_financing'.tr(),
      ],
      _TrustLevel.gold: [
        'solvency_dashboard.benefit_make_offers'.tr(),
        'solvency_dashboard.benefit_seller_sees'.tr(),
        'solvency_dashboard.benefit_higher_prob'.tr(),
        'solvency_dashboard.benefit_financing'.tr(),
        'solvency_dashboard.benefit_priority_visits'.tr(),
        'solvency_dashboard.benefit_certified_badge'.tr(),
      ],
    };


    final benefits = allBenefits[level] ?? allBenefits[_TrustLevel.bronze]!;
    final config = _levelConfig(level);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'solvency_dashboard.benefits_title'.tr(namedArgs: {'level': config.label}),
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
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
                              fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
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
        color: isExpiringSoon ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpiringSoon
              ? Theme.of(context).colorScheme.error.withOpacity(0.4)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_outlined,
            color: isExpiringSoon ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isExpiringSoon
                  ? 'solvency_dashboard.expiry_soon'.tr(namedArgs: {'days': daysLeft.toString()})
                  : 'solvency_dashboard.expiry_valid'.tr(namedArgs: {
                      'days': daysLeft.toString(),
                      'date': '${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}'
                    }),
              style: TextStyle(
                fontSize: 13,
                color: isExpiringSoon ? Theme.of(context).colorScheme.onErrorContainer : Theme.of(context).colorScheme.onSurfaceVariant,
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
      return _LevelConfig(
        label: 'transaction.solvency_level_gold'.tr(),
        icon: Icons.emoji_events,
        gradient: const [Color(0xFFB8860B), Color(0xFFDAA520)],
        description: 'solvency_dashboard.gold_desc'.tr(),
      );

    case _TrustLevel.silver:
      return _LevelConfig(
        label: 'transaction.solvency_level_silver'.tr(),
        icon: Icons.workspace_premium,
        gradient: const [Color(0xFF64748B), Color(0xFF94A3B8)],
        description: 'solvency_dashboard.silver_desc'.tr(),
      );

    case _TrustLevel.bronze:
      return _LevelConfig(
        label: 'transaction.solvency_level_bronze'.tr(),
        icon: Icons.military_tech,
        gradient: const [Color(0xFFB45309), Color(0xFFD97706)],
        description: 'solvency_dashboard.bronze_desc'.tr(),
      );

  }
}

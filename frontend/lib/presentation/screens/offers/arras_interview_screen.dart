import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../providers/auth_provider.dart';
import '../../providers/offers_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import '../../../core/config/env_config.dart';
import '../../../core/formatters/currency_input_formatter.dart';

const _kBlue  = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);
const _kBg    = Color(0xFFF8FAFC);

// ── Provider ──────────────────────────────────────────────────────────────────

final _arrasHubProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, offerId) async {
  final token =
      await const FlutterSecureStorage().read(key: 'auth_token');
  if (token == null) return null;
  final dio = Dio();
  try {
    final resp = await dio.get(
      '$EnvConfig.apiBaseUrl/arras/$offerId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return resp.data as Map<String, dynamic>;
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});

// ── Screen ────────────────────────────────────────────────────────────────────

/// Hub screen for the Arras flow. Shows the status of both interviews
/// and routes to the appropriate sub-screen.
class ArrasInterviewScreen extends ConsumerWidget {
  const ArrasInterviewScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arrasAsync = ref.watch(_arrasHubProvider(offer.id));
    final currentUser = ref.watch(authProvider).user;
    final isBuyer = currentUser?.id == offer.buyerId;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(context, ref),
      body: arrasAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (_, __) => _buildBody(context, ref, isBuyer, null),
        data: (data) => _buildBody(context, ref, isBuyer, data),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, bool isBuyer,
      Map<String, dynamic>? data) {
    final arrasStatus = data?['arras_status'] as String? ?? 'none';
    final buyerDone = data?['buyer_interview_confirmed'] == true;
    final sellerDone = data?['seller_interview_confirmed'] == true;
    final contractStatus = data?['contract_status'] as String?;
    final hasContract = contractStatus != null;
    final isGenerating = contractStatus == 'generating';
    final fullyAccepted = contractStatus == 'fully_accepted';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Hero header ──────────────────────────────────────────
        _HeroCard(
          isBuyer: isBuyer,
          buyerDone: buyerDone,
          sellerDone: sellerDone,
          arrasStatus: arrasStatus,
          offerAmount: offer.amount,
          depositPercentage: data?['deposit_percentage'] as int?,
          deadlineDays: data?['deadline_days'] as int?,
        ),
        const SizedBox(height: 24),

        // ── Role cards ───────────────────────────────────────────
        _RoleCard(
          title: 'Entrevista del Comprador',
          icon: Icons.person_outlined,
          isMyRole: isBuyer,
          isDone: buyerDone,
          color: _kBlue,
          statusLabel: buyerDone ? 'Completada' : 'Pendiente',
          ctaLabel: isBuyer
              ? (buyerDone ? 'Ver / Editar entrevista' : 'Comenzar entrevista')
              : null,
          onCta: isBuyer
              ? () => context.push('/offers/${offer.id}/arras/buyer',
                  extra: offer)
              : null,
        ),
        const SizedBox(height: 16),

        _RoleCard(
          title: 'Entrevista del Vendedor',
          icon: Icons.home_outlined,
          isMyRole: !isBuyer,
          isDone: sellerDone,
          color: _kGreen,
          statusLabel: sellerDone ? 'Completada' : 'Pendiente',
          ctaLabel: !isBuyer
              ? (sellerDone ? 'Ver / Editar entrevista' : 'Comenzar entrevista')
              : null,
          onCta: !isBuyer
              ? () => context.push('/offers/${offer.id}/arras/seller',
                  extra: offer)
              : null,
        ),

        // ── Contract section ─────────────────────────────────────
        if (buyerDone && sellerDone) ...[
          const SizedBox(height: 24),
          _ContractCard(
            isGenerating: isGenerating,
            hasContract: hasContract,
            fullyAccepted: fullyAccepted,
            contractStatus: contractStatus,
            onView: () => context.push('/offers/${offer.id}/arras/contract',
                extra: offer),
          ),
        ],

        // ── Info box ─────────────────────────────────────────────
        const SizedBox(height: 24),
        _InfoBox(
          icon: Icons.info_outline,
          text:
              'Cuando ambas partes completen y confirmen sus entrevistas, '
              'la inteligencia artificial redactara el Contrato de Arras Penitenciales '
              'con todas las condiciones acordadas. Podras revisarlo y proponer cambios '
              'antes de firmarlo digitalmente.',
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppBarBackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
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
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                      text: 'Inmu',
                      style: TextStyle(color: Color(0xFF2563EB))),
                  TextSpan(
                      text: 'Fácil',
                      style: TextStyle(color: Color(0xFF16A34A))),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
      actions: [
        Consumer(
          builder: (context, ref, _) {
            final isAuthenticated = ref.watch(authProvider).isAuthenticated;
            if (!isAuthenticated) return const SizedBox.shrink();
            return const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserAvatarMenu(),
                SizedBox(width: 16),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.isBuyer,
    required this.buyerDone,
    required this.sellerDone,
    required this.arrasStatus,
    required this.offerAmount,
    this.depositPercentage,
    this.deadlineDays,
  });

  final bool isBuyer;
  final bool buyerDone;
  final bool sellerDone;
  final String arrasStatus;
  final int offerAmount;
  final int? depositPercentage;
  final int? deadlineDays;

  String get _statusLabel {
    switch (arrasStatus) {
      case 'accepted':
        return 'Contrato firmado por ambas partes';
      case 'contract_ready':
      case 'buyer_accepted':
      case 'seller_accepted':
        return 'Contrato listo para revision';
      case 'generating':
        return 'Generando contrato con IA...';
      case 'both_done':
        return 'Generando borrador del contrato...';
      case 'buyer_done':
        return isBuyer
            ? 'Tu entrevista completada — esperando al vendedor'
            : 'Comprador listo — completa tu entrevista';
      case 'seller_done':
        return !isBuyer
            ? 'Tu entrevista completada — esperando al comprador'
            : 'Vendedor listo — completa tu entrevista';
      default:
        return 'Completa tu parte de la entrevista';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.handshake_outlined,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contrato de Arras',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Penitenciales',
                    style:
                        TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _statusLabel,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Chip(
                label:
                    '${CurrencyInputFormatter.format(offerAmount)} EUR',
                icon: Icons.euro_outlined,
              ),
              if (depositPercentage != null) ...[
                const SizedBox(width: 8),
                _Chip(
                  label: 'Arras $depositPercentage%',
                  icon: Icons.payments_outlined,
                ),
              ],
              if (deadlineDays != null) ...[
                const SizedBox(width: 8),
                _Chip(
                  label: '$deadlineDays dias',
                  icon: Icons.schedule_outlined,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusDot(
                  label: 'Comprador', active: buyerDone, color: _kGreen),
              const SizedBox(width: 16),
              _StatusDot(
                  label: 'Vendedor', active: sellerDone, color: _kGreen),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot(
      {required this.label, required this.active, required this.color});

  final String label;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          active ? Icons.check_circle : Icons.radio_button_unchecked,
          color: active ? color : Colors.white38,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight:
                active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.icon,
    required this.isMyRole,
    required this.isDone,
    required this.color,
    required this.statusLabel,
    this.ctaLabel,
    this.onCta,
  });

  final String title;
  final IconData icon;
  final bool isMyRole;
  final bool isDone;
  final Color color;
  final String statusLabel;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? color.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: isDone ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDone
                  ? color.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: isDone ? color : Colors.grey.shade400, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDone
                              ? const Color(0xFF1E3A5F)
                              : Colors.grey.shade600,
                        )),
                    if (isMyRole) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Tu',
                            style: TextStyle(
                                color: _kBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isDone ? color : Colors.grey.shade400,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(statusLabel,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDone
                                ? color
                                : Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onCta,
              style: FilledButton.styleFrom(
                backgroundColor: isDone ? Colors.grey.shade200 : color,
                foregroundColor: isDone ? color : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                minimumSize: const Size(0, 36),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: Text(isDone ? 'Ver' : 'Comenzar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({
    required this.isGenerating,
    required this.hasContract,
    required this.fullyAccepted,
    required this.contractStatus,
    required this.onView,
  });

  final bool isGenerating;
  final bool hasContract;
  final bool fullyAccepted;
  final String? contractStatus;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    IconData cardIcon;
    String cardTitle;
    String cardSubtitle;

    if (fullyAccepted) {
      cardColor = _kGreen;
      cardIcon = Icons.verified_outlined;
      cardTitle = 'Contrato firmado';
      cardSubtitle = 'Ambas partes han aceptado el contrato';
    } else if (isGenerating) {
      cardColor = _kBlue;
      cardIcon = Icons.auto_awesome_outlined;
      cardTitle = 'Generando contrato...';
      cardSubtitle = 'La IA esta redactando el contrato';
    } else if (hasContract) {
      cardColor = const Color(0xFFD97706);
      cardIcon = Icons.description_outlined;
      cardTitle = 'Contrato listo para revision';
      cardSubtitle = 'Ambas partes deben leer y aceptar el contrato';
    } else {
      cardColor = _kBlue;
      cardIcon = Icons.hourglass_empty_outlined;
      cardTitle = 'Generando contrato...';
      cardSubtitle = 'Espera mientras se prepara el borrador';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: cardColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: isGenerating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: cardColor, strokeWidth: 2))
                : Icon(cardIcon, color: cardColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cardTitle,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: cardColor)),
                Text(cardSubtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (hasContract && !isGenerating) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onView,
              style: FilledButton.styleFrom(
                backgroundColor: cardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                minimumSize: const Size(0, 36),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Ver contrato'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade800,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

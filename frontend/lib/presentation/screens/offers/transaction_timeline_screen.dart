import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/offers_provider.dart';
import '../../../config/router/app_router.dart';
import '../../widgets/common/app_bar_back_button.dart';

/// Transaction timeline screen — shows the lifecycle of a purchase offer.
class TransactionTimelineScreen extends ConsumerWidget {
  const TransactionTimelineScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = _buildSteps(offer.status);
    final currentUser = ref.watch(authProvider).user;
    final isBuyer = currentUser?.id == offer.buyerId;
    final s = offer.status.toLowerCase();
    // Buyer can withdraw while arras not yet signed (and not already closed)
    final canWithdraw = isBuyer &&
        (s == 'pending' || s == 'counter_offer' || s == 'accepted' || s == 'signing_pending');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, ref),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── Header cards ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _HeaderCards(offer: offer),
                ),
                // ── Title ───────────────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 4),
                  child: Text(
                    'Estado de la Transaccion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Sigue el progreso de tu venta en tiempo real',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                // ── Timeline ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                  child: _TimelineWidget(steps: steps),
                ),
                // ── Withdraw offer (buyer only, before arras signed) ─────────
                if (canWithdraw)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _WithdrawOfferButton(offer: offer),
                  ),
                // ── Help footer ─────────────────────────────────────────────
                const _HelpFooter(),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // ── Bottom brand bar ────────────────────────────────────────────
          const _BrandBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return AppBar(
      automaticallyImplyLeading: false,
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
                    TextSpan(
                        text: 'Inmu',
                        style: TextStyle(color: Color(0xFF2563EB))),
                    TextSpan(
                        text: 'Facil',
                        style: TextStyle(color: Color(0xFF16A34A))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
      actions: [
        GestureDetector(
          onTap: () => context.go('/'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
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
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: _UserAvatar(user: user),
        ),
      ],
    );
  }

  List<_TimelineStep> _buildSteps(String status) {
    final s = status.toLowerCase();

    // Map offer status to pipeline stage index:
    // 0 = pending (offer not yet accepted)
    // 1 = accepted (offer accepted, solvency check in progress)
    // 2 = signing_pending (arras contract pending signatures)
    // 3 = signed (arras signed, mortgage management)
    // 4 = completed (notary signed, transaction finished)
    // -1 = rejected / cancelled
    final int stage;
    switch (s) {
      case 'pending':
      case 'counter_offer':
        stage = 0;
      case 'accepted':
        stage = 1;
      case 'signing_pending':
        stage = 2;
      case 'signed':
        stage = 3;
      case 'completed':
        stage = 4;
      default: // rejected, withdrawn, cancelled
        stage = -1;
    }

    _StepState stepState(int stepIndex) {
      if (stage < 0) return _StepState.locked;
      if (stepIndex < stage) return _StepState.done;
      if (stepIndex == stage) return _StepState.active;
      return _StepState.locked;
    }

    return [
      _TimelineStep(
        // Title adapts: "Oferta Enviada" while pending, "Oferta Aceptada" once done
        title: stage == 0 ? 'Oferta Enviada' : 'Oferta Aceptada',
        subtitle: stage > 0
            ? 'Vendedor acepto la oferta'
            : stage == 0
                ? (s == 'counter_offer'
                    ? 'El vendedor ha realizado una contraoferta'
                    : 'Pendiente de respuesta del vendedor')
                : (s == 'withdrawn' ? 'Oferta retirada por el comprador' : 'Oferta rechazada por el vendedor'),
        state: stage < 0 ? _StepState.locked : stepState(0),
        // No CTA: buyer can only wait for seller to accept
      ),
      _TimelineStep(
        title: 'Verificacion de Solvencia',
        subtitle: stage > 1
            ? 'Validado por InmuFacil Secure-Tech'
            : stage == 1
                ? 'Verificando solvencia del comprador'
                : 'Pendiente de aceptacion de oferta',
        state: stepState(1),
        // No CTA: automatic process handled by InmuFacil
      ),
      _TimelineStep(
        title: 'Contrato de Arras',
        subtitle: stage > 2
            ? 'Firmado por ambas partes'
            : stage == 2
                ? 'Faltan las firmas del contrato'
                : 'Pendiente de verificacion de solvencia',
        description: stage == 2
            ? 'Ambas partes deben revisar y firmar digitalmente el documento de '
              'reserva para proceder con el bloqueo oficial del inmueble.'
            : null,
        state: stepState(2),
        ctaLabel: stage == 2 ? 'Ir a Firmar Ahora' : null,
        ctaIcon: stage == 2 ? Icons.edit_outlined : null,
      ),
      _TimelineStep(
        title: 'Gestion Hipotecaria',
        subtitle: stage > 3
            ? 'Tramitacion completada'
            : stage == 3
                ? 'Tramitando financiacion hipotecaria'
                : 'Pendiente de firma de arras',
        state: stepState(3),
        ctaLabel: stage == 3 ? 'Ver documentacion hipotecaria' : null,
        ctaIcon: stage == 3 ? Icons.description_outlined : null,
      ),
      _TimelineStep(
        title: 'Firma en Notaria',
        subtitle: stage == 4
            ? 'Transaccion completada'
            : 'Paso final de la transaccion',
        state: stepState(4),
      ),
    ];
  }
}

// ── User avatar widget ────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.profilePhotoUrl as String?;
    return SizedBox(
      width: 32,
      height: 32,
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF2563EB),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
              )
            : Container(
                color: const Color(0xFF2563EB),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
      ),
    );
  }
}

// ── Header cards (property + counterparty) ───────────────────────────────────

class _HeaderCards extends StatelessWidget {
  const _HeaderCards({required this.offer});

  final OfferData offer;

  @override
  Widget build(BuildContext context) {
    final title = offer.propertyTitle ?? 'Propiedad';
    final price = offer.propertyPrice;
    final counterparty = offer.sellerName ?? offer.buyerName ?? 'Contraparte';
    final counterPhotoUrl = offer.buyerPhotoUrl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Property card
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF6EE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.home_outlined,
                      color: Color(0xFF16A34A), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (price != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatPrice(price),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Counterparty card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'COMPRADOR',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    counterparty,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFDBEAFE),
                    backgroundImage: (counterPhotoUrl != null &&
                            counterPhotoUrl.isNotEmpty)
                        ? NetworkImage(counterPhotoUrl)
                        : null,
                    child: (counterPhotoUrl == null || counterPhotoUrl.isEmpty)
                        ? Text(
                            counterparty.isNotEmpty
                                ? counterparty[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPrice(double value) {
    final s = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()}\u20AC';
  }
}

// ── Timeline ─────────────────────────────────────────────────────────────────

enum _StepState { done, active, locked }

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.state,
    this.description,
    this.ctaLabel,
    this.ctaIcon,
  });

  final String title;
  final String subtitle;
  final _StepState state;
  final String? description;
  /// Optional call-to-action shown in the active card. Null = no button.
  final String? ctaLabel;
  final IconData? ctaIcon;
}

class _TimelineWidget extends StatelessWidget {
  const _TimelineWidget({required this.steps});

  final List<_TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (i) {
        return _StepRow(
          step: steps[i],
          isLast: i == steps.length - 1,
        );
      }),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    switch (step.state) {
      case _StepState.done:
        return _DoneRow(step: step, isLast: isLast);
      case _StepState.active:
        return _ActiveRow(step: step, isLast: isLast);
      case _StepState.locked:
        return _LockedRow(step: step, isLast: isLast);
    }
  }
}

// Done step: green checkmark + title + subtitle
class _DoneRow extends StatelessWidget {
  const _DoneRow({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DotColumn(
          isLast: isLast,
          dot: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 18, color: Colors.white),
          ),
          lineColor: const Color(0xFF16A34A),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 24, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Active step: blue dot + expanded card with CTA
class _ActiveRow extends StatelessWidget {
  const _ActiveRow({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DotColumn(
            isLast: isLast,
            dot: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_document,
                  size: 18, color: Colors.white),
            ),
            lineColor: const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Text(
                            'EN CURSO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    if (step.description != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        step.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (step.ctaLabel != null) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {},
                          icon: Icon(step.ctaIcon ?? Icons.arrow_forward, size: 16),
                          label: Text(
                            step.ctaLabel!,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
  }
}

// Locked step: lock icon + gray text
class _LockedRow extends StatelessWidget {
  const _LockedRow({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DotColumn(
          isLast: isLast,
          dot: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
            ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 16, color: Color(0xFFCBD5E1)),
            ),
            lineColor: const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
  }
}

// Shared dot+line column
class _DotColumn extends StatelessWidget {
  const _DotColumn({
    required this.dot,
    required this.isLast,
    required this.lineColor,
  });

  final Widget dot;
  final bool isLast;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          if (!isLast)
            Container(width: 2, height: 32, color: lineColor),
        ],
      ),
    );
  }
}

// ── Help footer ───────────────────────────────────────────────────────────────

class _HelpFooter extends StatelessWidget {
  const _HelpFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Text(
            '¿Necesitas ayuda con este paso?',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 15, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Hablar con un asesor legal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Withdraw offer button ─────────────────────────────────────────────────────

class _WithdrawOfferButton extends ConsumerStatefulWidget {
  const _WithdrawOfferButton({required this.offer});
  final OfferData offer;

  @override
  ConsumerState<_WithdrawOfferButton> createState() => _WithdrawOfferButtonState();
}

class _WithdrawOfferButtonState extends ConsumerState<_WithdrawOfferButton> {
  bool _loading = false;

  Future<void> _confirmAndWithdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirar oferta'),
        content: const Text(
          '¿Seguro que quieres retirar tu oferta? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await ref.read(sentOffersProvider.notifier).withdraw(widget.offer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oferta retirada correctamente')),
        );
        context.go('/profile?tab=2');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al retirar la oferta. Inténtalo de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _confirmAndWithdraw,
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
            )
          : const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
      label: const Text(
        'Retirar Oferta',
        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Brand bar ─────────────────────────────────────────────────────────────────

class _BrandBar extends StatelessWidget {
  const _BrandBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined,
              size: 14, color: Color(0xFF64748B)),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'InmuFacil Secure-Tech \u00B7 \u00A9 2023 InmuFacil S.L. Sistema de transacciones seguras bajo protocolo AES-256',
              style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              _FooterLink('Ayuda'),
              const SizedBox(width: 10),
              _FooterLink('Legal'),
              const SizedBox(width: 10),
              _FooterLink('Seguridad'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF64748B),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../providers/offers_provider.dart';

/// Displays the lifecycle of a purchase transaction for the buyer.
class TransactionTimelineScreen extends StatelessWidget {
  const TransactionTimelineScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(offer.status);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) context.pop();
            },
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PropertyHeader(offer: offer),
                  const SizedBox(height: 28),
                  const Text(
                    'Estado de la operacion',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _TimelineWidget(steps: steps),
                ],
              ),
            ),
          ),
          _Footer(),
        ],
      ),
    );
  }

  List<_TimelineStep> _buildSteps(String status) {
    final s = status.toLowerCase();

    _StepState propuestaState = _StepState.done;

    _StepState solvenciaState = _StepState.done;

    _StepState arrasState;
    if (s == 'accepted') {
      arrasState = _StepState.active;
    } else if (s == 'signing_pending' || s == 'completed') {
      arrasState = _StepState.done;
    } else {
      arrasState = _StepState.locked;
    }

    final bool arrasDone = arrasState == _StepState.done;
    final _StepState hipotecaState = arrasDone ? _StepState.active : _StepState.locked;
    const _StepState notariaState = _StepState.locked;

    return [
      _TimelineStep(
        title: 'Propuesta enviada',
        subtitle: 'La oferta ha sido registrada en el sistema.',
        state: propuestaState,
      ),
      _TimelineStep(
        title: 'Verificacion de solvencia',
        subtitle: 'Tu identidad y solvencia han sido validadas.',
        state: solvenciaState,
      ),
      _TimelineStep(
        title: 'Contrato de Arras',
        subtitle: 'Firma del contrato de arras con el vendedor.',
        state: arrasState,
      ),
      _TimelineStep(
        title: 'Gestion hipotecaria',
        subtitle: 'Tramitacion de financiacion con entidades bancarias.',
        state: hipotecaState,
      ),
      _TimelineStep(
        title: 'Firma en Notaria',
        subtitle: 'Escritura publica y entrega de llaves.',
        state: notariaState,
      ),
    ];
  }
}

// ── Property header card ──────────────────────────────────────────────────────

class _PropertyHeader extends StatelessWidget {
  const _PropertyHeader({required this.offer});

  final OfferData offer;

  @override
  Widget build(BuildContext context) {
    final counterparty = offer.sellerName ?? 'Vendedor';
    final title = offer.propertyTitle ?? 'Propiedad';
    final price = offer.propertyPrice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFEFF6FF),
                child: const Icon(Icons.person_outline, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vendedor',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    Text(
                      counterparty,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          if (price != null) ...[
            const SizedBox(height: 4),
            Text(
              'Oferta: ${_formatPrice(offer.amount)}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 8),
          _StatusBadge(status: offer.status),
        ],
      ),
    );
  }

  String _formatPrice(double value) {
    final formatted = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formatted EUR';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = _label(status);
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _label(String s) {
    switch (s.toLowerCase()) {
      case 'pending': return 'Pendiente';
      case 'accepted': return 'Aceptada';
      case 'countered': return 'Contraoferta';
      case 'signing_pending': return 'En firma';
      case 'completed': return 'Completada';
      case 'rejected': return 'Rechazada';
      default: return s;
    }
  }

  Color _color(String s) {
    switch (s.toLowerCase()) {
      case 'accepted': return const Color(0xFF16A34A);
      case 'countered': return const Color(0xFFD97706);
      case 'signing_pending': return const Color(0xFF2563EB);
      case 'completed': return const Color(0xFF16A34A);
      case 'rejected': return Colors.red;
      default: return const Color(0xFF64748B);
    }
  }
}

// ── Timeline widget ────────────────────────────────────────────────────────────

enum _StepState { done, active, locked }

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.state,
  });

  final String title;
  final String subtitle;
  final _StepState state;
}

class _TimelineWidget extends StatelessWidget {
  const _TimelineWidget({required this.steps});

  final List<_TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isLast = i == steps.length - 1;
        return _StepRow(step: step, isLast: isLast);
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
    final Color dotColor;
    final IconData dotIcon;
    switch (step.state) {
      case _StepState.done:
        dotColor = const Color(0xFF16A34A);
        dotIcon = Icons.check_rounded;
        break;
      case _StepState.active:
        dotColor = const Color(0xFF2563EB);
        dotIcon = Icons.radio_button_checked_rounded;
        break;
      case _StepState.locked:
        dotColor = const Color(0xFFCBD5E1);
        dotIcon = Icons.lock_outline_rounded;
        break;
    }

    final bool dimmed = step.state == _StepState.locked;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: dotColor.withValues(alpha: dimmed ? 0.25 : 1.0),
                  child: Icon(dotIcon, size: 16, color: dimmed ? dotColor : Colors.white),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: dimmed ? const Color(0xFFE2E8F0) : const Color(0xFF16A34A).withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: dimmed ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: dimmed ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Footer ─────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent_outlined, size: 20, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Necesitas ayuda? Hablar con un asesor legal',
              style: TextStyle(fontSize: 13, color: Color(0xFF2563EB), fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF2563EB)),
        ],
      ),
    );
  }
}

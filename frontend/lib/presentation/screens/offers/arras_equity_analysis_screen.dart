import 'dart:math' as math;

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
import '../../../core/network/dio_factory.dart';

const _kBlue     = Color(0xFF135BEC);
const _kGreen    = Color(0xFF16A34A);
const _kOrange   = Color(0xFFEA580C);
const _kRed      = Color(0xFFDC2626);
const _kNavy     = Color(0xFF135BEC);
const _kBg       = Color(0xFFF8FAFC);

// ── Provider ─────────────────────────────────────────────────────────────────

final _equityProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, offerId) async {
  final token = await const FlutterSecureStorage().read(key: 'auth_token');
  if (token == null) return null;
  final dio = buildAuthDio();
  try {
    final resp = await dio.get(
      '$EnvConfig.apiBaseUrl/arras/$offerId/equity',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return resp.data as Map<String, dynamic>;
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ArrasEquityAnalysisScreen extends ConsumerWidget {
  const ArrasEquityAnalysisScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equityAsync = ref.watch(_equityProvider(offer.id));
    final isBuyer =
        ref.watch(authProvider).user?.id == offer.buyerId;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(context, ref, isBuyer),
      body: equityAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (e, _) {
          String msg = 'Error al cargar el analisis.';
          if (e is DioException) {
            final detail = e.response?.data?['detail'];
            if (detail != null) msg = detail.toString();
          }
          return _ErrorView(
            message: msg,
            onRetry: () => ref.invalidate(_equityProvider(offer.id)),
          );
        },
        data: (data) {
          if (data == null) {
            return const _ErrorView(
              message:
                  'El analisis no esta disponible. Asegurate de que el contrato ha sido generado.',
            );
          }
          final score = (data['score'] as num?)?.toInt() ?? 0;
          final rawItems = data['items'] as List<dynamic>? ?? [];
          final items = rawItems
              .whereType<Map<String, dynamic>>()
              .toList();
          return _EquityBody(
            score: score,
            items: items,
            isBuyer: isBuyer,
            offerId: offer.id,
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, WidgetRef ref, bool isBuyer) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppBarBackButton(onPressed: () => context.pop()),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                      text: 'Inmu',
                      style: TextStyle(color: _kBlue)),
                  TextSpan(
                      text: 'Fácil',
                      style: TextStyle(color: _kGreen)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
      ),
      actions: [
        Consumer(builder: (context, ref, _) {
          final auth = ref.watch(authProvider);
          if (!auth.isAuthenticated) return const SizedBox.shrink();
          return const Row(
            mainAxisSize: MainAxisSize.min,
            children: [UserAvatarMenu(), SizedBox(width: 16)],
          );
        }),
      ],
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _EquityBody extends StatelessWidget {
  const _EquityBody({
    required this.score,
    required this.items,
    required this.isBuyer,
    required this.offerId,
  });

  final int score;
  final List<Map<String, dynamic>> items;
  final bool isBuyer;
  final String offerId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScoreHeader(score: score, isBuyer: isBuyer),
          const SizedBox(height: 24),
          Text(
            'Aspectos del contrato',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _EquityItemCard(
                item: item,
                offerId: offerId,
              )),
          const SizedBox(height: 32),
          _DisclaimerFooter(),
        ],
      ),
    );
  }
}

// ── Score header ──────────────────────────────────────────────────────────────

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.score, required this.isBuyer});

  final int score;
  final bool isBuyer;

  Color get _scoreColor {
    if (score >= 75) return _kGreen;
    if (score >= 50) return _kBlue;
    if (score >= 30) return _kOrange;
    return _kRed;
  }

  String get _scoreLabel {
    if (score >= 75) return 'Favorable';
    if (score >= 50) return 'Equilibrado';
    if (score >= 30) return 'Con alertas';
    return 'Desfavorable';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNavy, const Color(0xFF2D5A8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isBuyer
                ? 'Tu posicion como Comprador'
                : 'Tu posicion como Vendedor',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _ScoreGauge(score: score, color: _scoreColor),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _scoreColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _scoreColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              _scoreLabel,
              style: TextStyle(
                color: _scoreColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Analisis basado en las condiciones pactadas y el contrato generado por IA.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score gauge (arc) ─────────────────────────────────────────────────────────

class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(130, 130),
            painter: _GaugePainter(score: score, color: color),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  color: color,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'de 100',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = math.pi * 0.75;
    const sweepTotal = math.pi * 1.5;
    final sweepProgress = sweepTotal * (score / 100);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepProgress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.score != score || old.color != color;
}

// ── Item card ─────────────────────────────────────────────────────────────────

class _EquityItemCard extends StatelessWidget {
  const _EquityItemCard({required this.item, required this.offerId});

  final Map<String, dynamic> item;
  final String offerId;

  static Color _statusColor(String status) {
    switch (status) {
      case 'favorable':
        return _kGreen;
      case 'neutral':
        return _kBlue;
      case 'alerta':
        return _kOrange;
      case 'critico':
        return _kRed;
      default:
        return Colors.grey;
    }
  }

  static Color _statusBg(String status) {
    switch (status) {
      case 'favorable':
        return const Color(0xFFF0FDF4);
      case 'neutral':
        return const Color(0xFFEFF6FF);
      case 'alerta':
        return const Color(0xFFFFF7ED);
      case 'critico':
        return const Color(0xFFFEF2F2);
      default:
        return Colors.grey.shade50;
    }
  }

  static IconData _statusIcon(String status) {
    switch (status) {
      case 'favorable':
        return Icons.check_circle_outline;
      case 'neutral':
        return Icons.info_outline;
      case 'alerta':
        return Icons.warning_amber_outlined;
      case 'critico':
        return Icons.error_outline;
      default:
        return Icons.circle_outlined;
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'favorable':
        return 'Favorable';
      case 'neutral':
        return 'Neutral';
      case 'alerta':
        return 'Alerta';
      case 'critico':
        return 'Critico';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (item['status'] as String?) ?? 'neutral';
    final label = (item['label'] as String?) ?? '';
    final description = (item['description'] as String?) ?? '';
    final isCritico = status == 'critico';

    final color = _statusColor(status);
    final bg = _statusBg(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon(status), color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            if (isCritico) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/chat/$offerId'),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Ir al Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kRed,
                    side: BorderSide(
                        color: _kRed.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kOrange.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.analytics_outlined,
                  color: _kOrange, size: 52),
            ),
            const SizedBox(height: 24),
            const Text(
              'Analisis no disponible',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kNavy),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Reintentar'),
                style: FilledButton.styleFrom(
                  backgroundColor: _kBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Disclaimer footer ─────────────────────────────────────────────────────────

class _DisclaimerFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este analisis es orientativo y ha sido generado por inteligencia artificial. '
              'No constituye asesoramiento juridico. Consulta con un abogado antes de firmar.',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

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

// Dark-mode-aware colors are resolved at build time via colorScheme / isDark.

// ── Arras data provider (auto-refresh while generating) ──────────────────────

final _arrasContractProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, offerId) async {
  final token =
      await const FlutterSecureStorage().read(key: 'auth_token');
  if (token == null) return null;
  final dio = buildAuthDio();
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

class ArrasContractReviewScreen extends ConsumerStatefulWidget {
  const ArrasContractReviewScreen({super.key, required this.offer});

  final OfferData offer;

  @override
  ConsumerState<ArrasContractReviewScreen> createState() =>
      _ArrasContractReviewScreenState();
}

class _ArrasContractReviewScreenState
    extends ConsumerState<ArrasContractReviewScreen> {
  Timer? _pollTimer;
  bool _actionLoading = false;
  bool _showRejectDialog = false;
  final _rejectNotesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Poll every 4 seconds while contract is generating
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final data = ref
          .read(_arrasContractProvider(widget.offer.id))
          .asData
          ?.value;
      final status = data?['contract_status'] as String?;
      if (status == 'generating' || status == null) {
        ref.invalidate(_arrasContractProvider(widget.offer.id));
      } else {
        _pollTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _rejectNotesCtrl.dispose();
    super.dispose();
  }

  Future<Dio?> _buildDio() async {
    final token =
        await const FlutterSecureStorage().read(key: 'auth_token');
    if (token == null) return null;
    return buildAuthDio();
  }

  Future<void> _regenerateContract() async {
    setState(() => _actionLoading = true);
    final dio = await _buildDio();
    if (dio == null) {
      setState(() => _actionLoading = false);
      return;
    }
    try {
      await dio.post('/arras/${widget.offer.id}/contract/regenerate');
      ref.invalidate(_arrasContractProvider(widget.offer.id));
      // Restart polling
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        final data = ref
            .read(_arrasContractProvider(widget.offer.id))
            .asData
            ?.value;
        final status = data?['contract_status'] as String?;
        if (status == 'generating' || status == null) {
          ref.invalidate(_arrasContractProvider(widget.offer.id));
        } else {
          _pollTimer?.cancel();
        }
      });
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Error al reintentar';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg.toString())));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _acceptContract() async {
    setState(() => _actionLoading = true);
    final dio = await _buildDio();
    if (dio == null) {
      setState(() => _actionLoading = false);
      return;
    }
    try {
      await dio.post('/arras/${widget.offer.id}/contract/accept');
      ref.invalidate(_arrasContractProvider(widget.offer.id));
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Has aceptado el contrato.'),
            backgroundColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
          ),
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Error al aceptar';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg.toString())));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _rejectContract(String notes) async {
    setState(() => _actionLoading = true);
    final dio = await _buildDio();
    if (dio == null) {
      setState(() => _actionLoading = false);
      return;
    }
    try {
      await dio.post(
        '/arras/${widget.offer.id}/contract/reject',
        data: {'notes': notes},
      );
      ref.invalidate(_arrasContractProvider(widget.offer.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Rechazo enviado. Ambas partes deben volver a confirmar sus entrevistas.'),
          ),
        );
        context.pop();
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Error al rechazar';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg.toString())));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final arrasAsync =
        ref.watch(_arrasContractProvider(widget.offer.id));
    final currentUser = ref.watch(authProvider).user;
    final isBuyer = currentUser?.id == widget.offer.buyerId;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kGreen = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: _buildAppBar(context, ref),
      body: arrasAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          if (data == null) {
            return const Center(
                child: Text('No hay informacion de la entrevista'));
          }
          final contractStatus = data['contract_status'] as String?;
          final contractText = data['contract_text'] as String?;
          final buyerAccepted = data['buyer_contract_accepted'] == true;
          final sellerAccepted = data['seller_contract_accepted'] == true;
          final myAccepted = isBuyer ? buyerAccepted : sellerAccepted;
          final otherAccepted = isBuyer ? sellerAccepted : buyerAccepted;
          final fullyAccepted = contractStatus == 'fully_accepted';

          if (contractStatus == 'error') {
            return _buildErrorView(contractText ?? 'Error al generar el contrato.');
          }

          if (contractStatus == 'generating' || contractText == null) {
            return _buildGeneratingView();
          }

          if (fullyAccepted) {
            return _buildFullyAcceptedView();
          }

          return _buildContractView(
            contractText: contractText,
            contractStatus: contractStatus ?? '',
            isBuyer: isBuyer,
            myAccepted: myAccepted,
            otherAccepted: otherAccepted,
            generationCount: (data['generation_count'] as int?) ?? 0,
            buyerRejectionNotes:
                data['buyer_rejection_notes'] as String?,
            sellerRejectionNotes:
                data['seller_rejection_notes'] as String?,
          );
        },
      ),
    );
  }

  // ─── Views ────────────────────────────────────────────────────────────────

  Widget _buildErrorView(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: colorScheme.error, size: 56),
            ),
            const SizedBox(height: 24),
            Text(
              'Error al generar el contrato',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onErrorContainer,
                    height: 1.5),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _actionLoading ? null : _regenerateContract,
              icon: _actionLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: colorScheme.onPrimary, strokeWidth: 2))
                  : const Icon(Icons.refresh_outlined),
              label: const Text('Reintentar generacion'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Si el problema persiste, espera unos minutos antes de reintentar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingView() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
            const SizedBox(height: 28),
            Text(
              'Generando contrato con IA',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              'Gemini esta redactando el Contrato de Arras Penitenciales '
              'con las condiciones acordadas por ambas partes. '
              'Este proceso puede tardar unos segundos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_outlined,
                      color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'La pagina se actualizara automaticamente cuando el contrato este listo.',
                      style: TextStyle(
                          fontSize: 13, color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullyAcceptedView() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kGreen = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.check_circle, color: kGreen, size: 56),
            ),
            const SizedBox(height: 24),
            Text(
              'Contrato firmado',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              'Ambas partes han aceptado el Contrato de Arras Penitenciales. '
              'La transaccion avanza a la etapa de tasacion.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_outlined),
              label: const Text('Volver al timeline'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractView({
    required String contractText,
    required String contractStatus,
    required bool isBuyer,
    required bool myAccepted,
    required bool otherAccepted,
    required int generationCount,
    String? buyerRejectionNotes,
    String? sellerRejectionNotes,
  }) {
    final myRejectionNotes =
        isBuyer ? buyerRejectionNotes : sellerRejectionNotes;
    final otherRejectionNotes =
        isBuyer ? sellerRejectionNotes : buyerRejectionNotes;

    return Column(
      children: [
        // ── Status banner ──────────────────────────────────────
        _ContractStatusBanner(
          isBuyer: isBuyer,
          buyerAccepted: contractStatus == 'buyer_accepted' ||
              contractStatus == 'fully_accepted',
          sellerAccepted: contractStatus == 'seller_accepted' ||
              contractStatus == 'fully_accepted',
          generationCount: generationCount,
        ),

        // ── Equity analysis CTA ────────────────────────────────
        _EquityAnalysisBanner(offer: widget.offer),

        // ── Rejection notes if any ─────────────────────────────
        if (otherRejectionNotes != null && otherRejectionNotes.isNotEmpty)
          _RejectionNotesBanner(
            label: isBuyer ? 'Notas del vendedor:' : 'Notas del comprador:',
            notes: otherRejectionNotes,
          ),
        if (myRejectionNotes != null && myRejectionNotes.isNotEmpty)
          _RejectionNotesBanner(
            label: 'Mis notas anteriores:',
            notes: myRejectionNotes,
            isMine: true,
          ),

        // ── Contract text ──────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SelectableText(
                contractText,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.7,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),

        // ── Action bar ─────────────────────────────────────────
        if (!myAccepted)
          _ContractActionBar(
            onAccept: _actionLoading ? null : _acceptContract,
            onReject: _actionLoading
                ? null
                : () => _showRejectSheet(context),
            loading: _actionLoading,
          )
        else
          _WaitingBanner(
            label: otherAccepted
                ? 'Ambos han aceptado.'
                : 'Has aceptado. Esperando a la otra parte...',
          ),
      ],
    );
  }

  void _showRejectSheet(BuildContext context) {
    _rejectNotesCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solicitar cambios en el contrato',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Explica que cambios necesitas. Ambas partes deberan volver a confirmar '
              'sus entrevistas y el contrato se regenerara.',
              style: TextStyle(fontSize: 13, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectNotesCtrl,
              maxLines: 5,
              autofocus: true,
              decoration: InputDecoration(
                hintText:
                    'Ej: Necesito incluir la clausula de entrega de llaves en el plazo...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(ctx).colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(ctx).colorScheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final notes = _rejectNotesCtrl.text.trim();
                      if (notes.length < 5) return;
                      Navigator.of(ctx).pop();
                      _rejectContract(notes);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(ctx).colorScheme.error,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Enviar rechazo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
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
            Text.rich(
              TextSpan(
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                      text: 'Inmu',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  TextSpan(
                      text: 'Fácil',
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF16A34A))),
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
        Consumer(
          builder: (context, ref, _) {
            final isAuthenticated = ref.watch(authProvider).isAuthenticated;
            if (!isAuthenticated) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (MediaQuery.sizeOf(context).width >= 650)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go('/'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home_rounded, size: 18, color: Theme.of(context).colorScheme.onPrimary),
                          const SizedBox(width: 6),
                          Text(
                            'Inicio',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const UserAvatarMenu(),
                const SizedBox(width: 16),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ContractStatusBanner extends StatelessWidget {
  const _ContractStatusBanner({
    required this.isBuyer,
    required this.buyerAccepted,
    required this.sellerAccepted,
    required this.generationCount,
  });

  final bool isBuyer;
  final bool buyerAccepted;
  final bool sellerAccepted;
  final int generationCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.onPrimaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _Badge(label: 'Comprador', accepted: buyerAccepted),
          const Spacer(),
          if (generationCount > 1)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Version $generationCount',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ),
          const Spacer(),
          _Badge(label: 'Vendedor', accepted: sellerAccepted),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.accepted});

  final String label;
  final bool accepted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kGreen = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    return Row(
      children: [
        Icon(
          accepted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: accepted ? kGreen : Colors.white.withValues(alpha: 0.38),
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: accepted ? Colors.white : Colors.white.withValues(alpha: 0.54),
            fontSize: 12,
            fontWeight: accepted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _RejectionNotesBanner extends StatelessWidget {
  const _RejectionNotesBanner({
    required this.label,
    required this.notes,
    this.isMine = false,
  });

  final String label;
  final String notes;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isMine
        ? (isDark ? const Color(0xFFFBBF24) : Colors.orange.shade700)
        : colorScheme.error;
    final bg = isMine
        ? (isDark ? colorScheme.surfaceContainer : Colors.orange.shade50)
        : colorScheme.errorContainer;
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.comment_outlined, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                Text(notes,
                    style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractActionBar extends StatelessWidget {
  const _ContractActionBar({
    required this.onAccept,
    required this.onReject,
    this.loading = false,
  });

  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kGreen = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: loading ? null : onReject,
              icon: Icon(Icons.edit_outlined, color: colorScheme.error),
              label: Text('Solicitar cambios',
                  style: TextStyle(color: colorScheme.error)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: loading ? colorScheme.outlineVariant : colorScheme.error),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: loading ? null : onAccept,
              icon: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: colorScheme.onPrimary, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Aceptar contrato'),
              style: FilledButton.styleFrom(
                backgroundColor: kGreen,
                disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingBanner extends StatelessWidget {
  const _WaitingBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kGreen = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kGreen.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: kGreen, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    color: kGreen,
                    fontWeight: FontWeight.w500,
                    fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquityAnalysisBanner extends StatelessWidget {
  const _EquityAnalysisBanner({required this.offer});

  final OfferData offer;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push(
          '/offers/${offer.id}/arras/equity',
          extra: offer,
        ),
        child: Builder(
          builder: (context) {
            final cs = Theme.of(context).colorScheme;
            return Container(
          color: cs.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.analytics_outlined,
                    color: cs.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analizar mi posicion',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'IA analiza cada clausula desde tu perspectiva',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.primary, size: 20),
            ],
          ),
        );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/verification_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import '../../widgets/common/premium_button.dart';

class VerificationStatusScreen extends ConsumerStatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  ConsumerState<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState
    extends ConsumerState<VerificationStatusScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(verificationProvider.notifier).fetchKycStatus());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificationProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? _buildError(state)
              : SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 24),
                        child: _buildStatusCard(state),
                      ),
                    ),
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppBarBackButton(
          onPressed: () => context.go('/profile'),
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
                        text: 'Fácil',
                        style: TextStyle(color: Color(0xFF16A34A))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
      ),
      actions: [
        // Botón Inicio
        if (MediaQuery.sizeOf(context).width >= 650)
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.25),
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
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const UserAvatarMenu(),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildError(VerificationState state) {
    final isSessionExpired = state.errorMessage == '__session_expired__';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSessionExpired ? Icons.lock_clock : Icons.error_outline,
              size: 48,
              color: isSessionExpired
                  ? Colors.orange.shade400
                  : Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isSessionExpired
                  ? 'Tu sesión ha expirado'
                  : state.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSessionExpired
                    ? Colors.orange.shade700
                    : Colors.red.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSessionExpired) ...[
              const SizedBox(height: 8),
              Text(
                'Inicia sesión de nuevo para continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
            const SizedBox(height: 24),
            if (isSessionExpired)
              ElevatedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login),
                label: const Text('Iniciar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              )
            else
              TextButton(
                onPressed: () =>
                    ref.read(verificationProvider.notifier).fetchKycStatus(),
                child: const Text('Reintentar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(VerificationState state) {
    final status = state.kycStatus?.toLowerCase() ?? 'unverified';

    switch (status) {
      case 'validado':
        return _buildApprovedCard();
      case 'rechazado':
        return _buildRejectedCard(state);
      case 'unverified':
      case 'sin_verificar':
        return _buildNotStartedCard();
      default:
        return _buildPendingCard(state);
    }
  }

  // ── NOT STARTED ───────────────────────────────────────────────────────

  Widget _buildNotStartedCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.badge_outlined,
                  size: 40, color: Colors.blue.shade400),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verifica tu identidad',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Todavia no has enviado tus documentos. Completa la verificacion para acceder a todas las funcionalidades.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 28),
            PremiumButton(
              label: 'Iniciar verificacion',
              icon: Icons.arrow_forward,
              color: const Color(0xFF2563EB),
              onPressed: () => context.push('/verify-identity'),
            ),
          ],
        ),
      ),
    );
  }

  // ── PENDING ──────────────────────────────────────────────────────────

  Widget _buildPendingCard(VerificationState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            // Orange badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'VERIFICACIÓN EN CURSO',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Clock icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.access_time_filled,
                  size: 40, color: Colors.orange.shade400),
            ),

            const SizedBox(height: 20),

            const Text(
              'Estamos revisando tus documentos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El proceso de verificación puede tardar hasta 24 horas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),

            const SizedBox(height: 28),

            // 3-step progress
            _buildProgressSteps(),

            if (state.uploadDate != null) ...[
              const SizedBox(height: 20),
              Text(
                'Enviado el ${_formatDate(state.uploadDate!)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],

            const SizedBox(height: 28),

            PremiumButton(
              label: 'Volver al Inicio',
              icon: Icons.home_outlined,
              color: const Color(0xFF64748B),
              onPressed: () => context.go('/'),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () {
                ref.read(verificationProvider.notifier).reset();
                context.go('/verify-identity');
              },
              child: const Text(
                'Volver a enviar documentos',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSteps() {
    return Row(
      children: [
        _buildStep('Enviado', Icons.check_circle, true),
        _buildStepConnector(true),
        _buildStep('Validando', Icons.pending, false),
        _buildStepConnector(false),
        _buildStep('Listo', Icons.verified, false),
      ],
    );
  }

  Widget _buildStep(String label, IconData icon, bool completed) {
    final color = completed ? Colors.green : Colors.grey.shade400;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: completed ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool completed) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: completed ? Colors.green : Colors.grey.shade300,
      ),
    );
  }

  // ── APPROVED ─────────────────────────────────────────────────────────

  Widget _buildApprovedCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Green top bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: const Color(0xFF16A34A),
            child: const Center(
              child: Text(
                'IDENTIDAD VERIFICADA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                // Green shield icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.shield,
                          size: 48, color: Colors.green.shade400),
                      const Positioned(
                        bottom: 20,
                        right: 18,
                        child: Icon(Icons.check_circle,
                            size: 24, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ESTADO: VERIFICADO',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Tu identidad ha sido verificada correctamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF475569),
                  ),
                ),

                const SizedBox(height: 28),

                PremiumButton(
                  label: 'Publicar Inmueble',
                  icon: Icons.add_home_outlined,
                  color: const Color(0xFF16A34A),
                  onPressed: () => context.go('/404-publish'),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => context.go('/profile'),
                  child: const Text(
                    'Volver al perfil',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
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

  // ── REJECTED ─────────────────────────────────────────────────────────

  Widget _buildRejectedCard(VerificationState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Red header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: const Color(0xFFDC2626),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'VERIFICACIÓN FALLIDA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                // Error icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.gpp_bad,
                      size: 44, color: Colors.red.shade400),
                ),

                const SizedBox(height: 20),

                const Text(
                  'No pudimos verificar tu identidad',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),

                const SizedBox(height: 16),

                // Rejection reason box
                if (state.rejectionReason != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Motivo del rechazo:',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          () {
                            final r = state.rejectionReason!;
                            final isApiError = r.startsWith('Error al contactar') ||
                                r.contains('429') ||
                                r.contains('RESOURCE');
                            return isApiError
                                ? 'El servicio de verificación no está disponible en este momento. Inténtalo de nuevo más tarde.'
                                : r;
                          }(),
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                Text(
                  'Puedes volver a enviar tus documentos corrigiendo los errores indicados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),

                const SizedBox(height: 24),

                PremiumButton(
                  label: 'Reintentar Verificación',
                  icon: Icons.refresh,
                  color: const Color(0xFF2563EB),
                  onPressed: () {
                    ref.read(verificationProvider.notifier).reset();
                    context.go('/verify-identity');
                  },
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => context.go('/profile'),
                  child: const Text(
                    'Volver al perfil',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

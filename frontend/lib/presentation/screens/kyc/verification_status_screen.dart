import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(
                        text: 'Inmu',
                        style: TextStyle(color: colorScheme.primary)),
                    TextSpan(
                        text: 'Fácil',
                        style: TextStyle(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: colorScheme.surface,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: colorScheme.outlineVariant, height: 1),
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
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_rounded, size: 18, color: colorScheme.onPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'common.home'.tr(),
                    style: TextStyle(
                      color: colorScheme.onPrimary,
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
                  ? 'common.session_expired'.tr()
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
                'common.login_again'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
            const SizedBox(height: 24),
            if (isSessionExpired)
              ElevatedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login),
                label: Text('common.login'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
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
                child: Text('common.retry'.tr()),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
            Text(
              'kyc.verify_identity_title'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'kyc.not_started_desc'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 28),
            PremiumButton(
              label: 'kyc.start_verification'.tr(),
              icon: Icons.arrow_forward,
              color: colorScheme.primary,
              onPressed: () => context.push('/verify-identity'),
            ),
          ],
        ),
      ),
    );
  }

  // ── PENDING ──────────────────────────────────────────────────────────

  Widget _buildPendingCard(VerificationState state) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
                    'kyc.verification_in_progress'.tr(),
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

            Text(
              'kyc.reviewing_docs'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'kyc.verification_time'.tr(),
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
              label: 'common.back_to_home'.tr(),
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
              child: Text(
                'kyc.resubmit_docs'.tr(),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
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
        _buildStep('kyc.submitted_step'.tr(), Icons.check_circle, true),
        _buildStepConnector(true),
        _buildStep('kyc.validating_step'.tr(), Icons.pending, false),
        _buildStepConnector(false),
        _buildStep('kyc.ready_step'.tr(), Icons.verified, false),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
            color: greenColor,
            child: Center(
              child: Text(
                'kyc.identity_verified'.tr(),
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
                      Positioned(
                        bottom: 20,
                        right: 18,
                        child: Icon(Icons.check_circle,
                            size: 24, color: greenColor),
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
                    'kyc.status_verified'.tr(),
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'kyc.identity_verified_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 28),

                PremiumButton(
                  label: 'kyc.publish_property'.tr(),
                  icon: Icons.add_home_outlined,
                  color: greenColor,
                  onPressed: () => context.go('/404-publish'),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => context.go('/profile'),
                  child: Text(
                    'kyc.back_to_profile'.tr(),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
            color: colorScheme.error,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'kyc.verification_failed'.tr(),
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

                Text(
                  'kyc.could_not_verify'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
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
                          'kyc.rejection_reason'.tr(),
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
                                ? 'kyc.service_unavailable'.tr()
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
                  'kyc.resubmit_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),

                const SizedBox(height: 24),

                PremiumButton(
                  label: 'kyc.retry_verification'.tr(),
                  icon: Icons.refresh,
                  color: colorScheme.primary,
                  onPressed: () {
                    ref.read(verificationProvider.notifier).reset();
                    context.go('/verify-identity');
                  },
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => context.go('/profile'),
                  child: Text(
                    'kyc.back_to_profile'.tr(),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
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

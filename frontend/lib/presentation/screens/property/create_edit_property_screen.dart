import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_localization/easy_localization.dart';
import '../../providers/property_form_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import '../../widgets/common/user_avatar_menu.dart';
import 'widgets/property_stepper_header.dart';
import 'widgets/property_step1_type_location.dart';
import 'widgets/property_step2_details_price.dart';
import 'widgets/property_step3_doc_verification.dart';
import 'widgets/property_step3_photos_extras.dart';
import 'widgets/property_step4_ai_description.dart';
import 'widgets/property_step5_preview.dart';
import 'widgets/property_wizard_bottom_bar.dart';

class CreateEditPropertyScreen extends ConsumerStatefulWidget {
  const CreateEditPropertyScreen({super.key, this.editPropertyId});

  final String? editPropertyId;

  @override
  ConsumerState<CreateEditPropertyScreen> createState() =>
      _CreateEditPropertyScreenState();
}

class _CreateEditPropertyScreenState
    extends ConsumerState<CreateEditPropertyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(propertyFormProvider.notifier);
      notifier.reset();
      if (widget.editPropertyId != null) {
        notifier.loadPropertyForEdit(widget.editPropertyId!);
      }
    });
  }

  void _confirmCancel(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isMobile = MediaQuery.of(ctx).size.width < 600;

        final keepEditingButton = OutlinedButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(
              color: Theme.of(ctx).colorScheme.primary,
              width: 1.5,
            ),
          ),
          child: Text('property_wizard.keep_editing'.tr()),
        );

        final cancelExitButton = FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('property_wizard.cancel_exit'.tr()),
        );

        if (isMobile) {
          return AlertDialog(
            title: Text('property_wizard.cancel_title'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('property_wizard.cancel_message'.tr()),
                const SizedBox(height: 24),
                keepEditingButton,
                const SizedBox(height: 12),
                cancelExitButton,
              ],
            ),
          );
        }

        return AlertDialog(
          title: Text('property_wizard.cancel_title'.tr()),
          content: Text('property_wizard.cancel_message'.tr()),
          actions: [keepEditingButton, cancelExitButton],
        );
      },
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        ref.read(propertyFormProvider.notifier).reset();
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(propertyFormProvider);
    final notifier = ref.read(propertyFormProvider.notifier);

    // Show API errors as SnackBar (any error that is not session_expired)
    ref.listen<PropertyFormState>(propertyFormProvider, (prev, next) {
      if (next.status == PropertyFormStatus.error &&
          next.errorMessage != null &&
          next.errorMessage != '__session_expired__' &&
          prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'common.close'.tr(),
              textColor: Colors.white,
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }
    });

    // Session expired
    if (formState.errorMessage == '__session_expired__') {
      return _SessionExpiredScreen();
    }

    // Loading for edit
    if (formState.status == PropertyFormStatus.loadingForEdit) {
      return Scaffold(
        appBar: _buildAppBar(context, formState),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context, formState),
      body: Column(
        children: [
          const PropertyStepperHeader(),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 768;
                // Step 1 on desktop manages its own split layout + scroll internally
                if (isDesktop && formState.currentStep == 0) {
                  return const PropertyStep1TypeLocation();
                }
                // All other steps: render only the active step inside a scroll view.
                // State lives in the provider so IndexedStack is not needed.
                final Widget stepWidget = switch (formState.currentStep) {
                  0 => const PropertyStep1TypeLocation(),
                  1 => const PropertyStep2DetailsPrice(),
                  2 => const PropertyStep3PhotosExtras(),
                  3 => const PropertyStep3DocVerification(),
                  4 => const PropertyStep4AiDescription(),
                  _ => const PropertyStep5Preview(),
                };
                // Step 6 (preview) manages its own scroll
                if (formState.currentStep == 5) return stepWidget;
                return SingleChildScrollView(child: stepWidget);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: PropertyWizardBottomBar(
        onSubmit: () => notifier.submit(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, PropertyFormState formState) {
    final isEdit = formState.isEditMode;

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      // -- Leading: Cancel (x) ------------------------------------------------------
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppBarCloseButton(
          onPressed: () => _confirmCancel(context),
        ),
      ),
      // ── Title: logo + label (label hidden on mobile to avoid crowding) ──
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo_inmufacil.png', height: 28),
              if (MediaQuery.sizeOf(context).width >= 600) ...[
                const SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final cs = Theme.of(context).colorScheme;
                    return Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        children: [
                          TextSpan(
                              text: 'Inmu',
                              style: TextStyle(color: cs.primary)),
                          TextSpan(
                              text: 'Fácil',
                              style: TextStyle(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      // ── Actions: inicio + guardar borrador + avatar ───────────────────────────────
      actions: [
        if (MediaQuery.sizeOf(context).width >= 650)
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: Builder(
              builder: (context) {
                final cs = Theme.of(context).colorScheme;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home_rounded, size: 16, color: cs.onPrimary),
                      const SizedBox(width: 5),
                      Text('common.home'.tr(), style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        _SaveDraftButton(),
        const SizedBox(width: 12),
        const UserAvatarMenu(),
        const SizedBox(width: 12),
      ],
    );
  }
}

// ─── Save Draft button (AppBar action) ───────────────────────────────────────

class _SaveDraftButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(propertyFormProvider);
    final notifier = ref.read(propertyFormProvider.notifier);
    final isSaving = formState.status == PropertyFormStatus.savingDraft;
    final isSubmitting = formState.status == PropertyFormStatus.submitting ||
        formState.status == PropertyFormStatus.uploadingImages;

    return OutlinedButton(
      onPressed:
          (isSaving || isSubmitting) ? null : () => notifier.saveDraft(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFCA8A04),
        side: const BorderSide(color: Color(0xFFCA8A04)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        visualDensity: VisualDensity.compact,
      ),
      child: isSaving
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFCA8A04),
              ),
            )
          : Text(
              'property_wizard.save_draft'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
    );
  }
}

// ─── Session expired ─────────────────────────────────────────────────────────

class _SessionExpiredScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('property_wizard.session_expired_title'.tr(),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'property_wizard.session_expired_message'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/login'),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary),
              child: Text('property_wizard.login'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

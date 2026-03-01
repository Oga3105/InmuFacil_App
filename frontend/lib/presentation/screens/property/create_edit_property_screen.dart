import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/temp_translations.dart';
import '../../providers/property_form_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_bar_back_button.dart';
import 'widgets/property_stepper_header.dart';
import 'widgets/property_step1_type_location.dart';
import 'widgets/property_step2_details_price.dart';
import 'widgets/property_step3_photos_extras.dart';
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
      builder: (ctx) => AlertDialog(
        title: Text('property_wizard.cancel_title'.tr()),
        content: Text('property_wizard.cancel_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('property_wizard.keep_editing'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('property_wizard.cancel_exit'.tr()),
          ),
        ],
      ),
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
      backgroundColor: const Color(0xFFF8FAFC),
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
                  _ => const PropertyStep3PhotosExtras(),
                };
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
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      // -- Leading: Cancel (x) ------------------------------------------------------
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppBarCloseButton(
          onPressed: () => _confirmCancel(context),
        ),
      ),
      // ── Title: logo + label ──────────────────────────────────────────────
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo_inmufacil.png', height: 28),
              const SizedBox(width: 8),
              const Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
      // ── Actions: guardar borrador + avatar ───────────────────────────────
      actions: [
        _SaveDraftButton(),
        const SizedBox(width: 12),
        _AvatarButton(),
        const SizedBox(width: 12),
      ],
    );
  }
}

// ─── Avatar ──────────────────────────────────────────────────────────────────

class _AvatarButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final photoUrl = user?.profilePhotoUrl;
    
    return GestureDetector(
      onTap: () => context.go('/profile'),
      child: Builder(
        builder: (context) {
          final ts = DateTime.now().millisecondsSinceEpoch;
          return SizedBox(
            width: 36,
            height: 36,
            child: ClipOval(
              child: photoUrl != null
                  ? Image.network(
                      '$photoUrl?v=$ts',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF2563EB),
                        alignment: Alignment.center,
                        child: const Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF2563EB),
                      alignment: Alignment.center,
                      child: const Icon(Icons.person, color: Colors.white, size: 18),
                    ),
            ),
          );
        },
      ),
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Color(0xFF2563EB)),
            const SizedBox(height: 16),
            Text('property_wizard.session_expired_title'.tr(),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'property_wizard.session_expired_message'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/login'),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB)),
              child: Text('property_wizard.login'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

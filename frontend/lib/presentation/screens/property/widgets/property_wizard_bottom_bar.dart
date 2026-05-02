import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:easy_localization/easy_localization.dart';
import '../../../providers/property_form_provider.dart';

class PropertyWizardBottomBar extends ConsumerWidget {
  const PropertyWizardBottomBar({
    super.key,
    required this.onSubmit,
  });

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formState = ref.watch(propertyFormProvider);
    final notifier = ref.read(propertyFormProvider.notifier);
    final currentStep = formState.currentStep;
    final isSubmitting = formState.status == PropertyFormStatus.submitting ||
        formState.status == PropertyFormStatus.uploadingImages;
    final isLastStep = currentStep == 5;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (hidden on step 0)
          if (currentStep > 0)
            TextButton.icon(
              onPressed: isSubmitting ? null : () => notifier.prevStep(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: Text('property_wizard.back'.tr()),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            const SizedBox.shrink(),

          // Next / Submit button
          FilledButton(
            onPressed: isSubmitting
                ? () {} // keep enabled so color stays vivid
                : () {
                    if (isLastStep) {
                      onSubmit();
                    } else {
                      notifier.nextStep();
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: isLastStep ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)) : colorScheme.primary,
              disabledBackgroundColor: isLastStep ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)) : colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isSubmitting && isLastStep
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'property_wizard.publishing'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLastStep)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.rocket_launch_outlined, size: 16),
                        ),
                      Text(
                        isLastStep
                            ? 'property_wizard.publish_ad'.tr()
                            : 'property_wizard.next'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (!isLastStep) ...[
                        const SizedBox(width: 6),
                        const Text('→', style: TextStyle(fontSize: 15)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/temp_translations.dart';
import '../../../providers/property_form_provider.dart';

class PropertyWizardBottomBar extends ConsumerWidget {
  const PropertyWizardBottomBar({
    super.key,
    required this.onSubmit,
  });

  final VoidCallback onSubmit;

  static const _blue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(propertyFormProvider);
    final notifier = ref.read(propertyFormProvider.notifier);
    final currentStep = formState.currentStep;
    final isSubmitting = formState.status == PropertyFormStatus.submitting ||
        formState.status == PropertyFormStatus.uploadingImages;
    final isLastStep = currentStep == 2;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                foregroundColor: Colors.grey.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            const SizedBox.shrink(),

          // Next / Submit button
          FilledButton(
            onPressed: isSubmitting
                ? null
                : () {
                    if (isLastStep) {
                      onSubmit();
                    } else {
                      notifier.nextStep();
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLastStep
                            ? 'property_wizard.publish'.tr()
                            : 'property_wizard.next'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isLastStep ? '' : '→',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

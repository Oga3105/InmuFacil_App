import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/legal_guides_provider.dart';
import 'legal_info_sheet.dart';

// ---------------------------------------------------------------------------
// Colors (spec from task brief)
// ---------------------------------------------------------------------------

const _kBlue = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);

// ---------------------------------------------------------------------------
// LegalGuideButton
// ---------------------------------------------------------------------------

/// A button that opens a [LegalInfoSheet] for the given CCAA and guide type.
///
/// Visual state:
///   - Not consulted: [ElevatedButton] with blue background.
///   - Consulted:     [OutlinedButton] with green border/text + " (leido)" suffix.
class LegalGuideButton extends ConsumerWidget {
  const LegalGuideButton({
    super.key,
    required this.ccaa,
    required this.guideType,
    required this.label,
  });

  final String ccaa;
  final String guideType;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideKey = '${ccaa}_$guideType';
    final consulted = ref.watch(
      consultedGuidesProvider.select((s) => s.contains(guideKey)),
    );

    if (consulted) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: _kGreen,
          side: const BorderSide(color: _kGreen),
        ),
        onPressed: () => _onTap(context, ref, guideKey),
        child: Text('$label (leido)'),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _kBlue,
        foregroundColor: Colors.white,
      ),
      onPressed: () => _onTap(context, ref, guideKey),
      child: Text(label),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    String guideKey,
  ) async {
    await LegalInfoSheet.show(
      context,
      ccaa: ccaa,
      guideType: guideType,
      title: label,
    );
    // After the sheet closes, mark as consulted
    await ref
        .read(consultedGuidesProvider.notifier)
        .markAsConsulted(guideKey);
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:inmufacil_frontend/domain/entities/lifestyle_profile.dart';
import 'package:inmufacil_frontend/presentation/providers/lifestyle_provider.dart';
import 'package:inmufacil_frontend/presentation/widgets/common/app_bar_back_button.dart';
import 'package:inmufacil_frontend/presentation/widgets/common/user_avatar_menu.dart';

/// V63 / V63.1 — Lifestyle Questionnaire Screen
///
/// Renders a multi-section questionnaire that populates a [LifestyleProfile].
/// On "Guardar perfil" the profile is persisted via [lifestyleProfileProvider].
class LifestyleQuestionnaireScreen extends ConsumerStatefulWidget {
  const LifestyleQuestionnaireScreen({super.key});

  @override
  ConsumerState<LifestyleQuestionnaireScreen> createState() =>
      _LifestyleQuestionnaireScreenState();
}

class _LifestyleQuestionnaireScreenState
    extends ConsumerState<LifestyleQuestionnaireScreen> {
  late LifestyleProfile _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(lifestyleProfileProvider);
  }

  void _save() async {
    await ref.read(lifestyleProfileProvider.notifier).updateProfile(_draft);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('lifestyle.saved_snackbar'.tr()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AppBarBackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
        ),
        title: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo_inmufacil.png', height: 28),
                const SizedBox(width: 8),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: 'Inmu', style: TextStyle(color: Color(0xFF2563EB))),
                      TextSpan(text: 'Fácil', style: TextStyle(color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 650)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
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
                    Icon(Icons.home_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Text('Inicio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const UserAvatarMenu(),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Screen header ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_outlined, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'lifestyle.screen_title'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'lifestyle.screen_description'.tr(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Question 1: Ritmo de vida ───────────────────────────────────────
          _QuestionCard(
            title: 'lifestyle.pace_title'.tr(),
            child: _MultiOptionSelector<LifestylePace>(
              value: _draft.pace,
              options: [
                (LifestylePace.vibrant_center, 'lifestyle.pace_vibrant'.tr()),
                (LifestylePace.calm_peripheral, 'lifestyle.pace_calm'.tr()),
                (LifestylePace.residential_neighborhood, 'lifestyle.pace_residential'.tr()),
                (LifestylePace.cultural_zone, 'lifestyle.pace_cultural'.tr()),
                (LifestylePace.rural, 'lifestyle.pace_rural'.tr()),
              ],
              onChanged: (v) => setState(() { _draft = _draft.copyWith(pace: v); }),
            ),
          ),

          // ── Question 2: Entorno laboral ────────────────────────────────────
          _QuestionCard(
            title: 'lifestyle.work_title'.tr(),
            child: _MultiOptionSelector<WorkStyle>(
              value: _draft.workStyle,
              options: [
                (WorkStyle.daily_office, 'lifestyle.work_office'.tr()),
                (WorkStyle.home_office, 'lifestyle.work_home'.tr()),
                (WorkStyle.hybrid, 'lifestyle.work_hybrid'.tr()),
                (WorkStyle.freelance, 'lifestyle.work_freelance'.tr()),
              ],
              onChanged: (v) => setState(() { _draft = _draft.copyWith(workStyle: v); }),
            ),
          ),

          // ── Question 3: Movilidad ──────────────────────────────────────────
          _QuestionCard(
            title: 'lifestyle.mobility_title'.tr(),
            child: _MultiOptionSelector<MobilityStyle>(
              value: _draft.mobility,
              options: [
                (MobilityStyle.public_transport, 'lifestyle.mobility_public'.tr()),
                (MobilityStyle.private_car, 'lifestyle.mobility_car'.tr()),
                (MobilityStyle.cycling, 'lifestyle.mobility_cycling'.tr()),
                (MobilityStyle.walking, 'lifestyle.mobility_walking'.tr()),
              ],
              onChanged: (v) => setState(() { _draft = _draft.copyWith(mobility: v); }),
            ),
          ),

          // ── Question 4: Descanso ───────────────────────────────────────────
          _QuestionCard(
            title: 'lifestyle.sleep_title'.tr(),
            child: _MultiOptionSelector<SleepSensitivity>(
              value: _draft.sleep,
              options: [
                (SleepSensitivity.high_noise_sensitivity, 'lifestyle.sleep_sensitive'.tr()),
                (SleepSensitivity.deep_sleeper, 'lifestyle.sleep_deep'.tr()),
                (SleepSensitivity.needs_darkness, 'lifestyle.sleep_darkness'.tr()),
                (SleepSensitivity.night_owl, 'lifestyle.sleep_night_owl'.tr()),
              ],
              onChanged: (v) => setState(() { _draft = _draft.copyWith(sleep: v); }),
            ),
          ),

          // ── Question 5: Entorno ────────────────────────────────────────────
          _QuestionCard(
            title: 'lifestyle.green_title'.tr(),
            child: _MultiOptionSelector<GreenNeeds>(
              value: _draft.greenNeeds,
              options: [
                (GreenNeeds.needs_green, 'lifestyle.green_needs'.tr()),
                (GreenNeeds.prefers_services, 'lifestyle.green_services'.tr()),
                (GreenNeeds.near_water, 'lifestyle.green_water'.tr()),
                (GreenNeeds.mountain_nature, 'lifestyle.green_mountain'.tr()),
                (GreenNeeds.historic_center, 'lifestyle.green_historic'.tr()),
              ],
              onChanged: (v) => setState(() { _draft = _draft.copyWith(greenNeeds: v); }),
            ),
          ),

          // ── V63.1 Slider 1: Luz natural ────────────────────────────────────
          _QuestionCard(
            title: 'lifestyle.light_slider_title'.tr(),
            child: _LabelledSlider(
              value: _draft.naturalLightWeight,
              startLabel: 'lifestyle.light_slider_start'.tr(),
              endLabel: 'lifestyle.light_slider_end'.tr(),
              activeColor: const Color(0xFF2563EB),
              onChanged: (v) => setState(() {
                _draft = _draft.copyWith(naturalLightWeight: v);
              }),
            ),
          ),

          // ── V63.1 Slider 2: Zonas comunes ──────────────────────────────────
          _QuestionCard(
            title: 'lifestyle.social_slider_title'.tr(),
            child: _LabelledSlider(
              value: _draft.socialWeight,
              startLabel: 'lifestyle.social_slider_start'.tr(),
              endLabel: 'lifestyle.social_slider_end'.tr(),
              activeColor: const Color(0xFF16A34A),
              onChanged: (v) => setState(() {
                _draft = _draft.copyWith(socialWeight: v);
              }),
            ),
          ),

          // ── V63.1 Slider 3: Estado del inmueble ────────────────────────────
          _QuestionCard(
            title: 'lifestyle.ready_slider_title'.tr(),
            child: _LabelledSlider(
              value: _draft.readyToLiveWeight,
              startLabel: 'lifestyle.ready_slider_start'.tr(),
              endLabel: 'lifestyle.ready_slider_end'.tr(),
              activeColor: const Color(0xFFF59E0B),
              onChanged: (v) => setState(() {
                _draft = _draft.copyWith(readyToLiveWeight: v);
              }),
            ),
          ),

          // ── Profile type selector ──────────────────────────────────────────
          _QuestionCard(
            title: 'lifestyle.profile_type_title'.tr(),
            child: _ProfileTypeSelector(
              value: _draft.profileType,
              onChanged: (v) => setState(() {
                _draft = _draft.copyWith(profileType: v);
              }),
            ),
          ),

          const SizedBox(height: 24),

          // ── Save button ────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'lifestyle.save_button'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Private widgets
// ────────────────────────────────────────────────────────────────────────────

/// Wrapper card for each questionnaire question.
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Multi-option selector — renders N options as a Wrap of selectable chips.
class _MultiOptionSelector<T> extends StatelessWidget {
  const _MultiOptionSelector({
    required this.value,
    required this.options,
    required this.onChanged,
    this.accentColor = const Color(0xFF2563EB),
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final selected = value == opt.$1;
        return GestureDetector(
          onTap: () => onChanged(opt.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: selected
                  ? accentColor
                  : accentColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? accentColor
                    : accentColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Text(
              opt.$2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : accentColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Slider with start/end labels.
class _LabelledSlider extends StatelessWidget {
  const _LabelledSlider({
    required this.value,
    required this.startLabel,
    required this.endLabel,
    required this.activeColor,
    required this.onChanged,
  });

  final double value;
  final String startLabel;
  final String endLabel;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: activeColor,
            thumbColor: activeColor,
            inactiveTrackColor: activeColor.withValues(alpha: 0.2),
            overlayColor: activeColor.withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: 0.0,
            max: 1.0,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              startLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              endLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Grid of profile type chips (Single, Pareja, Familia...).
class _ProfileTypeSelector extends StatelessWidget {
  const _ProfileTypeSelector({
    required this.value,
    required this.onChanged,
  });

  final ProfileType value;
  final ValueChanged<ProfileType> onChanged;

  static const _options = <ProfileType, String>{
    ProfileType.single: 'lifestyle.profile_single',
    ProfileType.couple: 'lifestyle.profile_couple',
    ProfileType.family_children: 'lifestyle.profile_family_children',
    ProfileType.family_pets: 'lifestyle.profile_family_pets',
    ProfileType.senior: 'lifestyle.profile_senior',
    ProfileType.investor: 'lifestyle.profile_investor',
    ProfileType.student: 'lifestyle.profile_student',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.entries.map((entry) {
        final selected = value == entry.key;
        return GestureDetector(
          onTap: () => onChanged(entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF16A34A).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF16A34A).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Text(
              entry.value.tr(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF16A34A),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

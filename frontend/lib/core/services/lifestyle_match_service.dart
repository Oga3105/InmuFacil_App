import 'package:inmufacil_frontend/domain/entities/lifestyle_profile.dart';

/// V63.1 — Lifestyle Ultra-Match Engine
///
/// Computes a vectorial match score between a [LifestyleProfile] and a
/// property's ICI (Indicador de Calidad de Indicadores) scores.
///
/// This is a pure-function service — no singleton, no side effects.
class LifestyleMatchService {
  const LifestyleMatchService();

  /// Computes a match score in the range 0–100.
  ///
  /// [profile] — the user's lifestyle preferences.
  /// [propertyIciScores] — ICI indicator scores keyed by dimension:
  ///   - `silence`  : 0.0–1.0
  ///   - `activity` : 0.0–1.0
  ///   - `security` : 0.0–1.0
  ///   - `air`      : 0.0–1.0
  ///   - `greenspace`: 0.0–1.0
  ///
  /// Returns a score in the range [0, 100].
  double computeMatchScore(
    LifestyleProfile profile,
    Map<String, double> propertyIciScores,
  ) {
    // ── Base weights ──────────────────────────────────────────────────────────
    double wSilence = 1.0;
    double wActivity = 1.0;
    double wSecurity = 1.0;
    double wAir = 1.0;
    double wGreenspace = 1.0;

    // ── Profile-driven weight adjustments ─────────────────────────────────────

    // Family with children: prioritise security and green spaces
    if (profile.profileType == ProfileType.family_children) {
      wSecurity *= 1.5;
      wGreenspace *= 1.5;
    }

    // Family with pets: also values green spaces
    if (profile.profileType == ProfileType.family_pets) {
      wGreenspace *= 1.3;
    }

    // Noise-sensitive sleepers weight silence heavily
    if (profile.sleep == SleepSensitivity.high_noise_sensitivity) {
      wSilence = 2.0;
    }

    // Home-office workers prefer quieter neighbourhoods
    if (profile.workStyle == WorkStyle.home_office) {
      wActivity = (wActivity - 0.5).clamp(0.1, 10.0);
    }

    // Calm peripheral pace preference boosts silence, reduces activity
    if (profile.pace == LifestylePace.calm_peripheral) {
      wSilence *= 1.2;
      wActivity = (wActivity * 0.8).clamp(0.1, 10.0);
    }

    // Vibrant centre preference boosts activity
    if (profile.pace == LifestylePace.vibrant_center) {
      wActivity *= 1.2;
    }

    // Green needs boost greenspace score weight
    if (profile.greenNeeds == GreenNeeds.needs_green) {
      wGreenspace *= 1.4;
    }

    // Senior profiles: security + air quality matter more
    if (profile.profileType == ProfileType.senior) {
      wSecurity *= 1.3;
      wAir *= 1.2;
    }

    // V63.1 natural light weight influences air quality proxy
    // High natural light preference (>0.7) raises air weight slightly
    if (profile.naturalLightWeight > 0.7) {
      wAir *= 1.1;
    }

    // ── ICI score extraction ───────────────────────────────────────────────────
    final pSilence = (propertyIciScores['silence'] ?? 0.5).clamp(0.0, 1.0);
    final pActivity = (propertyIciScores['activity'] ?? 0.5).clamp(0.0, 1.0);
    final pSecurity = (propertyIciScores['security'] ?? 0.5).clamp(0.0, 1.0);
    final pAir = (propertyIciScores['air'] ?? 0.5).clamp(0.0, 1.0);
    final pGreenspace =
        (propertyIciScores['greenspace'] ?? 0.5).clamp(0.0, 1.0);

    // ── Weighted sum ──────────────────────────────────────────────────────────
    final weightedSum = wSilence * pSilence +
        wActivity * pActivity +
        wSecurity * pSecurity +
        wAir * pAir +
        wGreenspace * pGreenspace;

    final totalWeight =
        wSilence + wActivity + wSecurity + wAir + wGreenspace;

    if (totalWeight == 0) return 0.0;

    return ((weightedSum / totalWeight) * 100).clamp(0.0, 100.0);
  }

  /// Returns a human-readable match quality label for [score].
  ///
  /// Thresholds:
  ///  - >= 80 : "Muy alta coincidencia"
  ///  - >= 60 : "Alta coincidencia"
  ///  - >= 40 : "Coincidencia moderada"
  ///  - <  40 : "Baja coincidencia"
  String getMatchLabel(double score) {
    if (score >= 80) return 'Muy alta coincidencia';
    if (score >= 60) return 'Alta coincidencia';
    if (score >= 40) return 'Coincidencia moderada';
    return 'Baja coincidencia';
  }
}

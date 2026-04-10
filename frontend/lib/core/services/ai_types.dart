// Shared types for the AI service layer.
// Limits defined here MUST match FEATURE_LIMITS in backend/src/utils/ai_rate_limit.py.
// The backend is the source of truth — these values are used for client-side
// pre-flight checks to avoid unnecessary round-trips when the limit is known.

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

/// Thrown when all models in the fallback chain return 429.
class AiAllModelsExhaustedException implements Exception {
  const AiAllModelsExhaustedException();
  @override
  String toString() =>
      'Todos los modelos de IA estan agotados. Intentalo de nuevo mas tarde.';
}

/// Thrown when the user has consumed their daily quota for [taskCategory].
class SecurityRateLimitException implements Exception {
  const SecurityRateLimitException(this.taskCategory);
  final AiTaskCategory taskCategory;
  @override
  String toString() =>
      'Limite de seguridad alcanzado para ${taskCategory.displayName}. '
      'El uso de IA se restablecera en 24 horas.';
}

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum AiModelPriority { pro, flash, flashLite }

extension AiModelPriorityX on AiModelPriority {
  String get backendValue {
    switch (this) {
      case AiModelPriority.pro:
        return 'pro';
      case AiModelPriority.flash:
        return 'flash';
      case AiModelPriority.flashLite:
        return 'flash-lite';
    }
  }

  String get displayName {
    switch (this) {
      case AiModelPriority.pro:
        return 'Gemini Pro';
      case AiModelPriority.flash:
        return 'Gemini Flash';
      case AiModelPriority.flashLite:
        return 'Gemini Flash Lite';
    }
  }
}

/// Categories of AI features with their server-side daily limits.
/// The backend enforces these via ai_usage_log. The client uses them
/// for pre-flight UI feedback only — never as a security control.
enum AiTaskCategory {
  biometrics,
  legalContract,
  propertyDesc,
  comfortIndex,
  marketPrice,
  legalGuide,
  notaSimple,
  solvencyCheck,
  priceValidator,
  marketGap,
  neighborhoodTwins,
  urbanGrowth,
  arrasContract,
  aiGenerate,
}

extension AiTaskCategoryX on AiTaskCategory {
  /// Daily call limit per category (mirrors FEATURE_LIMITS in ai_rate_limit.py).
  int get dailyLimit {
    switch (this) {
      case AiTaskCategory.biometrics:
        return 3;
      case AiTaskCategory.legalContract:
        return 3;
      case AiTaskCategory.propertyDesc:
        return 5;
      case AiTaskCategory.comfortIndex:
        return 3;
      case AiTaskCategory.marketPrice:
        return 5;
      case AiTaskCategory.legalGuide:
        return 4;
      case AiTaskCategory.notaSimple:
        return 3;
      case AiTaskCategory.solvencyCheck:
        return 3;
      case AiTaskCategory.priceValidator:
        return 5;
      case AiTaskCategory.marketGap:
        return 3;
      case AiTaskCategory.neighborhoodTwins:
        return 3;
      case AiTaskCategory.urbanGrowth:
        return 3;
      case AiTaskCategory.arrasContract:
        return 2;
      case AiTaskCategory.aiGenerate:
        return 10;
    }
  }

  /// Feature key used as SharedPreferences cache key (matches backend feature name).
  String get featureKey {
    switch (this) {
      case AiTaskCategory.biometrics:
        return 'kyc_biometrics';
      case AiTaskCategory.legalContract:
        return 'arras_contract';
      case AiTaskCategory.propertyDesc:
        return 'property_desc';
      case AiTaskCategory.comfortIndex:
        return 'comfort_index';
      case AiTaskCategory.marketPrice:
        return 'market_price';
      case AiTaskCategory.legalGuide:
        return 'legal_guide';
      case AiTaskCategory.notaSimple:
        return 'nota_simple';
      case AiTaskCategory.solvencyCheck:
        return 'solvency_check';
      case AiTaskCategory.priceValidator:
        return 'price_validator';
      case AiTaskCategory.marketGap:
        return 'market_gap';
      case AiTaskCategory.neighborhoodTwins:
        return 'neighborhood_twins';
      case AiTaskCategory.urbanGrowth:
        return 'urban_growth';
      case AiTaskCategory.arrasContract:
        return 'arras_contract';
      case AiTaskCategory.aiGenerate:
        return 'ai_generate';
    }
  }

  /// Human-readable display name for UI messages.
  String get displayName {
    switch (this) {
      case AiTaskCategory.biometrics:
        return 'Verificacion de identidad';
      case AiTaskCategory.legalContract:
        return 'Contratos Arras';
      case AiTaskCategory.propertyDesc:
        return 'Descripcion de propiedad';
      case AiTaskCategory.comfortIndex:
        return 'Indice de confort';
      case AiTaskCategory.marketPrice:
        return 'Precio de mercado';
      case AiTaskCategory.legalGuide:
        return 'Guia legal';
      case AiTaskCategory.notaSimple:
        return 'Analisis Nota Simple';
      case AiTaskCategory.solvencyCheck:
        return 'Verificacion de solvencia';
      case AiTaskCategory.priceValidator:
        return 'Validador de precio';
      case AiTaskCategory.marketGap:
        return 'Analisis de negociacion';
      case AiTaskCategory.neighborhoodTwins:
        return 'Barrios gemelos';
      case AiTaskCategory.urbanGrowth:
        return 'Crecimiento urbano';
      case AiTaskCategory.arrasContract:
        return 'Contrato de arras';
      case AiTaskCategory.aiGenerate:
        return 'Generacion de contenido';
    }
  }

  /// Deprecated: use [displayName] instead.
  String get name => displayName;
}

/// Global daily limit across all AI features.
/// Must match GLOBAL_DAILY_LIMIT in backend/src/utils/ai_rate_limit.py.
const int kAiGlobalDailyLimit = 20;

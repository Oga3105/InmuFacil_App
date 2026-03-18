/// Shared types for the AI service layer (V41 + V44).
/// Defined in isolation to avoid circular imports between
/// AiService and AiRateLimiterService.

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
      'Limite de seguridad alcanzado para ${taskCategory.name}. '
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

enum AiTaskCategory { biometrics, legalContract, propertyDesc }

extension AiTaskCategoryX on AiTaskCategory {
  int get dailyLimit {
    switch (this) {
      case AiTaskCategory.biometrics:
        return 5;
      case AiTaskCategory.legalContract:
        return 3;
      case AiTaskCategory.propertyDesc:
        return 10;
    }
  }

  String get name {
    switch (this) {
      case AiTaskCategory.biometrics:
        return 'Biometria';
      case AiTaskCategory.legalContract:
        return 'Contratos de Arras';
      case AiTaskCategory.propertyDesc:
        return 'Generacion de Descripcion';
    }
  }
}

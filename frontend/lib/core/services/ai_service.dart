import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'ai_types.dart';
import 'ai_rate_limiter_service.dart';
import '../config/env_config.dart';

export 'ai_types.dart';

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Dio _buildDio() => Dio(
        BaseOptions(
          baseUrl: EnvConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

  // Prioritized list of models to attempt in order
  static const List<AiModelPriority> _defaultPriority = [
    AiModelPriority.pro,
    AiModelPriority.flash,
    AiModelPriority.flashLite,
  ];

  // ---------------------------------------------------------------------------
  // V41 — AI Smart Fallback
  // ---------------------------------------------------------------------------

  /// Generates content with automatic fallback across models.
  /// If the preferred model returns HTTP 429 (Resource Exhausted),
  /// waits 2 seconds then tries the next model in priority order.
  /// The prompt is NEVER written to logs to protect user privacy.
  Future<String> generateContentWithFallback({
    required String prompt,
    required AiTaskCategory taskCategory,
    List<AiModelPriority> modelPriority = _defaultPriority,
  }) async {
    // V44 — Enforce daily rate limit before hitting the network
    await _checkRateLimit(taskCategory);

    Exception? lastError;
    for (int i = 0; i < modelPriority.length; i++) {
      final model = modelPriority[i];
      try {
        final result = await _callModel(prompt, model);
        // Increment local usage counter on success
        await _incrementUsage(taskCategory);
        return result;
      } on DioException catch (e) {
        if (e.response?.statusCode == 429) {
          final nextModelName = i + 1 < modelPriority.length
              ? modelPriority[i + 1].backendValue
              : 'ninguno';
          // Only log model names — NEVER log prompt content (privacy rule)
          // ignore: avoid_print
          print(
            '[AI] Modelo ${model.backendValue} agotado. '
            'Conmutando a $nextModelName.',
          );
          lastError = e;
          if (i + 1 < modelPriority.length) {
            await Future.delayed(const Duration(seconds: 2));
          }
        } else {
          rethrow;
        }
      }
    }
    throw lastError ?? const AiAllModelsExhaustedException();
  }

  Future<String> _callModel(String prompt, AiModelPriority model) async {
    final dio = _buildDio();
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
    final response = await dio.post<Map<String, dynamic>>(
      '/ai/generate',
      data: {
        'prompt': prompt,
        'model_preference': model.backendValue,
      },
    );
    return (response.data?['content'] as String?) ?? '';
  }

  // ---------------------------------------------------------------------------
  // V44 — Rate Limiting (delegates to AiRateLimiterService)
  // ---------------------------------------------------------------------------

  Future<void> _checkRateLimit(AiTaskCategory category) async {
    final count = await AiRateLimiterService.instance.getUsageToday(category);
    if (count >= category.dailyLimit) {
      throw SecurityRateLimitException(category);
    }
  }

  Future<void> _incrementUsage(AiTaskCategory category) async {
    await AiRateLimiterService.instance.increment(category);
  }
}

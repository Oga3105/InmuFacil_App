import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ai_service.dart re-exports ai_types.dart, so all public AI types are available
import 'package:inmufacil_frontend/core/services/ai_service.dart';
import 'package:inmufacil_frontend/core/services/ai_rate_limiter_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiTaskCategory — limits', () {
    test('Property description limit is 10 per day', () {
      expect(AiTaskCategory.propertyDesc.dailyLimit, 10);
    });

    test('Biometrics limit is 5 per day', () {
      expect(AiTaskCategory.biometrics.dailyLimit, 5);
    });

    test('Legal contract limit is 3 per day', () {
      expect(AiTaskCategory.legalContract.dailyLimit, 3);
    });
  });

  group('AiRateLimiterService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AiRateLimiterService.instance.resetAll();
    });

    test('Initial usage is 0 for all categories', () async {
      for (final category in AiTaskCategory.values) {
        final count =
            await AiRateLimiterService.instance.getUsageToday(category);
        expect(count, 0, reason: 'Expected 0 for ${category.name}');
      }
    });

    test('Increment increases counter by 1', () async {
      await AiRateLimiterService.instance
          .increment(AiTaskCategory.propertyDesc);
      final count = await AiRateLimiterService.instance
          .getUsageToday(AiTaskCategory.propertyDesc);
      expect(count, 1);
    });

    test('Multiple increments accumulate correctly', () async {
      for (int i = 0; i < 3; i++) {
        await AiRateLimiterService.instance
            .increment(AiTaskCategory.legalContract);
      }
      final count = await AiRateLimiterService.instance
          .getUsageToday(AiTaskCategory.legalContract);
      expect(count, 3);
    });

    test('getAllUsageToday returns map with all categories', () async {
      await AiRateLimiterService.instance.increment(AiTaskCategory.biometrics);
      final all =
          await AiRateLimiterService.instance.getAllUsageToday();
      expect(all.length, AiTaskCategory.values.length);
      expect(all[AiTaskCategory.biometrics], 1);
      expect(all[AiTaskCategory.propertyDesc], 0);
    });

    test('resetAll clears all counters', () async {
      await AiRateLimiterService.instance.increment(AiTaskCategory.biometrics);
      await AiRateLimiterService.instance.resetAll();
      final count = await AiRateLimiterService.instance
          .getUsageToday(AiTaskCategory.biometrics);
      expect(count, 0);
    });
  });

  group('AiService — model priority', () {
    test('AiModelPriority has exactly 3 models (pro, flash, flash-lite)', () {
      expect(AiModelPriority.values.length, 3);
    });

    test('backendValue returns correct strings', () {
      expect(AiModelPriority.pro.backendValue, 'pro');
      expect(AiModelPriority.flash.backendValue, 'flash');
      expect(AiModelPriority.flashLite.backendValue, 'flash-lite');
    });

    test('displayName returns human-readable strings', () {
      expect(AiModelPriority.pro.displayName, 'Gemini Pro');
      expect(AiModelPriority.flash.displayName, 'Gemini Flash');
      expect(AiModelPriority.flashLite.displayName, 'Gemini Flash Lite');
    });
  });

  group('AiService — rate limit gate', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AiRateLimiterService.instance.resetAll();
    });

    test(
        'SecurityRateLimitException is thrown when daily limit is reached',
        () async {
      // Exhaust the propertyDesc limit (10)
      for (int i = 0; i < AiTaskCategory.propertyDesc.dailyLimit; i++) {
        await AiRateLimiterService.instance
            .increment(AiTaskCategory.propertyDesc);
      }

      // generateContentWithFallback must throw SecurityRateLimitException
      // before hitting any network call
      await expectLater(
        AiService.instance.generateContentWithFallback(
          prompt: 'test prompt',
          taskCategory: AiTaskCategory.propertyDesc,
        ),
        throwsA(isA<SecurityRateLimitException>()),
      );
    });

    test('SecurityRateLimitException message includes category name', () {
      const exc = SecurityRateLimitException(AiTaskCategory.biometrics);
      expect(exc.toString(), contains('Biometria'));
    });

    test('AiAllModelsExhaustedException has descriptive message', () {
      const exc = AiAllModelsExhaustedException();
      expect(exc.toString(), contains('agotados'));
    });
  });
}

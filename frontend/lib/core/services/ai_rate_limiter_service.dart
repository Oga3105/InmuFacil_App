import 'package:shared_preferences/shared_preferences.dart';
import 'ai_types.dart';

/// Rate limiting service for AI requests per user category.
/// Persists counters in SharedPreferences with automatic daily reset.
/// Keys follow the pattern: ai_usage_{categoryName}_{YYYY-MM-DD}
class AiRateLimiterService {
  AiRateLimiterService._();
  static final AiRateLimiterService instance = AiRateLimiterService._();

  String _keyFor(AiTaskCategory category) {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return 'ai_usage_${category.name}_$dateStr';
  }

  /// Returns the number of AI calls made today for [category].
  Future<int> getUsageToday(AiTaskCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyFor(category)) ?? 0;
  }

  /// Increments the usage counter for [category] by 1.
  Future<void> increment(AiTaskCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(category);
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  /// Returns usage counts for all categories today.
  Future<Map<AiTaskCategory, int>> getAllUsageToday() async {
    final result = <AiTaskCategory, int>{};
    for (final category in AiTaskCategory.values) {
      result[category] = await getUsageToday(category);
    }
    return result;
  }

  /// Resets all counters (used in tests or when implementing manual reset).
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final category in AiTaskCategory.values) {
      await prefs.remove(_keyFor(category));
    }
  }
}

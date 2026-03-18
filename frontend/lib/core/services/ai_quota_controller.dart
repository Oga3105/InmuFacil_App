import 'package:shared_preferences/shared_preferences.dart';

/// Alert levels for monthly AI quota consumption.
enum QuotaAlertLevel {
  /// Usage below 80 %.
  normal,

  /// Usage between 80 % and 89 % (inclusive).
  warning,

  /// Usage between 90 % and 99 % (inclusive).
  critical,

  /// Usage at or above 100 %.
  exceeded,
}

/// Controller that tracks and reports monthly AI call quota usage.
///
/// Quota counts are stored in SharedPreferences using the key
/// `ai_monthly_quota_YYYY_MM` where the suffix is the current year/month.
///
/// Default monthly quota: 1 000 calls.
class AiQuotaController {
  AiQuotaController._();

  static final AiQuotaController instance = AiQuotaController._();

  /// Default monthly quota. Change this constant to adjust the global limit.
  static const int monthlyQuota = 1000;

  static const String _keyPrefix = 'ai_monthly_quota_';

  String _currentMonthKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    return '$_keyPrefix${y}_$m';
  }

  /// Returns the number of AI calls made in the current calendar month.
  Future<int> getCurrentUsage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentMonthKey()) ?? 0;
  }

  /// Increments the current month's call count by one.
  Future<void> incrementUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _currentMonthKey();
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  /// Returns the percentage of the monthly quota consumed (0.0 – 100.0+).
  Future<double> getQuotaPercentage() async {
    final usage = await getCurrentUsage();
    return (usage / monthlyQuota) * 100.0;
  }

  /// Returns the alert level based on current quota consumption.
  ///
  /// Thresholds:
  /// - [QuotaAlertLevel.normal]   — below 80 %
  /// - [QuotaAlertLevel.warning]  — 80 % to 89 %
  /// - [QuotaAlertLevel.critical] — 90 % to 99 %
  /// - [QuotaAlertLevel.exceeded] — 100 % or more
  Future<QuotaAlertLevel> getAlertLevel() async {
    final percentage = await getQuotaPercentage();
    if (percentage >= 100.0) {
      return QuotaAlertLevel.exceeded;
    } else if (percentage >= 90.0) {
      return QuotaAlertLevel.critical;
    } else if (percentage >= 80.0) {
      return QuotaAlertLevel.warning;
    }
    return QuotaAlertLevel.normal;
  }

  /// Resets the current month's call count to zero.
  ///
  /// Intended for manual or scheduled (cron) monthly resets.
  Future<void> resetMonthlyQuota() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentMonthKey(), 0);
  }
}

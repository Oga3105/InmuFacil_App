import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Log entry for a single AI call.
class AiCallLog {
  const AiCallLog({
    required this.timestamp,
    required this.feature,
    required this.latencyMs,
    required this.success,
  });

  factory AiCallLog.fromJson(Map<String, dynamic> json) {
    return AiCallLog(
      timestamp: DateTime.parse(json['timestamp'] as String),
      feature: json['feature'] as String,
      latencyMs: json['latency_ms'] as int,
      success: json['success'] as bool,
    );
  }

  final DateTime timestamp;
  final String feature;
  final int latencyMs;
  final bool success;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'feature': feature,
        'latency_ms': latencyMs,
        'success': success,
      };
}

/// Service for recording and querying AI usage metrics.
///
/// Logs are persisted in SharedPreferences under the key
/// `ai_call_logs_YYYY_MM_DD` (one list per day).
class AiMetricsService {
  AiMetricsService._();

  static final AiMetricsService instance = AiMetricsService._();

  static const String _keyPrefix = 'ai_call_logs_';

  String _keyForDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$_keyPrefix${y}_${m}_$d';
  }

  /// Record a single AI call.
  Future<void> recordCall({
    required String feature,
    required int latencyMs,
    required bool success,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForDate(DateTime.now());
    final existing = prefs.getStringList(key) ?? [];
    final log = AiCallLog(
      timestamp: DateTime.now(),
      feature: feature,
      latencyMs: latencyMs,
      success: success,
    );
    existing.add(jsonEncode(log.toJson()));
    await prefs.setStringList(key, existing);
  }

  /// Return all logs for a specific date.
  Future<List<AiCallLog>> getLogsForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForDate(date);
    final raw = prefs.getStringList(key) ?? [];
    return raw.map((e) => AiCallLog.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
  }

  /// Return all logs from the past [days] days (including today).
  Future<List<AiCallLog>> getLogsForLastDays(int days) async {
    final now = DateTime.now();
    final allLogs = <AiCallLog>[];
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dayLogs = await getLogsForDate(date);
      allLogs.addAll(dayLogs);
    }
    return allLogs;
  }
}

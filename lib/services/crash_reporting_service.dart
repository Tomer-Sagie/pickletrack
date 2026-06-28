import 'dart:convert';

import '../database/database.dart';

/// Lightweight local crash reporting.
///
/// Stores the last 20 crashes as a JSON blob in `app_settings` under
/// the key `crash_log_v1`. This avoids a schema migration; the service
/// gracefully degrades if the DB is unavailable.
class CrashReportingService {
  CrashReportingService._();
  static final CrashReportingService _instance = CrashReportingService._();
  static CrashReportingService get instance => _instance;

  static const _key = 'crash_log_v1';
  static const _maxLogs = 20;

  /// Report a caught exception to the local crash log.
  ///
  /// [context] is a short string like 'main', 'scoring', 'db', etc.
  /// [error] and [stackTrace] are the caught values.
  Future<void> report({
    required AppDatabase db,
    required String context,
    required Object error,
    StackTrace? stackTrace,
  }) async {
    try {
      final logs = await _loadLogs(db);
      logs.add({
        'timestamp': DateTime.now().toIso8601String(),
        'context': context,
        'error': error.toString(),
        'stack': stackTrace?.toString(),
      });
      while (logs.length > _maxLogs) {
        logs.removeAt(0);
      }
      await db.setSetting(_key, jsonEncode(logs));
    } catch (_) {
      // If crash reporting itself fails, swallow silently —
      // we must not crash while reporting a crash.
    }
  }

  /// Return all stored crash logs, newest first.
  Future<List<Map<String, dynamic>>> getLogs(AppDatabase db) async {
    try {
      final logs = await _loadLogs(db);
      return List<Map<String, dynamic>>.from(logs.reversed);
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadLogs(AppDatabase db) async {
    final raw = await db.getSetting(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Clear all stored crash logs.
  Future<void> clearLogs(AppDatabase db) async {
    try {
      await db.setSetting(_key, '[]');
    } catch (_) {}
  }
}

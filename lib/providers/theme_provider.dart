import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';

/// Stores and retrieves the user's theme preference.
///
/// Implemented as an [AsyncNotifier] (rather than a synchronous [Notifier])
/// so that the initial DB read is awaited before the value is exposed to
/// the tree. [PickleTrackApp] is gated on this provider's `.when(...)` and
/// renders only once the AsyncValue is `data` — preventing the cold-start
/// flash where the user briefly sees the system theme before the stored
/// preference applies once the DB resolves.
final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final db = ref.read(databaseProvider);
    final raw = await db.getSetting('theme_mode');
    return _parseMode(raw);
  }

  /// Persist a new theme mode to the DB and reflect it in the provider
  /// state immediately so the UI re-evaluates without waiting on a
  /// re-round-trip to the database.
  Future<void> setMode(ThemeMode mode) async {
    state = AsyncValue.data(mode);
    final db = ref.read(databaseProvider);
    await db.setSetting('theme_mode', mode.name);
  }

  ThemeMode _parseMode(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

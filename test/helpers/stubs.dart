import 'package:drift/native.dart';
import 'package:flutter/material.dart' show ThemeMode;

import 'package:pickletrack/database/database.dart';
import 'package:pickletrack/providers/theme_provider.dart';

/// Stubbed [ThemeModeNotifier] used by widget tests so the
/// `AsyncNotifier` doesn't perform a real database read on
/// `theme_mode` during test setup. Without this override, test
/// ordering could leak a previously-written `theme_mode` value from
/// the real DB into the `AsyncValue` resolved for the next test.
///
/// Must extend [ThemeModeNotifier] (not [AsyncNotifier]) so
/// `themeModeProvider.overrideWith(StubThemeModeNotifier.new)`
/// type-checks — Riverpod requires the override factory to return
/// the same Notifier subtype that the provider was declared with.
///
/// Usage:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     themeModeProvider.overrideWith(StubThemeModeNotifier.new),
///   ],
///   child: const MaterialApp(home: HomeScreen()),
/// )
/// ```
class StubThemeModeNotifier extends ThemeModeNotifier {
  @override
  Future<ThemeMode> build() async => ThemeMode.system;

  // setMode is a no-op in tests.
  @override
  Future<void> setMode(ThemeMode mode) async {}
}

/// Constructs a fresh in-memory [AppDatabase] for widget tests so the
/// production-side `openDatabaseConnection` factory is never invoked.
///
/// Each call returns a brand-new in-memory Drift instance, so call
/// once per test scope and close it at tear-down:
///
/// ```dart
/// final db = createInMemoryDatabase();
/// addTearDown(() async => db.close());
///
/// ProviderScope(
///   overrides: [
///     databaseProvider.overrideWithValue(db),
///     themeModeProvider.overrideWith(StubThemeModeNotifier.new),
///   ],
///   child: const MaterialApp(home: HomeScreen()),
/// );
/// ```
///
/// Why override at all: the production `databaseProvider` builds a
/// real [AppDatabase] connected to the platform SQLite file every
/// time a `ProviderScope` is constructed. Drift surfaces the
/// repeated instantiations as the
/// `"AppDatabase instantiated multiple times"` warning on every
/// full-suite test run. Always route widget tests through an in-memory
/// instance instead.
AppDatabase createInMemoryDatabase() =>
    AppDatabase.forTesting(NativeDatabase.memory());

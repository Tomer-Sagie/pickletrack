import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pickletrack/database/database.dart';
import 'package:pickletrack/providers/database_provider.dart';
import 'package:pickletrack/providers/theme_provider.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ThemeModeNotifier', () {
    test(
      'first emission is AsyncValue.loading before the DB read completes',
      () async {
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)],
        );
        addTearDown(container.dispose);

        // Subscribe immediately so we can inspect the loading tick before
        // awaiting build(). Awaiting `read(future)` would jump straight
        // past it to the resolved value — which we also assert below.
        final sub = container.listen<AsyncValue<ThemeMode>>(
          themeModeProvider,
          (_, __) {},
          fireImmediately: true,
        );
        expect(sub.read(), isA<AsyncLoading<ThemeMode>>());

        final resolved = await container.read(themeModeProvider.future);
        expect(resolved, ThemeMode.system);
      },
    );

    test('resolves to ThemeMode.system when no theme_mode setting exists',
        () async {
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(themeModeProvider.future),
        ThemeMode.system,
      );
    });

    test('resolves to ThemeMode.dark when seeded with "dark"', () async {
      await db.setSetting('theme_mode', 'dark');
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(themeModeProvider.future),
        ThemeMode.dark,
      );
    });

    test('resolves to ThemeMode.light when seeded with "light"', () async {
      await db.setSetting('theme_mode', 'light');
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(themeModeProvider.future),
        ThemeMode.light,
      );
    });

    test('setMode writes the new value through to the DB', () async {
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      // Trigger build() so the notifier is wired to the DB.
      await container.read(themeModeProvider.future);

      await container
          .read(themeModeProvider.notifier)
          .setMode(ThemeMode.dark);

      // DB-level round-trip: the new value is now persisted.
      expect(await db.getSetting('theme_mode'), 'dark');

      // Provider state reflects the new value without waiting on another
      // read() — setMode assigns AsyncValue.data synchronously.
      expect(
        container.read(themeModeProvider).valueOrNull,
        ThemeMode.dark,
      );
    });

    test('multiple setMode calls round-trip the latest through to the DB',
        () async {
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      await container.read(themeModeProvider.future);

      final notifier = container.read(themeModeProvider.notifier);
      await notifier.setMode(ThemeMode.light);
      expect(await db.getSetting('theme_mode'), 'light');

      await notifier.setMode(ThemeMode.dark);
      expect(await db.getSetting('theme_mode'), 'dark');

      await notifier.setMode(ThemeMode.system);
      expect(await db.getSetting('theme_mode'), 'system');
    });
  });
}

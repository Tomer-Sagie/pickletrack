import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pickletrack/models/scoring_preset.dart';
import 'package:pickletrack/providers/database_provider.dart';
import 'package:pickletrack/providers/settings_provider.dart';
import 'package:pickletrack/providers/theme_provider.dart';
import 'package:pickletrack/screens/settings/settings_screen.dart';

import 'helpers/stubs.dart';

/// Sets a tall enough viewport for the entire Settings screen.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Pumps SettingsScreen with an in-memory DB and all defaults pinned
/// to concrete sync values so the loaders don't show a spinner.
Future<void> pumpSettings(
  WidgetTester tester, {
  ScoringPreset? preset,
  String? scoringRule,
  int? gameCount,
}) async {
  _useTallViewport(tester);
  final db = createInMemoryDatabase();
  addTearDown(() async => db.close());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        themeModeProvider.overrideWith(StubThemeModeNotifier.new),
        defaultScoringRuleProvider
            .overrideWith((_) => Future.value(scoringRule ?? 'sideout')),
        defaultGameCountProvider
            .overrideWith((_) => Future.value(gameCount ?? 1)),
        defaultScoringPresetProvider
            .overrideWith((_) => Future.value(preset ?? ScoringPreset.standard)),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Phase 6 — destructive tile icon', () {
    testWidgets(
      'Clear all data tile shows warning_amber_rounded instead of chevron',
      (tester) async {
        await pumpSettings(tester);

        // Inspect the ListTile by its unique label.
        final tileFinder =
            find.widgetWithText(ListTile, 'Clear all data');
        expect(tileFinder, findsOneWidget);

        final tile = tester.widget<ListTile>(tileFinder);
        expect(tile.trailing, isA<Icon>());

        final trailingIcon = tile.trailing as Icon;
        expect(trailingIcon.icon, Icons.warning_amber_rounded);
        expect(trailingIcon.color, Theme.of(tester.element(tileFinder))
            .colorScheme
            .error);
      },
    );

    testWidgets(
      'other Data tiles still use chevron_right unchanged',
      (tester) async {
        await pumpSettings(tester);

        // Chevron survives on the two non-destructive tiles we kept:
        // Clear Recent Players + Export All Data.
        expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
      },
    );
  });

  group('Phase 6 — picker opens as bottom sheet', () {
    testWidgets(
      'tapping Scoring rule tile opens a bottom sheet (not a SimpleDialog)',
      (tester) async {
        await pumpSettings(tester);

        await tester.tap(find.text('Scoring rule'));
        await tester.pumpAndSettle();

        // Sentinel unique to the picker: the Cancel tooltip on the
        // close icon button (dialogs in this screen have no Cancel
        // button).
        expect(find.byTooltip('Cancel'), findsOneWidget);
        expect(find.text('Default scoring rule'), findsOneWidget);
        // Confirm no legacy dialog is mounted.
        expect(find.byType(SimpleDialog), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'tapping a radio in the Scoring rule sheet closes it',
      (tester) async {
        await pumpSettings(tester);

        await tester.tap(find.text('Scoring rule'));
        await tester.pumpAndSettle();

        // Tap "Rally" inside the bottom sheet.
        await tester.tap(find.text('Rally'));
        await tester.pumpAndSettle();

        // Sheet should close and the tile should show the new value.
        expect(find.byTooltip('Cancel'), findsNothing);
        expect(find.text('Default scoring rule'), findsNothing);
      },
    );

    testWidgets(
      'tapping Games tile opens a bottom sheet for game-count picker',
      (tester) async {
        await pumpSettings(tester);

        await tester.tap(find.text('Games'));
        await tester.pumpAndSettle();

        expect(find.text('Default games'), findsOneWidget);
        expect(find.byType(SimpleDialog), findsNothing);
      },
    );

    testWidgets(
      'tapping Win Condition tile opens a bottom sheet',
      (tester) async {
        await pumpSettings(tester);

        await tester.tap(find.text('Win Condition'));
        await tester.pumpAndSettle();

        expect(find.text('Default win condition'), findsOneWidget);
        expect(find.byType(SimpleDialog), findsNothing);
      },
    );
  });

  group('Phase 6 — Custom preset informational tile in picker', () {
    testWidgets(
      'sheet renders four options, with Custom informational tile disabled when default is Custom',
      (tester) async {
        await pumpSettings(
          tester,
          preset: ScoringPreset.custom(playTo: 13, winBy: 2),
        );

        // Win Condition tile shows its label.
        await tester.tap(find.text('Win Condition'));
        await tester.pumpAndSettle();

        // Informational Custom tile present, with live values in subtitle.
        expect(find.text('Custom (set via Setup)'), findsOneWidget);
        // The exact subtitle "13, win by 2" appears only in the sheet
        // (the tile trailing reads "Custom (13, win by 2)" — different
        // exact text) so findsOneWidget is unambiguous here.
        expect(find.text('13, win by 2'), findsOneWidget);

        // Verify the corresponding RadioListTile has onChanged: null.
        final customOptionFinder = find.widgetWithText(
          RadioListTile<ScoringPreset>,
          'Custom (set via Setup)',
        );
        expect(customOptionFinder, findsOneWidget);
        final customOption =
            tester.widget<RadioListTile<ScoringPreset>>(customOptionFinder);
        expect(customOption.onChanged, isNull);
      },
    );

    testWidgets(
      'tapping the disabled Custom tile does not close the sheet',
      (tester) async {
        await pumpSettings(
          tester,
          preset: ScoringPreset.custom(playTo: 13, winBy: 2),
        );

        await tester.tap(find.text('Win Condition'));
        await tester.pumpAndSettle();

        final customOptionFinder = find.widgetWithText(
          RadioListTile<ScoringPreset>,
          'Custom (set via Setup)',
        );
        // Tap on the tile label itself — without a custom onChanged the
        // tile stays selected and the picker remains open.
        await tester.tap(customOptionFinder);
        await tester.pumpAndSettle();

        // Sheet is still open.
        expect(find.text('Default win condition'), findsOneWidget);
        expect(find.byTooltip('Cancel'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping a built-in preset closes the sheet',
      (tester) async {
        await pumpSettings(
          tester,
          preset: ScoringPreset.custom(playTo: 13, winBy: 2),
        );

        await tester.tap(find.text('Win Condition'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Standard (11, win by 2)'));
        await tester.pumpAndSettle();

        expect(find.text('Default win condition'), findsNothing);
      },
    );

    testWidgets(
      'when default is Standard (built-in), no Custom informational tile shows',
      (tester) async {
        await pumpSettings(tester, preset: ScoringPreset.standard);

        await tester.tap(find.text('Win Condition'));
        await tester.pumpAndSettle();

        expect(find.text('Default win condition'), findsOneWidget);
        // Only the three built-in presets in the menu. Note: find at
        // least one widget because the tile's trailing ALSO renders each
        // label (e.g. "Standard (11, win by 2)") — so the same text
        // appears in both the tile trailing and the menu item.
        expect(find.text('Custom (set via Setup)'), findsNothing);
        expect(find.text('Quick (7, win by 2)'), findsAtLeastNWidgets(1));
        expect(find.text('Standard (11, win by 2)'), findsAtLeastNWidgets(1));
        expect(find.text('Tournament (15, win by 2)'), findsAtLeastNWidgets(1));
      },
    );
  });
}

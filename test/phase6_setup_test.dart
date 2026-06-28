import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pickletrack/models/scoring_preset.dart';
import 'package:pickletrack/providers/database_provider.dart';
import 'package:pickletrack/providers/theme_provider.dart';
import 'package:pickletrack/screens/setup/setup_screen.dart';

import 'helpers/stubs.dart';

/// Sets a tall enough test viewport so the full setup form fits without
/// overflowing — the dropdown menu and Custom row would otherwise render
/// off-screen on a default 800x600 test viewport.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Pumps the SetupScreen with an empty in-memory database and a stubbed
/// theme notifier. Uses pump() (not pumpAndSettle) because the player
/// autocomplete debounce timer may prevent settling.
Future<void> pumpSetupWidget(WidgetTester tester) async {
  _useTallViewport(tester);
  final db = createInMemoryDatabase();
  addTearDown(() async => db.close());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        themeModeProvider.overrideWith(StubThemeModeNotifier.new),
      ],
      child: const MaterialApp(home: SetupScreen()),
    ),
  );
  // Two pumps: one to render, one to clear the autocomplete debounce
  // timer started by _PlayerNameField.initState so it doesn't fire
  // mid-test.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Opens the Win Condition dropdown. The closed-state button label
/// varies depending on the currently selected preset — always call
/// this AFTER pump.
Future<void> _openWinConditionDropdown(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<ScoringPreset>));
  await tester.pumpAndSettle();
}

void main() {
  group('Phase 6 — Win Condition dropdown', () {
    testWidgets(
      'initially shows Standard preset in the dropdown button',
      (tester) async {
        await pumpSetupWidget(tester);
        expect(find.text('Standard (11, win by 2)'), findsOneWidget);
      },
    );

    testWidgets(
      'picking Custom shows the live label with defaults and reveals the custom fields',
      (tester) async {
        await pumpSetupWidget(tester);

        await _openWinConditionDropdown(tester);

        // The Custom menu item is synthesized from empty text fields
        // (default → 11/2). Tapping it activates the Custom row.
        await tester.tap(find.text('Custom (11, win by 2)'));
        await tester.pumpAndSettle();

        // Closed dropdown now shows the live Custom label.
        expect(find.text('Custom (11, win by 2)'), findsOneWidget);
        // Custom text fields appear only when _isCustomPreset.
        expect(find.text('Play to'), findsOneWidget);
        expect(find.text('Win by'), findsOneWidget);
      },
    );

    testWidgets(
      'typing in the Custom Play-to field refreshes the dropdown label live',
      (tester) async {
        await pumpSetupWidget(tester);

        // Activate Custom.
        await _openWinConditionDropdown(tester);
        await tester.tap(find.text('Custom (11, win by 2)'));
        await tester.pumpAndSettle();

        // Find the Play-to TextFormField by its labelText descendant.
        final playToField = find.widgetWithText(TextFormField, 'Play to');
        expect(playToField, findsOneWidget);
        await tester.enterText(playToField, '13');
        await tester.pumpAndSettle();

        // Closed-state dropdown must reflect the new value in the same
        // rebuild — guards against the value/label desync the
        // onChanged-without-setState bug would cause.
        expect(find.text('Custom (13, win by 2)'), findsOneWidget);
        expect(find.text('Custom (11, win by 2)'), findsNothing);
      },
    );

    testWidgets(
      'typing in the Custom Win-by field refreshes the dropdown label live',
      (tester) async {
        await pumpSetupWidget(tester);

        await _openWinConditionDropdown(tester);
        await tester.tap(find.text('Custom (11, win by 2)'));
        await tester.pumpAndSettle();

        final winByField = find.widgetWithText(TextFormField, 'Win by');
        await tester.enterText(winByField, '3');
        await tester.pumpAndSettle();

        expect(find.text('Custom (11, win by 3)'), findsOneWidget);
        expect(find.text('Custom (11, win by 2)'), findsNothing);
      },
    );

    testWidgets(
      'typing both Custom fields together updates the synthesized label',
      (tester) async {
        await pumpSetupWidget(tester);

        await _openWinConditionDropdown(tester);
        await tester.tap(find.text('Custom (11, win by 2)'));
        await tester.pumpAndSettle();

        final playTo = find.widgetWithText(TextFormField, 'Play to');
        final winBy = find.widgetWithText(TextFormField, 'Win by');
        await tester.enterText(playTo, '15');
        await tester.enterText(winBy, '3');
        await tester.pumpAndSettle();

        expect(find.text('Custom (15, win by 3)'), findsOneWidget);
      },
    );

    testWidgets(
      'switching back to a built-in preset dismisses the Custom row',
      (tester) async {
        await pumpSetupWidget(tester);

        // Activate Custom.
        await _openWinConditionDropdown(tester);
        await tester.tap(find.text('Custom (11, win by 2)'));
        await tester.pumpAndSettle();
        expect(find.text('Play to'), findsOneWidget);

        // Open dropdown again and pick Standard.
        await _openWinConditionDropdown(tester);
        // After the menu opens, the closed-state button still reads
        // "Custom (11, win by 2)" — but the menu items include
        // "Standard (11, win by 2)" exactly once. Targeting by exact
        // ancestor makes sure we hit the menu item rather than the
        // button behind it.
        final standardItem = find.descendant(
          of: find.byType(DropdownMenuItem<ScoringPreset>),
          matching: find.text('Standard (11, win by 2)'),
        );
        await tester.tap(standardItem);
        await tester.pumpAndSettle();

        // Custom row is gone; closed dropdown shows Standard again.
        expect(find.text('Play to'), findsNothing);
        expect(find.text('Win by'), findsNothing);
        expect(find.text('Standard (11, win by 2)'), findsOneWidget);
      },
    );
  });
}

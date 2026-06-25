import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pickletrack/providers/database_provider.dart';
import 'package:pickletrack/providers/theme_provider.dart';
import 'package:pickletrack/screens/setup/setup_screen.dart';

import 'helpers/stubs.dart';

/// Sets a test viewport tall enough for the setup form and registers
/// tear-down to restore defaults.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Pumps the SetupScreen inside a ProviderScope with a tall enough
/// viewport.  Uses pump() instead of pumpAndSettle() because
/// SegmentedButton / DropdownButtonFormField use internal animations
/// that may prevent settling.
Future<void> pumpSetupScreen(
  WidgetTester tester, {
  bool quickStart = false,
}) async {
  _useTallViewport(tester);

  // Use an in-memory Drift DB so the production AppDatabase factory
  // is never opened during tests.
  final db = createInMemoryDatabase();
  addTearDown(() async => db.close());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        // Stub out the theme provider so its AsyncNotifier doesn't
        // touch the real DB during test setup — keeps test ordering
        // hermetic against any persisted theme_mode value.
        themeModeProvider.overrideWith(StubThemeModeNotifier.new),
      ],
      child: MaterialApp(home: SetupScreen(quickStart: quickStart)),
    ),
  );
  // One pump processes initState + build. Form controls are rendered.
  await tester.pump();
}

void main() {
  group('SetupScreen', () {
    testWidgets('shows New Match title in AppBar', (tester) async {
      await pumpSetupScreen(tester);
      expect(find.text('New Match'), findsOneWidget);
    });

    testWidgets('shows Match Type section with Singles and Doubles', (tester) async {
      await pumpSetupScreen(tester);

      expect(find.text('Match Type'), findsOneWidget);
      expect(find.text('Singles'), findsOneWidget);
      expect(find.text('Doubles'), findsOneWidget);
    });

    testWidgets('shows Team A and Team B player name fields', (tester) async {
      await pumpSetupScreen(tester);

      expect(find.text('Team A'), findsOneWidget);
      expect(find.text('Team B'), findsOneWidget);
      // Hint texts for doubles: Player A1, Player B1
      expect(find.text('Player A1'), findsOneWidget);
      expect(find.text('Player B1'), findsOneWidget);
    });

    testWidgets('shows Scoring Rule selector', (tester) async {
      await pumpSetupScreen(tester);

      expect(find.text('Scoring Rule'), findsOneWidget);
      expect(find.text('Side-Out'), findsOneWidget);
      expect(find.text('Rally'), findsOneWidget);
    });

    testWidgets('shows Games selector with 1 Game and Best of 3', (tester) async {
      await pumpSetupScreen(tester);

      expect(find.text('Games'), findsOneWidget);
      expect(find.text('1 Game'), findsOneWidget);
      expect(find.text('Best of 3'), findsOneWidget);
    });

    testWidgets('shows Win Condition dropdown with presets', (tester) async {
      await pumpSetupScreen(tester);

      expect(find.text('Win Condition'), findsOneWidget);
      // Standard preset should be displayed initially.
      expect(find.textContaining('Standard'), findsOneWidget);
    });

    testWidgets('shows Start Match button', (tester) async {
      await pumpSetupScreen(tester);

      expect(find.text('Start Match'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('hides starting server when no names entered', (tester) async {
      await pumpSetupScreen(tester);

      // Starting Server section is hidden when all names are empty.
      expect(find.text('Starting Server'), findsNothing);
    });

    testWidgets('Standard Start (quickStart=true) pre-fills player names', (tester) async {
      await pumpSetupScreen(tester, quickStart: true);

      // The internal quickStart flag seeds default names so the
      // Starting Server section renders immediately.
      expect(find.text('Starting Server'), findsOneWidget);
      // Four player fields for doubles.
      expect(find.byType(TextFormField), findsNWidgets(4));
    });

    testWidgets('switching to singles hides two player fields', (tester) async {
      await pumpSetupScreen(tester);

      // Tap Singles to switch match type.
      await tester.tap(find.text('Singles'));
      await tester.pump();

      // Singles mode: 2 player fields instead of 4.
      expect(find.byType(TextFormField), findsNWidgets(2));
      // Doubles-only hint texts should be gone.
      expect(find.text('Player A2'), findsNothing);
    });
  });
}

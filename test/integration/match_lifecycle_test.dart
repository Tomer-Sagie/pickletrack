import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pickletrack/database/database.dart';
import 'package:pickletrack/providers/database_provider.dart';
import 'package:pickletrack/providers/theme_provider.dart';
import 'package:pickletrack/router.dart';
import 'package:pickletrack/screens/details/match_details_screen.dart';
import 'package:pickletrack/screens/home/home_screen.dart';
import 'package:pickletrack/screens/home/resume_banner.dart';
import 'package:pickletrack/screens/live/live_match_screen.dart';
import 'package:pickletrack/screens/setup/setup_screen.dart';

import '../helpers/stubs.dart';

// Goldens are inherently cross-platform-unstable (Windows-captured PNGs
// fail on Ubuntu CI due to font/antialiasing differences) — see
// `test/live_match_screen_golden_test.dart` for the skip-on-CI fix.
//
// The Match Details Home IconButton wraps itself in a Tooltip at build
// time, so `find.byTooltip('Home')` matches the Tooltip element — and
// `find.descendant(of: tooltip, matching: IconButton)` matches nothing
// because the IconButton is the Tooltip's *ancestor*, not descendant.
// Use `find.ancestor(of: tooltip, matching: IconButton)` to find the
// IconButton whose render box sits inside the AppBar hit-test region.

void main() {
  group('Full Match Lifecycle Integration', () {
    late AppDatabase db;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    /// Pumps a fresh app with an in-memory database and a clean router.
    Future<void> pumpApp(WidgetTester tester) async {
      db = createInMemoryDatabase();
      addTearDown(() async => db.close());

      await db.setSetting('has_seen_onboarding', 'true');
      await db.setSetting('has_seen_tutorial', 'true');

      // AppBar trailing actions (Home + Share) need >1080px slack in
      // the test canvas; widen to 1200×2400 so the IconButton centres
      // sit inside the hit-test region rather than 5px past the edge.
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            themeModeProvider.overrideWith(StubThemeModeNotifier.new),
          ],
          child: MaterialApp.router(
            theme: ThemeData.light(),
            routerConfig: createRouter(),
          ),
        ),
      );

      // Wait for the first frame + any microtask futures to settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    /// Polls with short pumps until [finder] matches at least one widget
    /// or [timeout] elapses.
    Future<void> pumpUntilFound(
      WidgetTester tester,
      Finder finder, {
      Duration timeout = const Duration(seconds: 5),
    }) async {
      final stopwatch = Stopwatch()..start();
      while (stopwatch.elapsed < timeout) {
        await tester.pump(const Duration(milliseconds: 100));
        if (finder.evaluate().isNotEmpty) return;
      }
      fail('Timed out waiting for $finder');
    }

    testWidgets(
      'New Match: setup -> live scoring -> end match -> view details -> home',
      (tester) async {
        await pumpApp(tester);

        // -- Home Screen --
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('PickleTrack'), findsOneWidget);

        // Tap the "New Match" action card (identified by its unique icon).
        await tester.tap(find.byIcon(Icons.edit_note_rounded));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 200));

        // -- Setup Screen --
        expect(find.byType(SetupScreen), findsOneWidget);

        // Fill in player names (4 fields for doubles default).
        final nameFields = find.byType(TextFormField);
        expect(nameFields, findsNWidgets(4));

        await tester.enterText(nameFields.at(0), 'Alice');
        await tester.enterText(nameFields.at(1), 'Bob');
        await tester.enterText(nameFields.at(2), 'Carol');
        await tester.enterText(nameFields.at(3), 'Dave');

        // Wait for the 200 ms autocomplete debounce and the Starting Server
        // section to appear (it rebuilds when names are non-empty).
        await tester.pump(const Duration(milliseconds: 300));

        // Select Alice as the starting server.
        await tester.tap(find.widgetWithText(ChoiceChip, 'Alice'));
        await tester.pump(const Duration(milliseconds: 200));

        // Tap Start Match -> navigates to /match/live.
        await tester.tap(find.text('Start Match'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 300));

        // -- Live Match Screen --
        expect(find.byType(LiveMatchScreen), findsOneWidget);
        // Use pumpUntilFound because LiveMatchScreen starts in _loading=true
        // and loads match data asynchronously.
        await pumpUntilFound(tester, find.text('Alice serving'));

        // Score a few points (600 ms between taps -> clears the 500 ms
        // score-button debounce).
        await tester.tap(find.widgetWithText(FilledButton, 'Alice & Bob'));
        await tester.pump(const Duration(milliseconds: 600));

        await tester.tap(find.widgetWithText(FilledButton, 'Carol & Dave'));
        await tester.pump(const Duration(milliseconds: 600));

        await tester.tap(find.widgetWithText(FilledButton, 'Alice & Bob'));
        await tester.pump(const Duration(milliseconds: 600));

        // Tap End Match -> confirmation dialog.
        await tester.tap(find.text('End'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        // Confirm the "End Match" destructive action in the dialog.
        await tester.tap(find.widgetWithText(FilledButton, 'End Match'));
        await pumpUntilFound(tester, find.byType(MatchDetailsScreen));

        // -- Match Details Screen --
        expect(find.byType(MatchDetailsScreen), findsOneWidget);
        expect(find.text('Match Details'), findsOneWidget);

        // Winner banner. The match was ended after only 3 points (2-1),
        // so no game was won. endMatch() falls back to winner='B' when
        // teamAGamesWon == teamBGamesWon == 0.
        expect(find.text('Team B Wins!'), findsOneWidget);

        // Player names rendered in the details.
        expect(find.text('Alice'), findsAtLeastNWidgets(1));
        expect(find.text('Carol'), findsAtLeastNWidgets(1));

        // Match info cards.
        expect(find.text('Type'), findsOneWidget);
        expect(find.text('Doubles'), findsOneWidget);
        expect(find.text('Scoring'), findsOneWidget);
        expect(find.text('Side-Out'), findsOneWidget);

        // Score section.
        expect(find.text('Game Scores'), findsOneWidget);

        // Navigate back to Home.
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await pumpUntilFound(tester, find.byType(HomeScreen));

        // -- Home Screen --
        // Match history is now on the separate History tab;
        // verify we're back on Quick Play (hero header visible).
        await pumpUntilFound(tester, find.text('PickleTrack'));
        expect(find.byType(HomeScreen), findsOneWidget);

        // The completed match card should reference the players.
        expect(find.textContaining('Alice'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Carol'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'Standard Start: quick start -> live scoring -> end -> view details',
      (tester) async {
        await pumpApp(tester);

        // -- Home Screen --
        expect(find.byType(HomeScreen), findsOneWidget);

        // Tap the "Quick Start" action card.
        await tester.tap(find.text('Quick Start'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 200));

        // Bottom sheet appears with quick-start summary.
        expect(find.text('Quick Start'), findsAtLeastNWidgets(1));
        // The bottom sheet has a FilledButton.icon with label "Start Match".
        expect(find.text('Start Match'), findsOneWidget);

        // Tap "Start Match" in the bottom sheet.
        await tester.tap(find.text('Start Match'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 300));

        // -- Live Match Screen --
        expect(find.byType(LiveMatchScreen), findsOneWidget);
        // Use pumpUntilFound because LiveMatchScreen loads asynchronously.
        await pumpUntilFound(tester, find.text('Player A1 serving'));

        // Score points.
        await tester.tap(find.widgetWithText(FilledButton, 'Player A1 & Player A2'));
        await tester.pump(const Duration(milliseconds: 600));

        await tester.tap(find.widgetWithText(FilledButton, 'Player A1 & Player A2'));
        await tester.pump(const Duration(milliseconds: 600));

        await tester.tap(find.widgetWithText(FilledButton, 'Player B1 & Player B2'));
        await tester.pump(const Duration(milliseconds: 600));

        // End match via the bottom-bar button.
        await tester.tap(find.text('End'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.widgetWithText(FilledButton, 'End Match'));
        await pumpUntilFound(tester, find.byType(MatchDetailsScreen));

        // -- Match Details Screen --
        expect(find.byType(MatchDetailsScreen), findsOneWidget);
        expect(find.text('Match Details'), findsOneWidget);

        // Default player names should appear in the details.
        expect(find.text('Player A1'), findsAtLeastNWidgets(1));
        expect(find.text('Player B1'), findsAtLeastNWidgets(1));

        // The IconButton is the ANCESTOR of the tooltip widget (built at
        // IconButton build-time wraps with a Tooltip(message: 'Home')).
        // Walking up from the tooltip to find the IconButton gives a
        // tappable whose render box sits inside the AppBar hit-test
        // region — unlike the tooltip surrogate which extends past it.
        await tester.tap(
          find.ancestor(
            of: find.byTooltip('Home'),
            matching: find.byType(IconButton),
          ),
        );
        await pumpUntilFound(tester, find.byType(HomeScreen));

        // -- Home Screen --
        // Match history is now on the separate History tab;
        // verify we're back on Quick Play.
        await pumpUntilFound(tester, find.text('PickleTrack'));
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Resume banner appears for an active match and tapping it opens Live Match',
      (tester) async {
        // Create an active match in the DB BEFORE pumping the app so the
        // resume banner is visible on the initial home-screen load.
        final resumeDb = createInMemoryDatabase();
        addTearDown(() async => resumeDb.close());
        await resumeDb.setSetting('has_seen_onboarding', 'true');
        await resumeDb.setSetting('has_seen_tutorial', 'true');
        await resumeDb.createMatch(
          type: 'singles',
          scoringRule: 'sideout',
          gameCount: 1,
          playTo: 11,
          winBy: 2,
          players: [
            (name: 'Zara', team: 'A', isStartingServer: true, position: null),
            (name: 'Yusef', team: 'B', isStartingServer: false, position: null),
          ],
        );

        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(resumeDb),
              themeModeProvider.overrideWith(StubThemeModeNotifier.new),
            ],
            child: MaterialApp.router(
              theme: ThemeData.light(),
              routerConfig: createRouter(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // -- Home Screen with Resume Banner --
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(ResumeBanner), findsOneWidget);
        expect(find.text('LIVE'), findsOneWidget);
        // The banner shows team names with double-spaced "vs".
        expect(find.text('Zara  vs  Yusef'), findsOneWidget);

        // Tap the resume banner.
        await tester.tap(find.byType(ResumeBanner));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 300));

        // Should land on the live match screen.
        expect(find.byType(LiveMatchScreen), findsOneWidget);
        expect(find.text('Zara serving'), findsOneWidget);
      },
    );
  });
}

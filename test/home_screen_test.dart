import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pickletrack/database/database.dart';
import 'package:pickletrack/providers/active_match_provider.dart';
import 'package:pickletrack/providers/completed_matches_provider.dart';
import 'package:pickletrack/providers/database_provider.dart';
import 'package:pickletrack/providers/theme_provider.dart';
import 'package:pickletrack/screens/home/home_screen.dart';

import 'helpers/stubs.dart';

/// Helpers to build test data.

ActiveMatche _testActiveMatch({String type = 'doubles', String scoringRule = 'sideout'}) {
  return ActiveMatche(
    id: 1, type: type, scoringRule: scoringRule,
    gameCount: 1, playTo: 11, winBy: 2,
    createdAt: DateTime.now(), status: 'live',
  );
}

List<ActiveMatchPlayer> _testPlayers() => [
  const ActiveMatchPlayer(id: 1, matchId: 1, name: 'Alice', team: 'A', isStartingServer: true, position: 'right', serverNumber: null),
  const ActiveMatchPlayer(id: 2, matchId: 1, name: 'Bob', team: 'A', isStartingServer: false, position: 'left', serverNumber: null),
  const ActiveMatchPlayer(id: 3, matchId: 1, name: 'Carol', team: 'B', isStartingServer: false, position: 'right', serverNumber: null),
  const ActiveMatchPlayer(id: 4, matchId: 1, name: 'Dave', team: 'B', isStartingServer: false, position: 'left', serverNumber: null),
];

ActiveMatchContext _testActiveContext() => ActiveMatchContext(
  match: _testActiveMatch(),
  players: _testPlayers(),
  events: [],
);

CompletedMatche _testCompletedMatch({int id = 1, String type = 'doubles', String winner = 'A'}) {
  return CompletedMatche(
    id: id, type: type, scoringRule: 'sideout',
    gameCount: 1, gamesPlayed: 1, playTo: 11, winBy: 2,
    teamAPlayers: '["Alice","Bob"]', teamBPlayers: '["Carol","Dave"]',
    finalScores: '[{"game":1,"teamA":11,"teamB":3}]',
    winner: winner, durationSeconds: 900,
    startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
    completedAt: DateTime.now(),
  );
}

/// Pumps the HomeScreen with the given provider overrides.
Future<void> pumpHomeScreen(
  WidgetTester tester, {
  ActiveMatchContext? activeMatch,
  List<CompletedMatche>? completedMatches,
}) async {
  // Use an in-memory Drift DB so the production AppDatabase factory
  // (and its platform SQLite connection) is never opened during tests.
  final db = createInMemoryDatabase();
  addTearDown(() async => db.close());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        activeMatchProvider.overrideWith((_) => Future.value(activeMatch)),
        completedMatchesProvider.overrideWith((_) => Future.value(completedMatches ?? [])),
        // Stubs out the AsyncNotifier's DB read so test ordering can't
        // leak a previously-written theme_mode value across tests.
        themeModeProvider.overrideWith(StubThemeModeNotifier.new),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HomeScreen', () {
    testWidgets('shows hero header with tagline', (tester) async {
      await pumpHomeScreen(tester);

      // Header uses Unicode right single quotation mark (\u2019).
      expect(find.text("Let\u2019s play."), findsOneWidget);
      expect(find.textContaining('Track your pickleball matches'), findsOneWidget);
    });

    testWidgets('shows Standard Start and New Match action cards', (tester) async {
      await pumpHomeScreen(tester);

      expect(find.text('Standard Start'), findsOneWidget);
      // 'New Match' appears twice: once in the action card and once as
      // an EmptyState FilledButton CTA (added per Gemini finding G#13).
      expect(find.text('New Match'), findsNWidgets(2));
    });

    testWidgets(
      'Standard Start label + "Doubles, side-out, 11" subtitle '
      'remain stable when an active match exists',
      (tester) async {
        // Regression guard: the previous subtitle was conditional
        //   hasActive ? 'Replace current' : 'Doubles, standard rules'
        // which was misleading — tapping the card does NOT delete the
        // active match, it just routes to /match/setup?quick=true with the
        // same defaults as a fresh match. We flattened the subtitle to
        // always read "Doubles, side-out, 11" so the card is honest
        // regardless of whether an active match exists. This test pins
        // both rename + flatten so neither can silently regress.
        await pumpHomeScreen(tester, activeMatch: _testActiveContext());

        // Card label survives the rename.
        expect(find.text('Standard Start'), findsOneWidget);
        // Flattened subtitle invariant.
        expect(find.text('Doubles, side-out, 11'), findsOneWidget);
        // Legacy "Replace current" copy must not leak back in.
        expect(find.text('Replace current'), findsNothing);
      },
    );

    testWidgets('shows settings button in AppBar', (tester) async {
      await pumpHomeScreen(tester);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('shows empty state when no matches exist', (tester) async {
      await pumpHomeScreen(tester);

      expect(find.text('Ready to play?'), findsOneWidget);
      expect(find.textContaining('Tap Standard Start'), findsOneWidget);
    });

    testWidgets('shows loading spinner while completed matches load',
        (tester) async {
      // Use a Completer that never completes to keep the provider loading.
      final completer = Completer<List<CompletedMatche>>();

      final db = createInMemoryDatabase();
      addTearDown(() async => db.close());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            activeMatchProvider.overrideWith((_) => Future.value(null)),
            completedMatchesProvider.overrideWith((_) => completer.future),
            themeModeProvider.overrideWith(StubThemeModeNotifier.new),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      // After the initial frame, the completed-matches provider is still
      // loading because the completer hasn't been resolved.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows completed matches section when history exists', (tester) async {
      await pumpHomeScreen(
        tester,
        completedMatches: [_testCompletedMatch()],
      );

      expect(find.text('Match History'), findsOneWidget);
      // Score summary: '11-3'
      expect(find.textContaining('11-3'), findsOneWidget);
      expect(find.text('Doubles'), findsOneWidget);
    });

    testWidgets('shows resume banner when active match exists', (tester) async {
      await pumpHomeScreen(
        tester,
        activeMatch: _testActiveContext(),
      );

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.textContaining('Alice'), findsOneWidget);
      expect(find.textContaining('Carol'), findsOneWidget);
    });

    testWidgets('resume banner hides when no active match', (tester) async {
      await pumpHomeScreen(tester, activeMatch: null);

      expect(find.text('LIVE'), findsNothing);
    });

    testWidgets('PickleTrack title in AppBar', (tester) async {
      await pumpHomeScreen(tester);
      expect(find.text('PickleTrack'), findsOneWidget);
    });

    testWidgets('completed match shows duration and relative date', (tester) async {
      await pumpHomeScreen(
        tester,
        completedMatches: [_testCompletedMatch()],
      );

      // Duration: 15m (900 seconds)
      expect(find.textContaining('15m'), findsOneWidget);
      // Relative date should show minutes/hours/days ago
      expect(find.textContaining('ago'), findsOneWidget);
    });

    testWidgets(
      'empty-search state shows Clear Search button; tapping it resets the field',
      (tester) async {
        // Seed history with Alice/Bob/Carol/Dave so searching 'xyz'
        // (no match) drives the home screen into the empty-search branch.
        await pumpHomeScreen(
          tester,
          completedMatches: [_testCompletedMatch()],
        );

        // Only one TextField is mounted on Home (the search bar).
        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);

        await tester.enterText(searchField, 'xyz');
        await tester.pumpAndSettle();

        // Empty-state message echoes the query and 'Clear Search' is rendered.
        expect(find.text("No matches found for 'xyz'"), findsOneWidget);
        expect(find.text('Clear Search'), findsOneWidget);

        // Tap the Clear Search action.
        await tester.tap(find.text('Clear Search'));
        await tester.pumpAndSettle();

        // After tapping, the empty-state branch is gone and the suffix
        // clear icon inside the search bar also disappears (because
        // _searchQuery is now '').
        expect(find.textContaining('No matches found'), findsNothing);
        expect(find.text('Clear Search'), findsNothing);

        // Search field's controller is genuinely cleared (not just the
        // suffix icon removed).
        final fieldWidget = tester.widget<TextField>(searchField);
        expect(fieldWidget.controller!.text, '');
      },
    );
  });
}

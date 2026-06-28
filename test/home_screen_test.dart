import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pickletrack/database/database.dart';
import 'package:pickletrack/providers/active_match_provider.dart';
import 'package:pickletrack/providers/completed_matches_provider.dart';
import 'package:pickletrack/providers/database_provider.dart';
import 'package:pickletrack/providers/theme_provider.dart';
import 'package:pickletrack/providers/tournament_provider.dart';
import 'package:pickletrack/screens/home/quick_play_tab.dart';

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

/// Pumps the QuickPlayTab with the given provider overrides.
Future<void> pumpQuickPlay(
  WidgetTester tester, {
  ActiveMatchContext? activeMatch,
  List<CompletedMatche>? completedMatches,
}) async {
  final db = createInMemoryDatabase();
  addTearDown(() async => db.close());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        activeMatchProvider.overrideWith((_) => Future.value(activeMatch)),
        completedMatchesProvider.overrideWith((_) => Future.value(completedMatches ?? [])),
        themeModeProvider.overrideWith(StubThemeModeNotifier.new),
        tournamentsProvider.overrideWith((_) => Future.value([])),
      ],
      child: const MaterialApp(home: QuickPlayTab()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('QuickPlayTab', () {
    testWidgets('shows hero header with tagline', (tester) async {
      await pumpQuickPlay(tester);

      expect(find.text('Let\u2019s play.'), findsOneWidget);
      expect(find.textContaining('Track your pickleball matches'), findsOneWidget);
    });

    testWidgets('shows Quick Start and New Match action cards', (tester) async {
      await pumpQuickPlay(tester);

      expect(find.text('Quick Start'), findsOneWidget);
      // 'New Match' appears in the action card row.
      expect(find.text('New Match'), findsOneWidget);
    });

    testWidgets(
      'Quick Start label + subtitle remain stable when an active match exists',
      (tester) async {
        await pumpQuickPlay(tester, activeMatch: _testActiveContext());

        expect(find.text('Quick Start'), findsOneWidget);
        expect(find.text('Doubles, side-out, 11'), findsOneWidget);
        expect(find.text('Replace current'), findsNothing);
      },
    );

    testWidgets('PickleTrack title in AppBar', (tester) async {
      await pumpQuickPlay(tester);
      expect(find.text('PickleTrack'), findsOneWidget);
    });

    testWidgets('shows resume banner when active match exists', (tester) async {
      await pumpQuickPlay(
        tester,
        activeMatch: _testActiveContext(),
      );

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.textContaining('Alice'), findsOneWidget);
      expect(find.textContaining('Carol'), findsOneWidget);
    });

    testWidgets('resume banner hides when no active match', (tester) async {
      await pumpQuickPlay(tester, activeMatch: null);

      expect(find.text('LIVE'), findsNothing);
    });

    // ── Old tests kept but scoped to Quick Play tab only ──
    // Match history, search, and stats tests now belong in a separate
    // HistoryTab test file (lib/screens/home/history_tab.dart).
  });
}

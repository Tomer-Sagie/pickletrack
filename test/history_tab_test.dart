import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pickletrack/database/database.dart';
import 'package:pickletrack/providers/completed_matches_provider.dart';
import 'package:pickletrack/providers/database_provider.dart';
import 'package:pickletrack/screens/home/history_tab.dart';

import 'helpers/stubs.dart';

CompletedMatche _testCompletedMatch(
    {int id = 1, String type = 'doubles', String winner = 'A'}) {
  return CompletedMatche(
    id: id,
    type: type,
    scoringRule: 'sideout',
    gameCount: 1,
    gamesPlayed: 1,
    playTo: 11,
    winBy: 2,
    teamAPlayers: '["Alice","Bob"]',
    teamBPlayers: '["Carol","Dave"]',
    finalScores: '[{"game":1,"teamA":11,"teamB":3}]',
    winner: winner,
    durationSeconds: 900,
    startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
    completedAt: DateTime.now(),
  );
}

Future<void> pumpHistoryTab(
  WidgetTester tester, {
  List<CompletedMatche>? completedMatches,
}) async {
  final db = createInMemoryDatabase();
  addTearDown(() async => db.close());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        completedMatchesProvider
            .overrideWith((_) => Future.value(completedMatches ?? [])),
      ],
      child: const MaterialApp(home: HistoryTab()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HistoryTab', () {
    testWidgets('shows empty state when no matches', (tester) async {
      await pumpHistoryTab(tester);

      expect(find.text('No matches yet'), findsOneWidget);
      expect(find.textContaining('Go to Quick Play'), findsOneWidget);
    });

    testWidgets('shows match list when matches exist', (tester) async {
      await pumpHistoryTab(
          tester, completedMatches: [_testCompletedMatch()]);

      expect(find.textContaining('11-3'), findsOneWidget);
      // Match count header
      expect(find.textContaining('1 match'), findsOneWidget);
    });

    testWidgets('shows search bar when matches exist', (tester) async {
      await pumpHistoryTab(
          tester, completedMatches: [_testCompletedMatch()]);

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('filters out non-matching players', (tester) async {
      await pumpHistoryTab(
          tester, completedMatches: [_testCompletedMatch()]);

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'xyz');
      await tester.pumpAndSettle();

      // Should show no-results state
      expect(
          find.text("No matches found for 'xyz'"), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);
    });

    testWidgets('shows stats row with 5+ matches', (tester) async {
      final matches = List.generate(
          5,
          (i) => _testCompletedMatch(
              id: i + 1, winner: i < 3 ? 'A' : 'B'));
      await pumpHistoryTab(tester, completedMatches: matches);

      // Stats row should appear (5+ matches, no search query)
      expect(find.text('Played'), findsOneWidget);
      expect(find.text('Win Rate'), findsOneWidget);
      expect(find.text('Avg Score'), findsOneWidget);
    });
  });
}

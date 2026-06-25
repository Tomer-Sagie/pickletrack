import 'package:flutter_test/flutter_test.dart';

import 'package:pickletrack/database/database.dart';
import 'package:pickletrack/utils/match_helpers.dart';

CompletedMatche _match({
  int id = 1,
  String teamAJson = '["Alice","Bob"]',
  String teamBJson = '["Carol","Dave"]',
  String finalScoresJson = '[{"game":1,"teamA":11,"teamB":3}]',
  String winner = 'A',
}) {
  return CompletedMatche(
    id: id,
    type: 'doubles',
    scoringRule: 'sideout',
    gameCount: 1,
    gamesPlayed: 1,
    playTo: 11,
    winBy: 2,
    teamAPlayers: teamAJson,
    teamBPlayers: teamBJson,
    finalScores: finalScoresJson,
    winner: winner,
    durationSeconds: 900,
    startedAt: DateTime.utc(2026, 1, 1, 10, 0),
    completedAt: DateTime.utc(2026, 1, 1, 10, 15),
  );
}

void main() {
  group('filterByPlayerName', () {
    final alice = _match(id: 1, teamAJson: '["Alice","Bob"]');
    final carol = _match(id: 2, teamAJson: '["Eve","Frank"]', teamBJson: '["Carol"]');
    final eve = _match(id: 3, teamAJson: '["Eve","Frank"]');

    test('returns all matches when query is empty', () {
      final result = filterByPlayerName([alice, carol, eve], '');
      expect(result.length, 3);
    });

    test('filters by exact name (case-insensitive)', () {
      final result = filterByPlayerName([alice, carol, eve], 'alice');
      expect(result.map((m) => m.id), [1]);
    });

    test('filters by partial name (substring)', () {
      // 'frank' appears in matches 2 and 3 only (both have Frank on Team A).
      final result = filterByPlayerName([alice, carol, eve], 'frank');
      expect(result.map((m) => m.id).toList(), [2, 3]);
    });

    test('matches any team - A and B both included', () {
      final result = filterByPlayerName([alice, carol, eve], 'eve');
      expect(result.length, 2, reason: 'matches Eve twice across the two matches');
    });

    test('returns empty when no match contains the query', () {
      final result = filterByPlayerName([alice, carol, eve], 'zoe');
      expect(result, isEmpty);
    });

    test('does not throw on malformed JSON; excludes such matches', () {
      final bad = _match(id: 4, teamAJson: 'not-json');
      final result = filterByPlayerName([alice, bad, carol], 'alice');
      expect(result.map((m) => m.id), [1], reason: 'malformed JSON excluded');
    });

    test('is case-insensitive on the query AND the matched name', () {
      final result = filterByPlayerName([alice], 'ALICE');
      expect(result.length, 1);
    });
  });

  group('calculateMatchStats', () {
    test('empty list: zero everywhere', () {
      final stats = calculateMatchStats([]);
      expect(stats.totalMatches, 0);
      expect(stats.teamAWins, 0);
      expect(stats.winRatePercent, 0);
      expect(stats.avgTeamAScore, 0);
      expect(stats.avgTeamBScore, 0);
      expect(stats.avgScoreLabel, '0\u20130');
    });

    test('single A win: 100% win rate', () {
      final stats = calculateMatchStats([
        _match(winner: 'A', finalScoresJson: '[{"game":1,"teamA":11,"teamB":3}]'),
      ]);
      expect(stats.totalMatches, 1);
      expect(stats.teamAWins, 1);
      expect(stats.winRatePercent, 100);
      expect(stats.avgTeamAScore, 11);
      expect(stats.avgTeamBScore, 3);
    });

    test('mix of winners: rounds win-rate percentage', () {
      final stats = calculateMatchStats([
        _match(id: 1, winner: 'A'),
        _match(id: 2, winner: 'B'),
        _match(id: 3, winner: 'A'),
      ]);
      expect(stats.totalMatches, 3);
      expect(stats.teamAWins, 2);
      // 2/3 * 100 = 66.66... → rounds to 67 on this platform
      expect(stats.winRatePercent, 67);
    });

    test('all Team B wins: 0% win rate', () {
      final stats = calculateMatchStats([
        _match(id: 1, winner: 'B'),
        _match(id: 2, winner: 'B'),
      ]);
      expect(stats.teamAWins, 0);
      expect(stats.winRatePercent, 0);
    });

    test('multi-game match: averages across all games in finalScores', () {
      final stats = calculateMatchStats([
        _match(
          finalScoresJson:
              '[{"game":1,"teamA":11,"teamB":3},{"game":2,"teamA":11,"teamB":7}]',
        ),
      ]);
      expect(stats.totalMatches, 1);
      expect(stats.avgTeamAScore, 11); // (11+11)/2 = 11
      expect(stats.avgTeamBScore, 5); // (3+7)/2 = 5
    });

    test('malformed finalScores JSON: counted in totalMatches but not in avg', () {
      final stats = calculateMatchStats([
        _match(id: 1, finalScoresJson: '[broken'),
        _match(id: 2, finalScoresJson: '[{"game":1,"teamA":11,"teamB":7}]'),
      ]);
      expect(stats.totalMatches, 2);
      expect(stats.avgTeamAScore, 11);
      expect(stats.avgTeamBScore, 7);
    });

    test('avgScoreLabel uses en-dash separator', () {
      final stats = calculateMatchStats([
        _match(
          finalScoresJson:
              '[{"game":1,"teamA":9,"teamB":7},{"game":2,"teamA":11,"teamB":5}]',
        ),
      ]);
      // (9+11)/2 = 10, (7+5)/2 = 6
      expect(stats.avgScoreLabel, '10\u20136');
    });
  });

  group('formatScoreSummary', () {
    test('formats multi-game match', () {
      expect(
        formatScoreSummary(
            '[{"game":1,"teamA":11,"teamB":7},{"game":2,"teamA":11,"teamB":9}]'),
        '11-7, 11-9',
      );
    });

    test('formats single-game match', () {
      expect(
        formatScoreSummary('[{"game":1,"teamA":11,"teamB":3}]'),
        '11-3',
      );
    });

    test('returns the raw string when malformed', () {
      expect(formatScoreSummary('[broken'), '[broken');
    });
  });

  group('formatPlayerNames', () {
    test('joins single name as-is', () {
      expect(formatPlayerNames(['Alice']), 'Alice');
    });
    test('joins multiple names with " & "', () {
      expect(formatPlayerNames(['Alice', 'Bob']), 'Alice & Bob');
    });
    test('empty list returns empty string', () {
      expect(formatPlayerNames([]), '');
    });
  });
}

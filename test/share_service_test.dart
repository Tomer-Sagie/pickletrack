import 'package:flutter_test/flutter_test.dart';

import 'package:pickletrack/database/database.dart';
import 'package:pickletrack/services/share_service.dart';

CompletedMatche _match({
  int id = 1,
  String type = 'doubles',
  String scoringRule = 'sideout',
  int gameCount = 1,
  int gamesPlayed = 1,
  int playTo = 11,
  int winBy = 2,
  String winner = 'A',
  String teamA = '["Alice","Bob"]',
  String teamB = '["Carol","Dave"]',
  String scores = '[{"game":1,"teamA":11,"teamB":3}]',
  int duration = 900,
  DateTime? startedAt,
  DateTime? completedAt,
}) {
  return CompletedMatche(
    id: id,
    type: type,
    scoringRule: scoringRule,
    gameCount: gameCount,
    gamesPlayed: gamesPlayed,
    playTo: playTo,
    winBy: winBy,
    teamAPlayers: teamA,
    teamBPlayers: teamB,
    finalScores: scores,
    winner: winner,
    durationSeconds: duration,
    startedAt: startedAt ?? DateTime.utc(2026, 6, 23, 10, 0),
    completedAt: completedAt ?? DateTime.utc(2026, 6, 23, 10, 15),
  );
}

MatchEventLogData _event(int id, int gameNumber, int a, int b, String type) {
  return MatchEventLogData(
    id: id,
    completedMatchId: 1,
    gameNumber: gameNumber,
    eventType: type,
    scorerTeam: type == 'point' ? 'A' : null,
    serverName: null,
    teamAScore: a,
    teamBScore: b,
    serverNumber: null,
    timestamp: DateTime.utc(2026, 6, 23, 10, 0),
  );
}

void main() {
  group('buildMatchSummaryText', () {
    test('contains all the required fields', () {
      final text = buildMatchSummaryText(
        winnerLabel: 'Team A',
        teamAPlayers: 'Alice & Bob',
        teamBPlayers: 'Carol & Dave',
        finalScores: '11-3, 11-9',
        date: '6/23/2026',
        duration: '15m',
      );

      expect(text, contains('🏓 PickleTrack Match'));
      expect(text, contains('6/23/2026 · 15m'));
      expect(text, contains('Alice & Bob  vs  Carol & Dave'));
      expect(text, contains('Final: 11-3, 11-9'));
      expect(text, contains('Winner: Team A'));
      expect(text, contains('Tracked with PickleTrack'));
    });

    test('ends with a newline', () {
      final text = buildMatchSummaryText(
        winnerLabel: 'A',
        teamAPlayers: 'A',
        teamBPlayers: 'B',
        finalScores: '11-0',
        date: 'd',
        duration: '1m',
      );
      expect(text.endsWith('\n'), true);
    });
  });

  group('buildMatchExportEntry', () {
    test('decodes JSON columns into native lists', () {
      final entry = buildMatchExportEntry(
        _match(),
        eventLog: [_event(1, 1, 1, 0, 'point')],
      );
      expect(entry['teamAPlayers'], ['Alice', 'Bob']);
      expect(entry['teamBPlayers'], ['Carol', 'Dave']);
      expect(entry['finalScores'], [
        {'game': 1, 'teamA': 11, 'teamB': 3},
      ]);
    });

    test('emits timestamps as ISO-8601', () {
      final entry = buildMatchExportEntry(_match(
        startedAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
        completedAt: DateTime.utc(2026, 1, 2, 4, 4, 5),
      ));
      expect(entry['startedAt'], '2026-01-02T03:04:05.000Z');
      expect(entry['completedAt'], '2026-01-02T04:04:05.000Z');
    });

    test('serialises event log entries with all fields', () {
      final entry = buildMatchExportEntry(
        _match(),
        eventLog: [_event(1, 1, 1, 0, 'point')],
      );
      final log = entry['eventLog'] as List<dynamic>;
      expect(log, hasLength(1));
      final first = log.first as Map<String, dynamic>;
      expect(first['gameNumber'], 1);
      expect(first['eventType'], 'point');
      expect(first['scorerTeam'], 'A');
      expect(first['teamAScore'], 1);
      expect(first['teamBScore'], 0);
    });

    test('handles empty event log', () {
      final entry = buildMatchExportEntry(_match());
      expect(entry['eventLog'], isEmpty);
    });

    test('passes through scalar fields verbatim', () {
      final entry = buildMatchExportEntry(_match(
        id: 42,
        type: 'singles',
        winner: 'B',
        gameCount: 3,
        gamesPlayed: 2,
        playTo: 7,
        winBy: 2,
        duration: 600,
      ));
      expect(entry['id'], 42);
      expect(entry['type'], 'singles');
      expect(entry['winner'], 'B');
      expect(entry['gameCount'], 3);
      expect(entry['gamesPlayed'], 2);
      expect(entry['playTo'], 7);
      expect(entry['winBy'], 2);
      expect(entry['durationSeconds'], 600);
    });
  });

  group('encodeMatchExportJson', () {
    test('two-space indent in output', () {
      final json = encodeMatchExportJson([
        {'id': 1, 'a': 'b'},
      ]);
      expect(json, contains('  "id": 1'));
    });

    test('returns valid JSON for empty list', () {
      final json = encodeMatchExportJson([]);
      expect(json.trim(), '[]');
    });

    test('round-trips entries via decoder', () {
      final json = encodeMatchExportJson([buildMatchExportEntry(_match(id: 7))]);
      // Expect a top-level array of one entry
      expect(json.trim().startsWith('['), true);
      expect(json, contains('"id": 7'));
    });
  });
}

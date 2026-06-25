import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

/// Full match detail context for the detail screen.
class MatchDetailContext {
  final CompletedMatche match;
  final List<MatchEventLogData> eventLog;
  final List<String> teamAPlayers;
  final List<String> teamBPlayers;
  final List<Map<String, dynamic>> parsedScores;

  MatchDetailContext({
    required this.match,
    required this.eventLog,
    required this.teamAPlayers,
    required this.teamBPlayers,
    required this.parsedScores,
  });

  String get winnerLabel => match.winner == 'A' ? 'Team A' : 'Team B';
  bool get teamAWon => match.winner == 'A';

  String get typeLabel => match.type == 'singles' ? 'Singles' : 'Doubles';
  String get ruleLabel => match.scoringRule == 'sideout' ? 'Side-Out' : 'Rally';
  String get gameLabel => match.gameCount == 3 ? 'Best of 3' : '1 Game';

  String formatDuration() {
    final s = match.durationSeconds;
    if (s < 60) return '${s}s';
    final min = s ~/ 60;
    final sec = s % 60;
    if (min < 60) return '${min}m ${sec}s';
    final hr = min ~/ 60;
    return '${hr}h ${min % 60}m';
  }
}

final matchDetailProvider =
    FutureProvider.family<MatchDetailContext, int>((ref, matchId) async {
  final db = ref.watch(databaseProvider);
  final match = await (db.select(db.completedMatches)
        ..where((m) => m.id.equals(matchId)))
      .getSingle();
  final eventLog = await db.getMatchEventLog(matchId);

  final teamAPlayers = _parseStringList(match.teamAPlayers);
  final teamBPlayers = _parseStringList(match.teamBPlayers);
  final parsedScores = _parseScores(match.finalScores);

  return MatchDetailContext(
    match: match,
    eventLog: eventLog,
    teamAPlayers: teamAPlayers,
    teamBPlayers: teamBPlayers,
    parsedScores: parsedScores,
  );
});

List<String> _parseStringList(String json) {
  try {
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => e.toString()).toList();
  } catch (_) {
    return [];
  }
}

List<Map<String, dynamic>> _parseScores(String json) {
  try {
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  } catch (_) {
    return [];
  }
}

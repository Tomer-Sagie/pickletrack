import 'dart:convert';

import '../database/database.dart';

/// Aggregate stats for a list of completed matches.
class MatchStats {
  /// Total matches played.
  final int totalMatches;

  /// Number of matches won by Team A.
  final int teamAWins;

  /// Win rate as percentage 0–100.
  final int winRatePercent;

  /// Average score per game for Team A. 0 if no games recorded.
  final int avgTeamAScore;

  /// Average score per game for Team B. 0 if no games recorded.
  final int avgTeamBScore;

  const MatchStats({
    required this.totalMatches,
    required this.teamAWins,
    required this.winRatePercent,
    required this.avgTeamAScore,
    required this.avgTeamBScore,
  });

  /// Convenience for the "Avg Score" display string ("8–6").
  String get avgScoreLabel => '$avgTeamAScore\u2013$avgTeamBScore';
}

/// Filters [matches] by [query] (case-insensitive substring of any player
/// name on either team). Returns [matches] unchanged if [query] is empty.
///
/// Players are read from the JSON-encoded `teamAPlayers` / `teamBPlayers`
/// columns. Malformed JSON is treated as "no match" rather than throwing.
List<CompletedMatche> filterByPlayerName(
  Iterable<CompletedMatche> matches,
  String query,
) {
  if (query.isEmpty) return matches.toList(growable: false);
  final needle = query.toLowerCase();
  return matches.where((m) {
    try {
      final a = jsonDecode(m.teamAPlayers) as List<dynamic>;
      final b = jsonDecode(m.teamBPlayers) as List<dynamic>;
      final allNames = [...a, ...b].map((n) => n.toString().toLowerCase());
      return allNames.any((n) => n.contains(needle));
    } catch (_) {
      return false;
    }
  }).toList(growable: false);
}

/// Computes aggregate stats from [matches] — played count, Team A win rate,
/// and average score per game across all recorded final scores.
///
/// Robust against malformed `finalScores` JSON (silently skipped).
MatchStats calculateMatchStats(List<CompletedMatche> matches) {
  final totalMatches = matches.length;
  final teamAWins = matches.where((m) => m.winner == 'A').length;
  final winRate =
      totalMatches > 0 ? (teamAWins / totalMatches * 100).round() : 0;

  var totalA = 0;
  var totalB = 0;
  var gameCount = 0;
  for (final m in matches) {
    try {
      final scores = jsonDecode(m.finalScores) as List<dynamic>;
      for (final g in scores) {
        final game = g as Map<String, dynamic>;
        totalA += (game['teamA'] ?? 0) as int;
        totalB += (game['teamB'] ?? 0) as int;
        gameCount++;
      }
    } catch (_) {
      // Skip malformed data — keeps totalMatches intact while avg-score
      // is calculated only over parseable records.
    }
  }
  final avgA = gameCount > 0 ? (totalA / gameCount).round() : 0;
  final avgB = gameCount > 0 ? (totalB / gameCount).round() : 0;

  return MatchStats(
    totalMatches: totalMatches,
    teamAWins: teamAWins,
    winRatePercent: winRate,
    avgTeamAScore: avgA,
    avgTeamBScore: avgB,
  );
}

/// Parses the `finalScores` JSON column into a "11-3, 11-9" display string.
/// Returns the raw JSON string when it can't be parsed.
String formatScoreSummary(String finalScoresJson) {
  try {
    final list = jsonDecode(finalScoresJson) as List<dynamic>;
    return list.map((g) {
      final game = g as Map<String, dynamic>;
      final a = game['teamA'] ?? 0;
      final b = game['teamB'] ?? 0;
      return '$a-$b';
    }).join(', ');
  } catch (_) {
    return finalScoresJson;
  }
}

/// Formats the per-team player strings for display ("Alice & Bob").
String formatPlayerNames(List<String> names) => names.join(' & ');

/// Returns true when [name] matches the auto-generated defaults used by
/// the Setup screen when a player leaves the name field empty
/// ("Player A1", "Player A2", "Player B1", "Player B2" in both singles
/// and doubles). These placeholders should never be upserted into the
/// `recentPlayers` table — otherwise the autocomplete gets polluted
/// with junk entries every time a match starts with unnamed slots.
bool isPlaceholderDefaultName(String name) {
  return RegExp(r'^Player [AB]\d+$').hasMatch(name);
}

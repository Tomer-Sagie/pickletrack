import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../utils/match_helpers.dart';
import 'database_provider.dart';

/// Holds the full active match context: match row, players, and events.
class ActiveMatchContext {
  final ActiveMatche match;
  final List<ActiveMatchPlayer> players;
  final List<ScoreEvent> events;

  const ActiveMatchContext({
    required this.match,
    required this.players,
    required this.events,
  });

  /// Whether an active match exists.
  bool get isActive => true;

  /// The player names by team.
  List<String> get teamANames =>
      players.where((p) => p.team == 'A').map((p) => p.name).toList();
  List<String> get teamBNames =>
      players.where((p) => p.team == 'B').map((p) => p.name).toList();
}

/// Loads the active match (if any) from the database.
final activeMatchProvider =
    FutureProvider<ActiveMatchContext?>((ref) async {
  final db = ref.watch(databaseProvider);
  final match = await db.getActiveMatch();
  if (match == null) return null;

  final players = await db.getActiveMatchPlayers(match.id);
  final events = await db.getScoreEvents(match.id);

  return ActiveMatchContext(match: match, players: players, events: events);
});

/// Creates a new match in the database and returns the match ID.
Future<int> createMatchInDb({
  required WidgetRef ref,
  required String type,
  required String scoringRule,
  required int gameCount,
  required int playTo,
  required int winBy,
  required List<({String name, String team, bool isStartingServer, String? position})> players,
}) async {
  final db = ref.read(databaseProvider);

  // Guard: only one active match is allowed. If a stale row exists
  // (e.g. from a crash before cleanup), clear it before creating the
  // new one so we never have multiple active matches in the DB.
  final existing = await db.getActiveMatch();
  if (existing != null) {
    await db.delete(db.activeMatchPlayers).go();
    await db.delete(db.activeMatches).go();
    await db.delete(db.scoreEvents).go();
  }

  final matchId = await db.createMatch(
    type: type,
    scoringRule: scoringRule,
    gameCount: gameCount,
    playTo: playTo,
    winBy: winBy,
    players: players,
  );

  // Record player names — but skip auto-generated defaults like
  // "Player A1" / "Player B2" so they don't enter autocomplete.
  for (final p in players) {
    if (p.name.isNotEmpty && !isPlaceholderDefaultName(p.name)) {
      await db.recordPlayer(p.name);
    }
  }

  ref.invalidate(activeMatchProvider);
  return matchId;
}

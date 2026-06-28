import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'database_io.dart' if (dart.library.html) 'database_web.dart';
import 'tables.dart';
import '../utils/match_helpers.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    ActiveMatches,
    ActiveMatchPlayers,
    ScoreEvents,
    CompletedMatches,
    MatchEventLog,
    RecentPlayers,
    AppSettings,
    Tournaments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  /// Test-only constructor accepting a [QueryExecutor] directly so tests
  /// can run against `NativeDatabase.memory()` (or any other in-memory
  /// executor) without going through the platform-specific
  /// [openDatabaseConnection] factory.
  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  /// Schema-migration strategy.
  ///
  /// Defines an explicit [MigrationStrategy] so future schema bumps
  /// (new tables, new columns) can be added explicitly via [onUpgrade]
  /// without crashing on app startup with the default drift behaviour.
  /// [onCreate] runs the initial schema on a fresh install; [beforeOpen]
  /// enables foreign-key enforcement so `references()` constraints
  /// declared in [tables.dart] are honoured at the SQLite layer.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2: Add tournament tables + tournament columns on active_matches
            await m.createTable(tournaments);
            await m.addColumn(activeMatches, activeMatches.tournamentId);
            await m.addColumn(activeMatches, activeMatches.tournamentMatchId);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ── Active Match Queries ──

  /// Creates a new active match with players. Returns the match ID.
  /// If [tournamentId] and [tournamentMatchId] are provided, the match
  /// is linked to a tournament bracket match.
  Future<int> createMatch({
    required String type,
    required String scoringRule,
    required int gameCount,
    required int playTo,
    required int winBy,
    required List<({String name, String team, bool isStartingServer, String? position})> players,
    int? tournamentId,
    int? tournamentMatchId,
  }) async {
    return transaction(() async {
      final matchId = await into(activeMatches).insert(
        ActiveMatchesCompanion.insert(
          type: type,
          scoringRule: scoringRule,
          gameCount: Value(gameCount),
          playTo: Value(playTo),
          winBy: Value(winBy),
          createdAt: DateTime.now(),
          status: const Value('live'),
          tournamentId: Value(tournamentId),
          tournamentMatchId: Value(tournamentMatchId),
        ),
      );

      for (final player in players) {
        await into(activeMatchPlayers).insert(
          ActiveMatchPlayersCompanion.insert(
            matchId: matchId,
            name: player.name,
            team: player.team,
            isStartingServer: Value(player.isStartingServer),
            position: Value(player.position),
            serverNumber: const Value(null),
          ),
        );
      }

      return matchId;
    });
  }

  /// Returns the active match row, if one exists.
  Future<ActiveMatche?> getActiveMatch() {
    return (select(activeMatches)..limit(1)).getSingleOrNull();
  }

  /// Returns all players in the active match.
  Future<List<ActiveMatchPlayer>> getActiveMatchPlayers(int matchId) {
    return (select(activeMatchPlayers)
          ..where((p) => p.matchId.equals(matchId))
          ..orderBy([(p) => OrderingTerm.asc(p.id)]))
        .get();
  }

  /// Returns score events for the active match, ordered by id (chronological).
  Future<List<ScoreEvent>> getScoreEvents(int matchId) {
    return (select(scoreEvents)
          ..where((e) => e.matchId.equals(matchId))
          ..orderBy([(e) => OrderingTerm.asc(e.id)]))
        .get();
  }

  /// Deletes the last score event (for undo).
  Future<void> undoLastEvent(int matchId) async {
    // Find the max ID for this match, then delete that row.
    final maxIdQuery = selectOnly(scoreEvents)
      ..addColumns([scoreEvents.id.max()])
      ..where(scoreEvents.matchId.equals(matchId));
    final maxRow = await maxIdQuery.getSingle();
    final maxId = maxRow.read(scoreEvents.id.max());
    if (maxId != null) {
      await (delete(scoreEvents)..where((e) => e.id.equals(maxId))).go();
    }
  }

  // ── Completed Matches Queries ──

  /// Returns all completed matches, most recent first.
  Future<List<CompletedMatche>> getCompletedMatches() {
    return (select(completedMatches)
          ..orderBy([(m) => OrderingTerm.desc(m.completedAt)]))
        .get();
  }

  /// Returns event log for a completed match.
  Future<List<MatchEventLogData>> getMatchEventLog(int completedMatchId) {
    return (select(matchEventLog)
          ..where((e) => e.completedMatchId.equals(completedMatchId))
          ..orderBy([(e) => OrderingTerm.asc(e.id)]))
        .get();
  }

  // ── Recent Players ──

  /// Returns up to 20 recent player names, most recently used first.
  Future<List<RecentPlayer>> getRecentPlayers() {
    return (select(recentPlayers)
          ..orderBy([(p) => OrderingTerm.desc(p.lastUsed)])
          ..limit(20))
        .get();
  }

  /// Upserts a player name and prunes the list to 20.
  ///
  /// Wrapped in a [transaction] so concurrent calls never race on the
  /// read-then-write path (both seeing `existing == null` and trying
  /// to insert, which would crash with a unique-constraint violation).
  Future<void> recordPlayer(String name) async {
    await transaction(() async {
      final existing = await (select(recentPlayers)
            ..where((p) => p.name.equals(name)))
          .getSingleOrNull();

      if (existing != null) {
        await (update(recentPlayers)
              ..where((p) => p.name.equals(name)))
            .write(RecentPlayersCompanion(
          lastUsed: Value(DateTime.now()),
          usageCount: Value(existing.usageCount + 1),
        ));
      } else {
        await into(recentPlayers).insertOnConflictUpdate(
          RecentPlayersCompanion.insert(
            name: name,
            lastUsed: DateTime.now(),
          ),
        );
      }

      // Prune to 20 — delete all but the 20 most recent.
      final all = await (select(recentPlayers)
            ..orderBy([(p) => OrderingTerm.desc(p.lastUsed)]))
          .get();
      if (all.length > 20) {
        final toDelete = all.sublist(20).map((p) => p.name);
        await (delete(recentPlayers)..where((p) => p.name.isIn(toDelete))).go();
      }
    });
  }

  // ── Settings ──

  /// Gets a setting value by key.
  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Sets a setting value.
  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: key, value: value),
    );
  }

  // ── Tournament Queries ──

  /// Creates a new tournament and returns its ID.
  Future<int> createTournament({
    required String name,
    required String format,
    required String type,
    required String scoringRule,
    required int playTo,
    required int winBy,
    required int gameCount,
    required String playersJson,
    String? bracketJson,
  }) async {
    return into(tournaments).insert(
      TournamentsCompanion.insert(
        name: name,
        format: format,
        type: type,
        scoringRule: scoringRule,
        playTo: Value(playTo),
        winBy: Value(winBy),
        gameCount: Value(gameCount),
        status: const Value('in_progress'),
        playersJson: playersJson,
        bracketJson: Value(bracketJson),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Returns all tournaments, most recent first.
  Future<List<Tournament>> getTournaments() {
    return (select(tournaments)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Returns a single tournament by ID.
  Future<Tournament?> getTournament(int id) {
    return (select(tournaments)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Updates mutable tournament metadata: name, players list,
  /// and bracket JSON. Use this for in-place edits that don't change
  /// the bracket structure (format/type/scoring/playTo/winBy/gameCount
  /// are immutable post-creation).
  Future<void> updateTournamentMeta({
    required int tournamentId,
    required String name,
    required String playersJson,
    required String bracketJson,
  }) async {
    await (update(tournaments)..where((t) => t.id.equals(tournamentId)))
        .write(TournamentsCompanion(
      name: Value(name),
      playersJson: Value(playersJson),
      bracketJson: Value(bracketJson),
    ));
  }

  /// Updates the bracket JSON and status for a tournament.
  Future<void> updateTournamentBracket({
    required int tournamentId,
    required String bracketJson,
    String? status,
    String? finalRankingsJson,
    DateTime? completedAt,
  }) async {
    await (update(tournaments)..where((t) => t.id.equals(tournamentId)))
        .write(TournamentsCompanion(
      bracketJson: Value(bracketJson),
      status: status != null ? Value(status) : const Value.absent(),
      finalRankingsJson: finalRankingsJson != null
          ? Value(finalRankingsJson)
          : const Value.absent(),
      completedAt: completedAt != null
          ? Value(completedAt)
          : const Value.absent(),
    ));
  }

  /// Deletes a tournament by ID.
  Future<void> deleteTournament(int id) async {
    await (delete(tournaments)..where((t) => t.id.equals(id))).go();
  }

  // ── Match Completion ──

  /// Archives the active match to completed_matches + match_event_log,
  /// then clears the active tables.
  ///
  /// Wrapped in a single [transaction] so that a crash or partial failure
  /// mid-flight can never leave the database in an inconsistent state
  /// (orphan completed rows, double-archived active rows, etc.).
  /// Every step — inserting the completed row, copying the event log,
  /// recording recent players, and clearing the active tables — either
  /// succeeds as one unit or rolls back together.
  Future<int> completeMatch({
    required ActiveMatche match,
    required int currentGame,
    required List<ActiveMatchPlayer> players,
    required List<ScoreEvent> events,
    required String finalScoresJson,
    required String winner,
    required int durationSeconds,
    required DateTime startedAt,
  }) async {
    return transaction(() async {
      final teamA = players.where((p) => p.team == 'A').map((p) => p.name).toList();
      final teamB = players.where((p) => p.team == 'B').map((p) => p.name).toList();

      final completedId = await into(completedMatches).insert(
        CompletedMatchesCompanion.insert(
          type: match.type,
          scoringRule: match.scoringRule,
          gameCount: match.gameCount,
          gamesPlayed: currentGame,
          playTo: match.playTo,
          winBy: match.winBy,
          teamAPlayers: jsonEncode(teamA),
          teamBPlayers: jsonEncode(teamB),
          finalScores: finalScoresJson,
          winner: winner,
          durationSeconds: durationSeconds,
          startedAt: startedAt,
          completedAt: DateTime.now(),
        ),
      );

      // Copy events to log
      for (final event in events) {
        await into(matchEventLog).insert(
          MatchEventLogCompanion.insert(
            completedMatchId: completedId,
            gameNumber: event.gameNumber,
            eventType: event.eventType,
            scorerTeam: Value(event.scorerTeam),
            serverName: Value(event.serverName),
            teamAScore: event.teamAScore,
            teamBScore: event.teamBScore,
            serverNumber: Value(event.serverNumber),
            timestamp: event.timestamp,
          ),
        );
      }

      // Record player names — but skip auto-generated defaults like
      // "Player A1" / "Player B2" so they don't enter autocomplete.
      for (final player in players) {
        if (player.name.isNotEmpty && !isPlaceholderDefaultName(player.name)) {
          await recordPlayer(player.name);
        }
      }

      // Clear active tables
      await delete(scoreEvents).go();
      await delete(activeMatchPlayers).go();
      await delete(activeMatches).go();

      return completedId;
    });
  }
}

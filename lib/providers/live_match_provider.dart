import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import '../database/database.dart';
import '../models/scoring_preset.dart';
import '../providers/active_match_provider.dart';
import '../providers/completed_matches_provider.dart';
import '../providers/database_provider.dart';
import '../services/scoring_service.dart';

/// Holds the reconstructed match state plus DB references for the live screen.
class LiveMatchState {
  final ActiveMatche match;
  final List<ActiveMatchPlayer> players;
  final List<ScoreEvent> events;
  final MatchState scoringState;

  const LiveMatchState({
    required this.match,
    required this.players,
    required this.events,
    required this.scoringState,
  });

  String get matchType => match.type;
  String get scoringRule => match.scoringRule;
  int get gameCount => match.gameCount;
  int get currentGame => scoringState.currentGame;
  int get teamAScore => scoringState.teamAScore;
  int get teamBScore => scoringState.teamBScore;
  int get teamAGamesWon => scoringState.teamAGamesWon;
  int get teamBGamesWon => scoringState.teamBGamesWon;
  String? get servingPlayerId => scoringState.currentServerId;
  int get serverNumber => scoringState.serverNumber;
  String? get serverTeam => scoringState.serverTeam;

  bool get isDoubles => matchType == 'doubles';
  bool get isSideOut => scoringRule == 'sideout';
  bool get isGameOver => scoringState.isGameOver;
  bool get isMatchOver => scoringState.isMatchOver;
  bool get canUndo => events.isNotEmpty;

  bool isTeamServing(Team team) {
    final teamStr = team == Team.A ? 'A' : 'B';
    return serverTeam == teamStr;
  }

  String? get gameWinnerTeam {
    final w = scoringState.gameWinner;
    if (w == Team.A) return 'A';
    if (w == Team.B) return 'B';
    return null;
  }

  String get scoreCallout => scoringState.scoreCallout;

  String? playerName(String playerId) {
    for (final p in players) {
      if (_playerId(p) == playerId) return p.name;
    }
    return null;
  }

  String? playerSide(String playerId) {
    return scoringState.playerSides[playerId];
  }

  String? playerTeam(String playerId) {
    return scoringState.playerTeams[playerId];
  }

  String _playerId(ActiveMatchPlayer p) {
    // Match the ID scheme used at creation: A0, A1, B0, B1
    final aPlayers = players.where((x) => x.team == 'A').toList();
    final bPlayers = players.where((x) => x.team == 'B').toList();
    final aIdx = aPlayers.indexWhere((x) => x.id == p.id);
    final bIdx = bPlayers.indexWhere((x) => x.id == p.id);
    if (aIdx >= 0) return 'A$aIdx';
    if (bIdx >= 0) return 'B$bIdx';
    return '${p.team}${p.id}';
  }

  List<Map<String, dynamic>> get playerPositions {
    final result = <Map<String, dynamic>>[];
    for (final p in players) {
      final id = _playerId(p);
      result.add({
        'id': id,
        'name': p.name,
        'team': p.team,
        'side': scoringState.playerSides[id] ?? 'right',
      });
    }
    return result;
  }
}

/// Loads and manages the live match state.
class LiveMatchNotifier extends StateNotifier<LiveMatchState?> {
  final Ref _ref;

  LiveMatchNotifier(this._ref) : super(null);

  AppDatabase get _db => _ref.read(databaseProvider);

  // ── State snapshots for O(1) undo ──
  // After each point, the current MatchState is pushed here so undo can
  // restore the previous state instantly instead of replaying all events.
  // Invariant: _stateSnapshots.length == (state?.events.length ?? 0) + 1.
  final List<MatchState> _stateSnapshots = [];

  // ── Write queue ──
  // Chains all DB writes sequentially so scorePoint can fire-and-forget
  // inserts while undo/endMatch flush pending writes before operating.
  Future<void> _writeQueue = Future.value();

  /// Adds a database operation to the queue, ensuring strict FIFO order.
  void _enqueueWrite(Future<void> Function() operation) {
    _writeQueue = _writeQueue.then((_) => operation()).catchError((e) {
      // A failed insert shouldn't break the queue, but we log it so
      // storage issues (disk full, corruption) aren't completely invisible.
      debugPrint('LiveMatchNotifier: DB write failed — $e');
    });
  }

  /// Waits for all pending writes to complete.
  Future<void> _flushPendingWrites() => _writeQueue;

  /// Loads the active match from the database and reconstructs scoring state.
  Future<void> load() async {
    final match = await _db.getActiveMatch();
    if (match == null) {
      state = null;
      return;
    }

    final players = await _db.getActiveMatchPlayers(match.id);
    final events = await _db.getScoreEvents(match.id);

    // Build player ID maps
    final aPlayers = players.where((p) => p.team == 'A').toList();
    final bPlayers = players.where((p) => p.team == 'B').toList();

    final playerSides = <String, String>{};
    final playerTeams = <String, String>{};
    String? startingServerId;
    Team startingServerTeam = Team.A;

    for (var i = 0; i < aPlayers.length; i++) {
      final id = 'A$i';
      playerTeams[id] = 'A';
      playerSides[id] = aPlayers[i].position ?? (i == 0 ? 'right' : 'left');
      if (aPlayers[i].isStartingServer) {
        startingServerId = id;
        startingServerTeam = Team.A;
      }
    }
    for (var i = 0; i < bPlayers.length; i++) {
      final id = 'B$i';
      playerTeams[id] = 'B';
      playerSides[id] = bPlayers[i].position ?? (i == 0 ? 'right' : 'left');
      if (bPlayers[i].isStartingServer) {
        startingServerId = id;
        startingServerTeam = Team.B;
      }
    }

    // Build scoring preset
    final preset = ScoringPreset.custom(
      playTo: match.playTo,
      winBy: match.winBy,
    );

    // Create initial state
    final matchTypeEnum =
        match.type == 'singles' ? MatchType.singles : MatchType.doubles;
    final ruleEnum =
        match.scoringRule == 'sideout' ? ScoringRule.sideout : ScoringRule.rally;

    var scoringState = ScoringService.createInitialState(
      type: matchTypeEnum,
      rule: ruleEnum,
      preset: preset,
      gameCount: match.gameCount,
      startingServerId: startingServerId ?? 'A0',
      startingServerTeam: startingServerTeam,
      initialPlayerSides: playerSides,
      initialPlayerTeams: playerTeams,
    );

    // Seed snapshot list with the initial state (events.length == 0).
    _stateSnapshots..clear()..add(scoringState);

    // Replay events to reconstruct current state
    for (final event in events) {
      // Only replay user-action events (point, sideout).
      // game_end and match_end are generated internally by the scoring service
      // and replaying them would incorrectly score extra points.
      if (event.scorerTeam != null &&
          event.eventType != 'game_end' &&
          event.eventType != 'match_end') {
        final team = event.scorerTeam == 'A' ? Team.A : Team.B;
        if (scoringState.isGameInProgress) {
          try {
            final result = ScoringService.recordPoint(scoringState, team);
            scoringState = result.newState;
          } catch (_) {
            // Skip if state is inconsistent
          }
        }
      }
      // Always push a snapshot for every event — skipped events (game_end,
      // match_end) don't change state, so pushing the unchanged scoringState
      // maintains the invariant: snapshots.length == events.length + 1.
      _stateSnapshots.add(scoringState);
    }

    state = LiveMatchState(
      match: match,
      players: players,
      events: events,
      scoringState: scoringState,
    );
  }

  /// Records a point for the given team.
  Future<void> scorePoint(Team team) async {
    final current = state;
    if (current == null) return;

    try {
      final result = ScoringService.recordPoint(
        current.scoringState,
        team,
      );

      final now = DateTime.now();

      // Write event to DB
      final event = ScoreEventsCompanion.insert(
        matchId: current.match.id,
        gameNumber: current.scoringState.currentGame,
        eventType: result.eventType,
        scorerTeam: Value(result.scorerTeam),
        serverName: Value(
          result.newState.currentServerId != null
              ? current.playerName(result.newState.currentServerId!)
              : null,
        ),
        teamAScore: result.newState.teamAScore,
        teamBScore: result.newState.teamBScore,
        serverNumber: Value(
          result.newState.type == MatchType.doubles
              ? result.newState.serverNumber
              : null,
        ),
        timestamp: now,
      );

      // Persist to DB via the write queue — fire-and-forget so the UI
      // updates immediately.  undo / endMatch flush the queue first.
      _enqueueWrite(() => _db.into(_db.scoreEvents).insert(event));

      // Build events list from existing + new event data to avoid
      // a round-trip getScoreEvents reload on every point scored.
      final newEvent = ScoreEvent(
        id: current.events.length + 1, // synthetic id, replaced on undo reload
        matchId: current.match.id,
        gameNumber: current.scoringState.currentGame,
        eventType: result.eventType,
        scorerTeam: result.scorerTeam,
        serverName: result.newState.currentServerId != null
            ? current.playerName(result.newState.currentServerId!)
            : null,
        teamAScore: result.newState.teamAScore,
        teamBScore: result.newState.teamBScore,
        serverNumber: result.newState.type == MatchType.doubles
            ? result.newState.serverNumber
            : null,
        timestamp: now,
      );

      state = LiveMatchState(
        match: current.match,
        players: current.players,
        events: [...current.events, newEvent],
        scoringState: result.newState,
      );
      // Push snapshot for O(1) undo.
      _stateSnapshots.add(result.newState);
    } catch (e) {
      // Game already over or other error — ignore
    }
  }

  /// Undoes the last scoring action.
  Future<void> undo() async {
    final current = state;
    if (current == null || !current.canUndo) return;

    // Flush any pending writes before operating on the DB.
    await _flushPendingWrites();

    // Delete last event from DB.
    await _db.undoLastEvent(current.match.id);

    // Remove the last in-memory event and snapshot.
    final newEvents = List<ScoreEvent>.from(current.events)..removeLast();

    // O(1) path: restore from cached snapshot.
    // Invariant: _stateSnapshots.length == current.events.length + 1.
    if (_stateSnapshots.length == current.events.length + 1) {
      _stateSnapshots.removeLast();
      state = LiveMatchState(
        match: current.match,
        players: current.players,
        events: newEvents,
        scoringState: _stateSnapshots.last,
      );
      return;
    }

    // Fallback (shouldn't normally be reached): snapshots are out of sync.
    // Reload from DB and replay all events to reconstruct state.
    debugPrint('LiveMatchNotifier: snapshots desynced, falling back to replay');
    _stateSnapshots.clear();

    final events = await _db.getScoreEvents(current.match.id);
    final aPlayers = current.players.where((p) => p.team == 'A').toList();
    final bPlayers = current.players.where((p) => p.team == 'B').toList();

    final playerSides = <String, String>{};
    final playerTeams = <String, String>{};
    String? startingServerId;
    Team startingServerTeam = Team.A;
    for (var i = 0; i < aPlayers.length; i++) {
      final id = 'A$i';
      playerTeams[id] = 'A';
      playerSides[id] = aPlayers[i].position ?? (i == 0 ? 'right' : 'left');
      if (aPlayers[i].isStartingServer) {
        startingServerId = id;
        startingServerTeam = Team.A;
      }
    }
    for (var i = 0; i < bPlayers.length; i++) {
      final id = 'B$i';
      playerTeams[id] = 'B';
      playerSides[id] = bPlayers[i].position ?? (i == 0 ? 'right' : 'left');
      if (bPlayers[i].isStartingServer) {
        startingServerId = id;
        startingServerTeam = Team.B;
      }
    }
    final preset = ScoringPreset.custom(
      playTo: current.match.playTo, winBy: current.match.winBy,
    );
    final matchTypeEnum = current.match.type == 'singles'
        ? MatchType.singles : MatchType.doubles;
    final ruleEnum = current.match.scoringRule == 'sideout'
        ? ScoringRule.sideout : ScoringRule.rally;

    var scoringState = ScoringService.createInitialState(
      type: matchTypeEnum, rule: ruleEnum, preset: preset,
      gameCount: current.match.gameCount,
      startingServerId: startingServerId ?? 'A0',
      startingServerTeam: startingServerTeam,
      initialPlayerSides: playerSides,
      initialPlayerTeams: playerTeams,
    );
    _stateSnapshots.add(scoringState);

    for (final event in events) {
      if (event.scorerTeam != null &&
          event.eventType != 'game_end' &&
          event.eventType != 'match_end' &&
          scoringState.isGameInProgress) {
        try {
          final team = event.scorerTeam == 'A' ? Team.A : Team.B;
          final result = ScoringService.recordPoint(scoringState, team);
          scoringState = result.newState;
        } catch (_) {}
      }
      _stateSnapshots.add(scoringState);
    }

    state = LiveMatchState(
      match: current.match,
      players: current.players,
      events: events,
      scoringState: scoringState,
    );
  }

  /// Ends the match and archives it.
  Future<int?> endMatch() async {
    final current = state;
    if (current == null) return null;

    // Flush any pending writes before archiving — completeMatch deletes
    // the active score_events table, which would orphan in-flight inserts.
    await _flushPendingWrites();

    final finalScores = <Map<String, dynamic>>[];
    for (var g = 1; g <= current.scoringState.currentGame; g++) {
      final gameEvents = current.events
          .where((e) => e.gameNumber == g)
          .toList();
      final lastEvent = gameEvents.isNotEmpty ? gameEvents.last : null;
      finalScores.add({
        'game': g,
        'teamA': lastEvent?.teamAScore ?? 0,
        'teamB': lastEvent?.teamBScore ?? 0,
      });
    }

    final winner = current.scoringState.teamAGamesWon >
            current.scoringState.teamBGamesWon
        ? 'A'
        : 'B';

    final durationSeconds = DateTime.now()
        .difference(current.match.createdAt)
        .inSeconds;

    final completedId = await _db.completeMatch(
      match: current.match,
      currentGame: current.scoringState.currentGame,
      players: current.players,
      events: current.events,
      finalScoresJson: jsonEncode(finalScores),
      winner: winner,
      durationSeconds: durationSeconds,
      startedAt: current.match.createdAt,
    );

    // The DB is now authoritative: no active rows exist. Bring the
    // in-memory + dependent caches into sync so the rest of the app
    // doesn't keep rendering the just-archived match.
    //
    // - `state = null` → LiveMatchScreen's `liveState == null` branch
    //   renders a "No active match" fallback if any code path lands the
    //   user back on /match/live without navigating away.
    // - `_stateSnapshots.clear()` → undo history for a finished match
    //   is no longer meaningful; carrying it forward is just dead memory.
    // - `invalidate(activeMatchProvider)` → HomeScreen's ResumeBanner
    //   re-queries `db.getActiveMatch()` and receives `null`,
    //   so the banner disappears instead of pointing at a dead row.
    // - `invalidate(completedMatchesProvider)` → the just-archived
    //   match appears in Home → Match History without a manual refresh.
    state = null;
    _stateSnapshots.clear();
    _ref.invalidate(activeMatchProvider);
    _ref.invalidate(completedMatchesProvider);

    return completedId;
  }

  /// Returns the server's display name.
  String? get serverDisplayName {
    final s = state;
    if (s == null || s.servingPlayerId == null) return null;
    return s.playerName(s.servingPlayerId!);
  }
}

/// Provider for the live match notifier.
final liveMatchProvider =
    StateNotifierProvider<LiveMatchNotifier, LiveMatchState?>((ref) {
  return LiveMatchNotifier(ref);
});

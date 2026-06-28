import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../models/tournament.dart';
import 'database_provider.dart';

// ── Tournament List Provider ──

/// All tournaments, most recent first.
final tournamentsProvider =
    FutureProvider<List<Tournament>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getTournaments();
});

// ── Single Tournament Provider ──

/// A single tournament by ID, parsed into a full [TournamentData] object.
final tournamentProvider =
    FutureProvider.family<TournamentData?, int>((ref, id) async {
  final db = ref.watch(databaseProvider);
  final row = await db.getTournament(id);
  if (row == null) return null;

  return _parseTournament(row);
});

// ── Tournament Notifier (create, advance, delete) ──

class TournamentNotifier extends StateNotifier<TournamentData?> {
  final Ref _ref;
  final int? _tournamentId;

  TournamentNotifier(this._ref, this._tournamentId) : super(null);

  AppDatabase get _db => _ref.read(databaseProvider);

  /// Loads tournament data from the database.
  Future<void> load() async {
    if (_tournamentId == null) return;
    final row = await _db.getTournament(_tournamentId);
    if (row == null) {
      state = null;
      return;
    }
    state = _parseTournament(row);
  }

  /// Deletes the tournament from the database.
  Future<void> deleteTournament() async {
    if (_tournamentId == null) return;
    await _db.deleteTournament(_tournamentId);
    state = null;
    _ref.invalidate(tournamentsProvider);
  }

  /// Updates mutable metadata (name + players) and cascades the rename
  /// through bracket matches so completed match references stay in sync.
  ///
  /// Pass the new [name] and [players] list (with seeds preserved).
  /// Returns true on success. The state is reloaded to reflect persisted
  /// changes immediately.
  Future<bool> updateMeta({
    required String name,
    required List<TournamentPlayer> players,
  }) async {
    if (_tournamentId == null) return false;
    final current = state;
    if (current == null) return false;

    // Build a name-rename map: oldName -> newName, skipping unchanged.
    final renameMap = <String, String>{};
    for (final newPlayer in players) {
      final oldPlayer = current.players.firstWhere(
        (p) => p.seed == newPlayer.seed,
        orElse: () => TournamentPlayer(name: '', seed: newPlayer.seed),
      );
      final oldTrimmed = oldPlayer.name.trim();
      final newTrimmed = newPlayer.name.trim();
      if (oldTrimmed != newTrimmed && oldTrimmed.isNotEmpty) {
        renameMap[oldTrimmed] = newTrimmed;
      }
    }

    // Cascade renames into the bracket: playerA/B/winner references.
    // scoreJson stores only numeric game scores (see BracketMatch
    // `scoreJson` docs and live_match_provider where it's built), so
    // no name cascade is required there.
    final updatedBracket = current.bracket == null
        ? null
        : _cascadeRenames(current.bracket!, renameMap);

    final playersJson =
        jsonEncode(players.map((p) => p.toJson()).toList());
    await _db.updateTournamentMeta(
      tournamentId: _tournamentId,
      name: name.trim().isEmpty ? 'Tournament' : name.trim(),
      playersJson: playersJson,
      bracketJson:
          updatedBracket?.toJsonString() ?? current.bracket?.toJsonString() ?? '',
    );

    // Reload state from DB so downstream watchers see fresh data.
    await load();
    _ref.invalidate(tournamentsProvider);
    return true;
  }

  /// Walk the bracket and replace every occurrence of an old name with
  /// its new one across playerA/B/winner fields.
  TournamentBracket _cascadeRenames(
      TournamentBracket bracket, Map<String, String> renameMap) {
    if (renameMap.isEmpty) return bracket;
    final updatedRounds = bracket.rounds.map((round) {
      final updatedMatches = round.matches.map((match) {
        BracketMatch updated = match;
        updated = _renameInMatch(updated, 'A', renameMap);
        updated = _renameInMatch(updated, 'B', renameMap);
        final w = match.winnerName;
        if (w != null && renameMap.containsKey(w)) {
          updated = updated.copyWith(winnerName: renameMap[w]);
        }
        return updated;
      }).toList();
      return BracketRound(name: round.name, matches: updatedMatches);
    }).toList();
    return bracket.copyWith(rounds: updatedRounds);
  }

  BracketMatch _renameInMatch(
      BracketMatch match, String side, Map<String, String> renameMap) {
    final old =
        side == 'A' ? match.playerAName : match.playerBName;
    if (old != null && renameMap.containsKey(old)) {
      return side == 'A'
          ? match.copyWith(playerAName: renameMap[old])
          : match.copyWith(playerBName: renameMap[old]);
    }
    return match;
  }
}

/// Provider for the tournament notifier, keyed by tournament ID.
final tournamentNotifierProvider =
    StateNotifierProvider.family<TournamentNotifier, TournamentData?, int>(
  (ref, id) => TournamentNotifier(ref, id),
);

// ── Helpers ──

/// Parses a Drift [Tournament] row into a [TournamentData] object.
TournamentData _parseTournament(Tournament row) {
  final format = TournamentFormatX.fromJson(row.format);
  final status = _parseStatus(row.status);
  final players = (jsonDecode(row.playersJson) as List<dynamic>)
      .map((p) => TournamentPlayer.fromJson(p as Map<String, dynamic>))
      .toList();
  final bracket = row.bracketJson != null
      ? TournamentBracket.fromJsonString(row.bracketJson!)
      : null;

  return TournamentData(
    id: row.id,
    name: row.name,
    format: format,
    type: row.type,
    scoringRule: row.scoringRule,
    playTo: row.playTo,
    winBy: row.winBy,
    gameCount: row.gameCount,
    status: status,
    players: players,
    bracket: bracket,
    createdAt: row.createdAt,
    completedAt: row.completedAt,
  );
}

TournamentStatus _parseStatus(String s) {
  switch (s) {
    case 'in_progress':
      return TournamentStatus.inProgress;
    case 'completed':
      return TournamentStatus.completed;
    default:
      return TournamentStatus.setup;
  }
}

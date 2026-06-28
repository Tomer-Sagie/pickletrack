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

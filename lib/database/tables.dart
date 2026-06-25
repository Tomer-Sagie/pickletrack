// ignore_for_file: recursive_getters
import 'package:drift/drift.dart';

/// The single in-progress match. Only one row at a time.
class ActiveMatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type =>
      text().check(type.equals('singles') | type.equals('doubles'))();
  TextColumn get scoringRule => text()
      .named('scoring_rule')
      .check(scoringRule.equals('sideout') | scoringRule.equals('rally'))();
  IntColumn get gameCount =>
      integer().named('game_count').withDefault(const Constant(1))();
  IntColumn get playTo =>
      integer().named('play_to').withDefault(const Constant(11))();
  IntColumn get winBy =>
      integer().named('win_by').withDefault(const Constant(2))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  TextColumn get status => text()
      .withDefault(const Constant('setup'))
      .check(status.equals('setup') | status.equals('live') | status.equals('paused'))();
}

/// Players in the active match (2 or 4 rows).
class ActiveMatchPlayers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get matchId =>
      integer().named('match_id').references(ActiveMatches, #id)();
  TextColumn get name => text()();
  TextColumn get team =>
      text().check(team.equals('A') | team.equals('B'))();
  BoolColumn get isStartingServer =>
      boolean().named('is_starting_server').withDefault(const Constant(false))();
  TextColumn get position =>      text().nullable().check(position.equals('left') | position.equals('right'))();
  IntColumn get serverNumber =>
      integer().named('server_number').nullable()();
}

/// Append-only log of every score event. Supports unlimited undo by deleting from tail.
class ScoreEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get matchId => integer().named('match_id').references(ActiveMatches, #id)();
  IntColumn get gameNumber => integer().named('game_number')();
  TextColumn get eventType =>      text().named('event_type').check(eventType.equals('point') |
        eventType.equals('sideout') | eventType.equals('side_switch') |
        eventType.equals('game_end') | eventType.equals('match_end'))();
  TextColumn get scorerTeam =>
      text().named('scorer_team').nullable().check(
          scorerTeam.equals('A') | scorerTeam.equals('B'))();
  TextColumn get serverName => text().named('server_name').nullable()();
  IntColumn get teamAScore => integer().named('team_a_score')();
  IntColumn get teamBScore => integer().named('team_b_score')();
  IntColumn get serverNumber => integer().named('server_number').nullable()();
  DateTimeColumn get timestamp => dateTime()();
}

/// Completed match archive.
class CompletedMatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type =>
      text().check(type.equals('singles') | type.equals('doubles'))();
  TextColumn get scoringRule => text()
      .named('scoring_rule')
      .check(scoringRule.equals('sideout') | scoringRule.equals('rally'))();
  IntColumn get gameCount => integer().named('game_count')();
  IntColumn get gamesPlayed => integer().named('games_played')();
  IntColumn get playTo => integer().named('play_to')();
  IntColumn get winBy => integer().named('win_by')();
  TextColumn get teamAPlayers =>
      text().named('team_a_players')(); // JSON array
  TextColumn get teamBPlayers =>
      text().named('team_b_players')(); // JSON array
  TextColumn get finalScores =>
      text().named('final_scores')(); // JSON array
  TextColumn get winner =>
      text().check(winner.equals('A') | winner.equals('B'))();
  IntColumn get durationSeconds => integer().named('duration_seconds')();
  DateTimeColumn get startedAt => dateTime().named('started_at')();
  DateTimeColumn get completedAt => dateTime().named('completed_at')();
}

/// Frozen copy of score events for a completed match.
class MatchEventLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get completedMatchId => integer()
      .named('completed_match_id')
      .references(CompletedMatches, #id)();
  IntColumn get gameNumber => integer().named('game_number')();
  TextColumn get eventType => text().named('event_type')();
  TextColumn get scorerTeam =>
      text().named('scorer_team').nullable()();
  TextColumn get serverName => text().named('server_name').nullable()();
  IntColumn get teamAScore => integer().named('team_a_score')();
  IntColumn get teamBScore => integer().named('team_b_score')();
  IntColumn get serverNumber => integer().named('server_number').nullable()();
  DateTimeColumn get timestamp => dateTime()();
}

/// Recent player names for autocomplete. Max 20 rows, pruned on insert.
class RecentPlayers extends Table {
  TextColumn get name => text()();
  DateTimeColumn get lastUsed => dateTime().named('last_used')();
  IntColumn get usageCount =>
      integer().named('usage_count').withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {name};
}

/// App settings stored as key-value pairs.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

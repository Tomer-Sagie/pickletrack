import 'package:flutter_test/flutter_test.dart';
import 'package:pickletrack/models/scoring_preset.dart';
import 'package:pickletrack/services/scoring_service.dart';

// ── ScoringPreset ──

void main() {
  group('ScoringPreset', () {
    test('Quick preset has correct values', () {
      expect(ScoringPreset.quick.name, 'Quick');
      expect(ScoringPreset.quick.playTo, 7);
      expect(ScoringPreset.quick.winBy, 2);
      expect(ScoringPreset.quick.isCustom, false);
    });

    test('Standard preset has correct values', () {
      expect(ScoringPreset.standard.name, 'Standard');
      expect(ScoringPreset.standard.playTo, 11);
      expect(ScoringPreset.standard.winBy, 2);
    });

    test('Tournament preset has correct values', () {
      expect(ScoringPreset.tournament.name, 'Tournament');
      expect(ScoringPreset.tournament.playTo, 15);
      expect(ScoringPreset.tournament.winBy, 2);
    });

    test('Custom preset validates bounds', () {
      final p = ScoringPreset.custom(playTo: 21, winBy: 3);
      expect(p.name, 'Custom');
      expect(p.playTo, 21);
      expect(p.winBy, 3);
      expect(p.isCustom, true);
    });

    test('Custom preset label formatting', () {
      expect(ScoringPreset.standard.label, 'Standard (11, win by 2)');
      expect(ScoringPreset.quick.label, 'Quick (7, win by 2)');
    });

    test('Equality works', () {
      final a = ScoringPreset.custom(playTo: 11, winBy: 2);
      final b = ScoringPreset.custom(playTo: 11, winBy: 2);
      final c = ScoringPreset.custom(playTo: 15, winBy: 2);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('HashCode is consistent with equality', () {
      final a = ScoringPreset.custom(playTo: 11, winBy: 2);
      final b = ScoringPreset.custom(playTo: 11, winBy: 2);
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  // ── MatchState ──

  group('MatchState', () {
    late MatchState doublesSideOut;
    late MatchState singlesState;

    setUp(() {
      doublesSideOut = ScoringService.createInitialState(
        type: MatchType.doubles,
        rule: ScoringRule.sideout,
        preset: ScoringPreset.standard,
        gameCount: 1,
        startingServerId: 'A0',
        startingServerTeam: Team.A,
        initialPlayerSides: {
          'A0': 'right',
          'A1': 'left',
          'B0': 'right',
          'B1': 'left',
        },
        initialPlayerTeams: {
          'A0': 'A',
          'A1': 'A',
          'B0': 'B',
          'B1': 'B',
        },
      );

      singlesState = ScoringService.createInitialState(
        type: MatchType.singles,
        rule: ScoringRule.sideout,
        preset: ScoringPreset.standard,
        gameCount: 1,
        startingServerId: 'A0',
        startingServerTeam: Team.A,
        initialPlayerSides: {'A0': 'right', 'B0': 'left'},
        initialPlayerTeams: {'A0': 'A', 'B0': 'B'},
      );
    });

    test('scoreCallout for doubles shows 0-0-2', () {
      expect(doublesSideOut.scoreCallout, '0-0-2');
    });

    test('scoreCallout for singles shows 0-0', () {
      expect(singlesState.scoreCallout, '0-0');
    });

    test('scoreCallout after point in doubles shows 1-0-2 (no server change on point)', () {
      final result = ScoringService.recordPoint(doublesSideOut, Team.A);
      expect(result.newState.scoreCallout, '1-0-2');
    });

    test('isGameOver is false at start', () {
      expect(doublesSideOut.isGameOver, false);
      expect(singlesState.isGameOver, false);
    });

    test('isGameOver is true when team reaches 11 with 2-point lead', () {
      final state = doublesSideOut.copyWith(teamAScore: 11, teamBScore: 5);
      expect(state.isGameOver, true);
    });

    test('isGameOver is false at 11-10 (not enough margin)', () {
      final state = doublesSideOut.copyWith(teamAScore: 11, teamBScore: 10);
      expect(state.isGameOver, false);
    });

    test('isGameOver is true at 12-10', () {
      final state = doublesSideOut.copyWith(teamAScore: 12, teamBScore: 10);
      expect(state.isGameOver, true);
    });

    test('gameWinner returns correct team', () {
      final state = doublesSideOut.copyWith(teamAScore: 11, teamBScore: 3);
      expect(state.gameWinner, Team.A);
    });

    test('gameWinner returns null when game is not over', () {
      expect(doublesSideOut.gameWinner, null);
    });

    test('isMatchOver for 1-game match after 1 win', () {
      final state = doublesSideOut.copyWith(teamAGamesWon: 1);
      expect(state.isMatchOver, true);
    });

    test('isMatchOver for best-of-3 after 2 wins', () {
      final state = ScoringService.createInitialState(
        type: MatchType.doubles,
        rule: ScoringRule.sideout,
        preset: ScoringPreset.standard,
        gameCount: 3,
        startingServerId: 'A0',
        startingServerTeam: Team.A,
        initialPlayerSides: {'A0': 'r', 'A1': 'l', 'B0': 'r', 'B1': 'l'},
        initialPlayerTeams: {'A0': 'A', 'A1': 'A', 'B0': 'B', 'B1': 'B'},
      );
      final won = state.copyWith(teamAGamesWon: 2);
      expect(won.isMatchOver, true);
    });

    test('isMatchOver for best-of-3 after 1 win each is false', () {
      final state = ScoringService.createInitialState(
        type: MatchType.doubles,
        rule: ScoringRule.sideout,
        preset: ScoringPreset.standard,
        gameCount: 3,
        startingServerId: 'A0',
        startingServerTeam: Team.A,
        initialPlayerSides: {'A0': 'r', 'A1': 'l', 'B0': 'r', 'B1': 'l'},
        initialPlayerTeams: {'A0': 'A', 'A1': 'A', 'B0': 'B', 'B1': 'B'},
      );
      final tied = state.copyWith(teamAGamesWon: 1, teamBGamesWon: 1);
      expect(tied.isMatchOver, false);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = doublesSideOut.copyWith(teamAScore: 5);
      expect(updated.teamAScore, 5);
      expect(updated.teamBScore, 0);
      expect(updated.serverTeam, 'A');
      expect(updated.type, MatchType.doubles);
    });
  });

  // ── ScoringService: Initial State ──

  group('ScoringService.createInitialState', () {
    test('sets correct initial values for doubles', () {
      final state = ScoringService.createInitialState(
        type: MatchType.doubles,
        rule: ScoringRule.sideout,
        preset: ScoringPreset.standard,
        gameCount: 3,
        startingServerId: 'A0',
        startingServerTeam: Team.A,
        initialPlayerSides: {'A0': 'right', 'A1': 'left', 'B0': 'right', 'B1': 'left'},
        initialPlayerTeams: {'A0': 'A', 'A1': 'A', 'B0': 'B', 'B1': 'B'},
      );

      expect(state.currentGame, 1);
      expect(state.teamAScore, 0);
      expect(state.teamBScore, 0);
      expect(state.serverTeam, 'A');
      expect(state.serverNumber, 2); // doubles starts at 0-0-2
      expect(state.currentServerId, 'A0');
      expect(state.serverSide, 'right');
      expect(state.firstServerTeam, 'A');
      expect(state.playTo, 11);
      expect(state.winBy, 2);
      expect(state.gameCount, 3);
    });

    test('sets correct initial values for singles', () {
      final state = ScoringService.createInitialState(
        type: MatchType.singles,
        rule: ScoringRule.rally,
        preset: ScoringPreset.quick,
        gameCount: 1,
        startingServerId: 'B0',
        startingServerTeam: Team.B,
        initialPlayerSides: {'A0': 'right', 'B0': 'left'},
        initialPlayerTeams: {'A0': 'A', 'B0': 'B'},
      );

      expect(state.serverTeam, 'B');
      expect(state.serverNumber, 0);
      expect(state.currentServerId, 'B0');
      expect(state.firstServerTeam, 'B');
      expect(state.playTo, 7);
    });
  });

  // ── ScoringService: Side-Out Scoring ──

  group('Side-out scoring', () {
    late MatchState state;

    setUp(() {
      state = ScoringService.createInitialState(
        type: MatchType.doubles,
        rule: ScoringRule.sideout,
        preset: ScoringPreset.standard,
        gameCount: 1,
        startingServerId: 'A0',
        startingServerTeam: Team.A,
        initialPlayerSides: {
          'A0': 'right',
          'A1': 'left',
          'B0': 'right',
          'B1': 'left',
        },
        initialPlayerTeams: {
          'A0': 'A',
          'A1': 'A',
          'B0': 'B',
          'B1': 'B',
        },
      );
    });

    test('serving team scores a point', () {
      final result = ScoringService.recordPoint(state, Team.A);
      expect(result.eventType, 'point');
      expect(result.scorerTeam, 'A');
      expect(result.newState.teamAScore, 1);
      expect(result.newState.teamBScore, 0);
      expect(result.newState.serverTeam, 'A'); // still serving
    });

    test('non-serving team triggers side-out, no point scored', () {
      final result = ScoringService.recordPoint(state, Team.B);
      expect(result.eventType, 'sideout');
      expect(result.newState.teamAScore, 0);
      expect(result.newState.teamBScore, 0);
      expect(result.newState.serverNumber, 1); // server 2 lost → side-out to Server 1 on Team B
    });

    test('doubles rotation: server 2 loses → full side-out to other team', () {
      // Initial state: server 2 at 0-0-2
      // If Team B wins the rally → full side-out (because it's server 2)
      final r1 = ScoringService.recordPoint(state, Team.B);
      expect(r1.eventType, 'sideout');
      expect(r1.newState.serverTeam, 'B');
      expect(r1.newState.serverNumber, 1);
    });

    test('doubles rotation: server 1 loses → server 2 serves (not full side-out)', () {
      // Step 1: Server 2 of Team A loses → full side-out to Team B, Server 1
      final r1 = ScoringService.recordPoint(state, Team.B);
      expect(r1.newState.serverTeam, 'B');
      expect(r1.newState.serverNumber, 1);

      // Step 2: Team B's Server 1 loses → should go to Team B's Server 2 (partner)
      final r2 = ScoringService.recordPoint(r1.newState, Team.A);
      expect(r2.eventType, 'sideout');
      expect(r2.newState.serverTeam, 'B'); // same team
      expect(r2.newState.serverNumber, 2); // rotated to server 2
      expect(r2.newState.currentServerId, 'B1'); // partner of B0
    });

    test('doubles rotation: after full side-out, new team starts at server 1', () {
      // In the initial state at 0-0-2, server 2 of Team A is serving
      // If Team B wins the rally → full side-out (because it's server 2)
      final r1 = ScoringService.recordPoint(state, Team.B);
      expect(r1.eventType, 'sideout');
      expect(r1.newState.serverTeam, 'B');
      expect(r1.newState.serverNumber, 1);
      expect(r1.newState.currentServerId, 'B0'); // B0 is on right
      expect(r1.newState.serverSide, 'right');
    });

    test('scoring multiple points with same server alternates server side', () {
      // A scores point 1
      final r1 = ScoringService.recordPoint(state, Team.A);
      expect(r1.newState.teamAScore, 1);
      expect(r1.newState.serverSide, 'left'); // A0 moved to left (alternated)

      // A scores point 2
      final r2 = ScoringService.recordPoint(r1.newState, Team.A);
      expect(r2.newState.teamAScore, 2);
      expect(r2.newState.serverSide, 'right'); // back to right
    });

    test('throws when trying to score after game over', () {
      final done = state.copyWith(teamAScore: 11, teamBScore: 3);
      expect(() => ScoringService.recordPoint(done, Team.A), throwsStateError);
    });
  });

  // ── ScoringService: Rally Scoring ──

  group('Rally scoring', () {
    late MatchState state;

    setUp(() {
      state = ScoringService.createInitialState(
        type: MatchType.doubles,
        rule: ScoringRule.rally,
        preset: ScoringPreset.standard,
        gameCount: 1,
        startingServerId: 'A0',
        startingServerTeam: Team.A,
        initialPlayerSides: {
          'A0': 'right',
          'A1': 'left',
          'B0': 'right',
          'B1': 'left',
        },
        initialPlayerTeams: {
          'A0': 'A',
          'A1': 'A',
          'B0': 'B',
          'B1': 'B',
        },
      );
    });

    test('serving team scores a point', () {
      final result = ScoringService.recordPoint(state, Team.A);
      expect(result.eventType, 'point');
      expect(result.scorerTeam, 'A');
      expect(result.newState.teamAScore, 1);
      expect(result.newState.teamBScore, 0);
    });

    test('non-serving team scores — point + full side-out', () {
      final result = ScoringService.recordPoint(state, Team.B);
      expect(result.eventType, 'point');
      expect(result.scorerTeam, 'B');
      expect(result.newState.teamBScore, 1);
      expect(result.newState.teamAScore, 0);
      expect(result.newState.serverTeam, 'B');
      expect(result.newState.serverNumber, 1);
    });

    test('both teams can score in rally scoring', () {
      final r1 = ScoringService.recordPoint(state, Team.A);
      expect(r1.newState.teamAScore, 1);

      final r2 = ScoringService.recordPoint(r1.newState, Team.B);
      expect(r2.newState.teamBScore, 1);
      expect(r2.newState.teamAScore, 1);
    });

    test('singles rally: non-server scores a point + triggers side-out', () {
      final singles = ScoringService.createInitialState(
        type: MatchType.singles,
        rule: ScoringRule.rally,
        preset: ScoringPreset.standard,
        gameCount: 1,
        startingServerId: 'A0',
        startingServerTeam: Team.A,
        initialPlayerSides: {'A0': 'right', 'B0': 'left'},
        initialPlayerTeams: {'A0': 'A', 'B0': 'B'},
      );

      // B scores while A is serving in rally singles
      final result = ScoringService.recordPoint(singles, Team.B);
      expect(result.eventType, 'point');
      expect(result.scorerTeam, 'B');
      expect(result.newState.teamBScore, 1);
      expect(result.newState.serverTeam, 'B'); // side-out
    });

    test('singles rally: server scores, side changes with parity', () {
      final singles = ScoringService.createInitialState(
        type: MatchType.singles,
        rule: ScoringRule.rally,
        preset: ScoringPreset.standard,
        gameCount: 1,
        startingServerId: 'A0',
        startingServerTeam: Team.A,
        initialPlayerSides: {'A0': 'right', 'B0': 'left'},
        initialPlayerTeams: {'A0': 'A', 'B0': 'B'},
      );

      final r1 = ScoringService.recordPoint(singles, Team.A);
      expect(r1.newState.teamAScore, 1);
      expect(r1.newState.serverSide, 'left');
    });
  });

  // ── ScoringService: Singles ──

  group('Singles scoring', () {
    late MatchState state;

    setUp(() {
      state = ScoringService.createInitialState(
        type: MatchType.singles,
        rule: ScoringRule.sideout,
        preset: ScoringPreset.standard,
        gameCount: 1,
        startingServerId: 'A0',
        startingServerTeam: Team.A,
        initialPlayerSides: {'A0': 'right', 'B0': 'left'},
        initialPlayerTeams: {'A0': 'A', 'B0': 'B'},
      );
    });

    test('serving team scores, server side changes with parity', () {
      final r1 = ScoringService.recordPoint(state, Team.A);
      expect(r1.newState.teamAScore, 1);
      expect(r1.newState.serverSide, 'left'); // odd score → left

      final r2 = ScoringService.recordPoint(r1.newState, Team.A);
      expect(r2.newState.teamAScore, 2);
      expect(r2.newState.serverSide, 'right'); // even score → right
    });

    test('non-serving team triggers side-out, no point scored', () {
      final r1 = ScoringService.recordPoint(state, Team.B);
      expect(r1.eventType, 'sideout');
      expect(r1.newState.serverTeam, 'B');
      expect(r1.newState.teamAScore, 0);
      expect(r1.newState.teamBScore, 0);
    });

    test('new server serves from correct side based on score parity', () {
      // A scores 1 point, then B gets side-out
      final r1 = ScoringService.recordPoint(state, Team.A);
      final r2 = ScoringService.recordPoint(r1.newState, Team.B);
      expect(r2.newState.serverTeam, 'B');
      // B has 0 points (even) → serves from right
      expect(r2.newState.serverSide, 'right');
    });
  });

  // ── ScoringService: Game End ──

  group('Game end', () {
    test('game ends when team reaches 11-5 in side-out', () {
      final state = ScoringService.createInitialState(
        type: MatchType.doubles,
        rule: ScoringRule.sideout,
        preset: ScoringPreset.standard,
        gameCount: 3,
        startingServerId: 'A0',
        startingServerTeam: Team.A,
        initialPlayerSides: {'A0': 'r', 'A1': 'l', 'B0': 'r', 'B1': 'l'},
        initialPlayerTeams: {'A0': 'A', 'A1': 'A', 'B0': 'B', 'B1': 'B'},
      );

      final nearEnd = state.copyWith(teamAScore: 10, teamBScore: 5);
      final result = ScoringService.recordPoint(nearEnd, Team.A);

      expect(result.eventType, 'game_end');
      expect(result.newState.teamAGamesWon, 1);
      // Scores should reset for next game
      expect(result.newState.teamAScore, 0);
      expect(result.newState.teamBScore, 0);
      expect(result.newState.currentGame, 2);
    });

    test('match ends in best-of-3 after 2 wins', () {
      final state = ScoringService.createInitialState(
        type: MatchType.doubles,
        rule: ScoringRule.sideout,
        preset: ScoringPreset.standard,
        gameCount: 3,
        startingServerId: 'A0',
        startingServerTeam: Team.A,
        initialPlayerSides: {'A0': 'r', 'A1': 'l', 'B0': 'r', 'B1': 'l'},
        initialPlayerTeams: {'A0': 'A', 'A1': 'A', 'B0': 'B', 'B1': 'B'},
      );

      final g1End = state.copyWith(teamAGamesWon: 1, currentGame: 2);
      final nearEnd = g1End.copyWith(teamAScore: 10, teamBScore: 5);
      final result = ScoringService.recordPoint(nearEnd, Team.A);

      expect(result.eventType, 'match_end');
      expect(result.newState.teamAGamesWon, 2);
      expect(result.newState.isMatchOver, true);
    });

    test('side swap on game end: left and right are swapped', () {
      final state = ScoringService.createInitialState(
        type: MatchType.doubles,
        rule: ScoringRule.sideout,
        preset: ScoringPreset.standard,
        gameCount: 3,
        startingServerId: 'A0',
        startingServerTeam: Team.A,
        initialPlayerSides: {'A0': 'right', 'A1': 'left', 'B0': 'right', 'B1': 'left'},
        initialPlayerTeams: {'A0': 'A', 'A1': 'A', 'B0': 'B', 'B1': 'B'},
      );

      final nearEnd = state.copyWith(teamAScore: 10, teamBScore: 5);
      final result = ScoringService.recordPoint(nearEnd, Team.A);

      // After point (server alternates: A0 right→left, A1 left→right)
      // then game-end side swap (all players swap again):
      // A0: left→right, A1: right→left, B0: right→left, B1: left→right
      expect(result.newState.playerSides['A0'], 'right');
      expect(result.newState.playerSides['A1'], 'left');
      expect(result.newState.playerSides['B0'], 'left');
      expect(result.newState.playerSides['B1'], 'right');
    });

    test('server team alternates between games', () {
      // B served first in game 1, so on game 2 (even), A should serve
      final state = ScoringService.createInitialState(
        type: MatchType.doubles,
        rule: ScoringRule.sideout,
        preset: ScoringPreset.standard,
        gameCount: 3,
        startingServerId: 'B0',
        startingServerTeam: Team.B,
        initialPlayerSides: {'A0': 'right', 'A1': 'left', 'B0': 'right', 'B1': 'left'},
        initialPlayerTeams: {'A0': 'A', 'A1': 'A', 'B0': 'B', 'B1': 'B'},
      );

      final nearEnd = state.copyWith(teamBScore: 10, teamAScore: 5);
      final result = ScoringService.recordPoint(nearEnd, Team.B);

      expect(result.eventType, 'game_end');
      // Game 2 (even) → opposite of first server team (B) → A
      expect(result.newState.serverTeam, 'A');
      expect(result.newState.currentGame, 2);
    });

    test('game not over at 10-10', () {
      final state = ScoringService.createInitialState(
        type: MatchType.doubles,
        rule: ScoringRule.sideout,
        preset: ScoringPreset.standard,
        gameCount: 1,
        startingServerId: 'A0',
        startingServerTeam: Team.A,
        initialPlayerSides: {'A0': 'r', 'A1': 'l', 'B0': 'r', 'B1': 'l'},
        initialPlayerTeams: {'A0': 'A', 'A1': 'A', 'B0': 'B', 'B1': 'B'},
      );

      final near = state.copyWith(teamAScore: 10, teamBScore: 10);
      final result = ScoringService.recordPoint(near, Team.A);

      expect(result.eventType, 'point');
      expect(result.newState.isGameOver, false);
      expect(result.newState.teamAScore, 11);
    });
  });

  // ── ScoringService: hasTeamWon ──

  group('hasTeamWon', () {
    test('returns true when score meets threshold with margin', () {
      expect(ScoringService.hasTeamWon(11, 5, 11, 2), true);
    });

    test('returns false when score meets threshold but lacks margin', () {
      expect(ScoringService.hasTeamWon(11, 10, 11, 2), false);
    });

    test('returns false when score is below threshold', () {
      expect(ScoringService.hasTeamWon(10, 5, 11, 2), false);
    });

    test('returns true at 12-10 (win by 2 after reaching 11)', () {
      expect(ScoringService.hasTeamWon(12, 10, 11, 2), true);
    });
  });
}

import '../models/scoring_preset.dart';

/// Pure scoring logic for pickleball matches. No dependencies on Flutter or Drift.
/// All methods are static and take immutable state, returning new state.

enum MatchType { singles, doubles }

enum ScoringRule { sideout, rally }

enum Team { A, B }

/// Immutable snapshot of the current match state, used by the scoring service.
class MatchState {
  final MatchType type;
  final ScoringRule rule;
  final int playTo;
  final int winBy;
  final int gameCount;
  final int currentGame;
  final int teamAScore;
  final int teamBScore;
  final int teamAGamesWon;
  final int teamBGamesWon;
  final String? currentServerId; // player id serving
  final int serverNumber; // 1 or 2 for doubles, 0 for singles
  final String? serverTeam; // 'A' or 'B'
  final String? serverSide; // 'left' or 'right' for doubles
  final Map<String, String> playerSides; // playerId -> 'left' | 'right'
  final Map<String, String> playerTeams; // playerId -> 'A' | 'B'
  final String? firstServerTeam; // 'A' or 'B' — who served first in game 1

  const MatchState({
    required this.type,
    required this.rule,
    required this.playTo,
    required this.winBy,
    required this.gameCount,
    this.currentGame = 1,
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.teamAGamesWon = 0,
    this.teamBGamesWon = 0,
    this.currentServerId,
    this.serverNumber = 0,
    this.serverTeam,
    this.serverSide,
    this.playerSides = const {},
    this.playerTeams = const {},
    this.firstServerTeam,
  });

  /// The score callout string (e.g., "3-2-1" for doubles side-out, "3-2" for singles or rally).
  String get scoreCallout {
    // Server number only applies to side-out scoring; in rally scoring
    // the serve rotates every point and server number is not meaningful.
    if (type == MatchType.doubles && rule == ScoringRule.sideout) {
      return '$teamAScore-$teamBScore-$serverNumber';
    }
    return '$teamAScore-$teamBScore';
  }

  /// Whether a game is currently in progress.
  bool get isGameInProgress => !isGameOver;

  /// Whether the current game is over (a team reached playTo and leads by winBy).
  bool get isGameOver {
    if (teamAScore >= playTo && teamAScore - teamBScore >= winBy) return true;
    if (teamBScore >= playTo && teamBScore - teamAScore >= winBy) return true;
    return false;
  }

  /// Which team won the current game, if it's over.
  Team? get gameWinner {
    if (teamAScore >= playTo && teamAScore - teamBScore >= winBy) return Team.A;
    if (teamBScore >= playTo && teamBScore - teamAScore >= winBy) return Team.B;
    return null;
  }

  /// Whether the entire match is over.
  bool get isMatchOver {
    final gamesNeeded = (gameCount ~/ 2) + 1; // 1 for 1-game, 2 for best-of-3
    return teamAGamesWon >= gamesNeeded || teamBGamesWon >= gamesNeeded;
  }

  MatchState copyWith({
    MatchType? type,
    ScoringRule? rule,
    int? playTo,
    int? winBy,
    int? gameCount,
    int? currentGame,
    int? teamAScore,
    int? teamBScore,
    int? teamAGamesWon,
    int? teamBGamesWon,
    String? currentServerId,
    int? serverNumber,
    String? serverTeam,
    String? serverSide,
    Map<String, String>? playerSides,
    Map<String, String>? playerTeams,
    String? firstServerTeam,
  }) {
    return MatchState(
      type: type ?? this.type,
      rule: rule ?? this.rule,
      playTo: playTo ?? this.playTo,
      winBy: winBy ?? this.winBy,
      gameCount: gameCount ?? this.gameCount,
      currentGame: currentGame ?? this.currentGame,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      teamAGamesWon: teamAGamesWon ?? this.teamAGamesWon,
      teamBGamesWon: teamBGamesWon ?? this.teamBGamesWon,
      currentServerId: currentServerId ?? this.currentServerId,
      serverNumber: serverNumber ?? this.serverNumber,
      serverTeam: serverTeam ?? this.serverTeam,
      serverSide: serverSide ?? this.serverSide,
      playerSides: playerSides ?? this.playerSides,
      playerTeams: playerTeams ?? this.playerTeams,
      firstServerTeam: firstServerTeam ?? this.firstServerTeam,
    );
  }
}

/// Result of a scoring action. Describes what happened.
class ScoreResult {
  final MatchState newState;
  final String eventType; // 'point', 'sideout', 'side_switch', 'game_end', 'match_end'
  final String? scorerTeam;
  final String? description;

  const ScoreResult({
    required this.newState,
    required this.eventType,
    this.scorerTeam,
    this.description,
  });
}

/// Pure scoring logic. All methods are static.
class ScoringService {
  ScoringService._();

  // ── Initial State ──

  /// Creates the initial match state from setup parameters.
  static MatchState createInitialState({
    required MatchType type,
    required ScoringRule rule,
    required ScoringPreset preset,
    required int gameCount,
    required String startingServerId,
    required Team startingServerTeam,
    required Map<String, String> initialPlayerSides, // playerId -> 'left'|'right'
    required Map<String, String> initialPlayerTeams, // playerId -> 'A'|'B'
  }) {
    final serverSide =
        initialPlayerSides[startingServerId] ?? 'right';

    // Doubles starts at 0-0-2 (server number 2, only one serve before side-out)
    final initialServerNumber = type == MatchType.doubles ? 2 : 0;

    return MatchState(
      type: type,
      rule: rule,
      playTo: preset.playTo,
      winBy: preset.winBy,
      gameCount: gameCount,
      currentGame: 1,
      teamAScore: 0,
      teamBScore: 0,
      teamAGamesWon: 0,
      teamBGamesWon: 0,
      currentServerId: startingServerId,
      serverNumber: initialServerNumber,
      serverTeam: startingServerTeam == Team.A ? 'A' : 'B',
      serverSide: serverSide,
      playerSides: Map.from(initialPlayerSides),
      playerTeams: Map.from(initialPlayerTeams),
      firstServerTeam: startingServerTeam == Team.A ? 'A' : 'B',
    );
  }

  // ── Point Scored ──

  /// Records a point for [scoringTeam]. Returns the new state and event details.
  static ScoreResult recordPoint(MatchState state, Team scoringTeam) {
    if (!state.isGameInProgress) {
      throw StateError('Cannot score — game is already over.');
    }

    if (state.rule == ScoringRule.sideout) {
      return _recordSideOutPoint(state, scoringTeam);
    } else {
      return _recordRallyPoint(state, scoringTeam);
    }
  }

  /// Side-out scoring: only the serving team can score.
  static ScoreResult _recordSideOutPoint(MatchState state, Team scoringTeam) {
    final servingTeam =
        state.serverTeam == 'A' ? Team.A : Team.B;

    if (scoringTeam == servingTeam) {
      // Serving team scores — increment their score
      var newState = state;
      if (servingTeam == Team.A) {
        newState = newState.copyWith(teamAScore: state.teamAScore + 1);
      } else {
        newState = newState.copyWith(teamBScore: state.teamBScore + 1);
      }

      // Doubles: server alternates sides
      if (state.type == MatchType.doubles) {
        newState = _alternateServerSide(newState);
      } else {
        // Singles: side determined by score parity
        final serverScore =
            servingTeam == Team.A ? newState.teamAScore : newState.teamBScore;
        newState = newState.copyWith(
          serverSide: serverScore.isEven ? 'right' : 'left',
        );
      }

      // Check for game end
      if (newState.isGameOver) {
        return _handleGameEnd(newState, scoringTeam);
      }

      return ScoreResult(
        newState: newState,
        eventType: 'point',
        scorerTeam: scoringTeam == Team.A ? 'A' : 'B',
      );
    } else {
      // Non-serving team — side-out (no point scored)
      final winningTeam = state.serverTeam == 'A' ? 'B' : 'A';
      return _handleSideOut(state, winningTeam: winningTeam);
    }
  }

  /// Rally scoring: any team can score, server changes on rally loss.
  static ScoreResult _recordRallyPoint(MatchState state, Team scoringTeam) {
    var newState = state;
    if (scoringTeam == Team.A) {
      newState = newState.copyWith(teamAScore: state.teamAScore + 1);
    } else {
      newState = newState.copyWith(teamBScore: state.teamBScore + 1);
    }

    final servingTeam =
        state.serverTeam == 'A' ? Team.A : Team.B;

    // If the non-serving team scored, side-out (full side-out in rally scoring)
    if (scoringTeam != servingTeam) {
      newState = _handleSideOut(newState, forceFullSideOut: true, winningTeam: scoringTeam == Team.A ? 'A' : 'B').newState;

      // Check for game end
      if (newState.isGameOver) {
        return _handleGameEnd(newState, scoringTeam);
      }

      return ScoreResult(
        newState: newState,
        eventType: 'point',
        scorerTeam: scoringTeam == Team.A ? 'A' : 'B',
      );
    }

    // Serving team scored — alternate sides (doubles) or score parity (singles)
    if (state.type == MatchType.doubles) {
      newState = _alternateServerSide(newState);
    } else {
      final serverScore =
          servingTeam == Team.A ? newState.teamAScore : newState.teamBScore;
      newState = newState.copyWith(
        serverSide: serverScore.isEven ? 'right' : 'left',
      );
    }

    if (newState.isGameOver) {
      return _handleGameEnd(newState, scoringTeam);
    }

    return ScoreResult(
      newState: newState,
      eventType: 'point',
      scorerTeam: scoringTeam == Team.A ? 'A' : 'B',
    );
  }

  // ── Side-Out ──

  /// Handles a side-out: switches serving team and resets server rotation.
  /// Used by side-out scoring when the non-serving team wins a rally.
  /// Also used by rally scoring when non-server scores — but in that case
  /// we force a full side-out regardless of server number.
  static ScoreResult _handleSideOut(MatchState state,
      {bool forceFullSideOut = false, String? winningTeam}) {
    if (state.type == MatchType.singles) {
      final newTeam = state.serverTeam == 'A' ? 'B' : 'A';
      // In singles, the new server serves from the right if their score is even
      final newServerScore =
          newTeam == 'A' ? state.teamAScore : state.teamBScore;
      return ScoreResult(
        newState: state.copyWith(
          serverTeam: newTeam,
          serverSide: newServerScore.isEven ? 'right' : 'left',
        ),
        eventType: 'sideout',
        scorerTeam: winningTeam,
        description: 'Side out — Team $newTeam serving',
      );
    }

    // Doubles side-out
    // If forceFullSideOut (rally scoring, non-server scored), do a full side-out immediately.
    // Otherwise, follow the standard Server 1 → Server 2 → side-out rotation.
    if (!forceFullSideOut && state.serverNumber == 1) {
      // Server 1 lost — move to Server 2 (partner on same team)
      // Server 2 serves from wherever they're standing
      final partnerId = _findPartnerOnTeam(state, state.serverTeam ?? 'A');
      final partnerSide = state.playerSides[partnerId] ?? 'right';
      return ScoreResult(
        newState: state.copyWith(
          serverNumber: 2,
          currentServerId: partnerId,
          serverSide: partnerSide,
        ),
        eventType: 'sideout',
        scorerTeam: winningTeam,
        description: 'Server 1 out — Server 2 serving',
      );
    } else {
      // Server 2 lost — full side-out to other team
      final newTeam = state.serverTeam == 'A' ? 'B' : 'A';
      // New server is the player on the right side of the new team
      final newServerId = _findPlayerOnSide(state, newTeam, 'right');
      const newServerSide = 'right';

      return ScoreResult(
        newState: state.copyWith(
          serverTeam: newTeam,
          serverNumber: 1,
          currentServerId: newServerId,
          serverSide: newServerSide,
        ),
        eventType: 'sideout',
        scorerTeam: winningTeam,
        description: 'Side out — Team $newTeam serving',
      );
    }
  }

  // ── Game End ──

  /// Handles a game ending.
  static ScoreResult _handleGameEnd(MatchState state, Team winner) {
    var newState = state;
    if (winner == Team.A) {
      newState = newState.copyWith(teamAGamesWon: state.teamAGamesWon + 1);
    } else {
      newState = newState.copyWith(teamBGamesWon: state.teamBGamesWon + 1);
    }

    if (newState.isMatchOver) {
      return ScoreResult(
        newState: newState,
        eventType: 'match_end',
        scorerTeam: winner == Team.A ? 'A' : 'B',
        description: 'Match over! Team ${winner == Team.A ? "A" : "B"} wins!',
      );
    }

    // Advance to next game: side switch, reset scores, server alternates
    final nextGame = state.currentGame + 1;
    // Side switch: swap left/right for each side
    final swappedSides = <String, String>{};
    for (final entry in state.playerSides.entries) {
      swappedSides[entry.key] =
          entry.value == 'left' ? 'right' : 'left';
    }

    // First server of new game: alternates from game 1's first server.
    // Odd games = firstServerTeam, even games = opposite.
    final newServerTeam = _serverTeamForGame(state, nextGame);
    final newServerId = _findPlayerOnSide(
      MatchState(
        playerSides: swappedSides,
        playerTeams: state.playerTeams,
        type: state.type,
        rule: state.rule,
        playTo: state.playTo,
        winBy: state.winBy,
        gameCount: state.gameCount,
      ),
      newServerTeam,
      'right',
    );

    final initialServerNumber = state.type == MatchType.doubles ? 2 : 0;

    newState = newState.copyWith(
      currentGame: nextGame,
      teamAScore: 0,
      teamBScore: 0,
      currentServerId: newServerId,
      serverNumber: initialServerNumber,
      serverTeam: newServerTeam,
      serverSide: 'right',
      playerSides: swappedSides,
    );

    return ScoreResult(
      newState: newState,
      eventType: 'game_end',
      scorerTeam: winner == Team.A ? 'A' : 'B',
      description:
          'Game $nextGame starting — Team $newServerTeam serves',
    );
  }

  // ── Helpers ──

  /// Alternates the server's side in doubles (left ↔ right).
  /// Both players on the serving team swap positions.
  static MatchState _alternateServerSide(MatchState state) {
    final newSide = state.serverSide == 'left' ? 'right' : 'left';
    final newSides = Map<String, String>.from(state.playerSides);
    if (state.currentServerId != null) {
      newSides[state.currentServerId!] = newSide;
    }
    // Partner also swaps sides
    final partnerId = _findPartnerOnTeam(state, state.serverTeam ?? 'A');
    if (partnerId != null) {
      final partnerSide = state.playerSides[partnerId];
      if (partnerSide != null) {
        newSides[partnerId] = partnerSide == 'left' ? 'right' : 'left';
      }
    }
    return state.copyWith(serverSide: newSide, playerSides: newSides);
  }

  /// Finds a player on a given team and side.
  static String? _findPlayerOnSide(
      MatchState state, String team, String side) {
    for (final entry in state.playerSides.entries) {
      final playerId = entry.key;
      final playerTeam = state.playerTeams[playerId];
      if (entry.value == side && playerTeam == team) {
        return playerId;
      }
    }
    return null;
  }

  /// Finds the partner of the current server (same team, other player).
  static String? _findPartnerOnTeam(MatchState state, String team) {
    for (final entry in state.playerTeams.entries) {
      if (entry.value == team && entry.key != state.currentServerId) {
        return entry.key;
      }
    }
    return null;
  }

  /// Returns the team that should serve first in [gameNumber],
  /// alternating from the team that served first in game 1.
  /// Odd games = firstServerTeam, even games = opposite.
  static String _serverTeamForGame(MatchState state, int gameNumber) {
    if (gameNumber.isOdd) {
      return state.firstServerTeam ?? 'A';
    } else {
      return state.firstServerTeam == 'A' ? 'B' : 'A';
    }
  }

  // ── Validation ──

  /// Checks if a team has reached the win condition.
  static bool hasTeamWon(int score, int opponentScore, int playTo, int winBy) {
    return score >= playTo && score - opponentScore >= winBy;
  }
}

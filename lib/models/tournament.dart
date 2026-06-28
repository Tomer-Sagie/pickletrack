import 'dart:convert';

// ── Enums ──

enum TournamentFormat { singleElim, doubleElim, roundRobin }

enum TournamentStatus { setup, inProgress, completed }

enum BracketMatchStatus { pending, ready, inProgress, completed }

enum BracketSide { winners, losers, grandFinal }

// ── Helpers ──

extension TournamentFormatX on TournamentFormat {
  String get label {
    switch (this) {
      case TournamentFormat.singleElim:
        return 'Single Elimination';
      case TournamentFormat.doubleElim:
        return 'Double Elimination';
      case TournamentFormat.roundRobin:
        return 'Round Robin';
    }
  }

  String get shortLabel {
    switch (this) {
      case TournamentFormat.singleElim:
        return 'Single Elim';
      case TournamentFormat.doubleElim:
        return 'Double Elim';
      case TournamentFormat.roundRobin:
        return 'Round Robin';
    }
  }

  String get json {
    switch (this) {
      case TournamentFormat.singleElim:
        return 'single_elim';
      case TournamentFormat.doubleElim:
        return 'double_elim';
      case TournamentFormat.roundRobin:
        return 'round_robin';
    }
  }

  static TournamentFormat fromJson(String s) {
    switch (s) {
      case 'single_elim':
        return TournamentFormat.singleElim;
      case 'double_elim':
        return TournamentFormat.doubleElim;
      case 'round_robin':
        return TournamentFormat.roundRobin;
      default:
        return TournamentFormat.singleElim;
    }
  }
}

extension BracketMatchStatusX on BracketMatchStatus {
  String get json {
    switch (this) {
      case BracketMatchStatus.pending:
        return 'pending';
      case BracketMatchStatus.ready:
        return 'ready';
      case BracketMatchStatus.inProgress:
        return 'in_progress';
      case BracketMatchStatus.completed:
        return 'completed';
    }
  }

  static BracketMatchStatus fromJson(String s) {
    switch (s) {
      case 'pending':
        return BracketMatchStatus.pending;
      case 'ready':
        return BracketMatchStatus.ready;
      case 'in_progress':
        return BracketMatchStatus.inProgress;
      case 'completed':
        return BracketMatchStatus.completed;
      default:
        return BracketMatchStatus.pending;
    }
  }
}

extension BracketSideX on BracketSide {
  String get json {
    switch (this) {
      case BracketSide.winners:
        return 'winners';
      case BracketSide.losers:
        return 'losers';
      case BracketSide.grandFinal:
        return 'grand_final';
    }
  }

  String get label {
    switch (this) {
      case BracketSide.winners:
        return 'Winners';
      case BracketSide.losers:
        return 'Losers';
      case BracketSide.grandFinal:
        return 'Grand Final';
    }
  }

  static BracketSide? fromJson(String? s) {
    switch (s) {
      case 'winners':
        return BracketSide.winners;
      case 'losers':
        return BracketSide.losers;
      case 'grand_final':
        return BracketSide.grandFinal;
      default:
        return null;
    }
  }
}

// ── Model Classes ──

class TournamentPlayer {
  final String name;
  final int seed;
  final int? finalRanking;

  const TournamentPlayer({
    required this.name,
    required this.seed,
    this.finalRanking,
  });

  TournamentPlayer copyWith({String? name, int? seed, int? finalRanking}) {
    return TournamentPlayer(
      name: name ?? this.name,
      seed: seed ?? this.seed,
      finalRanking: finalRanking ?? this.finalRanking,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'seed': seed,
        if (finalRanking != null) 'finalRanking': finalRanking,
      };

  factory TournamentPlayer.fromJson(Map<String, dynamic> json) {
    return TournamentPlayer(
      name: json['name'] as String,
      seed: json['seed'] as int,
      finalRanking: json['finalRanking'] as int?,
    );
  }

  @override
  String toString() => 'TournamentPlayer($name, seed=$seed)';
}

class BracketMatch {
  final int id;
  final int round;
  final String roundName;
  final BracketSide? side;
  final String? playerAName;
  final String? playerBName;
  final int? playerASeed;
  final int? playerBSeed;
  final String? winnerName;
  final int? sourceMatchAId;
  final int? sourceMatchBId;
  final String? scoreJson;
  final BracketMatchStatus status;
  final int? completedMatchId;

  const BracketMatch({
    required this.id,
    required this.round,
    required this.roundName,
    this.side,
    this.playerAName,
    this.playerBName,
    this.playerASeed,
    this.playerBSeed,
    this.winnerName,
    this.sourceMatchAId,
    this.sourceMatchBId,
    this.scoreJson,
    this.status = BracketMatchStatus.pending,
    this.completedMatchId,
  });

  /// Whether both players are known and the match can be started.
  bool get isReady =>
      playerAName != null &&
      playerBName != null &&
      status == BracketMatchStatus.ready;

  /// Whether this match has a bye (one player is null).
  bool get isBye => playerAName == null || playerBName == null;

  /// Display label for player A (name or "TBD").
  String get playerADisplay => playerAName ?? 'TBD';

  /// Display label for player B (name or "TBD").
  String get playerBDisplay => playerBName ?? 'TBD';

  BracketMatch copyWith({
    int? id,
    int? round,
    String? roundName,
    BracketSide? side,
    String? playerAName,
    String? playerBName,
    int? playerASeed,
    int? playerBSeed,
    String? winnerName,
    int? sourceMatchAId,
    int? sourceMatchBId,
    String? scoreJson,
    BracketMatchStatus? status,
    int? completedMatchId,
  }) {
    return BracketMatch(
      id: id ?? this.id,
      round: round ?? this.round,
      roundName: roundName ?? this.roundName,
      side: side ?? this.side,
      playerAName: playerAName ?? this.playerAName,
      playerBName: playerBName ?? this.playerBName,
      playerASeed: playerASeed ?? this.playerASeed,
      playerBSeed: playerBSeed ?? this.playerBSeed,
      winnerName: winnerName ?? this.winnerName,
      sourceMatchAId: sourceMatchAId ?? this.sourceMatchAId,
      sourceMatchBId: sourceMatchBId ?? this.sourceMatchBId,
      scoreJson: scoreJson ?? this.scoreJson,
      status: status ?? this.status,
      completedMatchId: completedMatchId ?? this.completedMatchId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'round': round,
        'roundName': roundName,
        if (side != null) 'side': side!.json,
        'playerAName': playerAName,
        'playerBName': playerBName,
        if (playerASeed != null) 'playerASeed': playerASeed,
        if (playerBSeed != null) 'playerBSeed': playerBSeed,
        'winnerName': winnerName,
        if (sourceMatchAId != null) 'sourceMatchAId': sourceMatchAId,
        if (sourceMatchBId != null) 'sourceMatchBId': sourceMatchBId,
        'scoreJson': scoreJson,
        'status': status.json,
        if (completedMatchId != null) 'completedMatchId': completedMatchId,
      };

  factory BracketMatch.fromJson(Map<String, dynamic> json) {
    return BracketMatch(
      id: json['id'] as int,
      round: json['round'] as int,
      roundName: json['roundName'] as String,
      side: BracketSideX.fromJson(json['side'] as String?),
      playerAName: json['playerAName'] as String?,
      playerBName: json['playerBName'] as String?,
      playerASeed: json['playerASeed'] as int?,
      playerBSeed: json['playerBSeed'] as int?,
      winnerName: json['winnerName'] as String?,
      sourceMatchAId: json['sourceMatchAId'] as int?,
      sourceMatchBId: json['sourceMatchBId'] as int?,
      scoreJson: json['scoreJson'] as String?,
      status: BracketMatchStatusX.fromJson(json['status'] as String? ?? 'pending'),
      completedMatchId: json['completedMatchId'] as int?,
    );
  }

  @override
  String toString() =>
      'BracketMatch($id: $playerADisplay vs $playerBDisplay [$status])';
}

class BracketRound {
  final String name;
  final List<BracketMatch> matches;

  const BracketRound({required this.name, required this.matches});

  Map<String, dynamic> toJson() => {
        'name': name,
        'matches': matches.map((m) => m.toJson()).toList(),
      };

  factory BracketRound.fromJson(Map<String, dynamic> json) {
    return BracketRound(
      name: json['name'] as String,
      matches: (json['matches'] as List<dynamic>)
          .map((m) => BracketMatch.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RoundRobinStanding {
  final String playerName;
  final int wins;
  final int losses;
  final int pointsFor;
  final int pointsAgainst;

  const RoundRobinStanding({
    required this.playerName,
    required this.wins,
    required this.losses,
    required this.pointsFor,
    required this.pointsAgainst,
  });

  int get pointDifferential => pointsFor - pointsAgainst;
  int get gamesPlayed => wins + losses;

  RoundRobinStanding copyWith({
    String? playerName,
    int? wins,
    int? losses,
    int? pointsFor,
    int? pointsAgainst,
  }) {
    return RoundRobinStanding(
      playerName: playerName ?? this.playerName,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      pointsFor: pointsFor ?? this.pointsFor,
      pointsAgainst: pointsAgainst ?? this.pointsAgainst,
    );
  }

  Map<String, dynamic> toJson() => {
        'playerName': playerName,
        'wins': wins,
        'losses': losses,
        'pointsFor': pointsFor,
        'pointsAgainst': pointsAgainst,
      };

  factory RoundRobinStanding.fromJson(Map<String, dynamic> json) {
    return RoundRobinStanding(
      playerName: json['playerName'] as String,
      wins: json['wins'] as int,
      losses: json['losses'] as int,
      pointsFor: json['pointsFor'] as int,
      pointsAgainst: json['pointsAgainst'] as int,
    );
  }
}

class TournamentBracket {
  final TournamentFormat format;
  final List<BracketRound> rounds;
  final List<RoundRobinStanding>? standings;

  const TournamentBracket({
    required this.format,
    required this.rounds,
    this.standings,
  });

  /// Flattens all matches across all rounds.
  List<BracketMatch> get allMatches =>
      rounds.expand((r) => r.matches).toList();

  /// Finds a match by ID across all rounds.
  BracketMatch? findMatch(int matchId) {
    for (final round in rounds) {
      for (final match in round.matches) {
        if (match.id == matchId) return match;
      }
    }
    return null;
  }

  /// All matches that are ready to play (both players known, not started).
  List<BracketMatch> get readyMatches =>
      allMatches.where((m) => m.isReady).toList();

  /// All completed matches.
  List<BracketMatch> get completedMatches =>
      allMatches.where((m) => m.status == BracketMatchStatus.completed).toList();

  /// Total match count.
  int get totalMatches => allMatches.length;

  /// Whether the tournament is fully completed.
  bool get isComplete {
    if (format == TournamentFormat.roundRobin) {
      return allMatches.every((m) => m.status == BracketMatchStatus.completed);
    }
    // For elimination: the final match must be completed
    final lastRound = rounds.last;
    return lastRound.matches.every((m) => m.status == BracketMatchStatus.completed);
  }

  /// The tournament winner (for elimination formats).
  String? get winner {
    if (!isComplete) return null;
    if (format == TournamentFormat.roundRobin) {
      final sorted = sortedStandings;
      return sorted.isNotEmpty ? sorted.first.playerName : null;
    }
    final lastRound = rounds.last;
    return lastRound.matches.first.winnerName;
  }

  /// Sorted standings for round robin (by wins desc, then point diff desc).
  List<RoundRobinStanding> get sortedStandings {
    final s = List<RoundRobinStanding>.from(standings ?? []);
    s.sort((a, b) {
      if (b.wins != a.wins) return b.wins.compareTo(a.wins);
      return b.pointDifferential.compareTo(a.pointDifferential);
    });
    return s;
  }

  TournamentBracket copyWith({
    TournamentFormat? format,
    List<BracketRound>? rounds,
    List<RoundRobinStanding>? standings,
  }) {
    return TournamentBracket(
      format: format ?? this.format,
      rounds: rounds ?? this.rounds,
      standings: standings ?? this.standings,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  Map<String, dynamic> toJson() => {
        'format': format.json,
        'rounds': rounds.map((r) => r.toJson()).toList(),
        if (standings != null)
          'standings': standings!.map((s) => s.toJson()).toList(),
      };

  factory TournamentBracket.fromJson(Map<String, dynamic> json) {
    return TournamentBracket(
      format: TournamentFormatX.fromJson(json['format'] as String? ?? 'single_elim'),
      rounds: (json['rounds'] as List<dynamic>)
          .map((r) => BracketRound.fromJson(r as Map<String, dynamic>))
          .toList(),
      standings: json['standings'] != null
          ? (json['standings'] as List<dynamic>)
              .map((s) => RoundRobinStanding.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  factory TournamentBracket.fromJsonString(String s) {
    return TournamentBracket.fromJson(jsonDecode(s) as Map<String, dynamic>);
  }
}

/// Full tournament data combining metadata + bracket + players.
class TournamentData {
  final int? id;
  final String name;
  final TournamentFormat format;
  final String type; // 'singles' or 'doubles'
  final String scoringRule;
  final int playTo;
  final int winBy;
  final int gameCount;
  final TournamentStatus status;
  final List<TournamentPlayer> players;
  final TournamentBracket? bracket;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TournamentData({
    this.id,
    required this.name,
    required this.format,
    required this.type,
    required this.scoringRule,
    required this.playTo,
    required this.winBy,
    required this.gameCount,
    required this.status,
    required this.players,
    this.bracket,
    required this.createdAt,
    this.completedAt,
  });

  TournamentData copyWith({
    int? id,
    String? name,
    TournamentFormat? format,
    String? type,
    String? scoringRule,
    int? playTo,
    int? winBy,
    int? gameCount,
    TournamentStatus? status,
    List<TournamentPlayer>? players,
    TournamentBracket? bracket,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TournamentData(
      id: id ?? this.id,
      name: name ?? this.name,
      format: format ?? this.format,
      type: type ?? this.type,
      scoringRule: scoringRule ?? this.scoringRule,
      playTo: playTo ?? this.playTo,
      winBy: winBy ?? this.winBy,
      gameCount: gameCount ?? this.gameCount,
      status: status ?? this.status,
      players: players ?? this.players,
      bracket: bracket ?? this.bracket,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

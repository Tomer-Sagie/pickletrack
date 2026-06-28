import 'dart:convert';

import '../models/tournament.dart';

/// Pure bracket generation and advancement logic for tournaments.
/// No dependencies on Flutter or Drift. All methods are static.
class TournamentService {
  TournamentService._();

  // ════════════════════════════════════════════════════════════
  //  SINGLE ELIMINATION
  // ════════════════════════════════════════════════════════════

  /// Generates a single-elimination bracket from a list of seeded players.
  /// Handles byes for non-power-of-2 counts by giving top seeds automatic
  /// advancement in round 1.
  static TournamentBracket generateSingleElim(List<TournamentPlayer> players) {
    final n = players.length;
    if (n < 2) {
      return const TournamentBracket(
        format: TournamentFormat.singleElim,
        rounds: [],
      );
    }

    // Pad to next power of 2 with byes (null players)
    final bracketSize = _nextPow2(n);
    final slots = List<TournamentPlayer?>.filled(bracketSize, null);
    for (var i = 0; i < n; i++) {
      slots[i] = players[i];
    }

    // Standard seeded slot order: 1 vs 16, 8 vs 9, 4 vs 13, 5 vs 12, etc.
    final seededOrder = _seededSlotOrder(bracketSize);
    final arranged = List<TournamentPlayer?>.filled(bracketSize, null);
    for (var i = 0; i < bracketSize; i++) {
      final seedIdx = seededOrder[i] - 1;
      arranged[i] = seedIdx < n ? players[seedIdx] : null;
    }

    final rounds = <BracketRound>[];
    var matchId = 0;

    // Round 1
    final r1Matches = <BracketMatch>[];
    for (var i = 0; i < bracketSize; i += 2) {
      final pA = arranged[i];
      final pB = arranged[i + 1];
      matchId++;
      if (pA == null || pB == null) {
        // Bye — auto-advance the non-null player
        final winner = pA ?? pB;
        r1Matches.add(BracketMatch(
          id: matchId,
          round: 1,
          roundName: _roundName(1, bracketSize),
          playerAName: pA?.name,
          playerBName: pB?.name,
          playerASeed: pA?.seed,
          playerBSeed: pB?.seed,
          winnerName: winner?.name,
          status: BracketMatchStatus.completed,
        ));
      } else {
        r1Matches.add(BracketMatch(
          id: matchId,
          round: 1,
          roundName: _roundName(1, bracketSize),
          playerAName: pA.name,
          playerBName: pB.name,
          playerASeed: pA.seed,
          playerBSeed: pB.seed,
          status: BracketMatchStatus.ready,
        ));
      }
    }
    rounds.add(BracketRound(name: _roundName(1, bracketSize), matches: r1Matches));

    // Subsequent rounds — empty until previous round completes.
    // Round 2 has bracketSize/4 matches (each takes 2 winners from round 1).
    var currentSize = bracketSize ~/ 4;
    var roundNum = 2;
    while (currentSize >= 1) {
      final matches = <BracketMatch>[];
      for (var i = 0; i < currentSize; i++) {
        matchId++;
        // Source matches are the two matches from the previous round
        final prevRoundMatchCount = rounds.last.matches.length;
        final srcAIdx = (i * 2).clamp(0, prevRoundMatchCount - 1);
        final srcBIdx = (i * 2 + 1).clamp(0, prevRoundMatchCount - 1);
        final sourceAId = rounds.last.matches[srcAIdx].id;
        final sourceBId = rounds.last.matches[srcBIdx].id;

        // If both source matches already completed (byes), auto-advance
        final srcA = rounds.last.matches[srcAIdx];
        final srcB = rounds.last.matches[srcBIdx];
        final winnerA = srcA.winnerName;
        final winnerB = srcB.winnerName;

        // Pre-fill winners from any already-completed source matches
        // (e.g. byes) so advancement works correctly.
        final prefillA = srcA.status == BracketMatchStatus.completed
            ? winnerA
            : null;
        final prefillASeed = prefillA != null
            ? _findSeed(players, prefillA)
            : null;
        final prefillB = srcB.status == BracketMatchStatus.completed
            ? winnerB
            : null;
        final prefillBSeed = prefillB != null
            ? _findSeed(players, prefillB)
            : null;

        final isReady = prefillA != null && prefillB != null;
        matches.add(BracketMatch(
          id: matchId,
          round: roundNum,
          roundName: _roundName(roundNum, bracketSize),
          playerAName: prefillA,
          playerBName: prefillB,
          playerASeed: prefillASeed,
          playerBSeed: prefillBSeed,
          sourceMatchAId: sourceAId,
          sourceMatchBId: sourceBId,
          status: isReady
              ? BracketMatchStatus.ready
              : BracketMatchStatus.pending,
        ));
      }
      rounds.add(BracketRound(
          name: _roundName(roundNum, bracketSize), matches: matches));
      currentSize ~/= 2;
      roundNum++;
    }

    return TournamentBracket(
        format: TournamentFormat.singleElim, rounds: rounds);
  }

  /// Advances a single-elimination bracket after a match completes.
  /// Returns the updated bracket.
  static TournamentBracket advanceSingleElim(
    TournamentBracket bracket,
    int completedMatchId,
    String winnerName,
    String? scoreJson,
    int? completedDbId,
    List<TournamentPlayer> allPlayers,
  ) {
    final rounds = List<BracketRound>.from(bracket.rounds);

    // Find and update the completed match
    outer:
    for (var ri = 0; ri < rounds.length; ri++) {
      final matches = rounds[ri].matches;
      for (var mi = 0; mi < matches.length; mi++) {
        if (matches[mi].id == completedMatchId) {
          matches[mi] = matches[mi].copyWith(
            winnerName: winnerName,
            scoreJson: scoreJson,
            status: BracketMatchStatus.completed,
            completedMatchId: completedDbId,
          );
          break outer;
        }
      }
    }

    // Find the next match that depends on this one and fill in the winner
    final completedMatch = _findMatchInRounds(rounds, completedMatchId);
    if (completedMatch == null) {
      return TournamentBracket(
          format: bracket.format, rounds: rounds, standings: bracket.standings);
    }

    for (var ri = 0; ri < rounds.length; ri++) {
      for (var mi = 0; mi < rounds[ri].matches.length; mi++) {
        final m = rounds[ri].matches[mi];
        if (m.sourceMatchAId == completedMatchId) {
          rounds[ri].matches[mi] = m.copyWith(
            playerAName: winnerName,
            playerASeed: _findSeed(allPlayers, winnerName),
            status: m.playerBName != null
                ? BracketMatchStatus.ready
                : BracketMatchStatus.pending,
          );
        }
        if (m.sourceMatchBId == completedMatchId) {
          rounds[ri].matches[mi] = m.copyWith(
            playerBName: winnerName,
            playerBSeed: _findSeed(allPlayers, winnerName),
            status: m.playerAName != null
                ? BracketMatchStatus.ready
                : BracketMatchStatus.pending,
          );
        }
      }
    }

    return TournamentBracket(
        format: bracket.format, rounds: rounds, standings: bracket.standings);
  }

  // ════════════════════════════════════════════════════════════
  //  DOUBLE ELIMINATION
  // ════════════════════════════════════════════════════════════

  /// Generates a double-elimination bracket.
  /// Winners bracket is a standard single-elim bracket.
  /// Losers bracket matches are created as placeholders.
  /// Grand Final is the last match: WB winner vs LB winner.
  static TournamentBracket generateDoubleElim(List<TournamentPlayer> players) {
    // Generate winners bracket first
    final winnersBracket = generateSingleElim(players);

    final n = players.length;
    final bracketSize = _nextPow2(n);
    final losersRounds = _generateLosersBracketStructure(bracketSize);

    // Merge winners + losers rounds, then add grand final
    final allRounds = <BracketRound>[];

    // Winners bracket rounds (tagged with side)
    var matchId = winnersBracket.rounds.isNotEmpty
        ? winnersBracket.rounds.last.matches.last.id
        : 0;

    for (final round in winnersBracket.rounds) {
      allRounds.add(BracketRound(
        name: 'WB ${round.name}',
        matches: round.matches
            .map((m) => m.copyWith(side: BracketSide.winners))
            .toList(),
      ));
    }

    // Losers bracket rounds (placeholder matches)
    for (final lr in losersRounds) {
      final matches = <BracketMatch>[];
      for (final info in lr) {
        matchId++;
        matches.add(BracketMatch(
          id: matchId,
          round: info.round,
          roundName: info.name,
          side: BracketSide.losers,
          status: BracketMatchStatus.pending,
        ));
      }
      allRounds.add(BracketRound(name: lr.first.name, matches: matches));
    }

    // Grand Final
    matchId++;
    final wbFinalMatch = winnersBracket.rounds.isNotEmpty
        ? winnersBracket.rounds.last.matches.first
        : null;
    allRounds.add(BracketRound(
      name: 'Grand Final',
      matches: [
        BracketMatch(
          id: matchId,
          round: allRounds.length + 1,
          roundName: 'Grand Final',
          side: BracketSide.grandFinal,
          sourceMatchAId: wbFinalMatch?.id,
          status: BracketMatchStatus.pending,
        ),
      ],
    ));

    return TournamentBracket(
        format: TournamentFormat.doubleElim, rounds: allRounds);
  }

  /// Advances a double-elimination bracket after a match completes.
  /// WB losers drop to LB. LB losers are eliminated.
  /// Grand Final: WB winner vs LB winner.
  static TournamentBracket advanceDoubleElim(
    TournamentBracket bracket,
    int completedMatchId,
    String winnerName,
    String loserName,
    String? scoreJson,
    int? completedDbId,
    List<TournamentPlayer> allPlayers,
  ) {
    var rounds = List<BracketRound>.from(bracket.rounds);

    // Update completed match
    rounds = _updateMatchInRounds(rounds, completedMatchId, (m) {
      return m.copyWith(
        winnerName: winnerName,
        scoreJson: scoreJson,
        status: BracketMatchStatus.completed,
        completedMatchId: completedDbId,
      );
    });

    final completedMatch = _findMatchInRounds(rounds, completedMatchId);
    if (completedMatch == null) {
      return TournamentBracket(
          format: bracket.format, rounds: rounds, standings: bracket.standings);
    }

    // If winners bracket match: winner advances in WB, loser drops to LB
    // If losers bracket match: winner advances in LB, loser is eliminated
    // If grand final: tournament is over
    if (completedMatch.side == BracketSide.winners) {
      // Advance winner to next WB match
      rounds = _advanceWinnerToSource(rounds, completedMatchId, winnerName,
          allPlayers, BracketSide.winners);

      // Drop loser to losers bracket — find the next pending LB match
      // that expects a WB loser feed
      rounds = _dropLoserToLB(rounds, completedMatchId, loserName, allPlayers);
    } else if (completedMatch.side == BracketSide.losers) {
      // Advance winner to next LB match by finding the next LB round
      // with an empty slot. LB matches don't have source-match linkage
      // (they're filled dynamically), so we use positional advancement.
      rounds = _advanceLbWinner(rounds, completedMatch, winnerName, allPlayers);
    } else if (completedMatch.side == BracketSide.grandFinal) {
      // Tournament complete — nothing more to do
    }

    return TournamentBracket(
        format: bracket.format, rounds: rounds, standings: bracket.standings);
  }

  // ════════════════════════════════════════════════════════════
  //  ROUND ROBIN
  // ════════════════════════════════════════════════════════════

  /// Generates a round-robin bracket where every player plays every other
  /// player exactly once. Uses the circle method for scheduling.
  static TournamentBracket generateRoundRobin(
      List<TournamentPlayer> players) {
    final n = players.length;
    if (n < 2) {
      return const TournamentBracket(
        format: TournamentFormat.roundRobin,
        rounds: [],
      );
    }

    // Circle method: fix player 0, rotate the rest
    final plist = List<TournamentPlayer>.from(players);
    final hasBye = n.isOdd;
    if (hasBye) {
      plist.add(const TournamentPlayer(name: 'BYE', seed: -1));
    }

    final nn = plist.length;
    final roundsNeeded = nn - 1;
    final matchesPerRound = nn ~/ 2;

    final rounds = <BracketRound>[];
    var matchId = 0;

    final current = List<TournamentPlayer>.from(plist);

    for (var round = 0; round < roundsNeeded; round++) {
      final matches = <BracketMatch>[];
      for (var i = 0; i < matchesPerRound; i++) {
        final pA = current[i];
        final pB = current[nn - 1 - i];
        matchId++;

        if (pA.name == 'BYE' || pB.name == 'BYE') {
          // Skip bye matches — they don't count
          continue;
        }

        matches.add(BracketMatch(
          id: matchId,
          round: round + 1,
          roundName: 'Round ${round + 1}',
          playerAName: pA.name,
          playerBName: pB.name,
          playerASeed: pA.seed,
          playerBSeed: pB.seed,
          status: BracketMatchStatus.ready,
        ));
      }
      if (matches.isNotEmpty) {
        rounds.add(BracketRound(
            name: 'Round ${round + 1}', matches: matches));
      }

      // Rotate: fix position 0, shift the rest
      final last = current.removeLast();
      current.insert(1, last);
    }

    // Initialize standings
    final realPlayers = players.where((p) => p.name != 'BYE').toList();
    final standings = realPlayers
        .map((p) => RoundRobinStanding(
              playerName: p.name,
              wins: 0,
              losses: 0,
              pointsFor: 0,
              pointsAgainst: 0,
            ))
        .toList();

    return TournamentBracket(
      format: TournamentFormat.roundRobin,
      rounds: rounds,
      standings: standings,
    );
  }

  /// Advances a round-robin bracket after a match completes.
  /// Updates standings with the result.
  static TournamentBracket advanceRoundRobin(
    TournamentBracket bracket,
    int completedMatchId,
    String winnerName,
    String loserName,
    String? scoreJson,
    int? completedDbId,
  ) {
    var rounds = List<BracketRound>.from(bracket.rounds);

    // Update the completed match
    rounds = _updateMatchInRounds(rounds, completedMatchId, (m) {
      return m.copyWith(
        winnerName: winnerName,
        scoreJson: scoreJson,
        status: BracketMatchStatus.completed,
        completedMatchId: completedDbId,
      );
    });

    // Update standings
    final standings =
        List<RoundRobinStanding>.from(bracket.standings ?? []);

    // Parse scores from scoreJson if available
    int pointsFor = 0;
    int pointsAgainst = 0;
    if (scoreJson != null) {
      try {
        final scores = _parseScoreSummary(scoreJson);
        pointsFor = scores[0];
        pointsAgainst = scores[1];
      } catch (_) {}
    }

    // Determine which player is A and which is B to assign points correctly
    final match = _findMatchInRounds(rounds, completedMatchId);
    final isWinnerA = match?.playerAName == winnerName;

    for (var i = 0; i < standings.length; i++) {
      if (standings[i].playerName == winnerName) {
        standings[i] = standings[i].copyWith(
          wins: standings[i].wins + 1,
          pointsFor: standings[i].pointsFor + (isWinnerA ? pointsFor : pointsAgainst),
          pointsAgainst:
              standings[i].pointsAgainst + (isWinnerA ? pointsAgainst : pointsFor),
        );
      }
      if (standings[i].playerName == loserName) {
        standings[i] = standings[i].copyWith(
          losses: standings[i].losses + 1,
          pointsFor: standings[i].pointsFor + (isWinnerA ? pointsAgainst : pointsFor),
          pointsAgainst:
              standings[i].pointsAgainst + (isWinnerA ? pointsFor : pointsAgainst),
        );
      }
    }

    return TournamentBracket(
      format: bracket.format,
      rounds: rounds,
      standings: standings,
    );
  }

  // ════════════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ════════════════════════════════════════════════════════════

  /// Generates the bracket for any format.
  static TournamentBracket generateBracket(
    TournamentFormat format,
    List<TournamentPlayer> players,
  ) {
    switch (format) {
      case TournamentFormat.singleElim:
        return generateSingleElim(players);
      case TournamentFormat.doubleElim:
        return generateDoubleElim(players);
      case TournamentFormat.roundRobin:
        return generateRoundRobin(players);
    }
  }

  /// Advances the bracket after a match completes.
  static TournamentBracket advanceBracket(
    TournamentFormat format,
    TournamentBracket bracket,
    int completedMatchId,
    String winnerName,
    String loserName,
    String? scoreJson,
    int? completedDbId,
    List<TournamentPlayer> allPlayers,
  ) {
    switch (format) {
      case TournamentFormat.singleElim:
        return advanceSingleElim(
            bracket, completedMatchId, winnerName, scoreJson, completedDbId, allPlayers);
      case TournamentFormat.doubleElim:
        return advanceDoubleElim(
            bracket, completedMatchId, winnerName, loserName, scoreJson, completedDbId, allPlayers);
      case TournamentFormat.roundRobin:
        return advanceRoundRobin(
            bracket, completedMatchId, winnerName, loserName, scoreJson, completedDbId);
    }
  }

  /// Returns the next ready match to play, or null if none ready.
  static BracketMatch? getNextReadyMatch(TournamentBracket bracket) {
    final ready = bracket.readyMatches;
    if (ready.isEmpty) return null;
    // Return the earliest round match
    ready.sort((a, b) => a.round.compareTo(b.round));
    return ready.first;
  }

  /// Checks if the tournament is complete.
  static bool isTournamentComplete(TournamentBracket bracket) {
    return bracket.isComplete;
  }

  /// Returns the tournament winner.
  static String? getTournamentWinner(TournamentBracket bracket) {
    return bracket.winner;
  }

  /// Generates final rankings for a completed tournament.
  static List<TournamentPlayer> generateFinalRankings(
    TournamentBracket bracket,
    List<TournamentPlayer> players,
  ) {
    if (bracket.format == TournamentFormat.roundRobin) {
      final sorted = bracket.sortedStandings;
      return sorted.map((s) {
        final player = players.firstWhere((p) => p.name == s.playerName);
        return player.copyWith(
            finalRanking: sorted.indexOf(s) + 1);
      }).toList();
    }

    // Elimination: winner is 1st, runner-up is 2nd, etc.
    final ranked = <TournamentPlayer>[];
    final winner = bracket.winner;
    if (winner != null) {
      final w = _findPlayerByName(players, winner);
      if (w != null) {
        ranked.add(w.copyWith(finalRanking: 1));
      }

      // Find runner-up from the final match
      final finalMatch = bracket.rounds.last.matches.first;
      final runnerUpName = finalMatch.playerAName == winner
          ? finalMatch.playerBName
          : finalMatch.playerAName;
      if (runnerUpName != null) {
        final r = _findPlayerByName(players, runnerUpName);
        if (r != null) {
          ranked.add(r.copyWith(finalRanking: 2));
        }
      }
    }

    // Fill remaining with unranked players
    for (final p in players) {
      if (!ranked.any((r) => r.name == p.name)) {
        ranked.add(p.copyWith(finalRanking: ranked.length + 1));
      }
    }

    return ranked;
  }

  // ════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ════════════════════════════════════════════════════════════

  static int _nextPow2(int n) {
    var p = 1;
    while (p < n) {
      p *= 2;
    }
    return p;
  }

  /// Returns the standard seeded slot order for a bracket of [size].
  /// E.g., for 8 players: [1, 8, 4, 5, 2, 7, 3, 6]
  /// This ensures top seeds meet lowest seeds in early rounds.
  static List<int> _seededSlotOrder(int size) {
    if (size == 1) return [1];
    final half = size ~/ 2;
    final subOrder = _seededSlotOrder(half);
    final result = <int>[];
    for (final s in subOrder) {
      result.add(s);
      result.add(size + 1 - s);
    }
    return result;
  }

  static String _roundName(int round, int bracketSize) {
    final totalRounds = _log2(bracketSize);
    final remaining = totalRounds - round + 1;
    switch (remaining) {
      case 1:
        return 'Final';
      case 2:
        return 'Semifinals';
      case 3:
        return 'Quarterfinals';
      default:
        return 'Round $round';
    }
  }

  static int _log2(int n) {
    var r = 0;
    while (n > 1) {
      n ~/= 2;
      r++;
    }
    return r;
  }

  static int? _findSeed(List<TournamentPlayer> players, String name) {
    for (final p in players) {
      if (p.name == name) return p.seed;
    }
    return null;
  }

  static TournamentPlayer? _findPlayerByName(
      List<TournamentPlayer> players, String name) {
    for (final p in players) {
      if (p.name == name) return p;
    }
    return null;
  }

  static BracketMatch? _findMatchInRounds(
      List<BracketRound> rounds, int matchId) {
    for (final round in rounds) {
      for (final match in round.matches) {
        if (match.id == matchId) return match;
      }
    }
    return null;
  }

  static List<BracketRound> _updateMatchInRounds(
    List<BracketRound> rounds,
    int matchId,
    BracketMatch Function(BracketMatch) updater,
  ) {
    return rounds.map((round) {
      return BracketRound(
        name: round.name,
        matches: round.matches.map((m) {
          if (m.id == matchId) return updater(m);
          return m;
        }).toList(),
      );
    }).toList();
  }

  static List<BracketRound> _advanceWinnerToSource(
    List<BracketRound> rounds,
    int completedMatchId,
    String winnerName,
    List<TournamentPlayer> allPlayers,
    BracketSide side,
  ) {
    return rounds.map((round) {
      return BracketRound(
        name: round.name,
        matches: round.matches.map((m) {
          if (m.sourceMatchAId == completedMatchId) {
            return m.copyWith(
              playerAName: winnerName,
              playerASeed: _findSeed(allPlayers, winnerName),
              status: m.playerBName != null
                  ? BracketMatchStatus.ready
                  : BracketMatchStatus.pending,
            );
          }
          if (m.sourceMatchBId == completedMatchId) {
            return m.copyWith(
              playerBName: winnerName,
              playerBSeed: _findSeed(allPlayers, winnerName),
              status: m.playerAName != null
                  ? BracketMatchStatus.ready
                  : BracketMatchStatus.pending,
            );
          }
          return m;
        }).toList(),
      );
    }).toList();
  }

  /// Advances a losers-bracket winner to the next LB round's first empty
  /// slot. If there is no subsequent LB round, the winner is the LB
  /// champion and is placed into the Grand Final as player B.
  static List<BracketRound> _advanceLbWinner(
    List<BracketRound> rounds,
    BracketMatch completedMatch,
    String winnerName,
    List<TournamentPlayer> allPlayers,
  ) {
    // Find LB rounds after the current match's round
    final currentRound = completedMatch.round;
    BracketRound? nextLbRound;

    for (final round in rounds) {
      final isLb = round.matches.any((m) => m.side == BracketSide.losers);
      if (isLb && round.matches.first.round > currentRound) {
        nextLbRound = round;
        break;
      }
    }

    if (nextLbRound != null) {
      // Find the first pending match in the next LB round with an empty slot
      for (var mi = 0; mi < nextLbRound.matches.length; mi++) {
        final m = nextLbRound.matches[mi];
        if (m.status == BracketMatchStatus.pending) {
          if (m.playerAName == null) {
            nextLbRound.matches[mi] = m.copyWith(
              playerAName: winnerName,
              playerASeed: _findSeed(allPlayers, winnerName),
              status: m.playerBName != null
                  ? BracketMatchStatus.ready
                  : BracketMatchStatus.pending,
            );
            return rounds;
          }
          if (m.playerBName == null) {
            nextLbRound.matches[mi] = m.copyWith(
              playerBName: winnerName,
              playerBSeed: _findSeed(allPlayers, winnerName),
              status: m.playerAName != null
                  ? BracketMatchStatus.ready
                  : BracketMatchStatus.pending,
            );
            return rounds;
          }
        }
      }
    }

    // No next LB round or no empty slots — winner is LB champion
    return _placeLbWinnerInGrandFinal(rounds, winnerName, allPlayers);
  }

  /// Places the losers-bracket winner into the Grand Final as player B.
  static List<BracketRound> _placeLbWinnerInGrandFinal(
    List<BracketRound> rounds,
    String lbWinnerName,
    List<TournamentPlayer> allPlayers,
  ) {
    return rounds.map((round) {
      return BracketRound(
        name: round.name,
        matches: round.matches.map((m) {
          if (m.side == BracketSide.grandFinal) {
            return m.copyWith(
              playerBName: lbWinnerName,
              playerBSeed: _findSeed(allPlayers, lbWinnerName),
              status: m.playerAName != null
                  ? BracketMatchStatus.ready
                  : BracketMatchStatus.pending,
            );
          }
          return m;
        }).toList(),
      );
    }).toList();
  }

  static List<BracketRound> _dropLoserToLB(
    List<BracketRound> rounds,
    int wbMatchId,
    String loserName,
    List<TournamentPlayer> allPlayers,
  ) {
    // Find the first pending LB match that has an empty slot
    // and assign the loser there
    for (var ri = 0; ri < rounds.length; ri++) {
      for (var mi = 0; mi < rounds[ri].matches.length; mi++) {
        final m = rounds[ri].matches[mi];
        if (m.side == BracketSide.losers &&
            m.status == BracketMatchStatus.pending) {
          if (m.playerAName == null) {
            rounds[ri].matches[mi] = m.copyWith(
              playerAName: loserName,
              playerASeed: _findSeed(allPlayers, loserName),
              status: m.playerBName != null
                  ? BracketMatchStatus.ready
                  : BracketMatchStatus.pending,
            );
            return rounds;
          }
          if (m.playerBName == null) {
            rounds[ri].matches[mi] = m.copyWith(
              playerBName: loserName,
              playerBSeed: _findSeed(allPlayers, loserName),
              status: m.playerAName != null
                  ? BracketMatchStatus.ready
                  : BracketMatchStatus.pending,
            );
            return rounds;
          }
        }
      }
    }
    return rounds;
  }

  /// Generates the losers bracket structure for double elimination.
  /// Returns a list of rounds, each containing match info.
  static List<List<_LoserMatchInfo>> _generateLosersBracketStructure(
      int bracketSize) {
    final losersRounds = <List<_LoserMatchInfo>>[];

    final wbRounds = _log2(bracketSize);
    var lbRound = 1;
    var matchCount = bracketSize ~/ 4;

    while (lbRound < wbRounds * 2 - 1) {
      final infos = <_LoserMatchInfo>[];
      for (var i = 0; i < matchCount; i++) {
        infos.add(_LoserMatchInfo(
          round: lbRound,
          name: 'LB Round $lbRound',
        ));
      }
      losersRounds.add(infos);

      if (lbRound.isOdd && lbRound > 1) {
        matchCount ~/= 2;
      }
      lbRound++;
    }

    return losersRounds;
  }

  /// Parses a score JSON string like [{"game":1,"teamA":11,"teamB":7}]
  /// and returns [totalA, totalB].
  static List<int> _parseScoreSummary(String scoreJson) {
    try {
      final list = scoreJson.startsWith('[')
          ? (jsonDecode(scoreJson) as List)
          : <dynamic>[];
      var totalA = 0;
      var totalB = 0;
      for (final g in list) {
        final map = g as Map<String, dynamic>;
        totalA += (map['teamA'] ?? 0) as int;
        totalB += (map['teamB'] ?? 0) as int;
      }
      return [totalA, totalB];
    } catch (_) {
      return [0, 0];
    }
  }
}


class _LoserMatchInfo {
  final int round;
  final String name;

  const _LoserMatchInfo({
    required this.round,
    required this.name,
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pickletrack/models/tournament.dart';
import 'package:pickletrack/services/tournament_service.dart';

void main() {
  group('TournamentService — Single Elimination', () {
    test('generates bracket for 4 players', () {
      final players = [
        const TournamentPlayer(name: 'Alice', seed: 1),
        const TournamentPlayer(name: 'Bob', seed: 2),
        const TournamentPlayer(name: 'Carol', seed: 3),
        const TournamentPlayer(name: 'Dan', seed: 4),
      ];
      final bracket = TournamentService.generateSingleElim(players);

      expect(bracket.format, TournamentFormat.singleElim);
      expect(bracket.rounds.length, 2); // Semifinals, Final
      expect(bracket.totalMatches, 3);

      // Round 1 (quarterfinals for 4 players is actually just 2 matches)
      final r1 = bracket.rounds[0];
      expect(r1.name, 'Semifinals');
      expect(r1.matches.length, 2);

      // Final
      final finalRound = bracket.rounds.last;
      expect(finalRound.name, 'Final');
      expect(finalRound.matches.length, 1);
    });

    test('generates bracket for 8 players with correct seeding', () {
      final players = List.generate(8, (i) =>
        TournamentPlayer(name: 'P${i + 1}', seed: i + 1));
      final bracket = TournamentService.generateSingleElim(players);

      expect(bracket.rounds.length, 3); // Quarterfinals, Semifinals, Final
      expect(bracket.totalMatches, 7);

      // First round matchups: 1v8, 4v5, 2v7, 3v6
      final r1 = bracket.rounds[0];
      expect(r1.matches[0].playerASeed, 1);
      expect(r1.matches[0].playerBSeed, 8);
      expect(r1.matches[1].playerASeed, 4);
      expect(r1.matches[1].playerBSeed, 5);
      expect(r1.matches[2].playerASeed, 2);
      expect(r1.matches[2].playerBSeed, 7);
      expect(r1.matches[3].playerASeed, 3);
      expect(r1.matches[3].playerBSeed, 6);
    });

    test('handles byes for non-power-of-2 counts', () {
      final players = [
        const TournamentPlayer(name: 'P1', seed: 1),
        const TournamentPlayer(name: 'P2', seed: 2),
        const TournamentPlayer(name: 'P3', seed: 3),
      ];
      final bracket = TournamentService.generateSingleElim(players);

      // Padded to 4, so 1 bye match
      expect(bracket.rounds[0].matches.length, 2);
      final byeMatch = bracket.rounds[0].matches.firstWhere((m) => m.isBye);
      expect(byeMatch.status, BracketMatchStatus.completed);
      expect(byeMatch.winnerName, isNotNull);
    });

    test('advances winner through bracket', () {
      final players = [
        const TournamentPlayer(name: 'Alice', seed: 1),
        const TournamentPlayer(name: 'Bob', seed: 2),
        const TournamentPlayer(name: 'Carol', seed: 3),
        const TournamentPlayer(name: 'Dan', seed: 4),
      ];
      var bracket = TournamentService.generateSingleElim(players);

      // Alice beats Bob in semifinal
      final semiA = bracket.rounds[0].matches[0];
      bracket = TournamentService.advanceSingleElim(
        bracket, semiA.id, 'Alice', '[{"game":1,"teamA":11,"teamB":7}]', 1, players);

      // Carol beats Dan in semifinal
      final semiB = bracket.rounds[0].matches[1];
      bracket = TournamentService.advanceSingleElim(
        bracket, semiB.id, 'Carol', '[{"game":1,"teamA":11,"teamB":9}]', 2, players);

      // Final should now have Alice vs Carol
      final finalMatch = bracket.rounds.last.matches[0];
      expect(finalMatch.playerAName, 'Alice');
      expect(finalMatch.playerBName, 'Carol');
      expect(finalMatch.status, BracketMatchStatus.ready);

      // Alice wins final
      bracket = TournamentService.advanceSingleElim(
        bracket, finalMatch.id, 'Alice', '[{"game":1,"teamA":11,"teamB":5}]', 3, players);

      expect(bracket.isComplete, true);
      expect(bracket.winner, 'Alice');
    });

    test('returns empty bracket for <2 players', () {
      final bracket = TournamentService.generateSingleElim([
        const TournamentPlayer(name: 'Alice', seed: 1),
      ]);
      expect(bracket.rounds.isEmpty, true);
    });

    test('advances bye winner correctly to next round', () {
      final players = [
        const TournamentPlayer(name: 'P1', seed: 1),
        const TournamentPlayer(name: 'P2', seed: 2),
        const TournamentPlayer(name: 'P3', seed: 3),
      ];
      var bracket = TournamentService.generateSingleElim(players);

      // One match should be a bye (already completed)
      final byeMatch = bracket.rounds[0].matches.firstWhere((m) => m.isBye);
      expect(byeMatch.status, BracketMatchStatus.completed);

      // Find the non-bye match and complete it
      final realMatch = bracket.rounds[0].matches.firstWhere((m) => !m.isBye);
      bracket = TournamentService.advanceSingleElim(
        bracket, realMatch.id, 'P2', '[{"game":1,"teamA":11,"teamB":7}]', 1, players);

      // The final should now have the bye winner (P1) and the real winner (P2)
      final finalMatch = bracket.rounds.last.matches[0];
      expect(finalMatch.playerAName, 'P1');
      expect(finalMatch.playerBName, 'P2');
      expect(finalMatch.status, BracketMatchStatus.ready);
    });

    test('bye bracket becomes complete after final match', () {
      final players = [
        const TournamentPlayer(name: 'P1', seed: 1),
        const TournamentPlayer(name: 'P2', seed: 2),
        const TournamentPlayer(name: 'P3', seed: 3),
      ];
      var bracket = TournamentService.generateSingleElim(players);

      final realMatch = bracket.rounds[0].matches.firstWhere((m) => !m.isBye);
      bracket = TournamentService.advanceSingleElim(
        bracket, realMatch.id, 'P2', null, 1, players);

      // Advance the final
      final finalMatch = bracket.rounds.last.matches[0];
      bracket = TournamentService.advanceSingleElim(
        bracket, finalMatch.id, 'P2', null, 2, players);

      expect(bracket.isComplete, true);
      expect(bracket.winner, 'P2');
    });
  });

  group('TournamentService — Double Elimination', () {
    test('generates bracket for 4 players', () {
      final players = [
        const TournamentPlayer(name: 'A', seed: 1),
        const TournamentPlayer(name: 'B', seed: 2),
        const TournamentPlayer(name: 'C', seed: 3),
        const TournamentPlayer(name: 'D', seed: 4),
      ];
      final bracket = TournamentService.generateDoubleElim(players);

      expect(bracket.format, TournamentFormat.doubleElim);
      // Should have WB rounds + LB rounds + Grand Final
      expect(bracket.rounds.isNotEmpty, true);

      // Check that winners bracket matches have side = winners
      final wbMatches = bracket.allMatches
          .where((m) => m.side == BracketSide.winners)
          .toList();
      expect(wbMatches.isNotEmpty, true);

      // Check grand final exists
      final gfMatches = bracket.allMatches
          .where((m) => m.side == BracketSide.grandFinal)
          .toList();
      expect(gfMatches.length, 1);
    });

    test('advances WB loser to LB', () {
      final players = [
        const TournamentPlayer(name: 'A', seed: 1),
        const TournamentPlayer(name: 'B', seed: 2),
        const TournamentPlayer(name: 'C', seed: 3),
        const TournamentPlayer(name: 'D', seed: 4),
      ];
      var bracket = TournamentService.generateDoubleElim(players);

      // Find first WB match and complete it
      final wbMatch = bracket.allMatches
          .firstWhere((m) => m.side == BracketSide.winners && m.isReady);
      bracket = TournamentService.advanceDoubleElim(
        bracket, wbMatch.id, 'A', 'B', '[{"game":1,"teamA":11,"teamB":7}]', 1, players);

      // The loser (B) should appear in a LB match
      final lbMatches = bracket.allMatches
          .where((m) => m.side == BracketSide.losers)
          .toList();
      final hasB = lbMatches.any((m) =>
          m.playerAName == 'B' || m.playerBName == 'B');
      expect(hasB, true);
    });
  });

  group('TournamentService — Round Robin', () {
    test('generates schedule for 4 players', () {
      final players = [
        const TournamentPlayer(name: 'A', seed: 1),
        const TournamentPlayer(name: 'B', seed: 2),
        const TournamentPlayer(name: 'C', seed: 3),
        const TournamentPlayer(name: 'D', seed: 4),
      ];
      final bracket = TournamentService.generateRoundRobin(players);

      expect(bracket.format, TournamentFormat.roundRobin);
      // 4 players → 3 rounds, 2 matches per round = 6 matches total
      expect(bracket.rounds.length, 3);
      expect(bracket.totalMatches, 6);

      // Every player plays every other player exactly once
      final allMatches = bracket.allMatches;
      final pairings = <String>{};
      for (final m in allMatches) {
        final a = m.playerAName!;
        final b = m.playerBName!;
        final key = a.compareTo(b) < 0 ? '$a-$b' : '$b-$a';
        pairings.add(key);
      }
      expect(pairings.length, 6); // C(4,2) = 6
    });

    test('handles odd player count with bye', () {
      final players = [
        const TournamentPlayer(name: 'A', seed: 1),
        const TournamentPlayer(name: 'B', seed: 2),
        const TournamentPlayer(name: 'C', seed: 3),
      ];
      final bracket = TournamentService.generateRoundRobin(players);

      // 3 players → circle method adds BYE, but bye matches are skipped
      // So we get 3 rounds × 1 match each = 3 matches
      expect(bracket.totalMatches, 3);
      expect(bracket.allMatches.any((m) =>
          m.playerAName == 'BYE' || m.playerBName == 'BYE'), false);
    });

    test('updates standings after match completion', () {
      final players = [
        const TournamentPlayer(name: 'A', seed: 1),
        const TournamentPlayer(name: 'B', seed: 2),
        const TournamentPlayer(name: 'C', seed: 3),
      ];
      var bracket = TournamentService.generateRoundRobin(players);

      // Complete first match: A beats B 11-7
      final match1 = bracket.rounds[0].matches[0];
      bracket = TournamentService.advanceRoundRobin(
        bracket, match1.id, 'A', 'B',
        '[{"game":1,"teamA":11,"teamB":7}]', 1);

      final standings = bracket.standings!;
      final aStanding = standings.firstWhere((s) => s.playerName == 'A');
      final bStanding = standings.firstWhere((s) => s.playerName == 'B');

      expect(aStanding.wins, 1);
      expect(aStanding.losses, 0);
      expect(bStanding.wins, 0);
      expect(bStanding.losses, 1);
    });

    test('sorts standings by wins then point differential', () {
      final players = [
        const TournamentPlayer(name: 'A', seed: 1),
        const TournamentPlayer(name: 'B', seed: 2),
        const TournamentPlayer(name: 'C', seed: 3),
      ];
      var bracket = TournamentService.generateRoundRobin(players);

      // A beats B
      bracket = TournamentService.advanceRoundRobin(
        bracket, bracket.rounds[0].matches[0].id, 'A', 'B', null, 1);
      // B beats C
      bracket = TournamentService.advanceRoundRobin(
        bracket, bracket.rounds[1].matches[0].id, 'B', 'C', null, 2);
      // A beats C
      bracket = TournamentService.advanceRoundRobin(
        bracket, bracket.rounds[2].matches[0].id, 'A', 'C', null, 3);

      final sorted = bracket.sortedStandings;
      expect(sorted[0].playerName, 'A'); // 2 wins
      expect(sorted[1].playerName, 'B'); // 1 win
      expect(sorted[2].playerName, 'C'); // 0 wins
    });

    test('returns empty bracket for <2 players', () {
      final bracket = TournamentService.generateRoundRobin([
        const TournamentPlayer(name: 'A', seed: 1),
      ]);
      expect(bracket.rounds.isEmpty, true);
    });
  });

  group('TournamentService — Shared helpers', () {
    test('generateBracket dispatches to correct format', () {
      final players = [
        const TournamentPlayer(name: 'A', seed: 1),
        const TournamentPlayer(name: 'B', seed: 2),
      ];

      final se = TournamentService.generateBracket(TournamentFormat.singleElim, players);
      expect(se.format, TournamentFormat.singleElim);

      final de = TournamentService.generateBracket(TournamentFormat.doubleElim, players);
      expect(de.format, TournamentFormat.doubleElim);

      final rr = TournamentService.generateBracket(TournamentFormat.roundRobin, players);
      expect(rr.format, TournamentFormat.roundRobin);
    });

    test('getNextReadyMatch returns earliest round ready match', () {
      final players = [
        const TournamentPlayer(name: 'A', seed: 1),
        const TournamentPlayer(name: 'B', seed: 2),
        const TournamentPlayer(name: 'C', seed: 3),
        const TournamentPlayer(name: 'D', seed: 4),
      ];
      final bracket = TournamentService.generateSingleElim(players);
      final next = TournamentService.getNextReadyMatch(bracket);
      expect(next, isNotNull);
      expect(next!.round, 1);
    });

    test('isTournamentComplete returns false until final match done', () {
      final players = [
        const TournamentPlayer(name: 'A', seed: 1),
        const TournamentPlayer(name: 'B', seed: 2),
      ];
      var bracket = TournamentService.generateSingleElim(players);
      expect(bracket.isComplete, false);

      final match = bracket.allMatches.first;
      bracket = TournamentService.advanceSingleElim(
        bracket, match.id, 'A', null, 1, players);
      expect(bracket.isComplete, true);
    });

    test('generateFinalRankings for round robin', () {
      final players = [
        const TournamentPlayer(name: 'A', seed: 1),
        const TournamentPlayer(name: 'B', seed: 2),
      ];
      var bracket = TournamentService.generateRoundRobin(players);
      bracket = TournamentService.advanceRoundRobin(
        bracket, bracket.allMatches.first.id, 'A', 'B', null, 1);

      final rankings = TournamentService.generateFinalRankings(bracket, players);
      expect(rankings[0].name, 'A');
      expect(rankings[0].finalRanking, 1);
      expect(rankings[1].name, 'B');
      expect(rankings[1].finalRanking, 2);
    });
  });
}

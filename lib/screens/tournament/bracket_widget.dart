import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/tournament.dart';
import '../../theme/colors.dart';

/// Renders a tournament bracket as a horizontally scrollable list of rounds.
/// Each round is a vertical column of match cards.
class BracketWidget extends StatelessWidget {
  final TournamentBracket bracket;
  final void Function(BracketMatch match)? onMatchTap;
  final int? activeMatchId;

  const BracketWidget({
    super.key,
    required this.bracket,
    this.onMatchTap,
    this.activeMatchId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (bracket.rounds.isEmpty) {
      return Center(
        child: Text('No matches generated',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
      );
    }

    // For round robin, show standings at the top
    if (bracket.format == TournamentFormat.roundRobin) {
      return Column(
        children: [
          if (bracket.standings != null && bracket.standings!.isNotEmpty)
            _RoundRobinStandings(
                standings: bracket.sortedStandings, theme: theme),
          const SizedBox(height: 12),
          Expanded(
            child: _buildRoundsList(context, theme),
          ),
        ],
      );
    }

    return _buildRoundsList(context, theme);
  }

  Widget _buildRoundsList(BuildContext context, ThemeData theme) {
    // Group rounds by side for double elimination
    if (bracket.format == TournamentFormat.doubleElim) {
      final wbRounds = bracket.rounds
          .where((r) => r.matches.any((m) => m.side == BracketSide.winners))
          .toList();
      final lbRounds = bracket.rounds
          .where((r) => r.matches.any((m) => m.side == BracketSide.losers))
          .toList();
      final gfRounds = bracket.rounds
          .where((r) => r.matches.any((m) => m.side == BracketSide.grandFinal))
          .toList();

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wbRounds.isNotEmpty) ...[
              _buildSideLabel('Winners Bracket', theme),
              ...wbRounds.map((r) => _buildRoundColumn(r, theme)),
            ],
            const SizedBox(width: 16),
            if (lbRounds.isNotEmpty) ...[
              _buildSideLabel('Losers Bracket', theme),
              ...lbRounds.map((r) => _buildRoundColumn(r, theme)),
            ],
            const SizedBox(width: 16),
            if (gfRounds.isNotEmpty) ...[
              _buildSideLabel('Grand Final', theme),
              ...gfRounds.map((r) => _buildRoundColumn(r, theme)),
            ],
          ],
        ),
      );
    }

    // Single elim or round robin — flat list of rounds
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: bracket.rounds.map((r) => _buildRoundColumn(r, theme)).toList(),
      ),
    );
  }

  Widget _buildSideLabel(String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 4, bottom: 8),
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildRoundColumn(BracketRound round, ThemeData theme) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Round header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              round.name,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          // Match cards
          ...round.matches.map((match) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RepaintBoundary(
                  child: _MatchCard(
                    match: match,
                    onTap: onMatchTap != null && match.isReady
                        ? () => onMatchTap!(match)
                        : null,
                    isActive: match.id == activeMatchId,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Match Card ──

class _MatchCard extends StatelessWidget {
  final BracketMatch match;
  final VoidCallback? onTap;
  final bool isActive;

  const _MatchCard({
    required this.match,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = match.status == BracketMatchStatus.completed;
    final isBye = match.isBye && match.status == BracketMatchStatus.completed;

    Color borderColor;
    if (isActive) {
      borderColor = theme.colorScheme.primary;
    } else if (isCompleted) {
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.3);
    } else if (match.isReady) {
      borderColor = courtGreen.withValues(alpha: 0.4);
    } else {
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.15);
    }

    return Material(
      color: isActive
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: isActive ? 2 : 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Column(
            children: [
              // Match number badge
              Row(
                children: [
                  Text(
                    '#${match.id}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  if (match.side != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: match.side == BracketSide.winners
                            ? courtGreen.withValues(alpha: 0.15)
                            : match.side == BracketSide.losers
                                ? courtBlue.withValues(alpha: 0.15)
                                : theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        match.side!.label[0],
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (isCompleted)
                    const Icon(Icons.check_circle,
                        size: 14, color: courtGreen)
                  else if (match.isReady)
                    const Icon(Icons.play_circle_outline,
                        size: 14, color: courtGreen)
                  else if (isBye)
                    Text('BYE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                        ))
                  else
                    Icon(Icons.hourglass_empty,
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 6),
              // Player A
              _PlayerRow(
                name: match.playerADisplay,
                seed: match.playerASeed,
                isWinner: match.winnerName == match.playerAName,
                isLoser: isCompleted && match.winnerName != match.playerAName,
                theme: theme,
              ),
              const SizedBox(height: 2),
              // Player B
              _PlayerRow(
                name: match.playerBDisplay,
                seed: match.playerBSeed,
                isWinner: match.winnerName == match.playerBName,
                isLoser: isCompleted && match.winnerName != match.playerBName,
                theme: theme,
              ),
              // Score
              if (isCompleted && match.scoreJson != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatScore(match.scoreJson!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatScore(String scoreJson) {
    try {
      final list = scoreJson.startsWith('[')
          ? (jsonDecode(scoreJson) as List)
          : <dynamic>[];
      return list.map((g) {
        final map = g as Map<String, dynamic>;
        return '${map['teamA'] ?? 0}-${map['teamB'] ?? 0}';
      }).join(', ');
    } catch (_) {
      return '';
    }
  }
}

// ── Player Row ──

class _PlayerRow extends StatelessWidget {
  final String name;
  final int? seed;
  final bool isWinner;
  final bool isLoser;
  final ThemeData theme;

  const _PlayerRow({
    required this.name,
    this.seed,
    required this.isWinner,
    required this.isLoser,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    FontWeight weight;
    if (isWinner) {
      textColor = courtGreen;
      weight = FontWeight.w700;
    } else if (isLoser) {
      textColor = theme.colorScheme.onSurfaceVariant;
      weight = FontWeight.w400;
    } else {
      textColor = theme.colorScheme.onSurface;
      weight = FontWeight.w500;
    }

    return Row(
      children: [
        if (seed != null && seed! > 0)
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: seed == 1
                  ? courtGreen.withValues(alpha: 0.2)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              '$seed',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: seed == 1 ? courtGreen : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          const SizedBox(width: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: weight,
              decoration: isLoser ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isWinner)
          const Icon(Icons.emoji_events, size: 12, color: courtGreen),
      ],
    );
  }
}

// ── Round Robin Standings Table ──

class _RoundRobinStandings extends StatelessWidget {
  final List<RoundRobinStanding> standings;
  final ThemeData theme;

  const _RoundRobinStandings({required this.standings, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.leaderboard_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Standings',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            // Header row
            _StandingsHeader(theme: theme),
            const Divider(height: 1),
            // Player rows
            ...standings.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final s = entry.value;
              return _StandingsRow(
                rank: rank,
                name: s.playerName,
                wins: s.wins,
                losses: s.losses,
                pf: s.pointsFor,
                pa: s.pointsAgainst,
                diff: s.pointDifferential,
                theme: theme,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StandingsHeader extends StatelessWidget {
  final ThemeData theme;
  const _StandingsHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Expanded(flex: 3, child: Text('Player', style: style)),
          SizedBox(width: 36, child: Text('W', style: style, textAlign: TextAlign.center)),
          SizedBox(width: 36, child: Text('L', style: style, textAlign: TextAlign.center)),
          SizedBox(width: 40, child: Text('Diff', style: style, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _StandingsRow extends StatelessWidget {
  final int rank;
  final String name;
  final int wins;
  final int losses;
  final int pf;
  final int pa;
  final int diff;
  final ThemeData theme;

  const _StandingsRow({
    required this.rank,
    required this.name,
    required this.wins,
    required this.losses,
    required this.pf,
    required this.pa,
    required this.diff,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1
        ? courtGreen
        : rank == 2
            ? courtBlue
            : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: rankColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: rank <= 2 ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text('$wins',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 36,
            child: Text('$losses',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 40,
            child: Text(
              diff > 0 ? '+$diff' : '$diff',
              style: theme.textTheme.bodySmall?.copyWith(
                color: diff > 0 ? courtGreen : diff < 0 ? theme.colorScheme.error : null,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

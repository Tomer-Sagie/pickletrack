import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../database/database.dart';
import '../../providers/match_detail_provider.dart';
import '../../services/share_service.dart';
import '../../theme/colors.dart';
import '../../utils/match_date_format.dart';
import '../../widgets/shimmer.dart';

class MatchDetailsScreen extends ConsumerStatefulWidget {
  final int matchId;

  const MatchDetailsScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends ConsumerState<MatchDetailsScreen> {
  final _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(matchDetailProvider(widget.matchId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          // Match Details can be reached from Live (push) after a match
          // ends, or directly from Home (push). Popping naturally returns
          // to whichever screen pushed us; fall back to home if for some
          // reason there is nothing to pop (e.g. deep-link in the future).
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Semantics(
          header: true,
          child: const Text('Match Details'),
        ),
        actions: [
          // Explicit Home shortcut — useful when Match Details was reached
          // from a deep stack (Live → Details on background tab), where the
          // back arrow only pops one level at a time. Always go('/'),
          // regardless of how we got here, so the home stack is clean.
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Home',
            onPressed: () => context.go('/'),
          ),
          detail.whenOrNull(
            data: (ctx) => PopupMenuButton<_ShareAction>(
              tooltip: 'Share',
              icon: const Icon(Icons.ios_share_rounded),
              onSelected: (action) => _handleShare(context, action, ctx),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _ShareAction.text,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.short_text_rounded),
                    title: Text('Share text'),
                    subtitle: Text('Summary via OS share sheet'),
                  ),
                ),
                PopupMenuItem(
                  value: _ShareAction.screenshot,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.image_rounded),
                    title: Text('Share screenshot'),
                    subtitle: Text('Capture Match Details as PNG'),
                  ),
                ),
              ],
            ),
          ),
        ].whereType<Widget>().toList(),
      ),
      body: detail.when(
        data: (ctx) => _buildContent(context, theme, ctx),
        loading: () => const ShimmerMatchDetails(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text('Failed to load match', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(e.toString(), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(matchDetailProvider(widget.matchId)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, MatchDetailContext ctx) {
    // SingleChildScrollView+Column instead of ListView so the
    // RepaintBoundary captures the FULL content for screenshots,
    // not just the visible viewport.  ListView only paints visible
    // children, which clips long play-by-play logs.
    return RepaintBoundary(
      key: _repaintKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWinnerBanner(theme, ctx),
            const SizedBox(height: 20),
            _buildTeamsCard(theme, ctx),
            const SizedBox(height: 16),
            _buildScoreCards(theme, ctx),
            const SizedBox(height: 16),
            _buildInfoCard(theme, ctx),
            const SizedBox(height: 24),
            _buildEventLogSection(theme, ctx),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerBanner(ThemeData theme, MatchDetailContext ctx) {
    final winColor = ctx.teamAWon ? courtGreen : courtBlue;

    return Semantics(
      header: true,
      label: '${ctx.winnerLabel} Wins! ${ctx.teamAPlayers.join(' & ')} vs ${ctx.teamBPlayers.join(' & ')}',
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: winColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: winColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events_rounded, size: 40, color: winColor),
          const SizedBox(height: 8),
          Text(
            '${ctx.winnerLabel} Wins!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: winColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${ctx.teamAPlayers.join(' & ')}  vs  ${ctx.teamBPlayers.join(' & ')}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ));
  }

  Widget _buildTeamsCard(ThemeData theme, MatchDetailContext ctx) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: _TeamColumn(
                label: 'Team A',
                players: ctx.teamAPlayers,
                isWinner: ctx.teamAWon,
                color: courtGreen,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('VS', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: _TeamColumn(
                label: 'Team B',
                players: ctx.teamBPlayers,
                isWinner: !ctx.teamAWon,
                color: courtBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCards(ThemeData theme, MatchDetailContext ctx) {
    if (ctx.parsedScores.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text('No score data', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Game Scores', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ),
        ...ctx.parsedScores.asMap().entries.map((entry) {
          final i = entry.key;
          final game = entry.value;
          final a = game['teamA'] ?? 0;
          final b = game['teamB'] ?? 0;
          final gameWinner = a > b ? 'A' : 'B';
          final isLastGame = i == ctx.parsedScores.length - 1;

          return Card(
            elevation: 0,
            margin: EdgeInsets.only(bottom: isLastGame ? 0 : 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: gameWinner == 'A' ? courtGreen.withValues(alpha: 0.1) : courtBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Game ${i + 1}', style: theme.textTheme.labelSmall),
                  ),
                  const Spacer(),
                  Text(
                    '$a',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: gameWinner == 'A' ? FontWeight.w800 : FontWeight.w400,
                      color: a > b ? courtGreen : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('–', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline)),
                  ),
                  Text(
                    '$b',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: gameWinner == 'B' ? FontWeight.w800 : FontWeight.w400,
                      color: b > a ? courtBlue : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInfoCard(ThemeData theme, MatchDetailContext ctx) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _InfoRow(icon: Icons.sports_tennis_rounded, label: 'Type', value: ctx.typeLabel),
            const Divider(height: 1),
            _InfoRow(icon: Icons.rule_rounded, label: 'Scoring', value: ctx.ruleLabel),
            const Divider(height: 1),
            _InfoRow(icon: Icons.casino_rounded, label: 'Format', value: ctx.gameLabel),
            const Divider(height: 1),
            _InfoRow(icon: Icons.timer_outlined, label: 'Duration', value: ctx.formatDuration()),
            const Divider(height: 1),
            _InfoRow(icon: Icons.calendar_today_rounded, label: 'Date', value: _formatDate(ctx.match.completedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventLogSection(ThemeData theme, MatchDetailContext ctx) {
    if (ctx.eventLog.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group events by game number so we can render game headers.
    final eventsByGame = <int, List<MatchEventLogData>>{};
    for (final event in ctx.eventLog) {
      eventsByGame.putIfAbsent(event.gameNumber, () => []).add(event);
    }
    final sortedGames = eventsByGame.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Play-by-Play', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final gameNum in sortedGames) ...[
                  // Game header
                  _GameLogHeader(gameNumber: gameNum, theme: theme),
                  // Events for this game in chronological order
                  ...eventsByGame[gameNum]!.map((event) {
                    return RepaintBoundary(
                      child: _EventLogTile(event: event, theme: theme),
                    );
                  }),
                  if (gameNum != sortedGames.last)
                    const Divider(height: 1, indent: 14, endIndent: 14),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) => formatMatchDate(dt);

  Future<void> _handleShare(
    BuildContext context,
    _ShareAction action,
    MatchDetailContext ctx,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final dateLabel =
        '${ctx.match.completedAt.month}/${ctx.match.completedAt.day}/${ctx.match.completedAt.year}';
    final scoreStr = ctx.parsedScores
        .map((g) => '${g['teamA'] ?? 0}-${g['teamB'] ?? 0}')
        .join(', ');
    final label =
        'match_${ctx.match.id}_${ctx.winnerLabel.toLowerCase().replaceAll(' ', '_')}';

    switch (action) {
      case _ShareAction.text:
        await ShareService.shareMatchSummary(
          winnerLabel: ctx.winnerLabel,
          teamAPlayers: ctx.teamAPlayers.join(' & '),
          teamBPlayers: ctx.teamBPlayers.join(' & '),
          finalScores: scoreStr,
          date: dateLabel,
          duration: ctx.formatDuration(),
        );
      case _ShareAction.screenshot:
        if (_repaintKey.currentContext?.findRenderObject() == null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Screenshot unavailable — try again after layout settles.'),
            ),
          );
          return;
        }
        await ShareService.shareScreenshot(
          _repaintKey,
          matchLabel: label,
        );
    }
  }
}

enum _ShareAction { text, screenshot }

// ── Sub-widgets ──

class _TeamColumn extends StatelessWidget {
  final String label;
  final List<String> players;
  final bool isWinner;
  final Color color;

  const _TeamColumn({required this.label, required this.players, required this.isWinner, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWinner)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.emoji_events_rounded, size: 14, color: color),
              ),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        ...players.map((p) => Text(p, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isWinner ? FontWeight.w600 : FontWeight.w400), textAlign: TextAlign.center)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _GameLogHeader extends StatelessWidget {
  final int gameNumber;
  final ThemeData theme;

  const _GameLogHeader({required this.gameNumber, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Game $gameNumber',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventLogTile extends StatelessWidget {
  final MatchEventLogData event;
  final ThemeData theme;

  const _EventLogTile({required this.event, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isPoint = event.eventType == 'point';
    final isSideout = event.eventType == 'sideout';
    final scorerTeam = event.scorerTeam;
    final scoreColor = scorerTeam == 'A' ? courtGreen : scorerTeam == 'B' ? courtBlue : null;

    IconData icon;
    Color? iconColor;
    String label;

    if (isPoint) {
      icon = Icons.add_circle_rounded;
      iconColor = scoreColor;
      label = 'Point — Team ${scorerTeam ?? '?'}';
    } else if (isSideout) {
      icon = Icons.swap_horiz_rounded;
      iconColor = theme.colorScheme.outline;
      label = 'Side-Out';
    } else if (event.eventType == 'game_end') {
      icon = Icons.flag_rounded;
      iconColor = theme.colorScheme.primary;
      label = 'Game End';
    } else if (event.eventType == 'match_end') {
      icon = Icons.emoji_events_rounded;
      iconColor = theme.colorScheme.primary;
      label = 'Match End';
    } else {
      icon = Icons.circle;
      iconColor = theme.colorScheme.outline;
      label = event.eventType;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: iconColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            '${event.teamAScore}–${event.teamBScore}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

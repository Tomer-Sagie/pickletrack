import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../database/database.dart';
import '../../providers/active_match_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/confirm_dialog.dart';
import 'resume_banner.dart';

/// Quick Play tab — the primary landing screen with hero header,
/// action cards, resume banner, and tournament section.
/// Extracted from the old HomeScreen.
class QuickPlayTab extends ConsumerStatefulWidget {
  const QuickPlayTab({super.key});

  @override
  ConsumerState<QuickPlayTab> createState() => _QuickPlayTabState();
}

class _QuickPlayTabState extends ConsumerState<QuickPlayTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeMatch = ref.watch(activeMatchProvider);

    final scoringRuleAsync = ref.watch(defaultScoringRuleProvider);
    final presetAsync = ref.watch(defaultScoringPresetProvider);
    final gameCountAsync = ref.watch(defaultGameCountProvider);
    final ruleLabel =
        (scoringRuleAsync.valueOrNull ?? 'sideout') == 'sideout'
            ? 'side-out'
            : 'rally';
    final ruleDisplay =
        (scoringRuleAsync.valueOrNull ?? 'sideout') == 'sideout'
            ? 'Side-Out'
            : 'Rally';
    final playTo = presetAsync.valueOrNull?.playTo ?? 11;
    final winBy = presetAsync.valueOrNull?.winBy ?? 2;
    final isBestOf3 = (gameCountAsync.valueOrNull ?? 1) == 3;
    final quickStartSubtitle = isBestOf3
        ? 'Doubles, $ruleLabel, best of 3, first to $playTo'
        : 'Doubles, $ruleLabel, $playTo';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AppLogo(theme: theme),
            const SizedBox(width: 10),
            Semantics(
              header: true,
              child: const Text('PickleTrack'),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeMatchProvider);
        },
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _buildHeroHeader(theme),
            const SizedBox(height: 20),

            // ── Active match resume banner ──
            activeMatch.when(
              data: (match) {
                if (match == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _DismissibleResumeBanner(
                    match: match,
                    ref: ref,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ── Action buttons ──
            _buildActionButtons(
                theme, quickStartSubtitle, ruleDisplay, playTo, winBy),

            const SizedBox(height: 14),

            // ── Tournaments section ──
            _TournamentsList(theme: theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Let\u{2019}s play.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track your pickleball matches — free, offline, no ads.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    ThemeData theme,
    String quickStartSubtitle,
    String ruleDisplay,
    int playTo,
    int winBy,
  ) {
    return Column(
      children: [
        // Primary CTA — prominent, taller, full-width
        SizedBox(
          width: double.infinity,
          child: _ActionCard(
            icon: Icons.bolt_rounded,
            label: 'Quick Start',
            subtitle: quickStartSubtitle,
            color: courtGreen,
            onTap: () =>
                _showQuickStartSheet(context, ruleDisplay, playTo, winBy),
            prominent: true,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.edit_note_rounded,
                label: 'New Match',
                subtitle: 'Custom setup',
                color: courtBlue,
                onTap: () => context.push('/match/setup'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                icon: Icons.emoji_events_rounded,
                label: 'Tournament',
                subtitle: 'Brackets & playoffs',
                color: const Color(0xFFE8A317),
                onTap: () => context.push('/tournament/setup'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showQuickStartSheet(
      BuildContext context, String ruleDisplay, int playTo, int winBy) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.bolt_rounded, size: 36, color: courtGreen),
              const SizedBox(height: 8),
              Text('Quick Start',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                  'Doubles · $ruleDisplay · First to $playTo, win by $winBy',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.push('/match/setup?quick=true');
                      },
                      child: const Text('Edit Setup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _quickStartMatch(ruleDisplay, playTo, winBy);
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start Match'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _quickStartMatch(
      String ruleDisplay, int playTo, int winBy) async {
    final scoringRule = ruleDisplay == 'Rally' ? 'rally' : 'sideout';
    final gameCount = (ref.read(defaultGameCountProvider).valueOrNull ?? 1);
    try {
      await createMatchInDb(
        ref: ref,
        type: 'doubles',
        scoringRule: scoringRule,
        gameCount: gameCount,
        playTo: playTo,
        winBy: winBy,
        players: [
          (name: 'Player A1', team: 'A',
              isStartingServer: true, position: 'right'),
          (name: 'Player A2', team: 'A',
              isStartingServer: false, position: 'left'),
          (name: 'Player B1', team: 'B',
              isStartingServer: false, position: 'right'),
          (name: 'Player B2', team: 'B',
              isStartingServer: false, position: 'left'),
        ],
      );
      if (mounted) context.go('/match/live');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start match: $e')),
        );
      }
    }
  }
}

// ── Action Card ──

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool prominent;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconContainer = prominent ? 64.0 : 48.0;

    return Semantics(
      button: true,
      label: '$label, $subtitle',
      child: Material(
        color: color.withValues(alpha: prominent ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                14, prominent ? 28 : 22, 14, prominent ? 24 : 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconContainer,
                  height: iconContainer,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: prominent ? 0.22 : 0.18),
                    borderRadius:
                        BorderRadius.circular(prominent ? 16 : 14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: prominent ? 30 : 26, color: color),
                ),
                SizedBox(height: prominent ? 14 : 12),
                Text(
                  label,
                  style: (prominent
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.titleSmall)
                      ?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dismissible Resume Banner ──

class _DismissibleResumeBanner extends StatelessWidget {
  final ActiveMatchContext match;
  final WidgetRef ref;

  const _DismissibleResumeBanner({required this.match, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('resume-banner-${match.match.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.5},
      confirmDismiss: (_) async {
        return await showConfirmDialog(
          context,
          title: 'Delete active match?',
          message: 'This will remove the active match. You cannot undo this.',
          confirmLabel: 'Delete',
          isDestructive: true,
        );
      },
      onDismissed: (_) async {
        final db = ref.read(databaseProvider);
        try {
          await db.transaction(() async {
            await db.delete(db.activeMatchPlayers).go();
            await db.delete(db.scoreEvents).go();
            await db.delete(db.activeMatches).go();
          });
          ref.invalidate(activeMatchProvider);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete match: $e')),
            );
          }
        }
      },
      background: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline_rounded,
            color: Theme.of(context).colorScheme.onError, size: 28),
      ),
      child: ResumeBanner(match: match),
    );
  }
}

// ── Tournaments List ──

class _TournamentsList extends ConsumerStatefulWidget {
  final ThemeData theme;
  const _TournamentsList({required this.theme});

  @override
  ConsumerState<_TournamentsList> createState() => _TournamentsListState();
}

class _TournamentsListState extends ConsumerState<_TournamentsList> {
  final Set<int> _deletedTournamentIds = {};

  @override
  Widget build(BuildContext context) {
    final tournaments = ref.watch(tournamentsProvider);
    return tournaments.when(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_outlined,
                    size: 18,
                    color:
                        widget.theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Tournaments',
                    style: widget.theme.textTheme.titleSmall?.copyWith(
                      color: widget.theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
            const SizedBox(height: 10),
            ...list
                .where((t) => !_deletedTournamentIds.contains(t.id))
                .map((t) => _DismissibleTournamentCard(
                      tournament: t,
                      ref: ref,
                      onDeleted: () {
                        setState(
                            () => _deletedTournamentIds.add(t.id));
                        ref.invalidate(tournamentsProvider);
                      },
                    )),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _DismissibleTournamentCard extends StatelessWidget {
  final Tournament tournament;
  final WidgetRef ref;
  final VoidCallback? onDeleted;

  const _DismissibleTournamentCard({
    required this.tournament,
    required this.ref,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('tournament-${tournament.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.5},
      confirmDismiss: (_) async {
        return await showConfirmDialog(
          context,
          title: 'Delete tournament?',
          message:
              'This permanently removes "${tournament.name}" and all its bracket data.',
          confirmLabel: 'Delete',
          isDestructive: true,
        );
      },
      onDismissed: (_) async {
        final db = ref.read(databaseProvider);
        try {
          await db.deleteTournament(tournament.id);
          onDeleted?.call();
        } catch (e) {
          debugPrint('Failed to delete tournament: $e');
          onDeleted?.call();
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline_rounded,
            color: Theme.of(context).colorScheme.onError, size: 28),
      ),
      child: _TournamentCard(
        tournament: tournament,
        onTap: () => context.push('/tournament/${tournament.id}'),
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const _TournamentCard({required this.tournament, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = tournament.status == 'completed';
    final formatLabel = tournament.format == 'single_elim'
        ? 'Single Elim'
        : tournament.format == 'double_elim'
            ? 'Double Elim'
            : 'Round Robin';
    final dateLabel = _formatDate(tournament.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: isComplete ? courtGreen : const Color(0xFFE8A317),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$formatLabel · ${tournament.type == 'singles' ? 'Singles' : 'Doubles'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isComplete)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: courtGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Done',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: courtGreen,
                              fontWeight: FontWeight.w700)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8A317)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Live',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFE8A317),
                              fontWeight: FontWeight.w700)),
                    ),
                  const SizedBox(height: 2),
                  Text(dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

// ── App Logo ──

class _AppLogo extends StatelessWidget {
  final ThemeData theme;
  const _AppLogo({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: const Size(20, 20),
        painter: _PaddleIconPainter(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _PaddleIconPainter extends CustomPainter {
  final Color color;
  const _PaddleIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final headRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(2, 0, size.width - 4, size.height * 0.72),
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4),
      bottomLeft: const Radius.circular(2),
      bottomRight: const Radius.circular(2),
    );
    canvas.drawRRect(headRect, paint);

    final handlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.32, size.height * 0.70,
            size.width * 0.36, size.height * 0.30),
        const Radius.circular(2),
      ),
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PaddleIconPainter oldDelegate) =>
      color != oldDelegate.color;
}

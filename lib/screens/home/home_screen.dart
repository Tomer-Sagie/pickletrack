import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../database/database.dart';
import '../../providers/active_match_provider.dart';
import '../../providers/completed_matches_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/colors.dart';
import '../../utils/match_helpers.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'resume_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeMatch = ref.watch(activeMatchProvider);
    final completedMatches = ref.watch(completedMatchesProvider);

    // Read the user's configured defaults so the Standard Start card
    // subtitle is always honest about what tapping it will actually do —
    // the previous hardcoded 'Doubles, side-out, 11' was a lie whenever
    // the user changed defaults in Settings.
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
    final standardStartSubtitle = isBestOf3
        ? 'Doubles, $ruleLabel, best of 3, first to $playTo'
        : 'Doubles, $ruleLabel, $playTo';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text(
                '\u{1F3D3}', // pickleball paddle emoji
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 10),
            const Text('PickleTrack'),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeMatchProvider);
          ref.invalidate(completedMatchesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            // ── Hero header ──
            _buildHeroHeader(theme),

            const SizedBox(height: 20),

            // ── Active match resume banner ──
            activeMatch.when(
              data: (match) {
                if (match == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ResumeBanner(match: match),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ── Action buttons ──
            _buildActionButtons(theme, standardStartSubtitle, ruleDisplay, playTo, winBy),

            const SizedBox(height: 32),

            // ── Completed matches section / empty state ──
            completedMatches.when(
              data: (matches) {
                final hasActive = activeMatch.valueOrNull != null;

                if (matches.isEmpty && hasActive) {
                  // Show the Match History header with a 'no matches yet'
                  // placeholder instead of blank space — the old
                  // SizedBox.shrink() left a gaping hole below the
                  // action buttons.
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            'Match History',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No completed matches yet.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                }

                if (matches.isEmpty) {
                  return EmptyState(
                    icon: Icons.sports_tennis_rounded,
                    iconColor: theme.colorScheme.primary,
                    title: 'Ready to play?',
                    subtitle:
                        'Tap Standard Start to jump right in\nor New Match to customize everything.',
                    action: FilledButton.icon(
                      onPressed: () => context.push('/match/setup'),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('New Match'),
                    ),
                  );
                }

                final filtered =
                    filterByPlayerName(matches, _searchQuery);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          'Match History',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by player name…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        isDense: true,
                      ),
                      style: theme.textTheme.bodyMedium,
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 10),
                    if (filtered.isEmpty && _searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "No matches found for '$_searchQuery'",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text('Clear Search'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filtered.map((m) => _CompletedMatchCard(
                            match: m,
                            onDeleted: () {
                              ref.invalidate(completedMatchesProvider);
                            },
                          )),
                    if (matches.isNotEmpty)
                      _buildStatsRow(theme, matches),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 36, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text('Failed to load match history',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () =>
                            ref.invalidate(completedMatchesProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
    String standardStartSubtitle,
    String ruleDisplay,
    int playTo,
    int winBy,
  ) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.bolt_rounded,
            label: 'Standard Start',
            subtitle: standardStartSubtitle,
            color: courtGreen,
            onTap: () => _showQuickStartSheet(context, ruleDisplay, playTo, winBy),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.edit_note_rounded,
            label: 'New Match',
            subtitle: 'Custom setup',
            color: courtBlue,
            onTap: () => context.push('/match/setup'),
          ),
        ),
      ],
    );
  }

  void _showQuickStartSheet(BuildContext context, String ruleDisplay, int playTo, int winBy) {
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
                  color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.bolt_rounded, size: 36, color: courtGreen),
              const SizedBox(height: 8),
              Text('Standard Start', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Doubles · $ruleDisplay · First to $playTo, win by $winBy',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
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

  Future<void> _quickStartMatch(String ruleDisplay, int playTo, int winBy) async {
    final scoringRule = ruleDisplay == 'Rally' ? 'rally' : 'sideout';
    final gameCount =
        (ref.read(defaultGameCountProvider).valueOrNull ?? 1);
    try {
      await createMatchInDb(
        ref: ref,
        type: 'doubles',
        scoringRule: scoringRule,
        gameCount: gameCount,
        playTo: playTo,
        winBy: winBy,
        players: [
          (name: 'Player A1', team: 'A', isStartingServer: true, position: 'right'),
          (name: 'Player A2', team: 'A', isStartingServer: false, position: 'left'),
          (name: 'Player B1', team: 'B', isStartingServer: false, position: 'right'),
          (name: 'Player B2', team: 'B', isStartingServer: false, position: 'left'),
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

  Widget _buildStatsRow(ThemeData theme, List<CompletedMatche> matches) {
    final stats = calculateMatchStats(matches);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(child: _StatCard(label: 'Played', value: '${stats.totalMatches}', color: theme.colorScheme.primary, theme: theme)),
          const SizedBox(width: 8),
          Expanded(child: _StatCard(label: 'Win Rate', value: '${stats.winRatePercent}%', color: courtGreen, theme: theme)),
          const SizedBox(width: 8),
          Expanded(child: _StatCard(label: 'Avg Score', value: stats.avgScoreLabel, color: courtBlue, theme: theme)),
        ],
      ),
    );
  }
}

// ── Action Card ──

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: '$label, $subtitle',
      child: Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

// ── Stat Card ──

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _StatCard({required this.label, required this.value, required this.color, required this.theme});

  @override
  Widget build(BuildContext context) {
return Semantics(
      label: '$label: $value',
      child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    ));
  }
}

// ── Completed Match Card ──

class _CompletedMatchCard extends StatelessWidget {
  final CompletedMatche match;
  final VoidCallback? onDeleted;

  const _CompletedMatchCard({required this.match, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool teamAWon = match.winner == 'A';
    final String dateLabel = _formatDate(match.completedAt);
    final String durLabel = _formatDuration(match.durationSeconds);
    final String scoreSummary = _formatScoreSummary(match.finalScores);

    return Semantics(
      label: 'Match: $scoreSummary, $dateLabel',
      hint: 'Double tap to view details, swipe left to delete',
      child: Dismissible(
      key: Key('match-${match.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.5},
      confirmDismiss: (_) async {
        return await showConfirmDialog(
          context,
          title: 'Delete match?',
          message: 'This permanently removes this match record.',
          confirmLabel: 'Delete',
          isDestructive: true,
        );
      },
      onDismissed: (_) async {
        final db = ProviderScope.containerOf(context, listen: false).read(databaseProvider);
        await (db.delete(db.completedMatches)..where((m) => m.id.equals(match.id))).go();
        await (db.delete(db.matchEventLog)..where((e) => e.completedMatchId.equals(match.id))).go();
        onDeleted?.call();
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
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => context.push('/match/${match.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: teamAWon ? courtGreen : courtBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scoreSummary,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        match.type == 'singles' ? 'Singles' : 'Doubles',
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
                    Text(
                      dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      durLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    if (min < 60) return '${min}m ${sec}s';
    final hr = min ~/ 60;
    return '${hr}h ${min % 60}m';
  }

  String _formatScoreSummary(String json) => formatScoreSummary(json);
}

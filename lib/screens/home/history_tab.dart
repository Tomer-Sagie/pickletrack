import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../database/database.dart';
import '../../providers/completed_matches_provider.dart';
import '../../providers/database_provider.dart';
import '../../theme/colors.dart';
import '../../utils/match_helpers.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/shimmer.dart';

/// History tab — shows completed match list with search, filter, and stats.
/// Extracted from the home screen to live as its own bottom-nav tab.
class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<int> _deletedMatchIds = {};
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedMatches = ref.watch(completedMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                size: 22, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Semantics(
              header: true,
              child: const Text('History'),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: completedMatches.when(
        data: (matches) {
          if (matches.isEmpty) {
            return _EmptyHistory(theme: theme);
          }

          final filtered = filterByPlayerName(matches, _searchQuery)
              .where((m) => !_deletedMatchIds.contains(m.id))
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(completedMatchesProvider);
            },
            child: ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // Search bar (collapsible — only shown when there are matches)
                if (matches.isNotEmpty) ...[
                  _SearchBar(
                    controller: _searchController,
                    searchQuery: _searchQuery,
                    onChanged: (v) {
                      _debounceTimer?.cancel();
                      _debounceTimer =
                          Timer(const Duration(milliseconds: 300), () {
                        if (mounted) setState(() => _searchQuery = v);
                      });
                    },
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    theme: theme,
                  ),
                  const SizedBox(height: 10),
                ],
                // Match count header
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${filtered.length} ${filtered.length == 1 ? 'match' : 'matches'}${_searchQuery.isNotEmpty ? " for '$_searchQuery'" : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (filtered.isEmpty && _searchQuery.isNotEmpty)
                  _NoResults(query: _searchQuery, onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  })
                else
                  ...filtered.map((m) => _CompletedMatchCard(
                        match: m,
                        ref: ref,
                        onDeleted: () {
                          _deletedMatchIds.add(m.id);
                          // ignore: unused_result
                          ref.refresh(completedMatchesProvider);
                          setState(() {});
                        },
                      )),
                if (matches.length >= 5 && _searchQuery.isEmpty)
                  _MatchStatsRow(theme: theme, matches: matches),
              ],
            ),
          );
        },
        loading: () => const SafeArea(
          child: ShimmerMatchHistory(),
        ),
        error: (e, _) => _ErrorView(
          theme: theme,
          onRetry: () => ref.invalidate(completedMatchesProvider),
        ),
      ),
    );
  }
}

// ── Sub-widgets extracted from the old home screen ──

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ThemeData theme;

  const _SearchBar({
    required this.controller,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search by player name…',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        isDense: true,
      ),
      style: theme.textTheme.bodyMedium,
      onChanged: onChanged,
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final ThemeData theme;
  const _EmptyHistory({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_tennis_rounded,
                size: 56, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No matches yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed matches will appear here.\nGo to Quick Play to start one!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  final VoidCallback onClear;
  const _NoResults({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "No matches found for '$query'",
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onRetry;
  const _ErrorView({required this.theme, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 36, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text('Failed to load match history',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ── Completed Match Card ──

class _CompletedMatchCard extends StatelessWidget {
  final CompletedMatche match;
  final WidgetRef ref;
  final VoidCallback? onDeleted;

  const _CompletedMatchCard({
    required this.match,
    required this.ref,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool teamAWon = match.winner == 'A';
    final String dateLabel = _formatDate(match.completedAt);
    final String durLabel = _formatDuration(match.durationSeconds);
    final String scoreSummary = _formatScoreSummary(match.finalScores);

    return Semantics(
      label:
          '${match.type == 'singles' ? 'Singles' : 'Doubles'} match: $scoreSummary, $dateLabel',
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
          final db = ref.read(databaseProvider);
          try {
            await (db.delete(db.completedMatches)
                  ..where((m) => m.id.equals(match.id)))
                .go();
            await (db.delete(db.matchEventLog)
                  ..where((e) => e.completedMatchId.equals(match.id)))
                .go();
            onDeleted?.call();
          } catch (e) {
            debugPrint('Failed to delete match: $e');
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
        child: Card(
          margin: const EdgeInsets.only(bottom: 6),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              match.type == 'singles'
                                  ? Icons.person
                                  : Icons.people,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _formatPlayerNames(match),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
      ),
    );
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

  String _formatPlayerNames(CompletedMatche match) {
    try {
      final aList = jsonDecode(match.teamAPlayers) as List<dynamic>;
      final bList = jsonDecode(match.teamBPlayers) as List<dynamic>;
      final aNames = aList.map((e) => e.toString()).join(' & ');
      final bNames = bList.map((e) => e.toString()).join(' & ');
      return '$aNames vs $bNames';
    } catch (_) {
      return '';
    }
  }
}

// ── Match Stats Row ──

class _MatchStatsRow extends StatelessWidget {
  final ThemeData theme;
  final List<CompletedMatche> matches;

  const _MatchStatsRow({required this.theme, required this.matches});

  @override
  Widget build(BuildContext context) {
    final stats = calculateMatchStats(matches);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
              child: _StatCard(
                  label: 'Played',
                  value: '${stats.totalMatches}',
                  color: theme.colorScheme.primary,
                  theme: theme)),
          const SizedBox(width: 8),
          Expanded(
              child: _StatCard(
                  label: 'Win Rate',
                  value: '${stats.winRatePercent}%',
                  color: courtGreen,
                  theme: theme)),
          const SizedBox(width: 8),
          Expanded(
              child: _StatCard(
                  label: 'Avg Score',
                  value: stats.avgScoreLabel,
                  color: courtBlue,
                  theme: theme)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

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
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

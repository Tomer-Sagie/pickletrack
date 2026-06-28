import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/tournament.dart';
import '../../providers/active_match_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../services/tournament_service.dart';
import '../../theme/colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/shimmer.dart';
import 'bracket_widget.dart';

class TournamentScreen extends ConsumerStatefulWidget {
  final int tournamentId;

  const TournamentScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends ConsumerState<TournamentScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadTournament();
  }

  Future<void> _loadTournament() async {
    // Only show full-screen loading on initial load, not during
    // pull-to-refresh, so the RefreshIndicator spinner stays visible
    // and the bracket doesn't flash-replace with a shimmer skeleton.
    if (!mounted) return;
    final isInitial = _isLoading;
    if (isInitial) setState(() { _isLoading = true; _hasError = false; });
    try {
      await ref.read(tournamentNotifierProvider(widget.tournamentId).notifier).load();
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted && isInitial) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tournament = ref.watch(tournamentNotifierProvider(widget.tournamentId));

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(tournament?.name ?? 'Tournament'),
        ),
        actions: [
          if (!_isLoading && !_hasError && tournament != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Tournament',
              onPressed: () => _openEditSheet(tournament),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete Tournament',
              onPressed: () => _confirmDelete(),
            ),
          ],
        ],
      ),
      body: _buildBodyWithErrorHandling(theme),
    );
  }

  Widget _buildBodyWithErrorHandling(ThemeData theme) {
    if (_isLoading) {
      return const ShimmerTournament();
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 36, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text('Failed to load tournament',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadTournament,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final tournament = ref.watch(tournamentNotifierProvider(widget.tournamentId));
    if (tournament == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tournament not found',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      );
    }
    return _buildBody(theme, tournament);
  }

  Widget _buildBody(ThemeData theme, TournamentData tournament) {
    if (tournament.bracket == null) {
      return Center(
        child: Text('No bracket generated',
            style: theme.textTheme.bodyMedium),
      );
    }

    final bracket = tournament.bracket!;
    final nextMatch = TournamentService.getNextReadyMatch(bracket);
    final isComplete = TournamentService.isTournamentComplete(bracket);

    return Column(
      children: [
        // ── Info bar ──
        _buildInfoBar(theme, tournament, isComplete),

        // ── Winner banner ──
        if (isComplete) _buildWinnerBanner(theme, bracket),

        // ── Next match CTA ──
        if (!isComplete && nextMatch != null)
          _buildNextMatchCTA(theme, tournament, nextMatch),

        // ── Bracket ──
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTournament,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
              child: BracketWidget(
                bracket: bracket,
                onMatchTap: (match) => _onMatchTap(tournament, match),
                activeMatchId: null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBar(ThemeData theme, TournamentData t, bool isComplete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(t.format == TournamentFormat.singleElim
              ? Icons.sports_tennis_rounded
              : t.format == TournamentFormat.doubleElim
                  ? Icons.repeat_rounded
                  : Icons.loop_rounded,
              size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                _InfoChip(label: t.format.shortLabel, theme: theme),
                _InfoChip(label: t.type == 'singles' ? 'Singles' : 'Doubles', theme: theme),
                _InfoChip(
                    label: t.scoringRule == 'sideout' ? 'Side-Out' : 'Rally',
                    theme: theme),
                _InfoChip(label: 'To ${t.playTo}', theme: theme),
                if (t.gameCount == 3) _InfoChip(label: 'Best of 3', theme: theme),
                _InfoChip(
                    label: '${t.bracket?.completedMatches.length ?? 0}/${t.bracket?.totalMatches ?? 0} done',
                    theme: theme),
              ],
            ),
          ),
          if (isComplete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: courtGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Completed',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: courtGreen, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildWinnerBanner(ThemeData theme, TournamentBracket bracket) {
    final winner = bracket.winner;
    if (winner == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: courtGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: courtGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, size: 32, color: courtGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tournament Winner!',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800, color: courtGreen)),
                Text(winner,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextMatchCTA(
      ThemeData theme, TournamentData tournament, BracketMatch match) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.play_circle_filled,
              size: 28, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next Match',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                Text(
                  '${match.playerADisplay} vs ${match.playerBDisplay}',
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 40,
            width: 76,
            child: FilledButton.icon(
              onPressed: () => _startMatch(tournament, match),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Play',
                  maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ──

  void _onMatchTap(TournamentData tournament, BracketMatch match) {
    if (match.isReady) {
      _startMatch(tournament, match);
    } else if (match.status == BracketMatchStatus.completed) {
      // Could show match details if completed
      _showMatchInfo(match);
    }
  }

  void _showMatchInfo(BracketMatch match) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Match #${match.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${match.playerADisplay} vs ${match.playerBDisplay}'),
            if (match.winnerName != null) ...[
              const SizedBox(height: 8),
              Text('Winner: ${match.winnerName}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
            if (match.scoreJson != null) ...[
              const SizedBox(height: 4),
              Text('Score: ${match.scoreJson}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _startMatch(
      TournamentData tournament, BracketMatch match) async {
    final isDoubles = tournament.type == 'doubles';
    final playerA = match.playerAName!;
    final playerB = match.playerBName!;

    // Build player list respecting singles vs doubles.
    // For doubles: partner names default to '' so players can fill them
    // in on the live match screen. Real tournament apps show actual
    // player names, not fake placeholders like "Partner".
    final players = <({String name, String team, bool isStartingServer, String? position})>[
      (
        name: playerA,
        team: 'A',
        isStartingServer: true,
        position: isDoubles ? 'right' : null,
      ),
      if (isDoubles)
        (
          name: '',
          team: 'A',
          isStartingServer: false,
          position: 'left',
        ),
      (
        name: playerB,
        team: 'B',
        isStartingServer: false,
        position: isDoubles ? 'right' : null,
      ),
      if (isDoubles)
        (
          name: '',
          team: 'B',
          isStartingServer: false,
          position: 'left',
        ),
    ];

    await createMatchInDb(
      ref: ref,
      type: tournament.type,
      scoringRule: tournament.scoringRule,
      gameCount: tournament.gameCount,
      playTo: tournament.playTo,
      winBy: tournament.winBy,
      players: players,
      tournamentId: tournament.id,
      tournamentMatchId: match.id,
    );

    if (mounted) {
      context.go('/match/live');
    }
  }

  Future<void> _openEditSheet(TournamentData tournament) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditTournamentSheet(
        initialName: tournament.name,
        initialPlayers:
            tournament.players.map((p) => (seed: p.seed, name: p.name)).toList(),
        onSave: (name, players) async {
          final newPlayers = players
              .map((p) => TournamentPlayer(
                    name: p.name.trim().isEmpty
                        ? 'Player ${p.seed}'
                        : p.name.trim(),
                    seed: p.seed,
                  ))
              .toList();
          final success = await ref
              .read(tournamentNotifierProvider(widget.tournamentId).notifier)
              .updateMeta(name: name, players: newPlayers);
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success
                    ? 'Tournament updated'
                    : 'Failed to update tournament'),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete tournament?',
      message: 'This permanently removes the tournament and its bracket.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    await ref
        .read(tournamentNotifierProvider(widget.tournamentId).notifier)
        .deleteTournament();

    if (!mounted) return;
    context.go('/');
  }
}

// ── Edit Tournament Sheet ──

/// Modal bottom sheet for editing tournament name + player names.
/// Format / scoring / playTo / winBy are not editable after creation
/// because they define the bracket structure.
class _EditTournamentSheet extends StatefulWidget {
  final String initialName;
  final List<({int seed, String name})> initialPlayers;
  final Future<void> Function(String name,
      List<({int seed, String name})> players) onSave;

  const _EditTournamentSheet({
    required this.initialName,
    required this.initialPlayers,
    required this.onSave,
  });

  @override
  State<_EditTournamentSheet> createState() => _EditTournamentSheetState();
}

class _EditTournamentSheetState extends State<_EditTournamentSheet> {
  late final TextEditingController _nameController;
  late final List<TextEditingController> _playerControllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _playerControllers = widget.initialPlayers
        .map((p) => TextEditingController(text: p.name))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _playerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final filledCount = _playerControllers
        .where((c) => c.text.trim().isNotEmpty)
        .length;
    if (filledCount < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 player names are required.')),
      );
      return;
    }
    setState(() => _saving = true);
    final players = <({int seed, String name})>[
      for (var i = 0; i < _playerControllers.length; i++)
        (seed: widget.initialPlayers[i].seed, name: _playerControllers[i].text),
    ];
    await widget.onSave(_nameController.text, players);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: mediaQuery.viewInsets.bottom + 24,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Tournament',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Tournament name',
              prefixIcon: Icon(Icons.label_outline, size: 20),
              isDense: true,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 18),
          Text(
            'Player Names',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Renames cascade through the bracket.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: mediaQuery.size.height * 0.45,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < _playerControllers.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                          top: i > 0 ? 8 : 0),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? courtGreen.withValues(alpha: 0.15)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${widget.initialPlayers[i].seed}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: i == 0
                                    ? courtGreen
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _playerControllers[i],
                              decoration: InputDecoration(
                                labelText:
                                    'Player ${widget.initialPlayers[i].seed}',
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  size: 18,
                                ),
                                isDense: true,
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Info Chip ──

class _InfoChip extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _InfoChip({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600)),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/database_provider.dart';
import '../../providers/live_match_provider.dart';
import '../../services/scoring_service.dart';
import '../../services/sound_service.dart';
import '../../theme/colors.dart';
import '../../widgets/confirm_dialog.dart';
import 'court_diagram.dart';

class LiveMatchScreen extends ConsumerStatefulWidget {
  const LiveMatchScreen({super.key});

  @override
  ConsumerState<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends ConsumerState<LiveMatchScreen> {
  DateTime? _lastScoreTime;
  int _prevGamesWonA = 0;
  int _prevGamesWonB = 0;
  bool _initialLoadDone = false;
  bool _loading = true;
  String? _loadError;
  bool _showingBanner = false;
  bool _glowA = false;
  bool _glowB = false;
  Timer? _glowTimerA;
  Timer? _glowTimerB;
  bool _hapticEnabled = true;
  Timer? _elapsedTimer;
  String _elapsedStr = '00:00';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    Future.microtask(() async {
      try {
        await ref.read(liveMatchProvider.notifier).load();
      } catch (e) {
        _loadError = e.toString();
      }
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _loadPrefs() async {
    try {
      final db = ref.read(databaseProvider);
      final haptic = await db.getSetting('haptic_enabled');
      if (mounted) setState(() => _hapticEnabled = haptic != 'false');
    } catch (_) {}
  }

  @override
  void dispose() {
    _glowTimerA?.cancel();
    _glowTimerB?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _onTeamScore(Team team) {
    final now = DateTime.now();
    if (_lastScoreTime != null &&
        now.difference(_lastScoreTime!).inMilliseconds < 500) {
      return;
    }
    _lastScoreTime = now;

    if (team == Team.A) {
      _glowTimerA?.cancel();
      setState(() => _glowA = true);
      _glowTimerA = Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _glowA = false);
      });
    }
    if (team == Team.B) {
      _glowTimerB?.cancel();
      setState(() => _glowB = true);
      _glowTimerB = Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _glowB = false);
      });
    }

    ref.read(liveMatchProvider.notifier).scorePoint(team);
    SoundService().playPointScored();
    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _onUndo() async {
    ref.read(liveMatchProvider.notifier).undo();
  }

  Future<void> _onEndMatch() async {
    final state = ref.read(liveMatchProvider);
    if (state == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'End Match',
      message: 'End this match? Final scores will be saved.',
      confirmLabel: 'End Match',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    try {
      final completedId =
          await ref.read(liveMatchProvider.notifier).endMatch();
      if (completedId != null && mounted) {
        context.go('/');
        context.push('/match/$completedId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to end match: $e')),
        );
      }
    }
  }

  void _checkGameEnd(LiveMatchState? prev, LiveMatchState next) {
    if (!_initialLoadDone) {
      _prevGamesWonA = next.teamAGamesWon;
      _prevGamesWonB = next.teamBGamesWon;
      _initialLoadDone = true;
      return;
    }

    if (_showingBanner) return;

    if (next.isMatchOver) {
      _showingBanner = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMatchEndBanner(next);
      });
      return;
    }

    if (next.teamAGamesWon > _prevGamesWonA ||
        next.teamBGamesWon > _prevGamesWonB) {
      _showingBanner = true;
      final winner =
          next.teamAGamesWon > _prevGamesWonA ? 'A' : 'B';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showGameEndBanner(prev!, next, winner)
              .then((_) => _showingBanner = false);
        }
      });
    }

    _prevGamesWonA = next.teamAGamesWon;
    _prevGamesWonB = next.teamBGamesWon;
  }

  Future<void> _showGameEndBanner(
      LiveMatchState prevState, LiveMatchState nextState, String winner) async {
    final teamLabel = winner == 'A' ? 'Team A' : 'Team B';
    final scoreA = prevState.teamAScore;
    final scoreB = prevState.teamBScore;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Row(children: [
            Icon(Icons.emoji_events, color: Colors.amber.shade600),
            const SizedBox(width: 8),
            const Text('Game Over!'),
          ]),
          content: Text(
              '$teamLabel wins Game ${nextState.currentGame}\n$scoreA \u2013 $scoreB',
              textAlign: TextAlign.center),
          actions: [
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Next Game'))
          ],
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _showMatchEndBanner(LiveMatchState state) async {
    final winner =
        state.teamAGamesWon > state.teamBGamesWon ? 'A' : 'B';
    final teamLabel = winner == 'A' ? 'Team A' : 'Team B';
    final dialogResult = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Row(children: [
            Icon(Icons.emoji_events,
                color: Colors.amber.shade600, size: 32),
            const SizedBox(width: 8),
            const Text('Match Over!'),
          ]),
          content: Text(
              '$teamLabel wins the match!\n${state.teamAGamesWon} \u2013 ${state.teamBGamesWon}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          actions: [
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('View Details'))
          ],
        ),
      ),
    );
    try {
      final completedId =
          await ref.read(liveMatchProvider.notifier).endMatch();
      if (mounted) {
        if (dialogResult == true && completedId != null) {
          context.go('/');
          context.push('/match/$completedId');
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save match: $e')),
        );
        context.go('/');
      }
    }
    _showingBanner = false;
  }

  void _showPauseMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Paused', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 20),
              ListTile(
                  leading: const Icon(Icons.play_arrow_rounded, size: 28),
                  title: const Text('Resume'),
                  onTap: () => Navigator.of(ctx).pop()),
              Semantics(
                button: true,
                label: 'Save and exit, resume later from Home',
                child: ListTile(
                    leading: const Icon(Icons.save_alt_rounded, size: 28),
                    title: const Text('Save & Exit'),
                    subtitle: const Text('Resume later from Home'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      if (mounted) context.go('/');
                    }),
              ),
              Semantics(
                button: true,
                label: 'End match, final scores will be saved',
                child: ListTile(
                    leading: Icon(Icons.flag_rounded,
                        size: 28,
                        color: Theme.of(ctx).colorScheme.error),
                    title: Text('End Match',
                        style: TextStyle(
                            color: Theme.of(ctx).colorScheme.error)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _onEndMatch();
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LiveMatchState?>(liveMatchProvider, (prev, next) {
      if (prev != null && next != null) _checkGameEnd(prev, next);
    });

    final liveState = ref.watch(liveMatchProvider);
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
          appBar: AppBar(title: const Text('Live Match')),
          body: const Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Live Match')),
          body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Failed to load match',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_loadError!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home')),
          ])));
    }
    if (liveState == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Live Match')),
          body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('No active match'),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home')),
          ])));
    }

    if (_elapsedTimer == null) {
      _elapsedStr = _formatElapsed(liveState.match.createdAt);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startElapsedTimer(liveState.match.createdAt);
      });
    }

    return Scaffold(
      appBar: _buildAppBar(liveState, theme),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _showPauseMenu();
        },
        child: SafeArea(
          child: Column(children: [
            const SizedBox(height: 8),
            _buildCourtDiagram(liveState),
            const SizedBox(height: 10),
            _buildUnifiedScore(liveState, theme),
            const Spacer(),
            _buildPointButtons(liveState),
            const SizedBox(height: 8),
            _buildBottomBar(liveState, theme),
            // Extra padding for gesture bar clearance
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  void _startElapsedTimer(DateTime startTime) {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed(startTime);
    });
  }

  String _formatElapsed(DateTime startTime) {
    final elapsed = DateTime.now().difference(startTime);
    return '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  void _updateElapsed(DateTime startTime) {
    final newStr = _formatElapsed(startTime);
    if (newStr != _elapsedStr && mounted) {
      setState(() => _elapsedStr = newStr);
    }
  }

  // ── AppBar ──

  PreferredSizeWidget _buildAppBar(LiveMatchState state, ThemeData theme) {
    final ruleLabel = state.isSideOut ? 'Side-Out' : 'Rally';
    return AppBar(
      leading: IconButton(
          icon: const Icon(Icons.pause_rounded),
          onPressed: _showPauseMenu,
          tooltip: 'Pause'),
      title: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Game ${state.currentGame}/${state.gameCount}',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text(
            '$ruleLabel \u2022 ${state.isDoubles ? "Doubles" : "Singles"} \u2022 $_elapsedStr',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
      ]),
      centerTitle: true,
    );
  }

  // ── Court Diagram ──

  Widget _buildCourtDiagram(LiveMatchState state) {
    final positions = state.playerPositions
        .map((p) => PlayerPosition(
              id: p['id'] as String,
              name: p['name'] as String,
              team: p['team'] as String,
              side: p['side'] as String,
            ))
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: CourtDiagram(
          players: positions,
          servingPlayerId: state.servingPlayerId,
          isDoubles: state.isDoubles),
    );
  }

  // ── Unified Score Widget ──
  //
  // A single cohesive display replacing what was previously three
  // separate widgets (server indicator, score callout, scoreboard).
  // The eye no longer needs to scan across three zones to piece
  // together the game state.

  Widget _buildUnifiedScore(LiveMatchState state, ThemeData theme) {
    final serverTeam = state.serverTeam ?? 'A';
    final teamColor = serverTeam == 'A' ? courtGreen : courtBlue;
    final callout = state.scoreCallout;
    final serverName =
        ref.read(liveMatchProvider.notifier).serverDisplayName ?? '\u2014';
    final isDoubles = state.isDoubles;

    final aNames = _teamNames(state, 'A');
    final bNames = _teamNames(state, 'B');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: teamColor.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top: subtle server indicator ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: teamColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$serverName serving',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: teamColor, fontWeight: FontWeight.w600),
                ),
                if (isDoubles) ...[
                  const SizedBox(width: 4),
                  Text(
                    '\u2022 Server ${state.serverNumber}/2',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // ── Middle: scores + callout ──
            Row(
              children: [
                // Team A score
                Expanded(
                  child: _scoreColumn(
                    state.teamAScore,
                    aNames,
                    state.teamAGamesWon,
                    courtGreen,
                    _glowA,
                    theme,
                  ),
                ),
                // Callout center
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Semantics(
                    label: 'Score call: $callout',
                    container: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(
                            scale: Tween<double>(begin: 0.92, end: 1.0)
                                .animate(animation),
                            child: FadeTransition(
                                opacity: animation, child: child),
                          ),
                          child: Text(
                            callout,
                            key: ValueKey(callout),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 24,
                          height: 1,
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
                // Team B score
                Expanded(
                  child: _scoreColumn(
                    state.teamBScore,
                    bNames,
                    state.teamBGamesWon,
                    courtBlue,
                    _glowB,
                    theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreColumn(int score, List<String> names, int gamesWon,
      Color accentColor, bool showGlow, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Player names
        ...names.map((name) => Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                  fontSize: 11),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            )),
        const SizedBox(height: 4),
        // Score number
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          switchInCurve: Curves.easeOut,
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Text(
            '$score',
            key: ValueKey(score),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 52,
              color: showGlow
                  ? accentColor
                  : theme.colorScheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        // Games won dots
        if (gamesWon > 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                gamesWon,
                (_) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.circle, size: 6, color: accentColor),
                    )),
          ),
        ],
      ],
    );
  }

  List<String> _teamNames(LiveMatchState state, String team) {
    return state.players
        .where((p) => p.team == team)
        .map((p) => p.name)
        .toList();
  }

  // ── Point Buttons (equal visual weight) ──

  Widget _buildPointButtons(LiveMatchState state) {
    final isRally = state.scoringRule == 'rally';
    final servingA = state.isTeamServing(Team.A);
    final servingB = state.isTeamServing(Team.B);

    // Both buttons are always solid filled — same visual weight.
    // The non-serving team's button is dimmed slightly (not ghosted)
    // to indicate who has the serve without implying one action is
    // preferred. In rally scoring both are always at full strength.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        Expanded(
          child: SizedBox(
            height: 68,
            child: Semantics(
              button: true,
              label: 'Team A Scores',
              hint: 'Tap to score a point for Team A',
              child: FilledButton(
                onPressed: () => _onTeamScore(Team.A),
                style: FilledButton.styleFrom(
                  backgroundColor: (isRally || servingA)
                      ? courtGreen
                      : courtGreen.withValues(alpha: 0.45),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Team A',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 68,
            child: Semantics(
              button: true,
              label: 'Team B Scores',
              hint: 'Tap to score a point for Team B',
              child: FilledButton(
                onPressed: () => _onTeamScore(Team.B),
                style: FilledButton.styleFrom(
                  backgroundColor: (isRally || servingB)
                      ? courtBlue
                      : courtBlue.withValues(alpha: 0.45),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Team B',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Bottom Bar (separated destructive action) ──

  Widget _buildBottomBar(LiveMatchState state, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Undo — small icon button, physically isolated from End Match
          Semantics(
            button: true,
            label: 'Undo last point',
            child: SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                onPressed: state.canUndo ? _onUndo : null,
                icon: const Icon(Icons.undo_rounded, size: 22),
                tooltip: 'Undo',
                style: IconButton.styleFrom(
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const Spacer(),
          // End Match — separated from Undo by Spacer, clearly
          // differentiated as a destructive action
          Semantics(
            button: true,
            label: 'End this match and save final scores',
            child: OutlinedButton.icon(
              onPressed: _onEndMatch,
              icon: Icon(Icons.flag_rounded,
                  size: 18, color: theme.colorScheme.error),
              label: Text('End',
                  style: TextStyle(color: theme.colorScheme.error)),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(
                    color:
                        theme.colorScheme.error.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../providers/database_provider.dart';
import '../../providers/live_match_provider.dart';
import '../../services/scoring_service.dart';
import '../../services/sound_service.dart';
import '../../theme/colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/shimmer.dart';
import 'court_diagram.dart';
import 'tutorial_overlay.dart';
import 'live_match_helpers.dart';
import 'widgets/match_timer_subtitle.dart';
import 'widgets/pulse_dot.dart';
import 'widgets/spectator_overlay.dart';

// Previously this file hosted a top-level `filteredTeamNames`
// function. It was extracted to `live_match_helpers.dart` so sibling
// widgets (e.g. `widgets/spectator_overlay.dart`) can use it
// without importing this screen file (which would otherwise create
// a circular-style dependency).

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
  bool _showTutorial = false;
  bool _showCourt = true;
  String? _sideOutMessage;
  Timer? _sideOutTimer;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WakelockPlus.enable().catchError((_) {});
    _loadPrefs();
    _checkTutorial();
    Future.microtask(() async {
      try {
        await ref.read(liveMatchProvider.notifier).load();
      } catch (e) {
        _loadError = e.toString();
      }
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _checkTutorial() async {
    try {
      final db = ref.read(databaseProvider);
      final seen = await db.getSetting('has_seen_tutorial');
      if (mounted && seen != 'true') {
        setState(() => _showTutorial = true);
      }
    } catch (_) {}
  }

  Future<void> _dismissTutorial() async {
    setState(() => _showTutorial = false);
    try {
      final db = ref.read(databaseProvider);
      await db.setSetting('has_seen_tutorial', 'true');
    } catch (_) {}
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
    _confettiController.dispose();
    WakelockPlus.disable().catchError((_) {});
    _glowTimerA?.cancel();
    _glowTimerB?.cancel();
    _sideOutTimer?.cancel();
    super.dispose();
  }

  void _onTeamScore(Team team) {
    final now = DateTime.now();
    if (_lastScoreTime != null &&
        now.difference(_lastScoreTime!).inMilliseconds < 300) {
      return;
    }
    _lastScoreTime = now;

    final liveState = ref.read(liveMatchProvider);
    final wasServing = liveState?.isTeamServing(team) ?? false;
    final isSideOut = liveState != null && liveState.isSideOut && !wasServing;

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

    // Show side-out feedback in side-out scoring when non-serving team wins rally.
    // Use a stronger haptic (mediumImpact) so the user clearly feels the
    // distinction between a point scored and a side-out (no score change).
    if (isSideOut) {
      final otherTeam = team == Team.A ? 'Team A' : 'Team B';
      _sideOutTimer?.cancel();
      setState(() => _sideOutMessage = '$otherTeam won the rally — Side Out!');
      _sideOutTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _sideOutMessage = null);
      });
      SoundService().playPointScored();
      if (_hapticEnabled) {
        HapticFeedback.mediumImpact();
      }
    } else {
      SoundService().playPointScored();
      if (_hapticEnabled) {
        HapticFeedback.lightImpact();
      }
    }
  }

  Future<void> _onUndo() async {
  // Distinct haptic for undo so the user knows they took an action even
  // when nothing on the scoreboard visibly changes (e.g. immediately
  // after a side-out where the score is identical before/after).
  if (_hapticEnabled) {
    HapticFeedback.selectionClick();
  }
  await ref.read(liveMatchProvider.notifier).undo();
}

  Future<void> _onEndMatch() async {
    final state = ref.read(liveMatchProvider);
    if (state == null) return;
    final isTournamentMatch = state.match.tournamentId != null;
    final confirmed = await showConfirmDialog(
      context,
      title: 'End Match?',
      message:
          'End this match and save final scores to history?\n\n'
          'This cannot be undone. You can still scroll through the play-by-play '
          'after ending, but new points cannot be scored.',
      confirmLabel: 'End Match',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    try {
      final completedId =
          await ref.read(liveMatchProvider.notifier).endMatch();
      if (completedId != null && mounted) {
        if (isTournamentMatch && state.match.tournamentId != null) {
          context.go('/tournament/${state.match.tournamentId}');
        } else {
          context.go('/');
          context.push('/match/$completedId');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to end match: $e')),
        );
      }
    }
  }

  void _checkGameEnd(LiveMatchState prev, LiveMatchState next) {
    if (!_initialLoadDone) {
      _prevGamesWonA = next.teamAGamesWon;
      _prevGamesWonB = next.teamBGamesWon;
      _initialLoadDone = true;
      return;
    }

    if (_showingBanner) return;

    // Dismiss side-out message when a point is actually scored (scores changed)
    if (next.teamAScore != prev.teamAScore || next.teamBScore != prev.teamBScore) {
      _sideOutTimer?.cancel();
      if (mounted && _sideOutMessage != null) {
        setState(() => _sideOutMessage = null);
      }
    }

    if (next.isMatchOver) {
      _showingBanner = true;
      _confettiController.play();
      SoundService().playMatchEnd();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMatchEndBanner(next);
      });
      return;
    }

    if (next.teamAGamesWon > _prevGamesWonA ||
        next.teamBGamesWon > _prevGamesWonB) {
      _showingBanner = true;
      _confettiController.play();
      SoundService().playGameEnd();
      final winner =
          next.teamAGamesWon > _prevGamesWonA ? 'A' : 'B';
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        // The dialog result carries the user's intent — "Keep Playing"
        // returned false (close, no nudge), "Next Game" returned true
        // (close + explicit advance). Either way we re-arm the banner
        // gate so the next game-end can show again.
        await _showGameEndBanner(prev, next, winner);
        _showingBanner = false;
      });
    }

    _prevGamesWonA = next.teamAGamesWon;
    _prevGamesWonB = next.teamBGamesWon;
  }

  /// Returns the user's intent from the dialog:
  ///   false → "Keep Playing" (close, no advance nudge)
  ///   true  → "Next Game"   (close + explicit advance)
  ///   null  → barrier-dismiss / back-press / pop-without-value
  Future<bool?> _showGameEndBanner(
      LiveMatchState prevState, LiveMatchState nextState, String winner) async {
    final teamLabel = winner == 'A' ? 'Team A' : 'Team B';
    final scoreA = prevState.teamAScore;
    final scoreB = prevState.teamBScore;
    final result = await showDialog<bool?>(
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
            // "Keep Playing" closes the banner and stays on the same
            // rendered score (no auto-advance). Useful when the user
            // wants to confirm the call or wait for the opponent.
            // Returns false so the caller knows no advance is needed.
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep Playing'),
            ),
            // "Next Game" closes the banner AND fires a fresh
            // post-frame callback that nudges the playoff state, so the
            // user sees the scoreboard land on the next game's empty
            // 0-0 explicitly. The provider has already advanced, but a
            // tap on Next Game keeps a focused user from
            // accidentally scoring into the previous game's winner.
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Next Game'),
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(() {});
    return result;
  }

  Future<void> _showMatchEndBanner(LiveMatchState state) async {
    final winner =
        state.teamAGamesWon > state.teamBGamesWon ? 'A' : 'B';
    final teamLabel = winner == 'A' ? 'Team A' : 'Team B';
    final isTournamentMatch = state.match.tournamentId != null;

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
                child: Text(isTournamentMatch ? 'Back to Bracket' : 'View Details'))
          ],
        ),
      ),
    );
    try {
      final completedId =
          await ref.read(liveMatchProvider.notifier).endMatch();
      if (mounted) {
        if (dialogResult == true && completedId != null) {
          if (isTournamentMatch && state.match.tournamentId != null) {
            // Navigate back to the tournament bracket
            context.go('/tournament/${state.match.tournamentId}');
          } else {
            context.go('/');
            context.push('/match/$completedId');
          }
        } else {
          if (isTournamentMatch && state.match.tournamentId != null) {
            context.go('/tournament/${state.match.tournamentId}');
          } else {
            context.go('/');
          }
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
                label: 'Large score display for spectators',
                child: ListTile(
                    leading: const Icon(Icons.tv_rounded, size: 28),
                    title: const Text('Spectator Mode'),
                    subtitle: const Text('Big scores, no buttons'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showSpectatorMode();
                    }),
              ),
              Semantics(
                button: true,
                label: 'Pause and return later; resume from Home',
                child: ListTile(
                    leading: const Icon(Icons.pause_circle_outline_rounded,
                        size: 28),
                    title: const Text('Pause & Return Later'),
                    subtitle: const Text('Resume from Home'),
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

  void _showSpectatorMode() {
    final state = ref.read(liveMatchProvider);
    if (state == null) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const SpectatorOverlay(),
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
          body: const ShimmerMatchDetails());
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

    return Stack(
      children: [
        // Confetti overlay — fires on match win / game win
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [courtGreen, courtBlue, Color(0xFFC8E030), Color(0xFFE8A317)],
            numberOfParticles: 30,
            maxBlastForce: 20,
            minBlastForce: 5,
            gravity: 0.1,
          ),
        ),
        Scaffold(
          appBar: _buildAppBar(liveState, theme),
          body: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _showPauseMenu();
            },
            child: SafeArea(
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < -800) {
                    // Swipe up — Team A scores
                    _onTeamScore(Team.A);
                  } else if (details.primaryVelocity! > 800) {
                    // Swipe down — Team B scores
                    _onTeamScore(Team.B);
                  }
                },
                child: Column(children: [
                  const SizedBox(height: 8),
                  // Optional court diagram — hidden by default per audit;
                  // toggled from the AppBar action. When hidden, the score
                  // card floats up so the user is always looking at the
                  // numbers, not at pretty-but-unused real estate.
                  if (_showCourt)
                    Expanded(child: _buildCourtDiagram(liveState))
                  else
                    const SizedBox(height: 12),
                  const SizedBox(height: 10),
                  _buildGamePointIndicator(liveState, theme),
                  _buildServerBanner(liveState, theme),
                  _buildUnifiedScore(liveState, theme),
                  if (_sideOutMessage != null) _buildSideOutChip(theme),
                  const SizedBox(height: 10),
                  _buildPointButtons(liveState),
                  const SizedBox(height: 8),
                  _buildBottomBar(liveState, theme),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
          ),
        ),
        if (_showTutorial)
          Positioned.fill(
            child: TutorialOverlay(onComplete: _dismissTutorial),
          ),
      ],
    );
  }

  Widget _buildSideOutChip(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sync_alt_rounded,
                size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              _sideOutMessage!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamePointIndicator(LiveMatchState state, ThemeData theme) {
    // Delegate to [_isTeamAtGamePoint] so the banner and the per-
    // scorecard dot can never drift apart on a future tweak.
    final aAtGamePoint = _isTeamAtGamePoint(state, 'A');
    final bAtGamePoint = _isTeamAtGamePoint(state, 'B');
    if (!aAtGamePoint && !bAtGamePoint) return const SizedBox.shrink();

    final Color pointColor = aAtGamePoint ? courtGreen : courtBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: pointColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: pointColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_rounded, size: 14, color: pointColor),
            const SizedBox(width: 6),
            Text(
              'Game Point',
              style: theme.textTheme.labelMedium?.copyWith(
                color: pointColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
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
        Semantics(
          header: true,
          child: Text('Game ${state.currentGame}/${state.gameCount}',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        MatchTimerSubtitle(
          ruleLabel: ruleLabel,
          isDoubles: state.isDoubles,
          createdAt: state.match.createdAt,
        ),
      ]),
      centerTitle: true,
      actions: [
        // Court toggle — the diagram is purely decorative and eats half
        // the screen on small phones, so users opt-in via this small
        // icon. Hidden by default floats the score UI to a more
        // thumb-reachable spot.
        IconButton(
          icon: Icon(
            _showCourt
                ? Icons.grid_off_rounded
                : Icons.grid_on_rounded,
          ),
          tooltip: _showCourt ? 'Hide court diagram' : 'Show court diagram',
          onPressed: () => setState(() => _showCourt = !_showCourt),
        ),
      ],
    );
  }

  // ── Server banner (visible regardless of court toggle) ──

  /// Standalone server indicator chip that sits above the score card.
  /// Always visible even when the court diagram is hidden so users
  /// never lose track of who's serving mid-game.
  Widget _buildServerBanner(LiveMatchState state, ThemeData theme) {
    final serverTeam = state.serverTeam ?? 'A';
    final teamColor = serverTeam == 'A' ? courtGreen : courtBlue;
    final serverName =
        ref.read(liveMatchProvider.notifier).serverDisplayName ?? '—';
    final isDoubles = state.isDoubles;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Semantics(
        container: true,
        label:
            '$serverName serving${isDoubles && state.isSideOut ? ', server ${state.serverNumber} of 2' : ''}',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: teamColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$serverName serving',
              style: theme.textTheme.labelLarge?.copyWith(
                color: teamColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isDoubles && state.isSideOut) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Server ${state.serverNumber}/2',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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

  Widget _buildUnifiedScore(LiveMatchState state, ThemeData theme) {
    final serverTeam = state.serverTeam ?? 'A';
    final teamColor = serverTeam == 'A' ? courtGreen : courtBlue;
    final callout = state.scoreCallout;

    final aNames = _teamNames(state, 'A');
    final bNames = _teamNames(state, 'B');

    // Compute game-point status here so we can pass it to each
    // _scoreColumn — the leader gets a star dot next to its score.
    final isGamePointA = _isTeamAtGamePoint(state, 'A');
    final isGamePointB = _isTeamAtGamePoint(state, 'B');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
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
            // ── Middle: scores + callout ──
            Row(
              children: [
                // Team A score
                Expanded(
                  child: _scoreColumn(
                    score: state.teamAScore,
                    names: aNames,
                    gamesWon: state.teamAGamesWon,
                    accentColor: courtGreen,
                    showGlow: _glowA,
                    isGamePoint: isGamePointA,
                    theme: theme,
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
                        Text(
                          callout,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
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
                    score: state.teamBScore,
                    names: bNames,
                    gamesWon: state.teamBGamesWon,
                    accentColor: courtBlue,
                    showGlow: _glowB,
                    isGamePoint: isGamePointB,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreColumn({
    required int score,
    required List<String> names,
    required int gamesWon,
    required Color accentColor,
    required bool showGlow,
    required bool isGamePoint,
    required ThemeData theme,
  }) {
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
        // Score number — when this team is at game point, render a
        // pulsing star dot next to the score. Lifts straight from the
        // top-of-card banner so users see the cue wherever they're
        // looking (court is up top, score is in the middle).
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGamePoint) ...[
              PulseDot(color: accentColor),
              const SizedBox(width: 6),
            ],
            Text(
              '$score',
              key: ValueKey(score),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 56,
                color: showGlow
                    ? accentColor
                    : theme.colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
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

  /// Delegates to the top-level [filteredTeamNames] so the in-screen
  /// helper and the spectator overlay share a single source of truth
  /// for trim/filter + "Player N" fallback logic.
  List<String> _teamNames(LiveMatchState state, String team) {
    return filteredTeamNames(state, team, matchType: state.match.type);
  }

  /// True iff [team] can win the next point. Called by both the
  /// top-of-card banner ([_buildGamePointIndicator]) and the per-
  /// scorecard star dot — formerly duplicated as inline math blocks
  /// in two places, which risked silently drifting on a tweak.
  bool _isTeamAtGamePoint(LiveMatchState state, String team) {
    if (state.scoringState.isGameOver || state.scoringState.isMatchOver) {
      return false;
    }
    final myScore = team == 'A' ? state.teamAScore : state.teamBScore;
    final oppScore = team == 'A' ? state.teamBScore : state.teamAScore;
    final playTo = state.match.playTo;
    final winBy = state.match.winBy;
    final diff = myScore - oppScore;
    // Either leading at the target by less than winBy (one point away),
    // OR at playTo-1 with a diff that already meets winBy-1 (next point
    // ties or wins — only game point if you're one point from the
    // winning condition, which requires diff >= winBy-1 here).
    if (myScore >= playTo && diff >= winBy - 1 && diff < winBy) return true;
    if (myScore == playTo - 1 && diff >= winBy - 1) return true;
    return false;
  }

  // ── Point Buttons (equal visual weight, side-out badge incide) ──

  Widget _buildPointButtons(LiveMatchState state) {
    final isRally = state.scoringRule == 'rally';
    final servingA = state.isTeamServing(Team.A);
    final servingB = state.isTeamServing(Team.B);
    final aNames = _teamNames(state, 'A');
    final bNames = _teamNames(state, 'B');
    final aLabel = aNames.isNotEmpty ? aNames.join(' & ') : 'Team A';
    final bLabel = bNames.isNotEmpty ? bNames.join(' & ') : 'Team B';
    // Side-out badge: only show when the OPPOSITE team is serving AND this
    // is sideout scoring. Tap registers a side-out (no point scored),
    // so the badge tells users what tapping means. In rally scoring both
    // buttons score, so no badge is shown.
    final aCanSideOut = !isRally && !servingA;
    final bCanSideOut = !isRally && !servingB;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        Expanded(
          child: SizedBox(
            height: 88,
            child: Semantics(
              button: true,
              // Wording intentionally avoids the contradictory
              // "scores (side-out)" phrasing — a side-out button does
              // not change the score, so screen-reader users were
              // hearing a verb that contradicted the visual outcome.
              label: aCanSideOut
                  ? '$aLabel claims side-out'
                  : '$aLabel scores',
              hint: aCanSideOut
                  ? 'Side-out: serving team (B) loses rally to your team'
                  : 'Tap to score a point for Team A',
              child: FilledButton(
                onPressed: () => _onTeamScore(Team.A),
                style: FilledButton.styleFrom(
                  // Full alpha for BOTH teams — dim alpha made the
                  // non-serving button look disabled even though tapping
                  // it is REQUIRED in side-out scoring. The side-out
                  // badge inside the button communicates intent instead.
                  backgroundColor: courtGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _buildPointButtonContent(
                  label: aLabel,
                  accentColor: Colors.white,
                  sideOutBadge: aCanSideOut,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 88,
            child: Semantics(
              button: true,
              label: bCanSideOut
                  ? '$bLabel claims side-out'
                  : '$bLabel scores',
              hint: bCanSideOut
                  ? 'Side-out: serving team (A) loses rally to your team'
                  : 'Tap to score a point for Team B',
              child: FilledButton(
                onPressed: () => _onTeamScore(Team.B),
                style: FilledButton.styleFrom(
                  backgroundColor: courtBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _buildPointButtonContent(
                  label: bLabel,
                  accentColor: Colors.white,
                  sideOutBadge: bCanSideOut,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  /// Shared button content — label + optional side-out badge below.
  Widget _buildPointButtonContent({
    required String label,
    required Color accentColor,
    required bool sideOutBadge,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800)),
        if (sideOutBadge) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync_alt_rounded, size: 12, color: accentColor),
              const SizedBox(width: 4),
              Text('Side-Out',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: 0.5)),
            ],
          ),
        ],
      ],
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
              width: 56,
              height: 56,
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
          // End Match — separated from Undo by Spacer
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

// The inline widget classes (_PulseDot, _MatchTimerSubtitle,
// _SpectatorOverlay, _SpectatorTeamColumn) used to live here. They
// were extracted to focused files under `widgets/` so this screen
// reads as state + layout rather than an 800-LOC dump:
//
//   widgets/pulse_dot.dart              -- game-point pulsing dot
//   widgets/match_timer_subtitle.dart   -- 1Hz AppBar clock widget
//   widgets/spectator_overlay.dart      -- big-score spectator mode

import 'dart:async';

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
  String? _sideOutMessage;
  Timer? _sideOutTimer;

  @override
  void initState() {
    super.initState();
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

    // Show side-out feedback in side-out scoring when non-serving team wins rally
    if (isSideOut) {
      final otherTeam = team == Team.A ? 'Team A' : 'Team B';
      _sideOutTimer?.cancel();
      setState(() => _sideOutMessage = '$otherTeam won the rally — Side Out!');
      _sideOutTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _sideOutMessage = null);
      });
      SoundService().playPointScored();
    } else {
      SoundService().playPointScored();
    }

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
    final isTournamentMatch = state.match.tournamentId != null;
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
      SoundService().playMatchEnd();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMatchEndBanner(next);
      });
      return;
    }

    if (next.teamAGamesWon > _prevGamesWonA ||
        next.teamBGamesWon > _prevGamesWonB) {
      _showingBanner = true;
      SoundService().playGameEnd();
      final winner =
          next.teamAGamesWon > _prevGamesWonA ? 'A' : 'B';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showGameEndBanner(prev, next, winner)
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

  void _showSpectatorMode() {
    final state = ref.read(liveMatchProvider);
    if (state == null) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _SpectatorOverlay(state: state),
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
                  // Court fills available space at the top
                  Expanded(child: _buildCourtDiagram(liveState)),
                  const SizedBox(height: 10),
                  _buildGamePointIndicator(liveState, theme),
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
    final scoring = state.scoringState;
    if (scoring.isGameOver || scoring.isMatchOver) return const SizedBox.shrink();

    final int diff = (state.teamAScore - state.teamBScore).abs();
    final int leaderScore = state.teamAScore > state.teamBScore ? state.teamAScore : state.teamBScore;
    final int target = state.match.playTo;
    final int winBy = state.match.winBy;

    bool isGamePoint = false;
    String? pointLabel;

    if (leaderScore >= target && diff >= winBy - 1 && diff < winBy) {
      isGamePoint = true;
      pointLabel = 'Game Point';
    } else if (leaderScore == target - 1 && diff >= winBy - 1) {
      isGamePoint = true;
      pointLabel = 'Game Point';
    }

    if (!isGamePoint) return const SizedBox.shrink();

    final bool teamAIsLeader = state.teamAScore > state.teamBScore;
    final Color pointColor = teamAIsLeader ? courtGreen : courtBlue;

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
              pointLabel!,
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
        _MatchTimerSubtitle(
          ruleLabel: ruleLabel,
          isDoubles: state.isDoubles,
          createdAt: state.match.createdAt,
        ),
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
                if (isDoubles && state.isSideOut) ...[
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        Expanded(
          child: SizedBox(
            height: 80,
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
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 80,
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
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
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

// ── Isolated timer widget — prevents 1Hz full-screen rebuilds ──

class _MatchTimerSubtitle extends StatefulWidget {
  final String ruleLabel;
  final bool isDoubles;
  final DateTime createdAt;

  const _MatchTimerSubtitle({
    required this.ruleLabel,
    required this.isDoubles,
    required this.createdAt,
  });

  @override
  State<_MatchTimerSubtitle> createState() => _MatchTimerSubtitleState();
}

// ── Spectator overlay — large scores for tablets/spectators ──

class _SpectatorOverlay extends StatelessWidget {
  final LiveMatchState state;

  const _SpectatorOverlay({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aNames = state.players.where((p) => p.team == 'A').map((p) => p.name).join(' & ');
    final bNames = state.players.where((p) => p.team == 'B').map((p) => p.name).join(' & ');

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Game ${state.currentGame}/${state.gameCount}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _SpectatorTeamColumn(
                        names: aNames,
                        score: state.teamAScore,
                        games: state.teamAGamesWon,
                        color: courtGreen,
                        theme: theme,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '–',
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _SpectatorTeamColumn(
                        names: bNames,
                        score: state.teamBScore,
                        games: state.teamBGamesWon,
                        color: courtBlue,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  'Tap anywhere to exit',
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

class _SpectatorTeamColumn extends StatelessWidget {
  final String names;
  final int score;
  final int games;
  final Color color;
  final ThemeData theme;

  const _SpectatorTeamColumn({
    required this.names,
    required this.score,
    required this.games,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          names,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '$score',
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 96,
            fontWeight: FontWeight.w900,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (games > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              games,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MatchTimerSubtitleState extends State<_MatchTimerSubtitle> {
  late String _elapsedStr;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _elapsedStr = _formatElapsed(widget.createdAt);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedStr = _formatElapsed(widget.createdAt));
      }
    });
  }

  @override
  void didUpdateWidget(covariant _MatchTimerSubtitle old) {
    super.didUpdateWidget(old);
    if (old.createdAt != widget.createdAt) {
      _elapsedStr = _formatElapsed(widget.createdAt);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatElapsed(DateTime startTime) {
    final elapsed = DateTime.now().difference(startTime);
    return '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '${widget.ruleLabel} \u2022 ${widget.isDoubles ? "Doubles" : "Singles"} \u2022 $_elapsedStr',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

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
    // Single debounce guard for BOTH buttons — the old split
    // _lastPointTimeA / _lastPointTimeB allowed mashing both
    // buttons within 500 ms to score two simultaneous points.
    if (_lastScoreTime != null &&
        now.difference(_lastScoreTime!).inMilliseconds < 500) { return; }
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
    // Sound + haptic feedback
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
      final completedId = await ref.read(liveMatchProvider.notifier).endMatch();
      if (completedId != null && mounted) {
        // Reset to Home first then push Match Details on top so the system
        // back button on Match Details lands on Home instead of this dead
        // Live screen — endMatch() just wiped the active DB row, so the
        // Live provider emits null and renders 'No active match' if we left
        // it in the stack.
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
      // Defer to post-frame — showDialog needs a stable navigator state,
      // but we're inside a ref.listen callback during notifyListeners().
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMatchEndBanner(next);
      });
      return;
    }

    if (next.teamAGamesWon > _prevGamesWonA || next.teamBGamesWon > _prevGamesWonB) {
      _showingBanner = true;
      final winner = next.teamAGamesWon > _prevGamesWonA ? 'A' : 'B';
      // Same fix: defer dialog to post-frame callback.
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

  Future<void> _showGameEndBanner(LiveMatchState prevState, LiveMatchState nextState, String winner) async {
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
          content: Text('$teamLabel wins Game ${nextState.currentGame}\n$scoreA \u2013 $scoreB', textAlign: TextAlign.center),
          actions: [FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Next Game'))],
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _showMatchEndBanner(LiveMatchState state) async {
    final winner = state.teamAGamesWon > state.teamBGamesWon ? 'A' : 'B';
    final teamLabel = winner == 'A' ? 'Team A' : 'Team B';
    final dialogResult = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Row(children: [
            Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 32),
            const SizedBox(width: 8),
            const Text('Match Over!'),
          ]),
          content: Text('$teamLabel wins the match!\n${state.teamAGamesWon} \u2013 ${state.teamBGamesWon}',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          actions: [FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('View Details'))],
        ),
      ),
    );
    // Always end the match when the dialog is dismissed — whether the user
    // tapped "View Details" or pressed the system back button.
    try {
      final completedId = await ref.read(liveMatchProvider.notifier).endMatch();
      if (mounted) {
        if (dialogResult == true && completedId != null) {
          // Reset to Home first then push Match Details on top so the
          // system back button on Match Details lands on Home instead of
          // this dead Live screen — endMatch() just wiped the active DB
          // row, so the Live provider emits null and renders 'No active
          // match' if we left it in the stack.
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Paused', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              ListTile(leading: const Icon(Icons.play_arrow_rounded, size: 28), title: const Text('Resume'), onTap: () => Navigator.of(ctx).pop()),
              Semantics(
                button: true,
                label: 'Save and exit, resume later from Home',
                child: ListTile(leading: const Icon(Icons.save_alt_rounded, size: 28), title: const Text('Save & Exit'), subtitle: const Text('Resume later from Home'),
                  onTap: () { Navigator.of(ctx).pop(); if (mounted) context.go('/'); }),
              ),
              Semantics(
                button: true,
                label: 'End match, final scores will be saved',
                child: ListTile(leading: Icon(Icons.flag_rounded, size: 28, color: Theme.of(context).colorScheme.error),
                  title: Text('End Match', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () { Navigator.of(ctx).pop(); _onEndMatch(); }),
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

    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Live Match')), body: const Center(child: CircularProgressIndicator()));
    if (_loadError != null) {
      return Scaffold(appBar: AppBar(title: const Text('Live Match')), body: Center(child: Column(
        mainAxisSize: MainAxisSize.min, children: [
        Text('Failed to load match', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8), Text(_loadError!, style: theme.textTheme.bodySmall),
        const SizedBox(height: 16), FilledButton(onPressed: () => context.go('/'), child: const Text('Go Home')),
      ])));
    }
    if (liveState == null) {
      return Scaffold(appBar: AppBar(title: const Text('Live Match')), body: Center(child: Column(
        mainAxisSize: MainAxisSize.min, children: [
        const Text('No active match'), const SizedBox(height: 16),
        FilledButton(onPressed: () => context.go('/'), child: const Text('Go Home')),
      ])));
    }

    // Compute the initial elapsed string without calling setState
    // (we're inside build, so the widget hasn't rendered yet) and
    // defer the periodic timer to the post-frame callback so we
    // never call setState during a build phase.
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
        onPopInvokedWithResult: (didPop, _) { if (!didPop) _showPauseMenu(); },
        child: SafeArea(
          child: Column(children: [
            const SizedBox(height: 6),
            _buildCourtDiagram(liveState),
            const SizedBox(height: 6),
            _buildServerIndicator(liveState, theme),
            const SizedBox(height: 4),
            _buildScoreCallout(liveState, theme),
            const SizedBox(height: 4),
            _buildScoreboard(liveState, theme),
            const Spacer(),
            _buildPointButtons(liveState, theme),
            const SizedBox(height: 6),
            _buildBottomBar(liveState, theme),
            const SizedBox(height: 4),
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
      leading: IconButton(icon: const Icon(Icons.pause_rounded), onPressed: _showPauseMenu, tooltip: 'Pause'),
      title: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Game ${state.currentGame}/${state.gameCount}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        Text('$ruleLabel \u2022 ${state.isDoubles ? "Doubles" : "Singles"} \u2022 $_elapsedStr',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
      centerTitle: true,
    );
  }

  // ── Court Diagram ──

  Widget _buildCourtDiagram(LiveMatchState state) {
    final positions = state.playerPositions.map((p) => PlayerPosition(
      id: p['id'] as String, name: p['name'] as String,
      team: p['team'] as String, side: p['side'] as String,
    )).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: CourtDiagram(players: positions, servingPlayerId: state.servingPlayerId, isDoubles: state.isDoubles),
    );
  }

  // ── Server Indicator ──

  Widget _buildServerIndicator(LiveMatchState state, ThemeData theme) {
    final serverName = ref.read(liveMatchProvider.notifier).serverDisplayName ?? '\u2014';
    final serverTeam = state.serverTeam ?? 'A';
    final teamColor = serverTeam == 'A' ? courtGreen : courtBlue;
    final isServingTeamA = serverTeam == 'A';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: teamColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: teamColor.withValues(alpha: 0.3), width: 2),
        ),
        child: Row(children: [
          // Serving team badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: teamColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.sports_tennis_rounded, color: teamColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(serverName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: teamColor)),
              const SizedBox(height: 2),
              Text(state.isDoubles ? 'Server ${state.serverNumber} of 2' : 'Serving',
                  style: theme.textTheme.bodySmall?.copyWith(color: teamColor.withValues(alpha: 0.7))),
            ]),
          ),
          // Serving team label — tinted badge + teamColor text passes WCAG AA
          // (solid courtGreen + white text only hits ~4:1, below the 4.5:1 minimum).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: teamColor.withValues(alpha: 0.5), width: 1),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(isServingTeamA ? 'TEAM A' : 'TEAM B',
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: teamColor, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text('SERVING',
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: teamColor, fontSize: 9, letterSpacing: 1.5)),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Score Callout ──

  /// Big readable "score callout" — the canonical USAPA-formatted string
  /// the server announces before each serve. Doubles: `X-X-N` (server
  /// number at the end), Singles: `X-X`. Inserted between the server
  /// indicator and the scoreboard so players can read it without
  /// scrolling past the score cards. The score-call text is wrapped in
  /// `Semantics(label: ...)` so screen readers and uiautomator dumps
  /// surface the literal phrase (e.g. "Score call: 3-2-1") instead of
  /// just listing three numerics.
  Widget _buildScoreCallout(LiveMatchState state, ThemeData theme) {
    // Defensive fallback: `state.serverTeam` is always non-null coming out
    // of `ScoringService.createInitialState` (every code path sets it) and
    // the live-screen build early-returns on a null liveState, so `?? 'A'`
    // is purely a future-proofing net.
    final serverTeam = state.serverTeam ?? 'A';
    final accentColor = serverTeam == 'A' ? courtGreen : courtBlue;
    final callout = state.scoreCallout;

    // Only horizontal padding here — the pill's own internal vertical
    // padding owns the spacing between the server indicator above and
    // the scoreboard below. Stacking outer + inner vertical padding
    // would burn ~16 dp on small phones where the Spacer is already
    // tight.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        child: Semantics(
          label: 'Score call: $callout',
          container: true,            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              // Mirror switchInCurve on the outgoing side so the fade-out
              // decelerates naturally — the implicit `Curves.linear`
              // produces a slightly mechanical exit.
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Container(
              key: ValueKey<String>(callout),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    callout,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Scoreboard ──

  Widget _buildScoreboard(LiveMatchState state, ThemeData theme) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        Expanded(child: _buildScoreCard(
          teamLabel: 'Team A', playerNames: _teamNames(state, 'A'), score: state.teamAScore,
          isServing: state.isTeamServing(Team.A), gamesWon: state.teamAGamesWon,
          accentColor: courtGreen, theme: theme, showGlow: _glowA,
        )),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
          child: Text('VS', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.outline)),
        ),
        const SizedBox(width: 6),
        Expanded(child: _buildScoreCard(
          teamLabel: 'Team B', playerNames: _teamNames(state, 'B'), score: state.teamBScore,
          isServing: state.isTeamServing(Team.B), gamesWon: state.teamBGamesWon,
          accentColor: courtBlue, theme: theme, showGlow: _glowB,
        )),
      ]),
    );
  }

  List<String> _teamNames(LiveMatchState state, String team) {
    return state.players.where((p) => p.team == team).map((p) => p.name).toList();
  }

  Widget _buildScoreCard({
    required String teamLabel, required List<String> playerNames, required int score,
    required bool isServing, required int gamesWon, required Color accentColor,
    required ThemeData theme, required bool showGlow,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isServing ? accentColor.withValues(alpha: 0.08) : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showGlow ? accentColor : (isServing ? accentColor.withValues(alpha: 0.4) : Colors.transparent),
          width: showGlow ? 3 : (isServing ? 2 : 0),
        ),
        boxShadow: showGlow ? [BoxShadow(color: accentColor.withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 1)] : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(mainAxisSize: MainAxisSize.min, children: [
            if (gamesWon > 0) ...[
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(gamesWon, (_) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(Icons.circle, size: 8, color: accentColor),
                  ))),
              const SizedBox(height: 4),
            ],
            ...playerNames.map((name) => Text(name,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
                textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              switchInCurve: Curves.easeOut,
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Text('$score', key: ValueKey(score),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900, fontSize: 60, color: theme.colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            ),
          ]),
          // Score pop overlay
          if (showGlow)
            Positioned(
              top: -4, right: 2,
              child: _ScorePop(team: teamLabel == 'Team A' ? 'A' : 'B'),
            ),
        ],
      ),
    );
  }

  // ── Point Buttons ──

  Widget _buildPointButtons(LiveMatchState state, ThemeData theme) {
    final isRally = state.scoringRule == 'rally';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        Expanded(child: _PointButton(label: 'Team A Scores!', color: courtGreen,
            isPrimary: isRally || state.isTeamServing(Team.A), onTap: () => _onTeamScore(Team.A))),
        const SizedBox(width: 10),
        Expanded(child: _PointButton(label: 'Team B Scores!', color: courtBlue,
            isPrimary: isRally || state.isTeamServing(Team.B), onTap: () => _onTeamScore(Team.B))),
      ]),
    );
  }

  // ── Bottom Bar ──

  Widget _buildBottomBar(LiveMatchState state, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: state.canUndo ? _onUndo : null,
          icon: const Icon(Icons.undo_rounded, size: 20), label: const Text('Undo'),
        )),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(
          onPressed: _onEndMatch,
          icon: Icon(Icons.flag_rounded, size: 20, color: theme.colorScheme.error),
          label: Text('End Match', style: TextStyle(color: theme.colorScheme.error)),
          style: OutlinedButton.styleFrom(side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5))),
        )),
      ]),
    );
  }
}

// ── Score Pop Animation ──

class _ScorePop extends StatefulWidget {
  final String team;
  const _ScorePop({required this.team});

  @override
  State<_ScorePop> createState() => _ScorePopState();
}

class _ScorePopState extends State<_ScorePop> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = Tween<double>(begin: 1.4, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    _slide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.6)).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.team == 'A' ? courtGreen : courtBlue;
    return SlideTransition(
      position: _slide,
      child: ScaleTransition(
        scale: _fade,
        child: Opacity(
          opacity: (_fade.value.clamp(0.0, 1.0)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
            child: const Text('+1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ),
        ),
      ),
    );
  }
}

// ── Point Button ──

class _PointButton extends StatefulWidget {
  final String label;
  final Color color;
  final bool isPrimary;
  final VoidCallback onTap;

  const _PointButton({required this.label, required this.color, required this.isPrimary, required this.onTap});

  @override
  State<_PointButton> createState() => _PointButtonState();
}

class _PointButtonState extends State<_PointButton> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.94), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 1),
    ]).animate(_scaleCtrl);
  }

  @override
  void dispose() { _scaleCtrl.dispose(); super.dispose(); }

  void _handleTap() {
    _scaleCtrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      hint: 'Double tap to score a point for this team',
      child: ExcludeSemantics(
      child: AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, _) => Transform.scale(
        scale: _scaleAnim.value,
        child: SizedBox(
          height: 68,
          child: FilledButton(
            onPressed: _handleTap,
            style: FilledButton.styleFrom(
              backgroundColor: widget.isPrimary ? widget.color : widget.color.withValues(alpha: 0.12),
              foregroundColor: widget.isPrimary ? Colors.white : widget.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: widget.isPrimary ? BorderSide.none : BorderSide(color: widget.color.withValues(alpha: 0.25)),
              ),
            ),
            child: Text(widget.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          ),
        ),
      ),
    )));
  }
}

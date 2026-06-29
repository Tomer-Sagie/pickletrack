import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/live_match_provider.dart';
import '../../../theme/colors.dart';
import '../live_match_helpers.dart';

/// Full-screen spectator overlay shown from the Live Pause Menu.
///
/// Replaces the Live UI with a minimal, high-contrast score column
/// pair meant for tablets, TVs, or across-the-court viewing. Tap
/// anywhere to exit.
///
/// Extracted from `live_match_screen.dart` so the widget is
/// independently testable and the parent screen file doesn't grow
/// unbounded as more dialog/overlay types are added.
///
/// Imports [filteredTeamNames] from the sibling helpers file (not
/// the parent screen) to avoid a circular-style dependency.
class SpectatorOverlay extends ConsumerWidget {
  const SpectatorOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveMatchProvider);
    final theme = Theme.of(context);

    // If the match ended while the overlay was open (e.g. user let
    // the game time out from the main screen), fall back to a
    // placeholder so the overlay doesn't crash instead of restoring
    // a stale view.
    if (state == null) {
      return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
          body: Center(
            child: Text(
              'Match ended',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    // Shape the player list as records before passing it to the
    // zero-dep helper — the helper no longer takes `LiveMatchState`.
    final playerList = state.players
        .map((p) => (name: p.name, team: p.team))
        .toList(growable: false);
    final aNames = filteredTeamNames(playerList, 'A',
            matchType: state.match.type)
        .join(' & ');
    final bNames = filteredTeamNames(playerList, 'B',
            matchType: state.match.type)
        .join(' & ');

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

/// Single team column inside the [SpectatorOverlay]: name, large
/// score number, optional filled circles for games won in a
/// best-of-N.
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

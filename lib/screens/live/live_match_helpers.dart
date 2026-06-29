import '../providers/live_match_provider.dart';

/// Returns the non-empty trimmed player names for [team] ('A' or 'B')
/// from the active match state.
///
/// If the live match has no non-empty names on [team] (still in setup,
/// or empty fields submitted), falls back to a placeholder so the UI
/// always has something readable for the scorecard / spectator
/// overlay / point button label:
///
///   * `matchType == 'singles'` → `['Player 1']`
///   * otherwise                → `['Player 1', 'Player 2']`
///
/// Exposed as a top-level function (not a method on
/// `LiveMatchState`) so independent widgets (e.g. the spectator
/// overlay extracted into `screens/live/widgets/`) can call it
/// without importing `live_match_screen.dart`, which would create a
/// circular dependency on the screen's state class.
List<String> filteredTeamNames(
  LiveMatchState state,
  String team, {
  required String matchType,
}) {
  final names = state.players
      .where((p) => p.team == team)
      .map((p) => p.name.trim())
      .where((n) => n.isNotEmpty)
      .toList();
  if (names.isEmpty) {
    return matchType == 'singles' ? ['Player 1'] : ['Player 1', 'Player 2'];
  }
  return names;
}

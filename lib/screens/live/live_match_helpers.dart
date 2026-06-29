/// Minimal name + team record the [filteredTeamNames] helper
/// consumes. Defined here so callers can pre-shape whatever player
/// list they have (`state.players.map((p) => (name: p.name,
/// team: p.team)).toList()`) without dragging Drift-generated
/// types into a pure helper.
typedef PlayerNameAndTeam = ({String name, String team});

/// Returns the non-empty trimmed names from [players] whose
/// `.team` matches [team].
///
/// If the result is empty (still in setup, all-whitespace names,
/// missing team, etc.), falls back to a placeholder so the UI
/// always has something readable for the scorecard / spectator
/// overlay / point button label:
///
///   * `matchType == 'singles'` → `['Player 1']`
///   * otherwise                → `['Player 1', 'Player 2']`
///
/// Zero-dependency: takes a plain `List<PlayerNameAndTeam>`, not
/// a Drift-generated class or a `LiveMatchState`. This means:
///
///   * The helper can be unit-tested without a `ProviderScope` or
///     any Drift setup. See `test/live_match_helpers_test.dart`.
///   * Sibling widgets (e.g. `widgets/spectator_overlay.dart`) can
///     call it without importing the providers barrel or
///     `live_match_screen.dart` — breaking the circular-style
///     import the previous version had.
List<String> filteredTeamNames(
  List<PlayerNameAndTeam> players,
  String team, {
  required String matchType,
}) {
  final names = players
      .where((p) => p.team == team)
      .map((p) => p.name.trim())
      .where((n) => n.isNotEmpty)
      .toList();
  if (names.isEmpty) {
    return matchType == 'singles' ? ['Player 1'] : ['Player 1', 'Player 2'];
  }
  return names;
}

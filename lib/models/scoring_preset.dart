/// Scoring win condition presets for pickleball matches.
class ScoringPreset {
  final String name;
  final int playTo;
  final int winBy;
  final bool isCustom;

  const ScoringPreset({
    required this.name,
    required this.playTo,
    required this.winBy,
    this.isCustom = false,
  });

  /// Pre-built presets.
  static const quick = ScoringPreset(name: 'Quick', playTo: 7, winBy: 2);
  static const standard = ScoringPreset(name: 'Standard', playTo: 11, winBy: 2);
  static const tournament =
      ScoringPreset(name: 'Tournament', playTo: 15, winBy: 2);

  static const List<ScoringPreset> defaults = [quick, standard, tournament];

  /// Creates a custom preset. Validates play-to (1–99) and win-by (1–10).
  factory ScoringPreset.custom({required int playTo, required int winBy}) {
    assert(playTo >= 1 && playTo <= 99, 'playTo must be 1–99');
    assert(winBy >= 1 && winBy <= 10, 'winBy must be 1–10');
    return ScoringPreset(
      name: 'Custom',
      playTo: playTo,
      winBy: winBy,
      isCustom: true,
    );
  }

  /// Display label shown in the UI.
  String get label => '$name ($playTo, win by $winBy)';

  @override
  bool operator ==(Object other) =>
      other is ScoringPreset &&
      other.name == name &&
      other.playTo == playTo &&
      other.winBy == winBy;

  @override
  int get hashCode => Object.hash(name, playTo, winBy);
}

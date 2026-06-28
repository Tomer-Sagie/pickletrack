import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pickletrack/database/database.dart';
import 'package:pickletrack/models/scoring_preset.dart';
import 'package:pickletrack/providers/database_provider.dart';
import 'package:pickletrack/providers/live_match_provider.dart';
import 'package:pickletrack/providers/theme_provider.dart';
import 'package:pickletrack/screens/live/live_match_screen.dart';
import 'package:pickletrack/services/scoring_service.dart';

import 'helpers/stubs.dart';

// Golden tests below are skipped on CI because pixel-fidelity rendering
// drifts across platforms: the PNGs under `test/goldens/` were captured
// on Windows and routinely fail on Ubuntu CI with ~38% pixel diff (font
// fallback + subpixel antialiasing). Coarse matchesGoldenFile tolerances
// still can't bridge structural reflow caused by different font metrics.
//
// To regenerate goldens locally after a deliberate UI change:
//   flutter test --update-goldens test/live_match_screen_golden_test.dart
// then commit the updated PNGs. The structural assertions in
// `live_match_screen_test.dart` already cover the same visual contracts
// on CI; these goldens are belt-and-braces for humans.
bool get _isCI => Platform.environment.containsKey('CI');

/// Stub notifier — same as in live_match_screen_test.dart.
class _TestNotifier extends LiveMatchNotifier {
  final LiveMatchState? _prebuiltState;

  _TestNotifier(super.ref, this._prebuiltState);

  @override
  Future<void> load() async {
    state = _prebuiltState;
  }

  @override
  Future<void> scorePoint(Team team) async {}

  @override
  Future<void> undo() async {}

  @override
  Future<int?> endMatch() async {
    return null;
  }

  @override
  String? get serverDisplayName {
    final s = state;
    if (s == null || s.servingPlayerId == null) return null;
    return s.playerName(s.servingPlayerId!);
  }
}

/// Builds a LiveMatchState by running the scoring engine for the given
/// number of A/B points.
LiveMatchState buildPlayedState({
  String matchType = 'doubles',
  String scoringRule = 'sideout',
  int gameCount = 1,
  int pointsTeamA = 0,
  int pointsTeamB = 0,
  List<ActiveMatchPlayer>? players,
}) {
  final p = players ?? [
    const ActiveMatchPlayer(
      id: 1, matchId: 1, name: 'Alice', team: 'A',
      isStartingServer: true, position: 'right', serverNumber: null,
    ),
    const ActiveMatchPlayer(
      id: 2, matchId: 1, name: 'Bob', team: 'A',
      isStartingServer: false, position: 'left', serverNumber: null,
    ),
    const ActiveMatchPlayer(
      id: 3, matchId: 1, name: 'Carol', team: 'B',
      isStartingServer: false, position: 'right', serverNumber: null,
    ),
    const ActiveMatchPlayer(
      id: 4, matchId: 1, name: 'Dave', team: 'B',
      isStartingServer: false, position: 'left', serverNumber: null,
    ),
  ];

  final rule =
      scoringRule == 'sideout' ? ScoringRule.sideout : ScoringRule.rally;
  final type = matchType == 'singles' ? MatchType.singles : MatchType.doubles;

  var scoringState = ScoringService.createInitialState(
    type: type,
    rule: rule,
    preset: ScoringPreset.standard,
    gameCount: gameCount,
    startingServerId: 'A0',
    startingServerTeam: Team.A,
    initialPlayerSides: {
      'A0': 'right',
      'A1': 'left',
      'B0': 'right',
      'B1': 'left'
    },
    initialPlayerTeams: {'A0': 'A', 'A1': 'A', 'B0': 'B', 'B1': 'B'},
  );

  int aDone = 0, bDone = 0;
  while (aDone < pointsTeamA || bDone < pointsTeamB) {
    if (aDone < pointsTeamA) {
      try {
        final r = ScoringService.recordPoint(scoringState, Team.A);
        scoringState = r.newState;
        aDone++;
      } on Exception {
        break;
      }
    }
    if (bDone < pointsTeamB) {
      try {
        final r = ScoringService.recordPoint(scoringState, Team.B);
        scoringState = r.newState;
        bDone++;
      } on Exception {
        break;
      }
    }
  }

  return LiveMatchState(
    match: ActiveMatche(
      id: 1, type: matchType, scoringRule: scoringRule,
      gameCount: gameCount, playTo: 11, winBy: 2,
      createdAt: DateTime.now(), status: 'live',
    ),
    players: p,
    events: [],
    scoringState: scoringState,
  );
}

/// Pumps the screen to a loaded state using a deterministic viewport.
/// Returns a [Finder] that targets the full rendered output for golden capture.
Future<Finder> pumpGolden(WidgetTester tester, LiveMatchState state) async {
  // Fixed viewport for deterministic golden images.
  tester.view.physicalSize = const Size(1080, 2160);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  // Use an in-memory Drift DB so the production AppDatabase factory is
  // never opened during tests — the warning had been traced to this file.
  final db = createInMemoryDatabase();
  addTearDown(() async => db.close());

  const screenKey = Key('golden-target');

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        themeModeProvider.overrideWith(StubThemeModeNotifier.new),
        liveMatchProvider.overrideWith((ref) => _TestNotifier(ref, state)),
      ],
      child: const MaterialApp(
        home: SizedBox(
          key: screenKey,
          width: 1080,
          height: 2160,
          child: LiveMatchScreen(),
        ),
      ),
    ),
  );
  // One pump processes the Future.microtask (load + setState) and rebuilds.
  // CourtDiagram has a repeating animation, so pumpAndSettle would timeout.
  await tester.pump();

  return find.byKey(screenKey);
}

void main() {
  group('LiveMatchScreen golden', () {
    testWidgets('initial state – doubes side-out 0-0-2', (tester) async {
      if (_isCI) {
        markTestSkipped(
          'Golden PNGs are cross-platform-unstable; regenerate locally.',
        );
        return;
      }
      await pumpGolden(tester, buildPlayedState());
      await expectLater(
        find.byKey(const Key('golden-target')),
        matchesGoldenFile('goldens/live_match_initial.png'),
      );
    });

    testWidgets('after points – doubes side-out 3-1-1', (tester) async {
      if (_isCI) {
        markTestSkipped(
          'Golden PNGs are cross-platform-unstable; regenerate locally.',
        );
        return;
      }
      await pumpGolden(tester, buildPlayedState(pointsTeamA: 3, pointsTeamB: 1));
      await expectLater(
        find.byKey(const Key('golden-target')),
        matchesGoldenFile('goldens/live_match_after_points.png'),
      );
    });

    testWidgets('rally scoring mode', (tester) async {
      if (_isCI) {
        markTestSkipped(
          'Golden PNGs are cross-platform-unstable; regenerate locally.',
        );
        return;
      }
      await pumpGolden(
        tester,
        buildPlayedState(scoringRule: 'rally', pointsTeamA: 2, pointsTeamB: 2),
      );
      await expectLater(
        find.byKey(const Key('golden-target')),
        matchesGoldenFile('goldens/live_match_rally.png'),
      );
    });

    testWidgets('singles mode – initial state', (tester) async {
      if (_isCI) {
        markTestSkipped(
          'Golden PNGs are cross-platform-unstable; regenerate locally.',
        );
        return;
      }
      final state = buildPlayedState(
        matchType: 'singles',
        pointsTeamA: 5,
        pointsTeamB: 3,
        players: [
          const ActiveMatchPlayer(
            id: 1, matchId: 1, name: 'Alice', team: 'A',
            isStartingServer: true, position: null, serverNumber: null,
          ),
          const ActiveMatchPlayer(
            id: 2, matchId: 1, name: 'Bob', team: 'B',
            isStartingServer: false, position: null, serverNumber: null,
          ),
        ],
      );
      await pumpGolden(tester, state);
      await expectLater(
        find.byKey(const Key('golden-target')),
        matchesGoldenFile('goldens/live_match_singles.png'),
      );
    });
  });
}

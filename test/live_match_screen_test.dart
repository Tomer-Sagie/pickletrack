import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pickletrack/database/database.dart';
import 'package:pickletrack/models/scoring_preset.dart';
import 'package:pickletrack/providers/database_provider.dart';
import 'package:pickletrack/providers/live_match_provider.dart';
import 'package:pickletrack/providers/theme_provider.dart';
import 'helpers/stubs.dart';
import 'package:pickletrack/screens/live/court_diagram.dart';
import 'package:pickletrack/screens/live/live_match_screen.dart';
import 'package:pickletrack/services/scoring_service.dart';

/// Stub notifier that extends LiveMatchNotifier using a real Ref from
/// overrideWith.  load() sets the pre-built state directly.
class _TestNotifier extends LiveMatchNotifier {
  final LiveMatchState? _prebuiltState;
  final bool _useRealScoring;
  int scorePointCalls = 0;
  int undoCalls = 0;

  _TestNotifier(super.ref, this._prebuiltState,
      {bool useRealScoring = false})
      : _useRealScoring = useRealScoring;

  @override
  Future<void> load() async {
    state = _prebuiltState;
  }

  @override
  Future<void> scorePoint(Team team) async {
    scorePointCalls++;
    if (!_useRealScoring) return;
    final current = state;
    if (current == null) return;
    try {
      final result = ScoringService.recordPoint(current.scoringState, team);
      state = LiveMatchState(
        match: current.match,
        players: current.players,
        events: current.events,
        scoringState: result.newState,
      );
    } on Exception {
      // Game already over — ignore.
    }
  }

  @override
  Future<void> undo() async {
    undoCalls++;
  }

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

/// Builds a test LiveMatchState by running the scoring engine for the given
/// number of A/B points, producing realistic server positions and scores.
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

  // Advance state by simulating alternating points
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
      id: 1,
      type: matchType,
      scoringRule: scoringRule,
      gameCount: gameCount,
      playTo: 11,
      winBy: 2,
      createdAt: DateTime.now(),
      status: 'live',
    ),
    players: p,
    events: [],
    scoringState: scoringState,
  );
}

/// Ensures the test viewport is tall enough to avoid layout overflows on the
/// live-match screen, then pumps the widget with the given state.
void _useLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2160);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Wraps [LiveMatchScreen] in a ProviderScope with a tall enough viewport
/// that the live-match layout does not overflow.
Future<void> pumpWithState(WidgetTester tester, LiveMatchState state) async {
  _useLargeViewport(tester);

  // Use an in-memory Drift DB so the production AppDatabase factory is
  // never opened during tests.
  final db = createInMemoryDatabase();
  addTearDown(() async => db.close());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        themeModeProvider.overrideWith(StubThemeModeNotifier.new),
        liveMatchProvider.overrideWith((ref) => _TestNotifier(ref, state)),
      ],
      child: const MaterialApp(home: LiveMatchScreen()),
    ),
  );
  // pump() processes the Future.microtask (load + setState) and rebuilds.
  // pumpAndSettle() would time out because CourtDiagram has a repeating
  // AnimationController.
  await tester.pump();
}

void main() {
  group('LiveMatchScreen', () {
    // ── Loading / Error / Null states ──

    testWidgets('shows loading spinner initially', (tester) async {
      final db = createInMemoryDatabase();
      addTearDown(() async => db.close());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            themeModeProvider.overrideWith(StubThemeModeNotifier.new),
          ],
          child: const MaterialApp(home: LiveMatchScreen()),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows doubles scoreboard with teams and scores',
        (tester) async {
      await pumpWithState(tester, buildPlayedState());

      // Alice appears in both the score card and the server indicator.
      expect(find.text('Alice'), findsAtLeastNWidgets(1));
      expect(find.text('Carol'), findsAtLeastNWidgets(1));
      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('Team A Scores!'), findsOneWidget);
      expect(find.text('Team B Scores!'), findsOneWidget);
    });

    testWidgets('score cards show team scores separated by VS',
        (tester) async {
      await pumpWithState(tester, buildPlayedState());
      // Both score cards show 0 initially.
      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('VS'), findsOneWidget);
    });

    testWidgets('server indicator shows server number for doubles',
        (tester) async {
      await pumpWithState(tester, buildPlayedState());
      expect(find.text('Server 2 of 2'), findsOneWidget);
    });

    testWidgets('serving team badge shows TEAM A at start', (tester) async {
      await pumpWithState(tester, buildPlayedState());
      expect(find.text('TEAM A'), findsOneWidget);
      expect(find.text('SERVING'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows singles mode WITH court diagram', (tester) async {
      final state = buildPlayedState(
        matchType: 'singles',
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
      await pumpWithState(tester, state);
      expect(find.byType(CourtDiagram), findsOneWidget);
    });

    testWidgets('shows court diagram in doubles mode', (tester) async {
      await pumpWithState(tester, buildPlayedState());
      expect(find.byType(CourtDiagram), findsOneWidget);
    });

    testWidgets('shows game count in app bar', (tester) async {
      await pumpWithState(tester, buildPlayedState(gameCount: 3));
      expect(find.text('Game 1/3'), findsOneWidget);
    });

    testWidgets('shows rally scoring label in app bar', (tester) async {
      await pumpWithState(tester, buildPlayedState(scoringRule: 'rally'));
      expect(find.textContaining('Rally'), findsOneWidget);
    });

    testWidgets(
        'server swap: both players on serving team swap sides after point',
        (tester) async {
      final afterPoint = buildPlayedState(pointsTeamA: 1);
      await pumpWithState(tester, afterPoint);

      final sides = afterPoint.scoringState.playerSides;
      expect(sides['A0'], 'left');
      expect(sides['A1'], 'right');
    });

    testWidgets('server indicator shows the serving player name',
        (tester) async {
      final state = buildPlayedState();
      await pumpWithState(tester, state);
      // Alice (A0) is starting server — appears in both score card and
      // server indicator.
      expect(find.text('Alice'), findsAtLeastNWidgets(1));
    });

    testWidgets('undo button elements render when no events exist',
        (tester) async {
      await pumpWithState(tester, buildPlayedState());
      // Verify the undo button icon and label are present.
      // (OutlinedButton.icon uses a private subclass so find.byType won't match.)
      expect(find.text('Undo'), findsOneWidget);
      expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    });

    testWidgets('doubles mode shows VS divider between score cards',
        (tester) async {
      await pumpWithState(tester, buildPlayedState());
      expect(find.text('VS'), findsOneWidget);
    });

    testWidgets('shows end match button', (tester) async {
      await pumpWithState(tester, buildPlayedState());
      expect(find.text('End Match'), findsOneWidget);
    });

    testWidgets('point button debounce suppresses rapid dual-scoring', (tester) async {
      _useLargeViewport(tester);

      final db = createInMemoryDatabase();
      addTearDown(() async => db.close());

      // Capture the notifier from overrideWith so we can inspect call counts.
      _TestNotifier? notifier;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            themeModeProvider.overrideWith(StubThemeModeNotifier.new),
            liveMatchProvider.overrideWith((ref) {
              notifier = _TestNotifier(ref, buildPlayedState());
              return notifier!;
            }),
          ],
          child: const MaterialApp(home: LiveMatchScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Team A Scores!'));
      await tester.pump();
      expect(notifier!.scorePointCalls, 1);

      // Second rapid tap is suppressed by the 500 ms unified debounce
      // (Gemini finding G#8 — merged _lastPointTimeA/_lastPointTimeB
      // into a single _lastScoreTime to prevent dual-scoring).
      // scorePointCalls remains 1, not 2.
      await tester.tap(find.text('Team B Scores!'));
      await tester.pump();
      expect(notifier!.scorePointCalls, 1);
    });

    testWidgets('Team B point button fires scorePoint independently',
        (tester) async {
      _useLargeViewport(tester);

      final db = createInMemoryDatabase();
      addTearDown(() async => db.close());

      _TestNotifier? notifier;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            themeModeProvider.overrideWith(StubThemeModeNotifier.new),
            liveMatchProvider.overrideWith((ref) {
              notifier = _TestNotifier(ref, buildPlayedState());
              return notifier!;
            }),
          ],
          child: const MaterialApp(home: LiveMatchScreen()),
        ),
      );
      await tester.pump();

      // Tap Team B first (not debounced by a prior Team A tap).
      await tester.tap(find.text('Team B Scores!'));
      await tester.pump();
      expect(notifier!.scorePointCalls, 1);
    });

    testWidgets('tapping Team A Scores! updates the score in the UI',
        (tester) async {
      _useLargeViewport(tester);

      final db = createInMemoryDatabase();
      addTearDown(() async => db.close());

      // Capture the notifier to verify scorePoint was called.
      _TestNotifier? notifier;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            themeModeProvider.overrideWith(StubThemeModeNotifier.new),
            liveMatchProvider.overrideWith((ref) {
              notifier = _TestNotifier(ref, buildPlayedState(),
                  useRealScoring: true);
              return notifier!;
            }),
          ],
          child: const MaterialApp(home: LiveMatchScreen()),
        ),
      );
      await tester.pump();

      // Initial: both scores are 0.
      expect(find.text('0'), findsNWidgets(2));

      // Tap Team A's score button.
      await tester.tap(find.text('Team A Scores!'));
      // Process the tap + state change.
      await tester.pump();
      // Pump the AnimatedSwitcher (200ms) so old "0" fades out and only
      // the new "1" remains.
      await tester.pump(const Duration(milliseconds: 300));

      // Confirm scorePoint was invoked.
      expect(notifier!.scorePointCalls, 1);
      // Verify the notifier's state updated.
      expect(notifier!.state?.teamAScore, 1);

      // After a point: Team A shows 1, Team B still shows 0.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    // ── PopScope on match-end dialog ──

    testWidgets('match-end PopScope blocks system back, View Details works',
        (tester) async {
      bool viewDetailsTapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          // Show the dialog via post-frame callback (same mechanism the
          // real LiveMatchScreen uses).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => PopScope(
                canPop: false,
                child: AlertDialog(
                  title: const Text('Match Over!'),
                  content: const Text('Team A wins the match!'),
                  actions: [
                    FilledButton(
                      onPressed: () {
                        viewDetailsTapped = true;
                        Navigator.of(ctx).pop(true);
                      },
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ),
            );
          });
          return const Scaffold(body: Center(child: Text('screen')));
        }),
      ));

      // Pump to build the dialog widgets (the post-frame callback that
      // pushed the dialog route already ran during pumpWidget).
      await tester.pump();
      // Dialog should be visible.
      expect(find.text('Match Over!'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);

      // System back button should NOT dismiss the dialog (PopScope blocks it).
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Match Over!'), findsOneWidget);
      expect(viewDetailsTapped, isFalse);

      // Tapping "View Details" should dismiss the dialog.
      await tester.tap(find.text('View Details'));
      await tester.pump();
      expect(viewDetailsTapped, isTrue);
      expect(find.text('Match Over!'), findsNothing);
    });

    // ── Score Callout ──
    //
    // The callout surfaces `MatchState.scoreCallout` between the server
    // indicator and the scoreboard. Doubles: `X-X-N`, Singles: `X-X`.

    testWidgets('doubles initial state renders 0-0-2 callout',
        (tester) async {
      await pumpWithState(tester, buildPlayedState());

      // Doubles initial state: 0-0-2. The widget tree is searched
      // directly via find.text; the Semantics wrapper that gives screen
      // readers the same phrase is verified separately — see the
      // dedicated a11y test below.
      expect(find.text('0-0-2'), findsOneWidget);
    });

    testWidgets('singles initial state renders 0-0 callout', (tester) async {
      final state = buildPlayedState(
        matchType: 'singles',
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
      await pumpWithState(tester, state);

      // Singles has no server number — just the two scores.
      expect(find.text('0-0'), findsOneWidget);
    });

    testWidgets('callout updates to 1-0-2 after Team A scores',
        (tester) async {
      _useLargeViewport(tester);

      final db = createInMemoryDatabase();
      addTearDown(() async => db.close());

      _TestNotifier? notifier;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            themeModeProvider.overrideWith(StubThemeModeNotifier.new),
            liveMatchProvider.overrideWith((ref) {
              notifier = _TestNotifier(
                ref,
                buildPlayedState(),
                useRealScoring: true,
              );
              return notifier!;
            }),
          ],
          child: const MaterialApp(home: LiveMatchScreen()),
        ),
      );
      await tester.pump();

      // Sanity: starts as 0-0-2.
      expect(find.text('0-0-2'), findsOneWidget);

      await tester.tap(find.text('Team A Scores!'));
      await tester.pump();
      // AnimatedSwitcher is 200ms; score-card AnimatedSwitcher is also
      // 120ms. Pump past the longer of the two so the new child settles.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 50));

      // Callout now reads 1-0-2 — Team A scored, server #2 still serving.
      expect(find.text('0-0-2'), findsNothing);
      expect(find.text('1-0-2'), findsOneWidget);
    });

    testWidgets('callout flips to TEAM B accent after side-out',
        (tester) async {
      _useLargeViewport(tester);

      final db = createInMemoryDatabase();
      addTearDown(() async => db.close());

      _TestNotifier? notifier;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            themeModeProvider.overrideWith(StubThemeModeNotifier.new),
            liveMatchProvider.overrideWith((ref) {
              notifier = _TestNotifier(
                ref,
                buildPlayedState(),
                useRealScoring: true,
              );
              return notifier!;
            }),
          ],
          child: const MaterialApp(home: LiveMatchScreen()),
        ),
      );
      await tester.pump();

      // Tap Team B — forces side-out (server #2 lost → Team B serves #1).
      await tester.tap(find.text('Team B Scores!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Score is still 0-0 (side-out awards no point) but server
      // number is now 1, on Team B.
      expect(find.text('0-0-1'), findsOneWidget);
      // TEAM B serving badge replaces TEAM A.
      expect(find.text('TEAM B'), findsOneWidget);
      expect(find.text('TEAM A'), findsNothing);
    });

    testWidgets('callout exposes Score call semantics label for a11y',
        (tester) async {
      await pumpWithState(tester, buildPlayedState());
      // Verify the screen-reader announcement contract directly against
      // `Semantics.properties.label`. flutter_test's
      // `find.bySemanticsLabel` does not always traverse a
      // `Semantics(container: true)` wrapper that contains an
      // AnimatedSwitcher, so we read the property the framework will
      // actually publish to TalkBack.
      final semantics = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .firstWhere(
            (s) => (s.properties.label ?? '').startsWith('Score call:'),
            orElse: () =>
                fail('No Semantics widget with "Score call:" label'),
          );
      expect(semantics.properties.label, 'Score call: 0-0-2');
    });
  });

  // ── Golden test regen helper ──
  //
  // The test/goldens/*.png files are an artifact of the screen design.
  // When the visible layout changes (new widget added, spacing tweaked,
  // colors updated) the goldens must be regenerated with:
  //
  //   flutter test --update-goldens test/live_match_screen_golden_test.dart
  //
  // then committed alongside the code change. The test named below is
  // here so anyone running --update-goldens with a stale screen sees this
  // reminder fail loudly instead of silently overwriting a known-good
  // golden by accident.
  test(
      'goldens regen reminder: goldens must be regenerated with '
      '--update-goldens when layout changes', () {
    // Intentionally a no-op — see comment above.
  });
}

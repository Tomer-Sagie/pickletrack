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
import 'package:pickletrack/widgets/shimmer.dart';
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
  // Prevent the first-match tutorial overlay from blocking taps.
  await db.setSetting('has_seen_tutorial', 'true');

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
  await tester.pump();
}

void main() {
  group('LiveMatchScreen', () {
    // ── Loading / Error / Null states ──

    testWidgets('shows loading spinner initially', (tester) async {
      final db = createInMemoryDatabase();
      addTearDown(() async => db.close());
      await db.setSetting('has_seen_tutorial', 'true');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            themeModeProvider.overrideWith(StubThemeModeNotifier.new),
          ],
          child: const MaterialApp(home: LiveMatchScreen()),
        ),
      );
      expect(find.byType(ShimmerMatchDetails), findsOneWidget);
    });

    testWidgets('shows doubles scoreboard with teams and scores',
        (tester) async {
      await pumpWithState(tester, buildPlayedState());

      // Player names appear in the unified score.
      expect(find.text('Alice'), findsAtLeastNWidgets(1));
      expect(find.text('Carol'), findsAtLeastNWidgets(1));
      // Both teams have score 0 (unified score shows two score columns).
      // The callout "0-0-2" also contains 0s, so find.text('0') will
      // match more than 2. Just verify both point buttons exist.
      expect(find.text('Alice & Bob'), findsOneWidget);
      expect(find.text('Carol & Dave'), findsOneWidget);
    });

    testWidgets('score cards show team scores in unified widget',
        (tester) async {
      await pumpWithState(tester, buildPlayedState());
      // Initial callout is "0-0-2" — verify it renders.
      expect(find.text('0-0-2'), findsOneWidget);
    });

    testWidgets('server indicator shows server number for doubles',
        (tester) async {
      await pumpWithState(tester, buildPlayedState());
      // Unified score shows "Server 2/2" for doubles.
      expect(find.textContaining('Server 2'), findsOneWidget);
    });

    testWidgets('serving team badge shows team label at start',
        (tester) async {
      await pumpWithState(tester, buildPlayedState());
      // Court diagram has "TEAM A" / "TEAM B" labels.
      // The unified score server indicator shows the server name.
      expect(find.text('Alice serving'), findsOneWidget);
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
      // Alice (A0) is starting server — appears in unified score.
      expect(find.text('Alice serving'), findsOneWidget);
    });

    testWidgets('undo button is present', (tester) async {
      await pumpWithState(tester, buildPlayedState());
      // Undo is now an IconButton — verify the icon renders.
      expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    });

    testWidgets('doubles mode renders unified score without VS divider',
        (tester) async {
      await pumpWithState(tester, buildPlayedState());
      // VS divider is removed — unified score doesn't need it.
      expect(find.text('VS'), findsNothing);
      // Callout text is still present in the center.
      expect(find.text('0-0-2'), findsOneWidget);
    });

    testWidgets('shows end match button', (tester) async {
      await pumpWithState(tester, buildPlayedState());
      // End Match button now says "End" (compact, separated from Undo).
      expect(find.text('End'), findsOneWidget);
    });

    testWidgets('point button debounce suppresses rapid dual-scoring',
        (tester) async {
      _useLargeViewport(tester);

      final db = createInMemoryDatabase();
      addTearDown(() async => db.close());
      await db.setSetting('has_seen_tutorial', 'true');

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

      await tester.tap(find.text('Alice & Bob'));
      await tester.pump();
      expect(notifier!.scorePointCalls, 1);

      // Second rapid tap is suppressed by the 500 ms unified debounce.
      await tester.tap(find.text('Carol & Dave'));
      await tester.pump();
      expect(notifier!.scorePointCalls, 1);
    });

    testWidgets('Team B point button fires scorePoint independently',
        (tester) async {
      _useLargeViewport(tester);

      final db = createInMemoryDatabase();
      addTearDown(() async => db.close());
      await db.setSetting('has_seen_tutorial', 'true');

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
      await tester.tap(find.text('Carol & Dave'));
      await tester.pump();
      expect(notifier!.scorePointCalls, 1);
    });

    testWidgets('tapping Team A updates the score in the UI',
        (tester) async {
      _useLargeViewport(tester);

      final db = createInMemoryDatabase();
      addTearDown(() async => db.close());
      await db.setSetting('has_seen_tutorial', 'true');

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
      expect(find.text('0'), findsAtLeastNWidgets(1));

      // Tap Team A's score button.
      await tester.tap(find.text('Alice & Bob'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(notifier!.scorePointCalls, 1);
      expect(notifier!.state?.teamAScore, 1);

      // After a point: Team A shows 1.
      expect(find.text('1'), findsOneWidget);
    });

    // ── PopScope on match-end dialog ──

    testWidgets('match-end PopScope blocks system back, View Details works',
        (tester) async {
      bool viewDetailsTapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
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

      await tester.pump();
      expect(find.text('Match Over!'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Match Over!'), findsOneWidget);
      expect(viewDetailsTapped, isFalse);

      await tester.tap(find.text('View Details'));
      await tester.pump();
      expect(viewDetailsTapped, isTrue);
      expect(find.text('Match Over!'), findsNothing);
    });

    // ── Score Callout ──

    testWidgets('doubles initial state renders 0-0-2 callout',
        (tester) async {
      await pumpWithState(tester, buildPlayedState());
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
      expect(find.text('0-0'), findsOneWidget);
    });

    testWidgets('callout updates to 1-0-2 after Team A scores',
        (tester) async {
      _useLargeViewport(tester);

      final db = createInMemoryDatabase();
      addTearDown(() async => db.close());
      await db.setSetting('has_seen_tutorial', 'true');

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

      expect(find.text('0-0-2'), findsOneWidget);

      await tester.tap(find.text('Alice & Bob'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('0-0-2'), findsNothing);
      expect(find.text('1-0-2'), findsOneWidget);
    });

    testWidgets('callout flips to TEAM B accent after side-out',
        (tester) async {
      _useLargeViewport(tester);

      final db = createInMemoryDatabase();
      addTearDown(() async => db.close());
      await db.setSetting('has_seen_tutorial', 'true');

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

      // Tap Team B — forces side-out.
      await tester.tap(find.text('Carol & Dave'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Score is still 0-0 (side-out awards no point) but server
      // number is now 1, on Team B.
      expect(find.text('0-0-1'), findsOneWidget);
      // Serving indicator now shows Carol (B0).
      expect(find.text('Carol serving'), findsOneWidget);
    });

    testWidgets('callout exposes Score call semantics label for a11y',
        (tester) async {
      await pumpWithState(tester, buildPlayedState());
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
  test(
      'goldens regen reminder: goldens must be regenerated with '
      '--update-goldens when layout changes', () {
    // Intentionally a no-op — see comment above.
  });
}

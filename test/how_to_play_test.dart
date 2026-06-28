import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pickletrack/models/scoring_preset.dart';
import 'package:pickletrack/providers/database_provider.dart';
import 'package:pickletrack/providers/settings_provider.dart';
import 'package:pickletrack/providers/theme_provider.dart';
import 'package:pickletrack/screens/settings/settings_screen.dart';

import 'helpers/stubs.dart';

/// Sets a tall enough viewport for the entire Settings screen so the
/// How-to-Play ExpansionTile (which sits below the About card) plus
/// its 5 expanded sections fit on a single scroll surface without
/// being clipped by the viewport edge. 3200dp covers the cumulative
/// height of: Theme (3) + Defaults (5) + Feedback (4) + Data (3) +
/// About (8) + How-to-Play title (2) + 5 sections × ~3 each (~15).
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Pumps SettingsScreen with all async settings providers pinned to
/// concrete sync values so the entire tree settles with no loaders
/// before the test body expands the How-to-Play tile.
Future<void> pumpSettingsForHowToPlay(WidgetTester tester) async {
  _useTallViewport(tester);
  final db = createInMemoryDatabase();
  addTearDown(() async => db.close());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        themeModeProvider.overrideWith(StubThemeModeNotifier.new),
        defaultScoringRuleProvider
            .overrideWith((_) => Future.value('sideout')),
        defaultGameCountProvider.overrideWith((_) => Future.value(1)),
        defaultScoringPresetProvider
            .overrideWith((_) => Future.value(ScoringPreset.standard)),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // User-stated goal: "locking in the format against future
  // regressions". The Data source is the new structural piece
  // (extracted to `_kHowToPlaySections`); rendering the 5 sections
  // + ≥1 bullet each proves both the data shape AND the renderer
  // still agree.
  group('How-to-Play data source regression', () {
    testWidgets(
      'expanded tile shows all 5 section titles',
      (tester) async {
        await pumpSettingsForHowToPlay(tester);

        // Tile starts collapsed — verify the title is present and
        // the 5 section titles are NOT yet visible.
        expect(find.text('How to Play'), findsOneWidget);
        expect(find.text('Basic Rules'), findsNothing);
        expect(find.text('The Kitchen'), findsNothing);

        // Open the ExpansionTile.
        await tester.tap(find.text('How to Play'));
        await tester.pumpAndSettle();

        // Hard regression lock: there are exactly 5 sections.
        // A 6th section added (e.g. "Tournament Play" copy-pasted
        // in to `_kHowToPlaySections` by mistake) would silently
        // pass the per-title existence check above — counting the
        // ExpansionTile's children catches it. The children list is
        // mounted at construction time so `tile.children.length` is
        // stable across the open/close animation.
        final tile = tester.widget<ExpansionTile>(
          find.widgetWithText(ExpansionTile, 'How to Play'),
        );
        expect(tile.children.length, 5);

        // All 5 titles render at least once each.
        expect(find.text('Basic Rules'), findsAtLeastNWidgets(1));
        expect(find.text('Doubles Serving'), findsAtLeastNWidgets(1));
        expect(find.text('Singles Serving'), findsAtLeastNWidgets(1));
        expect(find.text('Rally Scoring'), findsAtLeastNWidgets(1));
        expect(find.text('The Kitchen'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'each of the 5 sections renders at least one bullet',
      (tester) async {
        await pumpSettingsForHowToPlay(tester);

        await tester.tap(find.text('How to Play'));
        await tester.pumpAndSettle();

        // One distinctive anchor phrase per section, chosen so a
        // sibling section's copy can't accidentally match.
        // `findsAtLeastNWidgets(1)` (not findsOneWidget) matches
        // the user's stated acceptance criterion — “at least one
        // bullet per section” — and tolerates an incidental second
        // render of the same bullet (which would still satisfy the
        // ≥1 contract). Specifically catches the case where a
        // section accidentally renders zero bullets.
        expect(
          find.textContaining('Games are played to 11 points'),
          findsAtLeastNWidgets(1),
          reason: 'Basic Rules must render at least one bullet',
        );
        expect(
          find.textContaining('first server of the game starts as Server 2'),
          findsAtLeastNWidgets(1),
          reason: 'Doubles Serving must render at least one bullet',
        );
        expect(
          find.textContaining('Serve from the right side when your score is even'),
          findsAtLeastNWidgets(1),
          reason: 'Singles Serving must render at least one bullet',
        );
        expect(
          find.textContaining('Every rally awards a point'),
          findsAtLeastNWidgets(1),
          reason: 'Rally Scoring must render at least one bullet',
        );
        expect(
          find.textContaining('No volleying while standing in the non-volley zone'),
          findsAtLeastNWidgets(1),
          reason: 'The Kitchen must render at least one bullet',
        );
      },
    );
  });
}

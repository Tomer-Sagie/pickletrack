# Changelog

## v1.1.0 — Audit & Stability Release

### 🔴 Critical

- **Spec updated** — Deferred-to-v1.1 section removed; all shipped features now documented in `pickletrack-spec.md`.
- **Accessibility overhaul** — `Semantics` wrappers added to all tappable widgets across Home, Live, Setup, Settings, and Match Details screens. Screen readers now announce button labels, hints, and score-callout values.
- **Home card subtitle corrected** — "Standard Start" card now reads the user's real Settings defaults (`defaultScoringRuleProvider`, `defaultGameCountProvider`, `defaultScoringPresetProvider`) instead of hardcoding "Doubles, side-out, 11."
- **Clear All Data invalidates providers** — After clearing data in Settings, the Home screen now reflects the empty state immediately without requiring a manual navigation away-and-back.

### 🔴 High

- **Elapsed-time crash on resume** — `setState()` during `build()` when resuming a live match (timer started before first frame). Deferred timer start to `addPostFrameCallback`.
- **Array OOB crash on Doubles↔Singles switch** — `_hasUnsavedChanges` loop now bounded by `min()` of controller/text lengths to prevent `RangeError` when match-type toggle shortens player fields.
- **Quick Start respects user defaults** — `_applyDefaults()` now reads from `defaultScoringRuleProvider` / `defaultGameCountProvider` / `defaultScoringPresetProvider` instead of hardcoding sideout / 1 game / 11-2.
- **"Start Match" button now starts the match** — Previously just pushed Setup (identical to "Edit Setup"). Now calls `createMatchInDb` with generic player names and navigates to `/match/live`.
- **Screenshot export captures full content** — `RepaintBoundary` now wraps `SingleChildScrollView`+`Column` instead of `ListView` so long play-by-play logs aren't truncated.
- **Match-type toggle preserves player names** — Switching Doubles↔Singles now restores previously typed text from old controllers instead of wiping to placeholders.
- **SwitchListTile accessibility unbroken** — Removed `Semantics` wrappers that overrode native toggle announcements; screen readers now correctly say "Switch, On/Off."
- **Score-callout font more legible** — Bumped from `titleLarge` (~22sp) to `headlineMedium` (~28sp) for more prominent score announcement.
- **Empty-state has actionable CTA** — "Ready to play?" empty state on Home now includes a `FilledButton` ("New Match") instead of just instructional text.
- **Live elapsed-time clock** — AppBar now shows a live `MM:SS` clock updated every second via `Timer.periodic`, replacing the old static snapshot.
- **ElevatedButton→FilledButton** — Point-score buttons now use `FilledButton` for correct M3 theme integration.
- **Hardcoded colors replaced** — SnackBar backgrounds now use `colorScheme.error` instead of `Colors.red.shade700`.
- **Discard-dialog fix** — `_fieldsTouched` replaced with `_hasUnsavedChanges` (compares against post-init snapshots) so the dialog only fires when changes actually exist.
- **Dismissible threshold tuned** — Match-card swipe-to-delete threshold set to 0.5 (was default ~0.25), reducing accidental deletions.
- **Active-match guard** — `createMatchInDb` now clears any stale active-match rows before creating a new match, preventing orphaned multi-active-match state from a previous crash.
- **Point-button debounce unified** — Split `_lastPointTimeA`/`_lastPointTimeB` merged into single `_lastScoreTime`, preventing simultaneous dual-scoring when mashing both buttons.
- **Unsafe `int.parse` hardened** — Router now uses `int.tryParse` with fallback for malformed match-ID deep links.
- **Singles court diagram** — Court diagram now renders for singles matches (2 centered dots, no center service line) instead of being hidden.
- **Dark-mode splash** — Bootstrap splash now respects `platformDispatcher.platformBrightness` so dark-mode users don't get a white flash before the theme loads.

### 🟠 Medium

- **Score-callout font size** — Bumped from `titleLarge` to `headlineMedium`.
- **`_repaintKey` explicit** — Made `late final` for single-init intent.
- **Empty-state CTA button** — Added `FilledButton` to "Ready to play?" state.
- **Home "no matches yet" placeholder** — Shows "No completed matches yet." with Match History header instead of blank `SizedBox.shrink()` when an active match exists but no completed matches.
- **Serving badge WCAG AA compliant** — Changed from solid `teamColor` + white text (~4:1 ratio) to tinted background + full `teamColor` text, exceeding 4.5:1 minimum.
- **Completed-matches error state** — DB read failures now show "Failed to load match history" with a Retry button instead of silently swallowing the error.
- **Starting Server chip prevents deselection** — Tapping the already-selected `ChoiceChip` is now a no-op, preventing accidental `null` selection.
- **Duplicate a11y on Point Buttons** — Added `ExcludeSemantics` to `FilledButton` child so screen readers don't double-announce.

### 🟢 Low

- **Removed unused color aliases** — `teamAScoreColor` and `teamBScoreColor` (exact duplicates of `courtGreen`/`courtBlue`) removed from `colors.dart`.
- **i18n readiness comment** — Added `TODO(i18n)` above How-to-Play section noting hardcoded English strings for future localization.
- **`endMatch` error handling** — Both `_onEndMatch` and `_showMatchEndBanner` now catch errors and show a SnackBar instead of leaving the user stuck on a dead screen.
- **`const` variable** — `newServerSide` in `scoring_service.dart` changed from `final` to `const`.

### 🧹 Tooling

- **Drift wasm migration** — `database_web.dart` migrated from deprecated `drift/web.dart` to `drift/wasm.dart`. Both connection branches (`database_io.dart`, `database_web.dart`) now return `DatabaseConnection` for conditional-import type safety.
- **Lint baseline zeroed** — 50 `dart analyze` info warnings reduced to 0 across 7 files (const constructors, curly braces, async context guards, Drift false positives).
- **Golden tests regenerated** — 4 golden images updated for visual changes (score-callout font, serving badge, singles court diagram). 3 test expectations updated to match new behavior.
- **Test count increased** — 143 tests (up from 135), all passing.

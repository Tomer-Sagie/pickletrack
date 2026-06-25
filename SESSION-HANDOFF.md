# Session Handoff — PickleTrack

> **Purpose:** Give a fresh Codebuff session everything it needs to continue building PickleTrack seamlessly.
> **Created:** June 23, 2026
> **Session summary:** ~7 rounds of user interviews → spec → court diagram design → simplified MVP scope → Flutter project scaffold + Drift database + scoring engine

---

## 1. What We're Building

**PickleTrack** — a free, offline-first, Flutter-based pickleball game tracker for iOS & Android. No accounts, no cloud, no paid dependencies. Lives entirely on-device with full kill-survival for in-progress matches.

**Tech stack:** Flutter (Dart) + Drift (SQLite) + Riverpod + go_router + Material Design 3

**Key files to read first (in order):**
1. `pickletrack-spec.md` — the full spec with every screen, data model, scoring rules, and defaults
2. `court-diagram-design.md` — detailed CustomPainter design for the mini court diagram widget
3. `pubspec.yaml` — dependencies (already simplified for MVP)
4. `lib/database/tables.dart` — 7 Drift table definitions
5. `lib/services/scoring_service.dart` — pure scoring engine (most critical logic)

---

## 2. Current State — What's Done

| Layer | Status | Files |
|-------|--------|-------|
| Spec & Design | ✅ Complete | `pickletrack-spec.md`, `court-diagram-design.md` |
| Project scaffold | ✅ Complete | `pubspec.yaml`, `analysis_options.yaml` |
| Theme system | ✅ Complete | `lib/theme/colors.dart`, `lib/theme/app_theme.dart` |
| Database schema | ✅ Complete | `lib/database/tables.dart` (7 tables), `lib/database/database.dart` |
| Scoring engine | ✅ Complete | `lib/services/scoring_service.dart` (side-out + rally, doubles rotation, win-by-2) |
| Scoring presets | ✅ Complete | `lib/models/scoring_preset.dart` |
| DB provider | ✅ Complete | `lib/providers/database_provider.dart` |
| Core app shell | ✅ Complete | `lib/main.dart`, `lib/app.dart`, `lib/router.dart` |
| Placeholder screens | ✅ Stubs only | All 5 screens are `// TODO` placeholders |
| Reusable widgets | ✅ Complete | `lib/widgets/confirm_dialog.dart`, `lib/widgets/empty_state.dart` |

### What has NOT been built yet (the real work):
- ❌ Home Screen (Quick Start, match list, resume banner)
- ❌ New Match Setup Screen (form with names, server picker, presets)
- ❌ Live Match Screen (scoreboard, court diagram, point buttons, undo, pause)
- ❌ Match Details Screen (play-by-play log)
- ❌ Settings Screen (theme toggle, defaults, clear data)
- ❌ All Riverpod providers beyond the database singleton
- ❌ Unit tests
- ❌ README

---

## 3. MVP Scope — What's In vs. Deferred

### Included in MVP:
- 5 screens (Home, Setup, Live, Details, Settings)
- Doubles + singles scoring (side-out and rally)
- Court position diagram (CustomPainter, per `court-diagram-design.md`)
- Server indicator with 0-0-2 rule display
- Full kill-survival (active match persisted to SQLite on every action)
- Unlimited undo
- Best-of-3 game support
- Quick Start with generic names + edit option
- Recent player name autocomplete
- Dark/light mode toggle
- Simple completed matches list (tap to view details)
- Basic Settings (theme, scoring defaults, clear data)

### Deferred to v1.1+:
- ❌ Sound/haptic feedback
- ❌ Search in match history
- ❌ Stats cards (win rate, avg score)
- ❌ Swipe-to-delete matches
- ❌ Share/export text + screenshot
- ❌ Sound & haptic toggles in Settings

---

## 4. Key Decisions from User Interviews (7 Rounds)

| Decision | Choice | Round |
|----------|--------|-------|
| Framework | Flutter (Dart) — free, polished UI | R1 |
| Database | Drift (SQLite) — best for relational match data | R1 |
| State management | Riverpod — 2026 Flutter standard | R1 |
| Feedback | Both haptic + sound (deferred to v1.1) | R1 |
| Resume match | Full kill survival (persist to SQLite) | R2 |
| Undo depth | Unlimited (full history) | R2 |
| Play-by-play | Full log (every point with timestamp) | R2 |
| Timer | Record final duration only, no visible clock | R2 |
| Scoring rules | Both side-out + rally, toggleable | R3 |
| 0-0-2 rule | Explicit "Server 1/2" indicator | R3 |
| Court position | Mini court diagram (polished, professional) | R3 |
| Edit matches | Read-only after completion | R3 |
| Design vibe | Classic court (pickleball court colors) | R4 |
| Accent color | Pickleball yellow/green #C8E030, M3 palette | R4 |
| Match history | Simple list (search + stats deferred) | R4 |
| Scoring presets | Full presets: Quick/Standard/Tournament/Custom | R4 |
| Quick Start | Doubles, 4 generic names, warn + edit option | R5 |
| Player names | Autocomplete from recent players (last 20) | R5 |
| Games per match | Configurable (1 game or best of 3) | R5 |
| Share/Export | Text + screenshot (deferred to v1.1) | R5 |
| Icons | Mix of Material 3 + open-source pickleball | R6 |
| Pause | Both "Pause" (freeze) + "Save & Exit" (home) | R6 |
| Delete matches | Swipe to delete (deferred to v1.1) | R6 |
| App name | PickleTrack | R7 |
| Device layout | Phone only (portrait) | R7 |
| Testing | Automated tests + manual QA checklist | R7 |
| Court viz | Mini court diagram via CustomPainter | R7 |

---

## 5. Architecture at a Glance

```
lib/
├── main.dart                    → ProviderScope → PickleTrackApp
├── app.dart                     → MaterialApp.router (M3 light/dark themes)
├── router.dart                  → go_router: /, /match/setup, /match/live, /match/:id, /settings
├── theme/
│   ├── colors.dart              → All M3 color constants + court accent colors
│   └── app_theme.dart           → light + dark ThemeData
├── database/
│   ├── tables.dart              → 7 Drift table classes
│   └── database.dart            → AppDatabase (queries, recordPlayer, completeMatch, undo)
├── models/
│   └── scoring_preset.dart      → Quick(7)/Standard(11)/Tournament(15)/Custom
├── providers/
│   └── database_provider.dart   → Singleton DB provider
├── services/
│   └── scoring_service.dart     → Pure MatchState + ScoringService (no deps)
├── screens/
│   ├── home/home_screen.dart        → STUB
│   ├── setup/setup_screen.dart      → STUB
│   ├── live/live_match_screen.dart  → STUB
│   ├── details/match_details_screen.dart → STUB
│   └── settings/settings_screen.dart → STUB
└── widgets/
    ├── confirm_dialog.dart      → Reusable confirmation dialog
    └── empty_state.dart         → Reusable empty state placeholder
```

### Data flow:
1. `SetupScreen` → creates `ActiveMatch` + `ActiveMatchPlayers` in Drift
2. `LiveMatchScreen` → reads state from Drift, passes actions to `ScoringService`, writes `ScoreEvents`
3. On match end → `AppDatabase.completeMatch()` archives to `CompletedMatches` + `MatchEventLog`, clears active tables
4. `HomeScreen` → reads `CompletedMatches` list, checks for active match (resume banner)

### Scoring engine design (`scoring_service.dart`):
- `MatchState` is an **immutable value object** with `copyWith`
- `ScoringService` has **only static methods** (no instances, no side effects)
- `recordPoint(state, team)` → returns `ScoreResult(newState, eventType)`
- Handles: side-out scoring, rally scoring, doubles 0-0-2 start, server 1→2→side-out rotation, game-end detection with win-by-2, best-of-3 game transitions with side-switch
- `playerTeams` and `playerSides` maps on `MatchState` enable correct partner lookup and side tracking

---

## 6. Database — 7 Tables

| Table | Purpose | Key columns |
|-------|---------|-------------|
| `active_matches` | Single in-progress match | type, scoring_rule, game_count, play_to, win_by, status |
| `active_match_players` | Players in active match | match_id (FK), name, team, is_starting_server, position (L/R) |
| `score_events` | Append-only event log | match_id, game_number, event_type, scorer_team, team_a_score, team_b_score, server_number |
| `completed_matches` | Archived finished matches | type, team_a_players (JSON), team_b_players (JSON), final_scores (JSON), winner, duration_seconds |
| `match_event_log` | Frozen play-by-play | completed_match_id (FK), game_number, event_type, scores |
| `recent_players` | Autocomplete source | name (PK), last_used, usage_count — pruned to 20 |
| `app_settings` | Key-value config | key (PK), value |

---

## 7. Bugs Already Found & Fixed

The scoring engine and database went through two rounds of code review. Fixed issues:

1. `_findPlayerOnSide` didn't filter by team → added `playerTeams` map to `MatchState`
2. Rally scoring doubles used wrong side-out rotation → added `forceFullSideOut` flag
3. Server 1→2 transition didn't change player ID → now uses `_findPartnerOnTeam`
4. `recordPlayer` prune logic silently failed → fixed unfiltered select
5. `undoLastEvent` subquery might not compile → replaced with two-step approach
6. Game alternation used wrong game number → now passes `nextGame` to `_serverTeamForGame`
7. `completeMatch` counted events for gamesPlayed → now takes `currentGame` parameter
8. `close()` was infinitely recursive → removed (Drift handles it)

---

## 8. How to Set Up on a New Machine

```bash
# 1. Install Flutter (if not already)
# https://docs.flutter.dev/get-started/install

# 2. Navigate to the project
cd "/Users/...your path.../PickleBall"

# 3. Install dependencies
flutter pub get

# 4. Generate Drift code (database.g.dart)
dart run build_runner build

# 5. Verify it compiles
flutter analyze

# 6. Run on emulator/device
flutter run
```

---

## 9. What to Build Next (Recommended Order)

### Priority 1: New Match Setup Screen
- File: `lib/screens/setup/setup_screen.dart` (already stubbed)
- Build the full form: match type segmented button, player name fields with autocomplete (from `recent_players`), starting server selector, scoring rule toggle, games selector, win condition preset picker
- Connect to `database_provider` to persist `ActiveMatch` + `ActiveMatchPlayers` on "Start Match"
- Validation: at least one name per team, server selected
- See spec §5.2 for full layout

### Priority 2: Live Match Screen
- Files in `lib/screens/live/`: live_match_screen, scoreboard, server_indicator, court_diagram, point_buttons, pause_menu
- Court diagram: follow `court-diagram-design.md` — two-layer CustomPainter (static court + animated player dots with radar-pulse server glow)
- Server indicator: show "Player X is Serving — Server 1 of 2" with score callout
- Scoreboard: two large score cards with animated number transitions
- Point buttons: debounced (500ms), wired to `ScoringService.recordPoint`, write `ScoreEvent` to DB
- Undo: delete last `ScoreEvent`, recalculate state
- Pause: bottom sheet with Resume / Save & Exit / End Match
- See spec §5.3 for full layout and edge cases

### Priority 3: Home Screen
- File: `lib/screens/home/home_screen.dart`
- Resume banner (if active match exists)
- Quick Start card → bottom sheet → edit or start
- New Match button → navigates to setup
- Completed matches list (simple list, tap to view details)
- See spec §5.1 for full layout

### Priority 4: Match Details Screen
- File: `lib/screens/details/match_details_screen.dart`
- Read-only: result banner, players, play-by-play log
- See spec §5.4

### Priority 5: Settings Screen
- File: `lib/screens/settings/settings_screen.dart`
- Theme toggle, scoring defaults, clear data
- See spec §5.5 (skip sound/haptic toggles for MVP)

### Priority 6: Unit Tests
- `test/scoring_service_test.dart` — test every scoring scenario
- `test/integration/full_match_test.dart` — create + complete match, verify storage

---

## 10. Prompt to Use in a New Chat

When you start a new Codebuff session on another device, use this prompt:

> "I'm continuing work on PickleTrack, a Flutter pickleball scoring app. Read `SESSION-HANDOFF.md` for full context, then read `pickletrack-spec.md` and `court-diagram-design.md`. The project scaffold, database, and scoring engine are complete. The 5 screen files are stubs that need real implementations. Start with the New Match Setup screen. Don't build sound/haptics, search, or sharing features — those are deferred to v1.1."

---

*End of handoff. Everything below this line is the existing project.*

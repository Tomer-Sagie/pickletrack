# PickleTrack — Specification Document

> **App Name:** PickleTrack  
> **Tagline:** A free, offline-first pickleball game tracker for iOS & Android  
> **Spec Version:** 1.0  
> **Date:** June 23, 2026

---

## MVP Scope (v1.0 — Current)

The following features are **included** in the current MVP:
- ✅ Flutter + Drift (SQLite) + Riverpod + go_router
- ✅ Home Screen: Quick Start + New Match buttons, simple completed matches list
- ✅ New Match Setup: match type, player names, starting server, scoring rule, games, win preset
- ✅ Live Match: scoreboard, server indicator, court diagram, point buttons, undo, pause, end match
- ✅ Match Details: read-only view with play-by-play
- ✅ Settings: theme toggle, scoring defaults, clear data
- ✅ Dark/light mode (M3 theming)
- ✅ Full kill survival for in-progress matches
- ✅ Recent player names autocomplete
- ✅ Drift database with all 7 tables and migrations

**All originally deferred v1.1 features shipped in v1.0:**
- ✅ Sound/haptic feedback on point scored (toggleable in Settings)
- ✅ Search in match history (filter by player name)
- ✅ Stats cards (matches played, win rate, avg score)
- ✅ Swipe-to-delete matches from history
- ✅ Share/export match details (text summary + screenshot)
- ✅ Sound & haptic toggles in Settings

---

## 1. Architecture Summary

PickleTrack is a **Flutter (Dart)** mobile application using **Drift (SQLite)** for local persistence, **Riverpod** for state management, and **Material Design 3** theming. All data lives on-device with zero cloud dependencies. The app survives force-kills mid-match by persisting in-progress match state to SQLite on every action. Navigation uses Flutter's built-in Navigator 2.0 / `go_router`. The app is phone-only (portrait orientation), with no tablet adaptation in v1. Scoring logic is pure Dart (no native plugins) and is fully unit-testable. Haptic + short sound feedback on point scoring is toggleable in Settings. Match Details can be shared via the native OS share sheet (text summary or screenshot).

**Key design principles:**
- Everything is free and open-source — no paid dependencies, no accounts, no cloud
- Offline-first with full kill-survival for in-progress matches
- Classic pickleball court aesthetic with M3 token-based theming
- Sensible defaults with configurable presets

---

## 2. Technology Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| **Framework** | Flutter 3.x (Dart) | Free, open-source, polished custom UI, Impeller engine for smooth animations |
| **Local DB** | Drift (SQLite wrapper) | Type-safe SQL, reactive streams, robust migrations, best for relational match/score data |
| **State Management** | Riverpod | Compile-safe, testable, 2026 Flutter standard |
| **Routing** | go_router | Declarative, deep-link capable, back-button friendly |
| **Icons** | Material 3 icons + open-source pickleball SVGs | Free, no AI-generated assets, authentic look |
| **Sound** | `audioplayers` or Flutter built-in | Lightweight short sound clips for point confirmation |
| **Haptics** | `HapticFeedback` (Flutter SDK) | Built-in, no extra dependency |
| **Sharing** | `share_plus` | Native OS share sheet for text + screenshot |
| **Screenshot** | `RepaintBoundary` + `dart:ui` | Capture Match Details screen for sharing |

---

## 3. Color Palette (Material Design 3)

Generated via [Material Theme Builder](https://material-foundation.github.io/material-theme-builder/) with primary `#C8E030`.

### Light Mode
| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#C8E030` | Score buttons, server indicator, accent elements |
| On Primary | `#1A2800` | Text/icons on primary-colored surfaces |
| Primary Container | `#EBFFA0` | Scoreboard background, card fills |
| On Primary Container | `#1A2800` | Text on container |
| Secondary | `#5C6146` | Secondary buttons, less prominent UI |
| Surface | `#FDFCF5` | Page backgrounds |
| On Surface | `#1B1C18` | Body text |
| Surface Variant | `#E4E3D3` | Cards, sheets |
| Tertiary | `#3D665F` | Stats, tertiary accents (deep teal) |
| Error | `#BA1A1A` | Validation errors, delete confirmations |
| Outline | `#75786A` | Borders, dividers |

### Dark Mode
| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#CFE945` | Slightly muted for dark backgrounds, score buttons |
| On Primary | `#283600` | Text on primary |
| Primary Container | `#3F4D00` | Scoreboard background |
| On Primary Container | `#EBFFA0` | Text on container |
| Secondary | `#C1C8A5` | Secondary elements |
| Surface | `#13140E` | Page backgrounds (near-black green-tinted) |
| On Surface | `#E4E3D3` | Body text |
| Surface Variant | `#44483D` | Cards, sheets |
| Tertiary | `#82D1C7` | Stats, tertiary accents |
| Error | `#FFB4AB` | Validation errors |
| Outline | `#8E9283` | Borders |

### Court-Inspired Accent Colors
| Name | Hex | Usage |
|------|-----|-------|
| Court Blue | `#2B5797` | Mini court diagram background |
| Court Green | `#4A8C3F` | Court area in diagram |
| Kitchen Zone | `#8B4513` | Non-volley zone line in court diagram |
| Net | `#333333` | Net line divider |

---

## 4. Data Model (Drift / SQLite)

### Tables

```sql
-- Active in-progress match (only one at a time)
CREATE TABLE active_match (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL CHECK(type IN ('singles', 'doubles')),
  scoring_rule TEXT NOT NULL CHECK(scoring_rule IN ('sideout', 'rally')),
  game_count INTEGER NOT NULL DEFAULT 1,  -- 1 or 3 (best of 3)
  created_at TEXT NOT NULL,  -- ISO 8601
  status TEXT NOT NULL DEFAULT 'setup' CHECK(status IN ('setup', 'live', 'paused'))
);

-- Players in the active match
CREATE TABLE active_match_players (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  match_id INTEGER NOT NULL REFERENCES active_match(id),
  name TEXT NOT NULL,
  team TEXT NOT NULL CHECK(team IN ('A', 'B')),
  is_starting_server INTEGER NOT NULL DEFAULT 0,
  position TEXT CHECK(position IN ('left', 'right'))  -- court position during play
);

-- Score events (append-only log, supports unlimited undo via deletion from tail)
CREATE TABLE score_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  match_id INTEGER NOT NULL,
  game_number INTEGER NOT NULL,
  event_type TEXT NOT NULL CHECK(event_type IN ('point', 'sideout', 'side_switch', 'game_end', 'match_end', 'timeout', 'resume')),
  scorer_team TEXT CHECK(scorer_team IN ('A', 'B')),
  server_name TEXT,
  team_a_score INTEGER NOT NULL,
  team_b_score INTEGER NOT NULL,
  server_number INTEGER,  -- 1 or 2 for doubles, NULL for singles
  timestamp TEXT NOT NULL  -- ISO 8601
);

-- Completed matches (archived from active)
CREATE TABLE completed_matches (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL CHECK(type IN ('singles', 'doubles')),
  scoring_rule TEXT NOT NULL CHECK(scoring_rule IN ('sideout', 'rally')),
  game_count INTEGER NOT NULL,
  games_played INTEGER NOT NULL,
  team_a_players TEXT NOT NULL,  -- JSON array of names
  team_b_players TEXT NOT NULL,  -- JSON array of names
  final_scores TEXT NOT NULL,    -- JSON: [{"game":1,"teamA":11,"teamB":7},...]
  winner TEXT NOT NULL CHECK(winner IN ('A', 'B')),
  duration_seconds INTEGER NOT NULL,
  started_at TEXT NOT NULL,
  completed_at TEXT NOT NULL
);

-- Play-by-play log for completed matches (frozen copy of score_events)
CREATE TABLE match_event_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  completed_match_id INTEGER NOT NULL REFERENCES completed_matches(id),
  game_number INTEGER NOT NULL,
  event_type TEXT NOT NULL,
  scorer_team TEXT,
  server_name TEXT,
  team_a_score INTEGER NOT NULL,
  team_b_score INTEGER NOT NULL,
  server_number INTEGER,
  timestamp TEXT NOT NULL
);

-- Recent player names for autocomplete (no persistent profiles)
CREATE TABLE recent_players (
  name TEXT PRIMARY KEY,
  last_used TEXT NOT NULL,  -- ISO 8601
  usage_count INTEGER NOT NULL DEFAULT 1
);

-- App settings (key-value)
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

### Key Design Decisions
- Active match state is in `active_match` + `active_match_players` + `score_events` tables. Survives force-kill.
- On match completion, data is copied to `completed_matches` + `match_event_log` and active tables are cleared.
- `score_events` is append-only in normal play; undo deletes the last event by ID.
- `recent_players` keeps last 20 names by `last_used`, older entries pruned on insert.
- Duration tracked via `started_at` on first point to `completed_at` on match end. No running clock visible during play.

---

## 5. Screen Specifications

### 5.1 Home Screen (`/`)

**Purpose:** Launching pad for all app functions.

**Layout (top to bottom):**
1. **App bar:** "PickleTrack" title, settings gear icon (top-right), theme toggle icon (top-right)
2. **Resume banner** (conditional): If an active match exists, show a prominent banner at top: "⏳ Match in Progress — Tap to Resume" with the match summary (doubles/singles, current score). Tapping goes to Live Match.
3. **Quick Start card:** Large card with pickleball icon. Tapping immediately creates a new doubles match with generic names ("Player A" / "Player B" vs "Player C" / "Player D"), side-out scoring, first to 11. **Before navigating to Live Match**, show a bottom sheet that:
   - Displays the defaults being used
   - Offers "Edit Setup" button (goes to New Match screen, pre-filled)
   - Offers "Start Match" button (proceeds to Live Match)
4. **New Match button:** "New Match" — navigates to New Match Setup screen.
5. **Match History section:** 
   - Search bar (filters by player name as you type)
   - List of completed matches, most recent first
   - Each item shows: date, type icon (1 person or 2 person icon), players, final score
   - Swipe left to reveal red "Delete" button with confirmation dialog
6. **Stats row** (bottom of history section): Simple stats cards — "Matches Played: X", "Win Rate: XX%", "Avg Game Score: X-X"

**Edge cases:**
- Empty state: "No matches yet. Start your first match!" with Quick Start button prominent
- No search results: "No matches found for '[query]'"

---

### 5.2 New Match Setup Screen (`/match/setup`)

**Purpose:** Configure a new match before play begins.

**Layout (top to bottom, scrollable):**
1. **App bar:** "New Match" with back arrow
2. **Match Type selector:** Segmented button — "Singles" | "Doubles" (default: Doubles)
3. **Player Names section:**
   - Team A header with 1 or 2 text fields (based on type)
   - Team B header with 1 or 2 text fields
   - Each field has autocomplete from `recent_players` (dropdown suggestions as you type)
   - Default names if left blank: "Player A1", "Player A2", "Player B1", "Player B2" (shown as placeholder text)
   - Validation: at least one name per team must be non-empty
4. **Starting Server selector:** Chip/radio row showing player names. Default: first player in Team A. Required selection.
5. **Scoring Rule:** Segmented button — "Side-Out" | "Rally" (default: Side-Out)
6. **Games:** Segmented button — "1 Game" | "Best of 3" (default: 1 Game)
7. **Win Condition preset:** Dropdown — "Standard (11, win by 2)" | "Quick (7, win by 2)" | "Tournament (15, win by 2)" | "Custom"
   - If "Custom": two number inputs appear — "Play to:" and "Win by:" with sensible min/max
8. **Start Match button:** Large, primary color, full-width at bottom. Validates form first. On tap, creates active match in DB and navigates to Live Match.

**Validation rules:**
- At least one player name per team (non-empty, non-whitespace)
- Starting server must be selected
- Custom score: play-to between 1–99, win-by between 1–10
- If best of 3 and rally scoring: each game plays to win condition

**Edge cases:**
- If Quick Start was used, this screen is pre-filled with the Quick Start defaults
- Back button discards setup (confirmation if fields were touched)

---

### 5.3 Live Match Screen (`/match/live`)

**Purpose:** The core scoring interface used during active play.

**Layout (portrait, top to bottom):**

1. **Top bar (compact):**
   - Pause icon button (left) → opens pause menu
   - Match info chip: "Singles" or "Doubles" + "Game 1/1" or "Game 1/3"
   - Elapsed time (hidden during play, shown on pause only per user preference)

2. **Court Position Diagram** (doubles only, ~120dp height):
   - Mini top-down court view
   - Court Blue (#2B5797) background with Court Green (#4A8C3F) playing area
   - Kitchen zone line (#8B4513) and net line (#333333)
   - 4 colored dots with player names positioned at L/R on each side
   - Current server's dot pulses/glows with primary color
   - Receiving team dots are muted

3. **Server Indicator** (prominent):
   - Large text: "[Player Name] is Serving"
   - Below: "Server 1 of 2" or "Server 2 of 2" (doubles) — explicitly shows 0-0-2 rule
   - Below that: score callout-style text: "0 – 0 – 1" (doubles) or "0 – 0" (singles)
   - Primary color background, dark text

4. **Scoreboard** (the centerpiece):
   - Two large score cards side by side: Team A | Team B
   - Score numbers: ~72sp font, bold, monospaced
   - Team labels above scores (player names, smaller)
   - The serving team's score card has a glow/border highlight
   - Animated number transitions on point scored

5. **Point Buttons** (large, tappable, bottom half):
   - Two large buttons: "Team A Scores!" and "Team B Scores!"
   - Primary color for the serving team's button (more prominent)
   - Muted/secondary for non-serving team's button (side-out mode — still tappable for side-out events, or hidden in rally mode since any rally scores)
   - In rally scoring mode: both buttons are equal prominence since anyone can score
   - Haptic feedback (light impact) + short "pop" sound on tap
   - Button shows brief success animation (scale pulse) on tap

6. **Bottom action bar:**
   - Undo button (left): reverses last score event. Enabled only when events exist.
   - "End Match" button (right): outlined, prompts confirmation dialog

**Pause Menu** (modal bottom sheet):
- "Resume" button
- "Save & Exit" — saves current state, returns to Home (match appears in resume banner)
- "End Match" — confirms, then completes match

**Doubles Serve Rotation Logic (Side-Out):**
1. Match starts at 0-0-2. Player on right side (Team A) serves first as Server 2 (only one serve before side-out).
2. After side-out → Team B: player on right side serves as Server 1.
3. Server 1 wins points → alternates left/right each point, same player serves.
4. Server 1 loses rally → partner (Server 2) serves from wherever they stand.
5. Server 2 loses rally → side-out to other team.
6. After each game, teams switch ends. First server is the player now on the right side of the team that should serve (based on starting server of game 1 alternation).

**Singles Serve Rotation Logic:**
1. Server serves from right when score is even, left when score is odd.
2. Side-out on lost rally.

**Rally Scoring Logic:**
1. Every rally awards a point (serving or receiving team can score).
2. Server changes: after a point, the team that won the rally serves next.
3. Doubles: server rotation within the team follows the same Server 1→Server 2→side-out pattern, but triggered by losing a rally (not losing the serve).

**End Match Flow:**
- Confirmation dialog: "End this match? Final scores will be saved."
- On confirm: record `completed_at` timestamp, calculate duration, copy to `completed_matches` table, copy `score_events` to `match_event_log`, clear active match tables, navigate to Match Details for the new completed match.

**Edge cases:**
- Win condition met: show "Game! Team [X] wins [score]!" banner. If best of 3 and not yet 2 wins, auto-advance to next game with side switch. If match won, show "Match! Team [X] wins!" and auto-navigate to Match Details.
- Undo at 0-0: blocked (no events to undo)
- Undo past game end: restores previous game state, removes game-end event
- App killed mid-match: on next launch, Home screen shows resume banner. Tapping resume goes directly to Live Match with full state restored.
- Rapid double-tap on point button: debounced (500ms) to prevent double-scoring

---

### 5.4 Match Details Screen (`/match/:id`)

**Purpose:** Read-only view of a completed match with full play-by-play.

**Layout (top to bottom, scrollable):**
1. **App bar:** Back arrow, "Match Details", share icon (top-right)
2. **Result banner:** Large card showing:
   - Winner team highlighted: "Team A Wins!" in primary color
   - Final scores per game: e.g., "Game 1: 11-7", "Game 2: 11-9"
   - Match type badge, scoring rule badge
   - Date and duration (e.g., "June 23, 2026 · 34 min")
3. **Players section:** Team A names | vs | Team B names, with starting server marked
4. **Play-by-Play Log:** Chronological list, scrollable:
   - Each entry: timestamp (relative, e.g., "2:15"), event icon, description
   - Example: "🔵 2:15 — Player A scored! (1-0, Server 1)"
   - Example: "🔄 5:30 — Side out → Team B serving"
   - Example: "🏆 23:45 — Game 1 ends: Team A wins 11-7"
   - Color-coded left border: green for Team A points, blue for Team B points, gray for side-outs/switches
5. **Share button** (floating or bottom): triggers OS share sheet with:
   - Text summary: "🏓 PickleTrack Match\nJune 23, 2026 · 34 min\nTeam A vs Team B\nFinal: 11-7, 11-9\nWinner: Team A"
   - Screenshot of the Match Details screen (via RepaintBoundary)

**Edge cases:**
- Long matches (3 close games): log is scrollable, grouped by game with "Game 1" / "Game 2" headers
- Share fails: silent fallback, no error shown (non-critical feature)

---

### 5.5 Settings Screen (`/settings`)

**Purpose:** App configuration.

**Layout (top to bottom, scrollable):**
1. **App bar:** "Settings" with back arrow
2. **Appearance section:**
   - Theme toggle: "Dark Mode" switch (persisted to `app_settings`)
3. **Scoring Defaults section:**
   - Default scoring rule: "Side-Out" | "Rally" (used for Quick Start)
   - Default win preset: "Standard (11, win by 2)" | "Quick (7, win by 2)" | "Tournament (15, win by 2)" | "Custom"
4. **Sound & Feedback section:**
   - Sound toggle: "Point Sound" switch
   - Haptic toggle: "Haptic Feedback" switch
5. **Data section:**
   - "Clear All Matches" — red text button, confirmation dialog: "Delete all saved matches? This cannot be undone."
   - "Clear Recent Players" — resets autocomplete suggestions
   - "Export All Data" — generates JSON file of all completed matches, shares via OS share sheet
6. **About section:**
   - App version
   - "How to Play" — brief pickleball scoring guide (inline or link)

---

## 6. Navigation & Routing

```
/                          → Home Screen
/match/setup               → New Match Setup
/match/setup?quick=true    → New Match Setup (pre-filled from Quick Start)
/match/live                → Live Match (active match must exist)
/match/:id                 → Match Details (completed match)
/settings                  → Settings
```

- Android back button: pops navigation stack. On Live Match, prompts "Save & Exit?" unless paused.
- iOS swipe-back: same behavior.
- Deep link: none required for v1.

---

## 7. Pickleball Scoring Rules Reference

### Default Rule Set (Standard Side-Out)
- Games played to **11 points**, must **win by 2**
- Only the **serving team** can score points
- **Doubles start at 0-0-2** (second server starts, so Team A only gets one server before first side-out)
- **Singles:** server position determined by score (even=right, odd=left)
- **Doubles rotation:** Server 1 serves until losing a rally → Server 2 serves until losing a rally → side-out
- **Side switch:** Teams switch ends after each game. In a deciding game (game 3 of best-of-3), switch when leading team reaches 6.

### Rally Scoring (Optional)
- Every rally awards a point to the winner
- Server changes on every rally loss (side-out on lost rally)
- Doubles server rotation within team: Server 1 → Server 2 on each lost rally, side-out after Server 2 loses

### Presets
| Name | Play To | Win By |
|------|---------|--------|
| Quick | 7 | 2 |
| Standard | 11 | 2 |
| Tournament | 15 | 2 |
| Custom | User-set | User-set |

---

## 8. File & Component Structure

```
pickletrack/
├── lib/
│   ├── main.dart                          # App entry, theme setup, Riverpod scope
│   ├── app.dart                           # MaterialApp.router configuration
│   ├── router.dart                        # go_router route definitions
│   │
│   ├── theme/
│   │   ├── app_theme.dart                 # Light + dark ThemeData (M3 tokens)
│   │   └── colors.dart                    # Color constants (primary, court, etc.)
│   │
│   ├── database/
│   │   ├── database.dart                  # Drift database definition
│   │   ├── tables.dart                    # Table definitions
│   │   └── database.g.dart                # Generated Drift code
│   │
│   ├── models/
│   │   ├── match.dart                     # Freezed match model
│   │   ├── score_event.dart               # Freezed score event model
│   │   └── scoring_preset.dart            # Scoring preset enum + config
│   │
│   ├── providers/
│   │   ├── database_provider.dart         # Drift database provider
│   │   ├── active_match_provider.dart     # Active match state + notifier
│   │   ├── match_history_provider.dart    # Completed matches + search
│   │   ├── recent_players_provider.dart   # Recent player names
│   │   └── settings_provider.dart         # App settings
│   │
│   ├── services/
│   │   ├── scoring_service.dart           # Pure scoring logic (unit-testable)
│   │   ├── sound_service.dart             # Sound playback
│   │   └── share_service.dart             # Text + screenshot sharing
│   │
│   ├── screens/
│   │   ├── home/
│   │   │   ├── home_screen.dart           # Home screen widget
│   │   │   ├── match_history_list.dart    # Match history listview
│   │   │   ├── stats_cards.dart           # Stats summary cards
│   │   │   └── resume_banner.dart         # In-progress match banner
│   │   │
│   │   ├── setup/
│   │   │   ├── setup_screen.dart          # New match setup screen
│   │   │   ├── player_name_field.dart     # Autocomplete name field
│   │   │   └── scoring_preset_picker.dart # Win condition selector
│   │   │
│   │   ├── live/
│   │   │   ├── live_match_screen.dart     # Live match screen
│   │   │   ├── scoreboard.dart            # Score cards
│   │   │   ├── server_indicator.dart      # Server info display
│   │   │   ├── court_diagram.dart         # Mini court diagram (doubles)
│   │   │   ├── point_buttons.dart         # Team A/B point buttons
│   │   │   ├── pause_menu.dart            # Pause bottom sheet
│   │   │   └── game_end_banner.dart       # Game/match win overlay
│   │   │
│   │   ├── details/
│   │   │   ├── match_details_screen.dart  # Read-only match view
│   │   │   └── play_by_play_log.dart      # Event log list
│   │   │
│   │   └── settings/
│   │       └── settings_screen.dart       # Settings screen
│   │
│   └── widgets/
│       ├── confirm_dialog.dart            # Reusable confirmation dialog
│       └── empty_state.dart               # Empty state placeholder
│
├── assets/
│   ├── sounds/
│   │   └── point_scored.wav              # Short pop sound (CC0 licensed)
│   └── icons/
│       └── pickleball.svg                # App icon source
│
├── test/
│   ├── scoring_service_test.dart         # Scoring logic unit tests
│   └── integration/
│       └── full_match_test.dart          # Create + complete match + verify storage
│
├── README.md                             # Run instructions, architecture, QA checklist
├── pubspec.yaml                          # Dependencies
└── pickletrack-spec.md                   # This file
```

---

## 9. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  drift: ^2.21.0          # SQLite ORM
  sqlite3_flutter_libs: ^0.5.0
  riverpod: ^2.5.0        # State management
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0      # Navigation
  share_plus: ^10.0.0     # OS share sheet
  path_provider: ^2.1.0   # App data directory
  path: ^1.9.0             # Path utilities
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  intl: ^0.19.0            # Date formatting

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.21.0       # Drift code generator
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  flutter_lints: ^5.0.0
  mocktail: ^1.0.0         # Mocking for tests
```

---

## 10. Testing Strategy

### Unit Tests (`test/scoring_service_test.dart`)
- Side-out singles: server scores, side-out on loss, win condition (11, win by 2)
- Side-out doubles: 0-0-2 start, server 1→2 rotation, side switch
- Rally scoring: both teams score, server changes on rally loss
- Win by 2: game continues past 11 until 2-point gap
- Best of 3: game 1, game 2, game 3 logic, match win detection
- Undo: single undo, multiple undo, undo past game boundary
- Custom presets: play-to and win-by edge cases

### Integration Test (`test/integration/full_match_test.dart`)
- Create a doubles match via setup
- Simulate point scoring to completion (11-7)
- Verify completed match stored in DB
- Verify play-by-play log accuracy
- Verify resume functionality after simulated kill

### Manual QA Checklist (in README)
- Install on iOS simulator + Android emulator
- Quick Start flow → edit → start match
- Full singles match play-through
- Full doubles match with serve rotation (verify 0-0-2)
- Pause → Save & Exit → Resume from Home
- Force-kill app mid-match → relaunch → verify resume
- Undo multiple points, verify score reverts
- Swipe-to-delete match from history
- Dark mode toggle (verify all screens)
- Share match details (text + screenshot)
- Best of 3 match with side switch between games
- Rally scoring mode play-through
- Custom win condition (e.g., play to 5, win by 1)
- Sound + haptic toggle on/off
- Clear all data from Settings

---

## 11. Defaults & Sensible Choices Log

| Decision | Default | Rationale |
|----------|---------|-----------|
| Match type | Doubles | Most common recreational format |
| Scoring rule | Side-Out | Official pickleball standard |
| Win condition | 11, win by 2 | USA Pickleball standard |
| Doubles start | 0-0-2 | Official rule (only one server before first side-out) |
| Starting server | Player A1 (Team A, first player) | Simple default |
| Generic names | Player A1, A2, B1, B2 | Clear, neutral, easy to understand |
| Games per match | 1 game | Simpler default; best of 3 is configurable |
| Theme | System default (light) | Respects device setting |
| Sound | On by default | Confirmation during play is helpful |
| Haptic | On by default | Subtle feedback without being intrusive |
| Recent players limit | 20 names | Balances usefulness with privacy |
| Undo debounce | 500ms | Prevents accidental double-taps |

---

## 12. Open Questions / Future Considerations

- **Rally scoring serve rotation:** For doubles rally scoring, the exact USA Pickleball rally scoring server rotation rules are still provisional. The implementation will follow the most common recreational interpretation: rally winner serves, within-team rotation follows Server 1→2→side-out.
- **iPad/tablet layout:** Explicitly deferred to future version. Phone portrait only for v1.
- **Localization:** English only for v1. Widget structure will use Flutter's `Localizations` pattern for future i18n.
- **Watch companion:** Out of scope for v1.
- **Live activity / dynamic island:** Out of scope for v1.
- **Tournament/bracket mode:** Out of scope for v1.

---

*Specification complete. Ready for implementation.*

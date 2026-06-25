# Court Diagram — Design Document

> **Component:** `CourtDiagram` widget for Live Match screen  
> **Last Updated:** June 23, 2026

---

## Summary of Research

### Key Decisions (backed by Flutter best practices + sports UX research)

| Decision | Choice | Why |
|----------|--------|-----|
| **Orientation** | Traditional top-down (net horizontal) | Users expect this view; compressed but recognizable |
| **Aspect ratio** | ~1:1.6 (compressed from 1:2.2 real court) | Fits portrait phone; still looks like a court |
| **Kitchen zones** | Preserve 32% length proportion | Anchors the diagram as "pickleball" |
| **Player dots** | Centered in service boxes | Maps to L/R serving positions naturally |
| **Server glow** | Expanding/contracting ring (radar pulse) | Clear, doesn't muddy contrast with court colors |
| **Lines** | Include center service line; omit sideline extensions | Clean, uncluttered; center line is essential for L/R positions |
| **Rendering** | Two-layer CustomPainter (static court + animated players) | Perf: static court never repaints; only player positions animate |

### Research Sources
- Flutter CustomPainter API reference + Very Good Ventures "Mastering CustomPainter" guide
- Plugfox "High-Performance Canvas Rendering" best practices
- USA Pickleball official court dimensions (20' x 44', 7' kitchen)
- Wikimedia Commons CC0 pickleball court diagram reference
- Analyzed: ESPN, theScore, tennis/pickleball tracker apps for court visualization patterns

---

## Visual Design

### Component Dimensions

```
┌────────────────── 360dp (phone width) ──────────────────┐
│                                                          │
│   ┌────────────────── 328dp court area ──────────────┐   │
│   │   Background: Court Blue (#2B5797)                │   │
│   │   ┌──────────── 300dp playing surface ────────┐   │   │
│   │   │  Surface: Court Green (#4A8C3F)            │   │   │
│   │   │                                            │   │   │
│   │   │  ═══ Baseline (2dp, white 70% opacity)     │   │   │  ← top
│   │   │                                            │   │   │
│   │   │     Service Box TL    Service Box TR       │   │   │
│   │   │         ●                   ●              │   │   │  ← 12dp dots
│   │   │     "Player A1"        "Player A2"         │   │   │  ← 11sp labels
│   │   │                                            │   │   │
│   │   │  ─── Kitchen Line (1.5dp, #8B4513) ───     │   │   │  ← 29dp from net
│   │   │  │         Kitchen Zone           │        │   │   │  ← subtle fill
│   │   │  ════════ NET (4dp, #333333) ════════      │   │   │  ← center
│   │   │  │         Kitchen Zone           │        │   │   │
│   │   │  ─── Kitchen Line (1.5dp, #8B4513) ───     │   │   │  ← 29dp from net
│   │   │                                            │   │   │
│   │   │     Service Box BL    Service Box BR       │   │   │
│   │   │         ●                   ●              │   │   │
│   │   │     "Player B1"        "Player B2"         │   │   │
│   │   │                                            │   │   │
│   │   │  ═══ Baseline (2dp, white 70% opacity)     │   │   │  ← bottom
│   │   │                                            │   │   │
│   │   │  ┊  Center Service Line (1dp, white 50%) ┊  │   │   │  ← vertical
│   │   └────────────────────────────────────────────┘   │   │
│   │   Team A                          Team B           │   │  ← team labels
│   └────────────────────────────────────────────────────┘   │
│                                                          │
│  Total component height: ~180dp                           │
└──────────────────────────────────────────────────────────┘
```

### Exact Measurements

| Element | Size/Position | Notes |
|---------|--------------|-------|
| Component total height | ~180dp | Fits between server indicator and scoreboard |
| Court background (blue) | 328dp × 160dp | 16dp padding from screen edges |
| Playing surface (green) | 300dp × 148dp | 6dp inset from blue background |
| Net line | 4dp thick, centered horizontally | #333333, solid |
| Kitchen zone height | 29dp each side of net | ~32% of half-court length (preserves real proportion) |
| Kitchen zone fill | Subtle brown tint at 8% opacity | Hint of the kitchen zone without clutter |
| Kitchen line | 1.5dp thick, #8B4513 | Solid line marking NVZ boundary |
| Baselines | 2dp thick, white at 70% opacity | Top and bottom edges of playing surface |
| Sidelines | 2dp thick, white at 70% opacity | Left and right edges of playing surface |
| Center service line | 1dp, white at 50% opacity | Vertical, from kitchen line to baseline on each side |
| Player dot radius | 12dp | On-screen ~24dp circle (tappable-size visual) |
| Player dot Y position | Centered in service box | ~midpoint between baseline and kitchen line |
| Player dot X position | Left/right quarter points of court width | Centered in each service box horizontally |
| Name label font | 11sp, white, semi-bold | One line, 80dp max width, ellipsis overflow |
| Team labels | 10sp, white at 80% opacity | Below court (Team A left, Team B right) |

### Dark Mode Adjustments
All colors remain the same — the court diagram is its own self-contained visual with a dark blue surround (#2B5797), so it works identically in light and dark modes. In dark mode, the court's blue background blends more naturally with the dark surface.

### Singles Mode
In singles mode, only 2 player dots (Team A bottom service box center, Team B top service box center — from each team's perspective, the player is centered in their half). No center service line needed.

---

## Server Glow Animation

### Design: Expanding/Contracting Ring ("Radar Pulse")

```
Frame 0 (idle):         Frame 0.5 (mid-pulse):    Frame 1.0 (end):
     ●                       ○                       ○  (fading)
  (solid dot)           (ring at 1.5x radius)    (ring at 2x radius, 0% opacity)
```

- **Ring properties:** Stroke width 2dp, primary color (#C8E030), starts at dot edge
- **Animation:** 1.5 second loop
  - 0.0s → 0.3s: Expand ring from radius 12dp to 28dp, opacity 100% → 0%
  - 0.3s → 0.5s: Pause (ring invisible)
  - 0.5s → 0.8s: Expand ring from 12dp to 28dp, opacity 100% → 0%
  - 0.8s → 1.5s: Pause
- **Implementation:** `AnimationController` with `repeat()`, `CurvedAnimation` for easing
- **Server dot itself:** Primary color (#C8E030) with subtle drop shadow
- **Non-server dots:** White (#FFFFFF) at 70% opacity, no glow

### Why Radar Pulse over Radial Gradient Glow
The thinker analysis confirmed: a pulsing radial gradient behind a dot muddies contrast with the green court background and player name text. The clean expanding ring draws the eye immediately without degrading readability. This is the pattern used by professional sports broadcast graphics.

---

## CustomPainter Architecture (Two-Layer)

### Layer 1: `CourtSurfacePainter` (Static — never repaints)

```dart
class CourtSurfacePainter extends CustomPainter {
  // No repaint listener needed — static court
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw order: background → surface → kitchen tint → lines → labels
    _drawBackground(canvas, size);      // Court Blue rect
    _drawPlayingSurface(canvas, size);  // Court Green rect
    _drawKitchenZones(canvas, size);    // Subtle tint + brown lines
    _drawNetLine(canvas, size);         // Dark center line
    _drawCourtLines(canvas, size);      // Baselines, sidelines, center service line
    _drawTeamLabels(canvas, size);      // "Team A" / "Team B" text
  }
  
  @override
  bool shouldRepaint(CourtSurfacePainter oldDelegate) => false;
}
```

### Layer 2: `PlayerPositionPainter` (Animated — repaints on state change)

```dart
class PlayerPositionPainter extends CustomPainter {
  final List<PlayerPosition> players;
  final String? servingPlayerId;
  final Animation<double> serverGlowAnimation;
  
  PlayerPositionPainter({
    required this.players,
    required this.servingPlayerId,
    required Listenable serverGlowAnimation,
  }) : super(repaint: serverGlowAnimation);
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final player in players) {
      final isServer = player.id == servingPlayerId;
      _drawPlayerDot(canvas, player.position, isServer);
      
      if (isServer) {
        _drawServerGlowRing(canvas, player.position, serverGlowAnimation.value);
      }
      
      _drawPlayerName(canvas, player.position, player.name, isServer);
    }
  }
  
  @override
  bool shouldRepaint(PlayerPositionPainter oldDelegate) {
    return players != oldDelegate.players || 
           servingPlayerId != oldDelegate.servingPlayerId;
  }
}
```

### Widget Composition

```dart
class CourtDiagram extends StatefulWidget {
  final List<PlayerPosition> players;
  final String? servingPlayerId;
  final MatchType matchType; // singles | doubles
  
  // ...
}

class _CourtDiagramState extends State<CourtDiagram>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  
  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          // Layer 1: Static court — wrapped in RepaintBoundary
          RepaintBoundary(
            child: CustomPaint(
              painter: CourtSurfacePainter(),
              size: Size.infinite,
            ),
          ),
          // Layer 2: Animated player dots
          CustomPaint(
            painter: PlayerPositionPainter(
              players: widget.players,
              servingPlayerId: widget.servingPlayerId,
              serverGlowAnimation: _glowController,
            ),
            size: Size.infinite,
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }
}
```

---

## Coordinate Calculations (Dart pseudocode)

```dart
// All positions are calculated relative to the canvas Size
// to ensure responsive layout on any screen width.

class CourtMetrics {
  final double canvasWidth;
  final double canvasHeight;
  
  // Court bounds (playing surface, inset from background)
  static const double courtInsetX = 14.0; // from canvas edge to blue bg
  static const double courtInsetY = 10.0;
  static const double surfaceInsetFromBg = 6.0; // green surface inset from blue bg
  
  // The full court background rectangle
  Rect get backgroundRect => Rect.fromLTWH(
    courtInsetX, courtInsetY,
    canvasWidth - courtInsetX * 2,
    canvasHeight - courtInsetY * 2,
  );
  
  // The green playing surface
  Rect get surfaceRect => Rect.fromLTWH(
    courtInsetX + surfaceInsetFromBg,
    courtInsetY + surfaceInsetFromBg,
    canvasWidth - (courtInsetX + surfaceInsetFromBg) * 2,
    canvasHeight - (courtInsetY + surfaceInsetFromBg) * 2,
  );
  
  // Net Y position (center of playing surface)
  double get netY => surfaceRect.center.dy;
  
  // Kitchen line distance from net (preserving 32% proportion)
  double get kitchenOffset {
    final halfCourtHeight = surfaceRect.height / 2;
    return halfCourtHeight * 0.32; // 32% of half-court = kitchen zone
  }
  
  // Kitchen lines (above and below net)
  double get kitchenLineTop => netY - kitchenOffset;
  double get kitchenLineBottom => netY + kitchenOffset;
  
  // Player dot positions (centered in service boxes)
  Offset playerDotPosition({required String team, required String side}) {
    final quarterX = surfaceRect.width / 4;
    final leftX = surfaceRect.left + quarterX;
    final rightX = surfaceRect.right - quarterX;
    final x = side == 'left' ? leftX : rightX;
    
    final baselineToKitchen = kitchenOffset; // from baseline to kitchen line
    final serviceBoxCenter = baselineToKitchen / 2;
    
    final y = team == 'A'
        ? netY - kitchenOffset - serviceBoxCenter  // top service box center
        : netY + kitchenOffset + serviceBoxCenter; // bottom service box center
    
    return Offset(x, y);
  }
  
  // For singles: player centered in full half-court
  Offset singlesPlayerPosition({required String team}) {
    final x = surfaceRect.center.dx;
    final halfCourtCenter = (surfaceRect.height / 2 - kitchenOffset) / 2;
    final y = team == 'A'
        ? netY - kitchenOffset - halfCourtCenter
        : netY + kitchenOffset + halfCourtCenter;
    return Offset(x, y);
  }
}
```

---

## Player Dot Drawing

```dart
void _drawPlayerDot(Canvas canvas, Offset position, bool isServer) {
  final dotPaint = Paint()
    ..color = isServer 
        ? const Color(0xFFC8E030) // Primary
        : Colors.white.withOpacity(0.7)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2); // soft shadow
  
  canvas.drawCircle(position, 12.0, dotPaint);
  
  // Inner highlight (smaller white circle for 3D effect)
  if (isServer) {
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(position.dx - 2, position.dy - 2), 5.0, highlightPaint);
  }
}

void _drawServerGlowRing(Canvas canvas, Offset position, double animValue) {
  // animValue 0..1 cycles: 0→0.3 expand, 0.5→0.8 expand
  final ringProgress = _getRingProgress(animValue); // 0..1 expansion
  
  final ringRadius = 12.0 + (16.0 * ringProgress); // 12dp → 28dp
  final ringOpacity = 1.0 - ringProgress;           // 1.0 → 0.0
  
  final ringPaint = Paint()
    ..color = const Color(0xFFC8E030).withOpacity(ringOpacity)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  
  canvas.drawCircle(position, ringRadius, ringPaint);
}
```

---

## State Integration

The `CourtDiagram` widget receives data from the Riverpod `activeMatchProvider`:

```dart
// In Live Match Screen:
final activeMatch = ref.watch(activeMatchProvider);

if (activeMatch.type == MatchType.doubles) {
  CourtDiagram(
    matchType: MatchType.doubles,
    players: [
      PlayerPosition(
        id: activeMatch.teamAPlayer1.id,
        name: activeMatch.teamAPlayer1.name,
        team: 'A',
        side: activeMatch.teamAPlayer1.courtSide, // 'left' or 'right'
      ),
      // ... 3 more players
    ],
    servingPlayerId: activeMatch.currentServer.id,
  );
}
```

The `activeMatchProvider` manages:
- Player court positions (updated on point scored → server alternates sides, side-out → new server)
- Current server ID
- Match type

---

## Edge Cases & States

| State | Behavior |
|-------|----------|
| **Singles mode** | 2 dots (one per team), centered, no center service line |
| **Doubles mode** | 4 dots in service boxes, center line shown |
| **Side-out (new server)** | Server glow transitions to new player's dot; animation continues seamlessly |
| **Point scored (same server)** | Server's L/R position swaps; dot animates to new position (implicitly via TweenAnimationBuilder or AnimatedPositioned in widget layer) |
| **Game end / match end** | Court diagram still visible; no server glow (no active server) |
| **Paused state** | Animation pauses (`_glowController.stop()`) to conserve battery |
| **Very long player names** | Truncated with ellipsis at 80dp max width per label |

---

## Performance Notes

1. **RepaintBoundary on static layer** — the court surface never repaints after initial render
2. **AnimationController paused when not visible** — `_glowController.stop()` when screen is not in foreground (via `WidgetsBindingObserver`)
3. **`shouldRepaint` is strict** — only returns true when player positions or server actually change
4. **No `saveLayer` calls** — avoids expensive offscreen buffer allocation
5. **`MaskFilter` used sparingly** — only on player dots (2 per render), not on court lines
6. **All coordinates pre-computed** — the `CourtMetrics` class calculates once; painters just draw

---

## Open-Source Asset Usage

No external SVG assets needed. The entire court is drawn procedurally via `CustomPainter`. This:
- Guarantees zero licensing concerns
- Ensures pixel-perfect rendering at all screen densities
- Allows full control over colors to match the M3 theme palette
- Eliminates asset bundle size for court graphics

If a pickleball-specific icon is needed for the app icon or Home screen, the [Wikimedia Commons CC0 pickleball court diagram](https://commons.wikimedia.org/wiki/File:Pickleballcourt.PNG) can be referenced as a proportions guide, but is not bundled in the app.

---

*Design complete. Ready for implementation in `lib/screens/live/court_diagram.dart`.*

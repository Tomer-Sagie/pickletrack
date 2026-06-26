import 'package:flutter/material.dart';

/// Player position data for the court diagram.
class PlayerPosition {
  final String id;
  final String name;
  final String team; // 'A' or 'B'
  final String side; // 'left' or 'right'

  const PlayerPosition({
    required this.id,
    required this.name,
    required this.team,
    required this.side,
  });
}

/// Vertical pickleball court diagram with player positions.
///
/// The court is drawn top-to-bottom: Team A at the top, Team B at the
/// bottom, net running horizontally through the center. This matches
/// the real court's proportions better than the old compressed
/// horizontal layout.
///
/// Two-layer CustomPainter: the static court surface is wrapped in a
/// [RepaintBoundary] and never repaints. Player dots repaint only when
/// the server or positions change. The server glow is a simple colored
/// ring — no repeating animation on web to avoid jank.
class CourtDiagram extends StatelessWidget {
  final List<PlayerPosition> players;
  final String? servingPlayerId;
  final bool isDoubles;

  const CourtDiagram({
    super.key,
    required this.players,
    this.servingPlayerId,
    this.isDoubles = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Use a LayoutBuilder so the painters get the real available width.
    // Height is fixed at 240dp — tall enough for readable dots but
    // compact enough to leave room for the scoreboard and buttons.
    return SizedBox(
      height: 240,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Layer 1: Static court surface — only repaints on
              // brightness or isDoubles change
              RepaintBoundary(
                child: CustomPaint(
                  painter: _CourtSurfacePainter(
                    isDoubles: isDoubles,
                    brightness: brightness,
                  ),
                  size: Size(constraints.maxWidth, 240),
                ),
              ),
              // Layer 2: Player dots — only repaints on state change
              CustomPaint(
                painter: _PlayerPositionPainter(
                  players: players,
                  servingPlayerId: servingPlayerId,
                  isDoubles: isDoubles,
                  brightness: brightness,
                ),
                size: Size(constraints.maxWidth, 240),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Layer 1: Static Court Surface ──

class _CourtSurfacePainter extends CustomPainter {
  final bool isDoubles;
  final Brightness brightness;

  const _CourtSurfacePainter({this.isDoubles = true, required this.brightness});

  @override
  void paint(Canvas canvas, Size size) {
    final m = _Metrics(size, isDoubles: isDoubles);
    final c = _CourtColors.of(brightness);

    // Outer background
    canvas.drawRRect(m.bgRect, Paint()..color = c.surround);

    // Playing surface
    canvas.drawRRect(m.surfaceRect, Paint()..color = c.surface);

    // Kitchen tint
    final kitchenPaint = Paint()..color = c.kitchenTint;
    canvas.drawRect(m.kitchenTopRect, kitchenPaint);
    canvas.drawRect(m.kitchenBottomRect, kitchenPaint);

    // Court lines
    final linePaint = Paint()
      ..color = c.courtLine
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final sr = m.surfaceRect.outerRect;

    // Sidelines
    canvas.drawLine(sr.topLeft, sr.bottomLeft, linePaint);
    canvas.drawLine(sr.topRight, sr.bottomRight, linePaint);

    // Baselines
    canvas.drawLine(sr.topLeft, sr.topRight, linePaint);
    canvas.drawLine(sr.bottomLeft, sr.bottomRight, linePaint);

    // Kitchen lines
    final kitchenLinePaint = Paint()
      ..color = c.kitchenLine
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(m.kitchenTopLeft, m.kitchenTopRight, kitchenLinePaint);
    canvas.drawLine(m.kitchenBottomLeft, m.kitchenBottomRight, kitchenLinePaint);

    // Net
    final netPaint = Paint()
      ..color = c.net
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(m.netLeft, m.netRight, netPaint);

    // Center line (doubles only)
    if (isDoubles) {
      final centerPaint = Paint()
        ..color = c.centerLine
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final cx = m.surfaceRect.center.dx;
      // Top half
      canvas.drawLine(
        Offset(cx, m.surfaceRect.top),
        Offset(cx, m.kitchenTopRect.bottom),
        centerPaint,
      );
      // Bottom half
      canvas.drawLine(
        Offset(cx, m.kitchenBottomRect.top),
        Offset(cx, m.surfaceRect.bottom),
        centerPaint,
      );
    }

    // Team labels
    _label(canvas, 'TEAM A', m.teamALabelPos, 10, c.teamLabel);
    _label(canvas, 'TEAM B', m.teamBLabelPos, 10, c.teamLabel);
  }

  void _label(Canvas canvas, String text, Offset pos, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_CourtSurfacePainter oldDelegate) =>
      isDoubles != oldDelegate.isDoubles || brightness != oldDelegate.brightness;
}

// ── Layer 2: Player Dots ──

class _PlayerPositionPainter extends CustomPainter {
  final List<PlayerPosition> players;
  final String? servingPlayerId;
  final bool isDoubles;
  final Brightness brightness;

  const _PlayerPositionPainter({
    required this.players,
    this.servingPlayerId,
    this.isDoubles = true,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final m = _Metrics(size, isDoubles: isDoubles);
    final c = _CourtColors.of(brightness);

    for (final player in players) {
      final isServer = player.id == servingPlayerId;
      final pos = m.playerDot(player.team, player.side);

      // ── Shadow circle (below the dot, offset slightly) ──
      final shadowPaint = Paint()
        ..color = c.dotShadow
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(pos.dx + 1.5, pos.dy + 1.5), 10, shadowPaint);

      // ── Main dot ──
      final dotColor = isServer ? c.serverDot : c.playerDot(player.team);
      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 10, dotPaint);

      // ── Server ring ──
      if (isServer) {
        final ringPaint = Paint()
          ..color = c.serverRing
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(pos, 15, ringPaint);
      }

      // ── Name label with background pill ──
      final displayName = player.name.length > 10
          ? '${player.name.substring(0, 9)}\u2026'
          : player.name;
      final labelColor = isServer ? c.serverDot : c.nameLabel;

      final tp = TextPainter(
        text: TextSpan(
          text: displayName,
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            fontWeight: isServer ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 72);

      // Background pill behind the name
      if (displayName.isNotEmpty) {
        final pillRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(pos.dx, pos.dy + 20),
            width: tp.width + 12,
            height: tp.height + 6,
          ),
          const Radius.circular(8),
        );
        canvas.drawRRect(pillRect, Paint()..color = c.namePill);
      }

      // Paint the name text
      tp.paint(
        canvas,
        Offset(pos.dx - tp.width / 2, pos.dy + 20 - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_PlayerPositionPainter oldDelegate) {
    if (brightness != oldDelegate.brightness) return true;
    if (isDoubles != oldDelegate.isDoubles) return true;
    if (players.length != oldDelegate.players.length) return true;
    if (servingPlayerId != oldDelegate.servingPlayerId) return true;
    for (var i = 0; i < players.length; i++) {
      if (players[i].id != oldDelegate.players[i].id ||
          players[i].side != oldDelegate.players[i].side) {
        return true;
      }
    }
    return false;
  }
}

// ── Coordinate Calculator ──

class _Metrics {
  final Size size;
  final bool isDoubles;

  _Metrics(this.size, {required this.isDoubles});

  // ── Background (blue surround) ──
  static const _insetX = 12.0;
  static const _insetY = 6.0;
  static const _surfaceInset = 5.0;

  RRect get bgRect => RRect.fromRectAndRadius(
        Rect.fromLTWH(_insetX, _insetY,
            size.width - _insetX * 2, size.height - _insetY * 2),
        const Radius.circular(6),
      );

  // ── Playing surface (green) ──
  RRect get surfaceRect => RRect.fromRectAndRadius(
        Rect.fromLTWH(
          _insetX + _surfaceInset,
          _insetY + _surfaceInset,
          size.width - (_insetX + _surfaceInset) * 2,
          size.height - (_insetY + _surfaceInset) * 2,
        ),
        const Radius.circular(4),
      );

  // ── Net (horizontal, centered) ──
  Offset get netLeft =>
      Offset(surfaceRect.left, surfaceRect.center.dy);
  Offset get netRight =>
      Offset(surfaceRect.right, surfaceRect.center.dy);

  // ── Kitchen (preserves ~32% of half-court) ──
  double get _halfHeight => surfaceRect.height / 2;
  double get _kitchenOffset => _halfHeight * 0.30;

  Rect get kitchenTopRect => Rect.fromLTRB(
        surfaceRect.left,
        surfaceRect.center.dy - _kitchenOffset,
        surfaceRect.right,
        surfaceRect.center.dy,
      );

  Rect get kitchenBottomRect => Rect.fromLTRB(
        surfaceRect.left,
        surfaceRect.center.dy,
        surfaceRect.right,
        surfaceRect.center.dy + _kitchenOffset,
      );

  Offset get kitchenTopLeft =>
      Offset(surfaceRect.left, kitchenTopRect.top);
  Offset get kitchenTopRight =>
      Offset(surfaceRect.right, kitchenTopRect.top);
  Offset get kitchenBottomLeft =>
      Offset(surfaceRect.left, kitchenBottomRect.bottom);
  Offset get kitchenBottomRight =>
      Offset(surfaceRect.right, kitchenBottomRect.bottom);

  // ── Player dot positions ──
  Offset playerDot(String team, String side) {
    final double x;
    if (isDoubles) {
      final q = surfaceRect.width / 4;
      final leftX = surfaceRect.left + q;
      final rightX = surfaceRect.right - q;
      x = side == 'left' ? leftX : rightX;
    } else {
      x = surfaceRect.center.dx;
    }

    // Y: centered between baseline and kitchen line
    final topBoxCenter =
        (surfaceRect.top + kitchenTopRect.top) / 2;
    final bottomBoxCenter =
        (surfaceRect.bottom + kitchenBottomRect.bottom) / 2;

    return Offset(x, team == 'A' ? topBoxCenter : bottomBoxCenter);
  }

  // ── Team labels ──
  Offset get teamALabelPos =>
      Offset(bgRect.center.dx, bgRect.top - 2);
  Offset get teamBLabelPos =>
      Offset(bgRect.center.dx, bgRect.bottom + 2);
}

// ── Theme-aware Court Colors ──

/// Light and dark variants for every color used on the court diagram.
/// The court surface colours are toned down in dark mode so the bright
/// green/blue doesn't clash with the dark UI, while remaining
/// recognisable as a pickleball court.
class _CourtColors {
  final Color surround;
  final Color surface;
  final Color kitchenTint;
  final Color kitchenLine;
  final Color courtLine;
  final Color centerLine;
  final Color net;
  final Color teamLabel;
  final Color dotShadow;
  final Color serverDot;
  final Color serverRing;
  final Color nameLabel;
  final Color namePill;

  const _CourtColors._({
    required this.surround,
    required this.surface,
    required this.kitchenTint,
    required this.kitchenLine,
    required this.courtLine,
    required this.centerLine,
    required this.net,
    required this.teamLabel,
    required this.dotShadow,
    required this.serverDot,
    required this.serverRing,
    required this.nameLabel,
    required this.namePill,
  });

  factory _CourtColors.of(Brightness brightness) {
    return brightness == Brightness.dark ? _dark : _light;
  }

  Color playerDot(String team) {
    if (team == 'A' || team == 'B') {
      return Colors.white.withValues(alpha: 0.85);
    }
    return Colors.white.withValues(alpha: 0.6);
  }

  // ── Light mode (current look) ──

  static const _light = _CourtColors._(
    surround: Color(0xFF2B5797),
    surface: Color(0xFF4A8C3F),
    kitchenTint: Color(0x148B4513), // 0xFF8B4513 @ 8%
    kitchenLine: Color(0xFF8B4513),
    courtLine: Color(0xCCFFFFFF), // white @ 80%
    centerLine: Color(0x73FFFFFF), // white @ 45%
    net: Color(0xFF444444),
    teamLabel: Color(0xB3FFFFFF), // white @ 70%
    dotShadow: Color(0x30000000),
    serverDot: Color(0xFFC8E030),
    serverRing: Color(0x80C8E030), // primary @ 50%
    nameLabel: Color(0xE6FFFFFF), // white @ 90%
    namePill: Color(0x60000000),
  );

  // ── Dark mode (muted, deeper tones) ──

  static const _dark = _CourtColors._(
    surround: Color(0xFF1A3058),
    surface: Color(0xFF2A4F22),
    kitchenTint: Color(0x1F5C2E0A), // 0xFF5C2E0A @ 12%
    kitchenLine: Color(0xFF5C2E0A),
    courtLine: Color(0x8CFFFFFF), // white @ 55%
    centerLine: Color(0x59FFFFFF), // white @ 35%
    net: Color(0xFF5A5A5A),
    teamLabel: Color(0x8CFFFFFF), // white @ 55%
    dotShadow: Color(0x40000000),
    serverDot: Color(0xFFC8E030),
    serverRing: Color(0x80C8E030), // primary @ 50%
    nameLabel: Color(0xCCFFFFFF), // white @ 80%
    namePill: Color(0x80000000),
  );
}

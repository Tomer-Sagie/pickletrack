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

/// Vertical pickleball court diagram with clean player markers.
///
/// The court is drawn top-to-bottom: Team A at the top, Team B at the
/// bottom, net running horizontally through the center.
///
/// Uses nested CustomPaint with a SizedBox.expand() fill child instead
/// of LayoutBuilder+Stack to avoid layout-cycle-prone patterns.
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
    return SizedBox(
      height: 240,
      child: CustomPaint(
        painter: _CourtSurfacePainter(
          isDoubles: isDoubles,
          brightness: brightness,
        ),
        child: CustomPaint(
          painter: _PlayerPositionPainter(
            players: players,
            servingPlayerId: servingPlayerId,
            isDoubles: isDoubles,
            brightness: brightness,
          ),
          child: const SizedBox.expand(),
        ),
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
    canvas.drawLine(
        m.kitchenBottomLeft, m.kitchenBottomRight, kitchenLinePaint);

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
      canvas.drawLine(
        Offset(cx, m.surfaceRect.top),
        Offset(cx, m.kitchenTopRect.bottom),
        centerPaint,
      );
      canvas.drawLine(
        Offset(cx, m.kitchenBottomRect.top),
        Offset(cx, m.surfaceRect.bottom),
        centerPaint,
      );
    }

    // Team labels — positioned INSIDE the surface with clear padding
    _label(canvas, 'TEAM A', m.teamALabelPos, 10, c.teamLabel);
    _label(canvas, 'TEAM B', m.teamBLabelPos, 10, c.teamLabel);
  }

  void _label(
      Canvas canvas, String text, Offset pos, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_CourtSurfacePainter oldDelegate) =>
      isDoubles != oldDelegate.isDoubles ||
      brightness != oldDelegate.brightness;
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final m = _Metrics(size, isDoubles: isDoubles);
    final c = _CourtColors.of(brightness);

    for (final player in players) {
      final isServer = player.id == servingPlayerId;
      final pos = m.playerDot(player.team, player.side);
      final initials = _initials(player.name);

      // ── Player circle ──
      final dotColor = isServer ? c.serverDot : c.playerDot;
      canvas.drawCircle(pos, 12, Paint()..color = dotColor);

      // ── Server ring: white outline for maximum contrast on any surface ──
      if (isServer) {
        canvas.drawCircle(
          pos,
          18,
          Paint()
            ..color = c.serverRing
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }

      // ── Initials inside the circle ──
      final initialsTp = TextPainter(
        text: TextSpan(
          text: initials,
          style: TextStyle(
            color: c.initialsText,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      initialsTp.paint(
        canvas,
        Offset(pos.dx - initialsTp.width / 2,
            pos.dy - initialsTp.height / 2),
      );

      // ── Name below dot (clean, no heavy pill) ──
      final displayName = player.name.length > 10
          ? '${player.name.substring(0, 9)}\u2026'
          : player.name;
      final nameTp = TextPainter(
        text: TextSpan(
          text: displayName,
          style: TextStyle(
            color: c.nameLabel,
            fontSize: 9,
            fontWeight: isServer ? FontWeight.w700 : FontWeight.w500,
            // Subtle shadow for readability on green surface
            shadows: const [
              Shadow(
                  color: Color(0x60000000),
                  blurRadius: 2,
                  offset: Offset(0, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 72);
      nameTp.paint(
        canvas,
        Offset(pos.dx - nameTp.width / 2, pos.dy + 18),
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

  // ── Background ──
  static const _insetX = 12.0;
  static const _padY = 12.0;
  static const _surfaceInset = 5.0;

  RRect get bgRect => RRect.fromRectAndRadius(
        Rect.fromLTWH(
            _insetX, _padY, size.width - _insetX * 2, size.height - _padY * 2),
        const Radius.circular(6),
      );

  // ── Playing surface ──
  RRect get surfaceRect => RRect.fromRectAndRadius(
        Rect.fromLTWH(
          _insetX + _surfaceInset,
          _padY + _surfaceInset + 12, // extra top padding for label
          size.width - (_insetX + _surfaceInset) * 2,
          size.height - (_padY + _surfaceInset) * 2 - 24, // room for both labels
        ),
        const Radius.circular(4),
      );

  // ── Net ──
  Offset get netLeft => Offset(surfaceRect.left, surfaceRect.center.dy);
  Offset get netRight => Offset(surfaceRect.right, surfaceRect.center.dy);

  // ── Kitchen ──
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

  Offset get kitchenTopLeft => Offset(surfaceRect.left, kitchenTopRect.top);
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
      x = side == 'left'
          ? surfaceRect.left + q
          : surfaceRect.right - q;
    } else {
      x = surfaceRect.center.dx;
    }
    final topBoxCenter = (surfaceRect.top + kitchenTopRect.top) / 2;
    final bottomBoxCenter =
        (surfaceRect.bottom + kitchenBottomRect.bottom) / 2;
    return Offset(x, team == 'A' ? topBoxCenter : bottomBoxCenter);
  }

  // ── Team labels (inside the surface, padded from edges) ──
  Offset get teamALabelPos => Offset(
      surfaceRect.center.dx, surfaceRect.top - 16);
  Offset get teamBLabelPos => Offset(
      surfaceRect.center.dx, surfaceRect.bottom + 16);
}

// ── Theme-aware Court Colors ──

class _CourtColors {
  final Color surround;
  final Color surface;
  final Color kitchenTint;
  final Color kitchenLine;
  final Color courtLine;
  final Color centerLine;
  final Color net;
  final Color teamLabel;
  final Color playerDot;
  final Color serverDot;
  final Color serverRing;
  final Color initialsText;
  final Color nameLabel;

  const _CourtColors._({
    required this.surround,
    required this.surface,
    required this.kitchenTint,
    required this.kitchenLine,
    required this.courtLine,
    required this.centerLine,
    required this.net,
    required this.teamLabel,
    required this.playerDot,
    required this.serverDot,
    required this.serverRing,
    required this.initialsText,
    required this.nameLabel,
  });

  factory _CourtColors.of(Brightness brightness) {
    return brightness == Brightness.dark ? _dark : _light;
  }

  static const _light = _CourtColors._(
    surround: Color(0xFF2B5797),
    surface: Color(0xFF4A8C3F),
    kitchenTint: Color(0x148B4513),
    kitchenLine: Color(0xFF8B4513),
    courtLine: Color(0xCCFFFFFF),
    centerLine: Color(0x73FFFFFF),
    net: Color(0xFF444444),
    teamLabel: Color(0xB3FFFFFF),
    playerDot: Color(0xD9FFFFFF),
    serverDot: Color(0xFFC8E030),
    serverRing: Color(0xFFFFFFFF),
    initialsText: Color(0xFF1A2800),
    nameLabel: Color(0xE6FFFFFF),
  );

  static const _dark = _CourtColors._(
    surround: Color(0xFF1A3058),
    surface: Color(0xFF2A4F22),
    kitchenTint: Color(0x1F5C2E0A),
    kitchenLine: Color(0xFF5C2E0A),
    courtLine: Color(0x8CFFFFFF),
    centerLine: Color(0x59FFFFFF),
    net: Color(0xFF5A5A5A),
    teamLabel: Color(0x8CFFFFFF),
    playerDot: Color(0xD9FFFFFF),
    serverDot: Color(0xFFC8E030),
    serverRing: Color(0xFFFFFFFF),
    initialsText: Color(0xFF1A2800),
    nameLabel: Color(0xCCFFFFFF),
  );
}

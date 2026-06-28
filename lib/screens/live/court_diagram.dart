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

/// Vertical pickleball court diagram — redesigned with gradients,
/// 3D player markers, proper net with posts, and modern color hierarchy.
///
/// Single CustomPainter approach: one paint pass draws everything
/// (court surface + player markers) to avoid layout-cycle-prone
/// Stack/LayoutBuilder patterns.
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
    return RepaintBoundary(
      child: CustomPaint(
        painter: _CourtPainter(
          players: players,
          servingPlayerId: servingPlayerId,
          isDoubles: isDoubles,
          brightness: brightness,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ── Single unified painter ──

class _CourtPainter extends CustomPainter {
  final List<PlayerPosition> players;
  final String? servingPlayerId;
  final bool isDoubles;
  final Brightness brightness;
  final List<TextPainter> _textPainters = [];

  _CourtPainter({
    required this.players,
    this.servingPlayerId,
    required this.isDoubles,
    required this.brightness,
  });

  TextPainter _createTextPainter(TextSpan span, {TextDirection dir = TextDirection.ltr}) {
    final tp = TextPainter(text: span, textDirection: dir);
    _textPainters.add(tp);
    return tp;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final tp in _textPainters) {
      tp.dispose();
    }
    _textPainters.clear();
    final m = _Metrics(size, isDoubles: isDoubles);
    final c = _CourtColors.of(brightness);

    _drawSurround(canvas, m, c);
    _drawSurface(canvas, m, c);
    _drawKitchenZones(canvas, m, c);
    _drawCourtLines(canvas, m, c);
    _drawNet(canvas, m, c);
    _drawTeamLabels(canvas, m, c);
    _drawPlayers(canvas, m, c);
  }

  // ── Court surround (blue area around the playing surface) ──

  void _drawSurround(Canvas canvas, _Metrics m, _CourtColors c) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [c.surroundTop, c.surroundBottom],
      ).createShader(m.bgRect.outerRect);
    canvas.drawRRect(m.bgRect, paint);
  }

  // ── Playing surface (green court) ──

  void _drawSurface(Canvas canvas, _Metrics m, _CourtColors c) {
    // Subtle shadow under the surface for depth
    final shadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);
    canvas.drawRRect(m.surfaceRect, shadowPaint);

    // Gradient green surface
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [c.surfaceTop, c.surfaceBottom],
      ).createShader(m.surfaceRect.outerRect);
    canvas.drawRRect(m.surfaceRect, paint);
  }

  // ── Kitchen zones (non-volley area) ──

  void _drawKitchenZones(Canvas canvas, _Metrics m, _CourtColors c) {
    final kitchenPaint = Paint()..color = c.kitchenTint;
    canvas.drawRect(m.kitchenTopRect, kitchenPaint);
    canvas.drawRect(m.kitchenBottomRect, kitchenPaint);
  }

  // ── Court lines (baselines, sidelines, kitchen lines) ──

  void _drawCourtLines(Canvas canvas, _Metrics m, _CourtColors c) {
    final sr = m.surfaceRect.outerRect;

    // Outer court lines (sidelines + baselines)
    final linePaint = Paint()
      ..color = c.courtLine
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(sr.topLeft, sr.topRight, linePaint);
    canvas.drawLine(sr.bottomLeft, sr.bottomRight, linePaint);
    canvas.drawLine(sr.topLeft, sr.bottomLeft, linePaint);
    canvas.drawLine(sr.topRight, sr.bottomRight, linePaint);

    // Kitchen lines
    final kitchenLinePaint = Paint()
      ..color = c.kitchenLine
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(sr.left, m.kitchenTopY), Offset(sr.right, m.kitchenTopY), kitchenLinePaint);
    canvas.drawLine(
        Offset(sr.left, m.kitchenBottomY), Offset(sr.right, m.kitchenBottomY), kitchenLinePaint);

    // Center service line (doubles only)
    if (isDoubles) {
      final centerPaint = Paint()
        ..color = c.centerLine
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final cx = sr.center.dx;
      canvas.drawLine(Offset(cx, sr.top), Offset(cx, m.kitchenTopY), centerPaint);
      canvas.drawLine(Offset(cx, m.kitchenBottomY), Offset(cx, sr.bottom), centerPaint);
    }
  }

  // ── Net with posts ──

  void _drawNet(Canvas canvas, _Metrics m, _CourtColors c) {
    final sr = m.surfaceRect.outerRect;
    final netY = sr.center.dy;

    // Net posts (small rectangles at each sideline)
    final postPaint = Paint()..color = c.netPost;
    const postW = 4.0;
    const postH = 12.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(sr.left, netY), width: postW, height: postH),
        const Radius.circular(2),
      ),
      postPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(sr.right, netY), width: postW, height: postH),
        const Radius.circular(2),
      ),
      postPaint,
    );

    // Net top band (thick solid line)
    final netPaint = Paint()
      ..color = c.net
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(sr.left, netY), Offset(sr.right, netY), netPaint);
  }

  // ── Team labels ──

  void _drawTeamLabels(Canvas canvas, _Metrics m, _CourtColors c) {
    _label(canvas, 'TEAM A', m.teamALabelPos, 9, c.teamLabel);
    _label(canvas, 'TEAM B', m.teamBLabelPos, 9, c.teamLabel);
  }

  void _label(Canvas canvas, String text, Offset pos, double size, Color color) {
    final tp = _createTextPainter(
      TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  // ── Player markers (3D dots with shadows, gradients, initials) ──

  void _drawPlayers(Canvas canvas, _Metrics m, _CourtColors c) {
    for (final player in players) {
      final isServer = player.id == servingPlayerId;
      final pos = m.playerDot(player.team, player.side);
      final radius = (m.size.height * 0.05).clamp(12.0, 20.0);

      // Drop shadow (simple offset circle — no MaskFilter for performance)
      canvas.drawCircle(
        pos + const Offset(0, 2),
        radius,
        Paint()..color = const Color(0x33000000),
      );

      // Server ring (behind dot, primary color)
      if (isServer) {
        canvas.drawCircle(
          pos,
          radius + 5,
          Paint()
            ..color = c.serverRing
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }

      // Dot with radial gradient (3D ball effect)
      final dotColor = isServer ? c.serverDot : c.playerDot;
      final dotLight = isServer ? c.serverDotLight : c.playerDotLight;
      final dotPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
          colors: [dotLight, dotColor],
        ).createShader(Rect.fromCircle(center: pos, radius: radius));
      canvas.drawCircle(pos, radius, dotPaint);

      // Subtle white border for definition
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = const Color(0x30FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      // Initials inside the dot
      final initials = _initials(player.name);
      final initialsTp = _createTextPainter(
        TextSpan(
          text: initials,
          style: TextStyle(
            color: c.initialsText,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      )..layout();
      initialsTp.paint(
        canvas,
        Offset(pos.dx - initialsTp.width / 2, pos.dy - initialsTp.height / 2),
      );

      // Name below dot (with shadow for readability)
      final displayName = player.name.length > 10
          ? '${player.name.substring(0, 9)}\u2026'
          : player.name;
      final nameTp = _createTextPainter(
        TextSpan(
          text: displayName,
          style: TextStyle(
            color: c.nameLabel,
            fontSize: 10,
            fontWeight: isServer ? FontWeight.w700 : FontWeight.w600,
            shadows: const [
              Shadow(color: Color(0x80000000), blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
        ),
      )..layout(maxWidth: 80);
      nameTp.paint(
        canvas,
        Offset(pos.dx - nameTp.width / 2, pos.dy + radius + 4),
      );
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  bool shouldRepaint(_CourtPainter oldDelegate) {
    if (brightness != oldDelegate.brightness) return true;
    if (isDoubles != oldDelegate.isDoubles) return true;
    if (players.length != oldDelegate.players.length) return true;
    if (servingPlayerId != oldDelegate.servingPlayerId) return true;
    for (var i = 0; i < players.length; i++) {
      if (players[i].id != oldDelegate.players[i].id ||
          players[i].side != oldDelegate.players[i].side ||
          players[i].name != oldDelegate.players[i].name) {
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

  static const _insetX = 10.0;
  static const _padY = 10.0;
  static const _surfaceInset = 5.0;
  static const _labelPad = 14.0;

  RRect get bgRect => RRect.fromRectAndRadius(
        Rect.fromLTWH(
          _insetX, _padY,
          size.width - _insetX * 2,
          size.height - _padY * 2,
        ),
        const Radius.circular(10),
      );

  RRect get surfaceRect => RRect.fromRectAndRadius(
        Rect.fromLTWH(
          _insetX + _surfaceInset,
          _padY + _surfaceInset + _labelPad,
          size.width - (_insetX + _surfaceInset) * 2,
          size.height - (_padY + _surfaceInset) * 2 - _labelPad * 2,
        ),
        const Radius.circular(6),
      );

  double get _halfHeight => surfaceRect.height / 2;
  double get _kitchenOffset => _halfHeight * 0.30;

  double get kitchenTopY => surfaceRect.center.dy - _kitchenOffset;
  double get kitchenBottomY => surfaceRect.center.dy + _kitchenOffset;

  Rect get kitchenTopRect => Rect.fromLTRB(
        surfaceRect.left, kitchenTopY, surfaceRect.right, surfaceRect.center.dy);

  Rect get kitchenBottomRect => Rect.fromLTRB(
        surfaceRect.left, surfaceRect.center.dy, surfaceRect.right, kitchenBottomY);

  Offset playerDot(String team, String side) {
    final double x;
    if (isDoubles) {
      final q = surfaceRect.width / 4;
      x = side == 'left' ? surfaceRect.left + q : surfaceRect.right - q;
    } else {
      x = surfaceRect.center.dx;
    }
    final topCenter = (surfaceRect.top + kitchenTopY) / 2;
    final bottomCenter = (surfaceRect.bottom + kitchenBottomY) / 2;
    return Offset(x, team == 'A' ? topCenter : bottomCenter);
  }

  Offset get teamALabelPos =>
      Offset(surfaceRect.center.dx, surfaceRect.top - _labelPad / 2 - 2);
  Offset get teamBLabelPos =>
      Offset(surfaceRect.center.dx, surfaceRect.bottom + _labelPad / 2 + 2);
}

// ── Theme-aware Court Colors ──

class _CourtColors {
  // Surround (blue area)
  final Color surroundTop;
  final Color surroundBottom;

  // Surface (green court)
  final Color surfaceTop;
  final Color surfaceBottom;

  // Kitchen
  final Color kitchenTint;
  final Color kitchenLine;

  // Lines
  final Color courtLine;
  final Color centerLine;

  // Net
  final Color net;
  final Color netPost;

  // Labels
  final Color teamLabel;

  // Player dots
  final Color playerDot;
  final Color playerDotLight;
  final Color serverDot;
  final Color serverDotLight;
  final Color serverRing;
  final Color initialsText;
  final Color nameLabel;

  const _CourtColors._({
    required this.surroundTop,
    required this.surroundBottom,
    required this.surfaceTop,
    required this.surfaceBottom,
    required this.kitchenTint,
    required this.kitchenLine,
    required this.courtLine,
    required this.centerLine,
    required this.net,
    required this.netPost,
    required this.teamLabel,
    required this.playerDot,
    required this.playerDotLight,
    required this.serverDot,
    required this.serverDotLight,
    required this.serverRing,
    required this.initialsText,
    required this.nameLabel,
  });

  factory _CourtColors.of(Brightness brightness) {
    return brightness == Brightness.dark ? _dark : _light;
  }

  // ── Light mode ──
  static const _light = _CourtColors._(
    // Blue surround: lighter top → deeper bottom
    surroundTop: Color(0xFF3268AC),
    surroundBottom: Color(0xFF1E4078),
    // Green surface: vibrant top → deeper bottom
    surfaceTop: Color(0xFF5AA04D),
    surfaceBottom: Color(0xFF3D7535),
    // Kitchen: subtle darker green
    kitchenTint: Color(0x22335522),
    kitchenLine: Color(0xBFFFFFFF),
    // Court lines: white
    courtLine: Color(0xCCFFFFFF),
    centerLine: Color(0x73FFFFFF),
    // Net
    net: Color(0xFF2A2A2A),
    netPost: Color(0xFF1A1A1A),
    // Team labels
    teamLabel: Color(0xB3FFFFFF),
    // Player dots: white with gradient
    playerDot: Color(0xE6FFFFFF),
    playerDotLight: Color(0xFFFFFFFF),
    // Server dot: primary (lime)
    serverDot: Color(0xFFC8E030),
    serverDotLight: Color(0xFFEBFF80),
    serverRing: Color(0xFFFFFFFF),
    initialsText: Color(0xFF1A2800),
    nameLabel: Color(0xF2FFFFFF),
  );

  // ── Dark mode ──
  static const _dark = _CourtColors._(
    surroundTop: Color(0xFF1E3A6B),
    surroundBottom: Color(0xFF0F1F42),
    surfaceTop: Color(0xFF3A6B32),
    surfaceBottom: Color(0xFF1E4A1A),
    kitchenTint: Color(0x221A3010),
    kitchenLine: Color(0x99FFFFFF),
    courtLine: Color(0x99FFFFFF),
    centerLine: Color(0x59FFFFFF),
    net: Color(0xFF444444),
    netPost: Color(0xFF333333),
    teamLabel: Color(0x8CFFFFFF),
    playerDot: Color(0xCCFFFFFF),
    playerDotLight: Color(0xE6FFFFFF),
    serverDot: Color(0xFFC8E030),
    serverDotLight: Color(0xFFEBFF80),
    serverRing: Color(0xFFFFFFFF),
    initialsText: Color(0xFF1A2800),
    nameLabel: Color(0xCCFFFFFF),
  );
}

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

/// Mini court diagram widget for the Live Match screen.
/// Two-layer CustomPainter: static court surface + animated player dots.
class CourtDiagram extends StatefulWidget {
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
  State<CourtDiagram> createState() => _CourtDiagramState();
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
    );
    // Only run the radar pulse when there is an active server. When
    // servingPlayerId is null (paused, before the first serve, or after
    // the match is over) the pulse is invisible anyway, so we skip the
    // per-frame repaint to save battery and isolate wake-ups.
    _syncGlowToActiveServer();
  }

  @override
  void didUpdateWidget(CourtDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.servingPlayerId != widget.servingPlayerId) {
      _syncGlowToActiveServer();
    }
  }

  /// Start the radar pulse loop only when an active server exists.
  void _syncGlowToActiveServer() {
    if (widget.servingPlayerId == null) {
      _glowController.stop();
    } else if (!_glowController.isAnimating) {
      _glowController.repeat();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        return SizedBox(
          height: 180,
          child: Stack(
            children: [
              // Layer 1: Static court surface
              RepaintBoundary(
                child: CustomPaint(
                  painter: _CourtSurfacePainter(isDoubles: widget.isDoubles),
                  size: Size.infinite,
                ),
              ),
              // Layer 2: Animated player dots
              CustomPaint(
                painter: _PlayerPositionPainter(
                  players: widget.players,
                  servingPlayerId: widget.servingPlayerId,
                  glowValue: _glowController.value,
                  isDoubles: widget.isDoubles,
                ),
                size: Size.infinite,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Layer 1: Static Court Surface ──

class _CourtSurfacePainter extends CustomPainter {
  final bool isDoubles;

  const _CourtSurfacePainter({this.isDoubles = true});

  @override
  void paint(Canvas canvas, Size size) {
    final metrics = _CourtMetrics(size);

    // Background
    final bgPaint = Paint()..color = const Color(0xFF2B5797);
    canvas.drawRect(metrics.backgroundRect, bgPaint);

    // Playing surface
    final surfacePaint = Paint()..color = const Color(0xFF4A8C3F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(metrics.surfaceRect, const Radius.circular(4)),
      surfacePaint,
    );

    // Kitchen zone tint
    final kitchenPaint = Paint()..color = const Color(0xFF8B4513).withValues(alpha: 0.08);
    canvas.drawRect(
      Rect.fromLTRB(
        metrics.surfaceRect.left,
        metrics.kitchenLineTop,
        metrics.surfaceRect.right,
        metrics.netY,
      ),
      kitchenPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        metrics.surfaceRect.left,
        metrics.netY,
        metrics.surfaceRect.right,
        metrics.kitchenLineBottom,
      ),
      kitchenPaint,
    );

    // Court lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Sidelines
    canvas.drawLine(
      Offset(metrics.surfaceRect.left, metrics.surfaceRect.top),
      Offset(metrics.surfaceRect.left, metrics.surfaceRect.bottom),
      linePaint,
    );
    canvas.drawLine(
      Offset(metrics.surfaceRect.right, metrics.surfaceRect.top),
      Offset(metrics.surfaceRect.right, metrics.surfaceRect.bottom),
      linePaint,
    );

    // Baselines
    canvas.drawLine(
      Offset(metrics.surfaceRect.left, metrics.surfaceRect.top),
      Offset(metrics.surfaceRect.right, metrics.surfaceRect.top),
      linePaint,
    );
    canvas.drawLine(
      Offset(metrics.surfaceRect.left, metrics.surfaceRect.bottom),
      Offset(metrics.surfaceRect.right, metrics.surfaceRect.bottom),
      linePaint,
    );

    // Center service line — only in doubles mode
    if (isDoubles) {
      final centerPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final centerX = metrics.surfaceRect.center.dx;

      // Top half center line
      canvas.drawLine(
        Offset(centerX, metrics.surfaceRect.top),
        Offset(centerX, metrics.kitchenLineTop),
        centerPaint,
      );
      // Bottom half center line
      canvas.drawLine(
        Offset(centerX, metrics.kitchenLineBottom),
        Offset(centerX, metrics.surfaceRect.bottom),
        centerPaint,
      );
    }

    // Kitchen lines
    final kitchenLinePaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(metrics.surfaceRect.left, metrics.kitchenLineTop),
      Offset(metrics.surfaceRect.right, metrics.kitchenLineTop),
      kitchenLinePaint,
    );
    canvas.drawLine(
      Offset(metrics.surfaceRect.left, metrics.kitchenLineBottom),
      Offset(metrics.surfaceRect.right, metrics.kitchenLineBottom),
      kitchenLinePaint,
    );

    // Net
    final netPaint = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(metrics.surfaceRect.left, metrics.netY),
      Offset(metrics.surfaceRect.right, metrics.netY),
      netPaint,
    );

    // Team labels
    _drawLabel(
      canvas,
      'Team A  —  Team B',
      Offset(metrics.backgroundRect.center.dx, metrics.backgroundRect.bottom - 4),
      Colors.white.withValues(alpha: 0.8),
      10,
    );
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset position,
    Color color,
    double fontSize,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy),
    );
  }

  @override
  bool shouldRepaint(_CourtSurfacePainter oldDelegate) =>
      isDoubles != oldDelegate.isDoubles;
}

// ── Court Coordinate Calculator ──

class _CourtMetrics {
  final Size canvasSize;

  static const courtInsetX = 14.0;
  static const courtInsetY = 10.0;
  static const surfaceInsetFromBg = 6.0;

  _CourtMetrics(this.canvasSize);

  Rect get backgroundRect => Rect.fromLTWH(
        courtInsetX,
        courtInsetY,
        canvasSize.width - courtInsetX * 2,
        canvasSize.height - courtInsetY * 2,
      );

  Rect get surfaceRect => Rect.fromLTWH(
        courtInsetX + surfaceInsetFromBg,
        courtInsetY + surfaceInsetFromBg,
        canvasSize.width - (courtInsetX + surfaceInsetFromBg) * 2,
        canvasSize.height - (courtInsetY + surfaceInsetFromBg) * 2,
      );

  double get netY => surfaceRect.center.dy;

  double get kitchenOffset {
    final halfCourtHeight = surfaceRect.height / 2;
    return halfCourtHeight * 0.32;
  }

  double get kitchenLineTop => netY - kitchenOffset;
  double get kitchenLineBottom => netY + kitchenOffset;

  Offset playerDotPosition({required String team, required String side, bool isDoubles = true}) {
    final double x;
    if (isDoubles) {
      final quarterX = surfaceRect.width / 4;
      final leftX = surfaceRect.left + quarterX;
      final rightX = surfaceRect.right - quarterX;
      x = side == 'left' ? leftX : rightX;
    } else {
      // Singles: player centered in half-court
      x = surfaceRect.center.dx;
    }

    final baselineToKitchen = kitchenOffset;
    final serviceBoxCenter = baselineToKitchen / 2;

    final y = team == 'A'
        ? netY - kitchenOffset - serviceBoxCenter
        : netY + kitchenOffset + serviceBoxCenter;

    return Offset(x, y);
  }
}

// ── Layer 2: Animated Player Dots ──

class _PlayerPositionPainter extends CustomPainter {
  final List<PlayerPosition> players;
  final String? servingPlayerId;
  final double glowValue;
  final bool isDoubles;

  const _PlayerPositionPainter({
    required this.players,
    this.servingPlayerId,
    required this.glowValue,
    this.isDoubles = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final metrics = _CourtMetrics(size);

    for (final player in players) {
      final isServer = player.id == servingPlayerId;
      final position = metrics.playerDotPosition(
        team: player.team,
        side: player.side,
        isDoubles: isDoubles,
      );

      // Player dot
      final dotPaint = Paint()
        ..color = isServer
            ? const Color(0xFFC8E030)
            : Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(position, 12.0, dotPaint);

      // Inner highlight for server
      if (isServer) {
        final highlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(position.dx - 2, position.dy - 2),
          5.0,
          highlightPaint,
        );

        // Server glow ring (radar pulse)
        final ringProgress = _getRingProgress(glowValue);
        final ringRadius = 12.0 + (16.0 * ringProgress);
        final ringOpacity = 1.0 - ringProgress;

        final ringPaint = Paint()
          ..color = const Color(0xFFC8E030).withValues(alpha: ringOpacity.clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(position, ringRadius, ringPaint);
      }

      // Player name label
      final displayName = player.name.length > 10
          ? '${player.name.substring(0, 9)}…'
          : player.name;

      final textPainter = TextPainter(
        text: TextSpan(
          text: displayName,
          style: TextStyle(
            color: isServer ? const Color(0xFFC8E030) : Colors.white.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 80);

      textPainter.paint(
        canvas,
        Offset(position.dx - textPainter.width / 2, position.dy + 16),
      );
    }
  }

  double _getRingProgress(double animValue) {
    // Two pulses per 1.5s loop: 0→0.3 and 0.5→0.8
    if (animValue <= 0.3) {
      return animValue / 0.3;
    } else if (animValue >= 0.5 && animValue <= 0.8) {
      return (animValue - 0.5) / 0.3;
    }
    return 0.0;
  }

  @override
  bool shouldRepaint(_PlayerPositionPainter oldDelegate) {
    return players != oldDelegate.players ||
        servingPlayerId != oldDelegate.servingPlayerId ||
        glowValue != oldDelegate.glowValue;
  }
}



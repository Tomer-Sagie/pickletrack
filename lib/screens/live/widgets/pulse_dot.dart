import 'package:flutter/material.dart';

/// Pulsing game-point indicator dot rendered next to the leading
/// team's score on the live scorecard.
///
/// Drives an internal 1.2s repeating [AnimationController] and
/// interpolates dot radius + alpha + box-shadow blur. Extracted
/// from `live_match_screen.dart` so the animation controller
/// lifecycle is owned by a focused widget that's independently
/// testable (pump it under a SizedBox, assert pulse present).
class PulseDot extends StatefulWidget {
  final Color color;
  const PulseDot({super.key, required this.color});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          width: 10 + 4 * t,
          height: 10 + 4 * t,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.85 - 0.45 * t),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4 * (1 - t)),
                blurRadius: 8 + 6 * t,
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

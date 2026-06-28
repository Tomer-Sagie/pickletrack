import 'package:flutter/material.dart';

/// A shimmer loading effect wrapper — paints an animated gradient over
/// placeholder shapes so users perceive instant feedback instead of
/// staring at a spinner.  No external packages needed.
class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Opaque neutral grays so BlendMode.srcIn produces visible, natural
    // card-surface tones in both themes (no white-block artifacts).
    final base = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final highlight =
        isDark ? const Color(0xFF3E3E3E) : const Color(0xFFF0F0F0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(
                percent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double percent;
  const _SlidingGradientTransform({required this.percent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Slide the gradient from -1 to +1 across the width each cycle.
    final dx = (percent * 2.0 - 1.0) * bounds.width;
    return Matrix4.translationValues(dx, 0, 0);
  }
}

// ── Placeholder shapes ──────────────────────────────────────────────

/// A rounded rectangle placeholder with shimmer.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          // Color is irrelevant — Shimmer's srcIn blend replaces it entirely.
          // Just needs to be non-transparent for the mask to have a shape.
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ── Skeleton card for match history loading ─────────────────────────

class ShimmerMatchHistory extends StatelessWidget {
  const ShimmerMatchHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: 14, width: 120),
          SizedBox(height: 16),
          _MatchCardSkeleton(),
          SizedBox(height: 6),
          _MatchCardSkeleton(),
          SizedBox(height: 6),
          _MatchCardSkeleton(),
          SizedBox(height: 6),
          _MatchCardSkeleton(),
          SizedBox(height: 6),
          _MatchCardSkeleton(),
        ],
      ),
    );
  }
}

class _MatchCardSkeleton extends StatelessWidget {
  const _MatchCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(14),
        child: const Row(
          children: [
            ShimmerBox(width: 4, height: 36, borderRadius: 2),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerBox(height: 14, width: 160),
                  SizedBox(height: 6),
                  ShimmerBox(height: 10, width: 220),
                ],
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerBox(height: 10, width: 48),
                SizedBox(height: 6),
                ShimmerBox(height: 10, width: 36),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton for match details loading ──────────────────────────────

class ShimmerMatchDetails extends StatelessWidget {
  const ShimmerMatchDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShimmerBox(height: 120, borderRadius: 16),
          SizedBox(height: 20),
          ShimmerBox(height: 80, borderRadius: 12),
          SizedBox(height: 16),
          ShimmerBox(height: 100, borderRadius: 12),
          SizedBox(height: 16),
          ShimmerBox(height: 220, borderRadius: 12),
        ],
      ),
    );
  }
}

// ── Skeleton for tournament bracket loading ─────────────────────────

class ShimmerTournament extends StatelessWidget {
  const ShimmerTournament({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ShimmerBox(height: 44, borderRadius: 0),
        SizedBox(height: 12),
        Expanded(
          child: _BracketSkeletonList(),
        ),
      ],
    );
  }
}

class _BracketSkeletonList extends StatelessWidget {
  const _BracketSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
      children: const [
        ShimmerBox(height: 56, borderRadius: 12),
        SizedBox(height: 8),
        ShimmerBox(height: 56, borderRadius: 12),
        SizedBox(height: 8),
        ShimmerBox(height: 56, borderRadius: 12),
        SizedBox(height: 8),
        ShimmerBox(height: 56, borderRadius: 12),
        SizedBox(height: 8),
        ShimmerBox(height: 56, borderRadius: 12),
        SizedBox(height: 8),
        ShimmerBox(height: 56, borderRadius: 12),
      ],
    );
  }
}

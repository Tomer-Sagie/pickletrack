import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';
import '../../theme/colors.dart';

/// First-time onboarding screen. Shown once on app launch.
///
/// Tracks completion via `app_settings` key `has_seen_onboarding`.
/// Call [onComplete] when the user finishes or skips onboarding.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      title: 'Tap to Score',
      subtitle: 'Two big buttons. One tap = one point.',
      body:
          'Green = Team A, blue = Team B. Tap your team to score. '
          'Undo below if you miss-tap. The serving team is always highlighted.',
      illustration: _ScoreButtonsIllustration(),
      accentColor: courtGreen,
    ),
    _OnboardingSlide(
      title: 'Resume Anytime',
      subtitle: 'Pick up where you left off.',
      body:
          'Walk away mid-match? No problem. A resume banner appears on the home '
          'screen — tap to jump straight back to the live score.',
      illustration: _ResumeBannerIllustration(),
      accentColor: Color(0xFFE8A317),
    ),
    _OnboardingSlide(
      title: 'Offline & Private',
      subtitle: 'Your data stays on your phone.',
      body:
          'No accounts, no internet, no ads. Matches, tournaments, and stats '
          'live locally — they\'re still there next time you open the app, online or not.',
      illustration: _OfflineIllustration(),
      accentColor: courtBlue,
    ),
    _OnboardingSlide(
      title: 'Run Tournaments',
      subtitle: 'Single elim, double elim, or round-robin.',
      body:
          'Add players, generate a bracket, tap to start each match. '
          'Finals and standings update automatically as matches finish.',
      illustration: _BracketIllustration(),
      accentColor: Color(0xFFE8A317),
    ),
  ];

  Future<void> _finish() async {
    try {
      final db = ProviderScope.containerOf(context, listen: false)
          .read(databaseProvider);
      await db.setSetting('has_seen_onboarding', 'true');
    } catch (_) {}
    widget.onComplete();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage + 1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ── Slides with fade + scale animation ──
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (i) =>
                        setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      // AnimatedSwitcher gives a soft fade + scale-up when
                      // the page changes, even though PageView itself is
                      // already sliding. Doubling up reads as "polished".
                      return _AnimatedSlide(
                        key: ValueKey(index),
                        child: _buildSlide(_slides[index], theme),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (i) {
                          final active = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? _slides[i].accentColor
                                  : theme.colorScheme.outline
                                      .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _nextPage,
                          icon: Icon(
                            isLast
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                          ),
                          label: Text(
                            isLast ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ── Quiet Skip (bottom-left, subdued) ──
            Positioned(
              left: 8,
              bottom: 8,
              child: SafeArea(
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.7),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide, ThemeData theme) {
    // ConstrainedBox + IntrinsicHeight -> content is centered when it fits
    // and can scroll if it grows beyond the viewport (large text scaling
    // or landscape on a 5" phone).
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
          // ── Illustration (CustomPaint mockup) ──
          SizedBox(
            width: 240,
            height: 190,
            child: slide.illustration,
          ),
          const SizedBox(height: 32),
          Semantics(
            header: true,
            child: Text(
              slide.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            slide.subtitle,
            style: theme.textTheme.titleSmall?.copyWith(
              color: slide.accentColor,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            slide.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// ── Animated Slide wrapper (fade + scale on enter) ──

class _AnimatedSlide extends StatefulWidget {
  final Widget child;
  const _AnimatedSlide({super.key, required this.child});

  @override
  State<_AnimatedSlide> createState() => _AnimatedSlideState();
}

class _AnimatedSlideState extends State<_AnimatedSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _scale = Tween(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ── Data Model ──

class _OnboardingSlide {
  final String title;
  final String subtitle;
  final String body;
  final Widget illustration;
  final Color accentColor;

  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.illustration,
    required this.accentColor,
  });
}

// ── Painter Utilities (shared across all illustrations) ──

/// Shared helper for CustomPainter text rendering. Tracks every
/// TextPainter it creates on the painter's [trackers] list so the
/// painter can dispose them at the start of the next paint pass —
/// avoids leaking Paragraph objects on theme/brightness changes.
class _PainterUtils {
  static void drawText(
    Canvas canvas,
    List<TextPainter> trackers,
    String text,
    Offset center, {
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = Colors.black,
    TextAlign textAlign = TextAlign.center,
    List<FontFeature>? features,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          fontFeatures: features,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    )..layout();
    trackers.add(tp);
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  static void disposeAll(List<TextPainter> trackers) {
    for (final tp in trackers) {
      tp.dispose();
    }
    trackers.clear();
  }
}

// ── Illustrations (CustomPaint mockups of the actual app UI) ──

/// Two big score buttons (green / blue) with a score display above.
class _ScoreButtonsIllustration extends StatelessWidget {
  const _ScoreButtonsIllustration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: _ScoreButtonsPainter(
        cardColor: theme.colorScheme.surfaceContainerHighest,
        accent: theme.colorScheme.primary,
      ),
    );
  }
}

class _ScoreButtonsPainter extends CustomPainter {
  final Color cardColor;
  final Color accent;
  final List<TextPainter> _textPainters = [];
  _ScoreButtonsPainter({required this.cardColor, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    _PainterUtils.disposeAll(_textPainters);
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );
    canvas.drawRRect(cardRect, Paint()..color = cardColor);

    // Score row at top
    const scoreFontSize = 32.0;
    const features = [FontFeature.tabularFigures()];
    _PainterUtils.drawText(
      canvas, _textPainters, '11',
      Offset(size.width * 0.30, size.height * 0.08),
      size: scoreFontSize, weight: FontWeight.w900, color: courtGreen,
      features: features,
    );
    _PainterUtils.drawText(
      canvas, _textPainters, '–',
      Offset(size.width * 0.50, size.height * 0.08),
      size: scoreFontSize, weight: FontWeight.w900,
      color: accent.withValues(alpha: 0.4),
      features: features,
    );
    _PainterUtils.drawText(
      canvas, _textPainters, '7',
      Offset(size.width * 0.70, size.height * 0.08),
      size: scoreFontSize, weight: FontWeight.w900, color: courtBlue,
      features: features,
    );

    // Two large buttons (green / blue)
    const btnHeight = 64.0;
    const btnRadius = 14.0;
    final btnY = size.height - btnHeight - 18;
    final leftBtnRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(16, btnY, (size.width - 48) / 2, btnHeight),
      const Radius.circular(btnRadius),
    );
    final rightBtnRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width - 16 - (size.width - 48) / 2,
        btnY,
        (size.width - 48) / 2,
        btnHeight,
      ),
      const Radius.circular(btnRadius),
    );
    canvas.drawRRect(leftBtnRect, Paint()..color = courtGreen);
    canvas.drawRRect(rightBtnRect, Paint()..color = courtBlue);

    _PainterUtils.drawText(canvas, _textPainters, 'Team A',
        Offset(16 + (size.width - 48) / 4, btnY + btnHeight / 2),
        size: 14, weight: FontWeight.w800, color: Colors.white);
    _PainterUtils.drawText(
        canvas, _textPainters, 'Team B',
        Offset(
            size.width - 16 - (size.width - 48) / 4, btnY + btnHeight / 2),
        size: 14, weight: FontWeight.w800, color: Colors.white);

    // Tap ripple on left button
    canvas.drawCircle(
      Offset(16 + (size.width - 48) / 4, btnY + btnHeight / 2),
      26,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_ScoreButtonsPainter old) =>
      old.cardColor != cardColor || old.accent != accent;
}

/// Resume banner card with LIVE pulse + team names.
class _ResumeBannerIllustration extends StatelessWidget {
  const _ResumeBannerIllustration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: _ResumeBannerPainter(
        cardColor: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

class _ResumeBannerPainter extends CustomPainter {
  final Color cardColor;
  final List<TextPainter> _textPainters = [];
  _ResumeBannerPainter({required this.cardColor});

  @override
  void paint(Canvas canvas, Size size) {
    _PainterUtils.disposeAll(_textPainters);
    final bannerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.30, size.width, size.height * 0.40),
      const Radius.circular(16),
    );
    canvas.drawRRect(bannerRect, Paint()..color = cardColor);

    // LIVE pulse dot
    canvas.drawCircle(
      Offset(24, size.height * 0.45),
      8,
      Paint()..color = courtGreen,
    );
    canvas.drawCircle(
      Offset(24, size.height * 0.45),
      14,
      Paint()
        ..color = courtGreen.withValues(alpha: 0.25),
    );

    _PainterUtils.drawText(canvas, _textPainters, 'LIVE',
        Offset(60, size.height * 0.42),
        size: 12, weight: FontWeight.w800, color: courtGreen);

    _PainterUtils.drawText(canvas, _textPainters, 'Alice  vs  Bob',
        Offset(size.width / 2, size.height * 0.58),
        size: 18, weight: FontWeight.w700, color: Colors.black87);

    // Play arrow on the right
    final playRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width - 56, size.height * 0.40, 40, 30),
      const Radius.circular(8),
    );
    canvas.drawRRect(playRRect, Paint()..color = courtGreen);
    _PainterUtils.drawText(canvas, _textPainters, '▶',
        Offset(size.width - 36, size.height * 0.55),
        size: 14, weight: FontWeight.w800, color: Colors.white);
  }

  @override
  bool shouldRepaint(_ResumeBannerPainter old) =>
      old.cardColor != cardColor;
}

/// Phone outline + cloud slash = offline + private.
class _OfflineIllustration extends StatelessWidget {
  const _OfflineIllustration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: _OfflinePainter(
        phoneColor: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

class _OfflinePainter extends CustomPainter {
  final Color phoneColor;
  final List<TextPainter> _textPainters = [];
  _OfflinePainter({required this.phoneColor});

  @override
  void paint(Canvas canvas, Size size) {
    _PainterUtils.disposeAll(_textPainters);
    // Phone outline
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.28, size.height * 0.05, size.width * 0.44,
          size.height * 0.90),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      phoneRect,
      Paint()
        ..color = phoneColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      phoneRect,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Phone screen content (mock scoreboard)
    _PainterUtils.drawText(canvas, _textPainters, '11 – 6',
        Offset(size.width / 2, size.height * 0.40),
        size: 26, weight: FontWeight.w900, color: Colors.black87);

    // Cloud with red slash (no internet)
    final cloudCenter = Offset(size.width * 0.78, size.height * 0.30);
    final cloudRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: cloudCenter, width: 60, height: 32),
      const Radius.circular(14),
    );
    canvas.drawRRect(cloudRect, Paint()..color = Colors.black12);
    _PainterUtils.drawText(canvas, _textPainters, '☁',
        cloudCenter.translate(0, -1),
        size: 22, weight: FontWeight.w800, color: Colors.black54);

    // Slash through cloud
    canvas.drawLine(
      Offset(cloudCenter.dx - 28, cloudCenter.dy + 14),
      Offset(cloudCenter.dx + 28, cloudCenter.dy - 14),
      Paint()
        ..color = Colors.red.shade600
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Lock icon (private)
    final lockCenter = Offset(size.width * 0.78, size.height * 0.70);
    _PainterUtils.drawText(canvas, _textPainters, '🔒', lockCenter,
        size: 28, weight: FontWeight.w800, color: Colors.black87);

    // Checkmark badge (still working)
    final checkCenter = Offset(size.width * 0.22, size.height * 0.70);
    canvas.drawCircle(checkCenter, 18, Paint()..color = courtGreen);
    _PainterUtils.drawText(canvas, _textPainters, '✓', checkCenter,
        size: 22, weight: FontWeight.w900, color: Colors.white);
  }

  @override
  bool shouldRepaint(_OfflinePainter old) =>
      old.phoneColor != phoneColor;
}

/// Mini bracket tree: line + 4 nodes.
class _BracketIllustration extends StatelessWidget {
  const _BracketIllustration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: _BracketPainter(
        primary: theme.colorScheme.primary,
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color primary;
  final List<TextPainter> _textPainters = [];
  _BracketPainter({required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    _PainterUtils.disposeAll(_textPainters);
    // Bracket frame
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      bgRect,
      Paint()..color = primary.withValues(alpha: 0.06),
    );

    // Two columns (round 1, round 2)
    final round1X = size.width * 0.30;
    final round2X = size.width * 0.70;
    const matchH = 32.0;
    const matchW = 60.0;
    final yCenter = size.height * 0.50;

    // 4 nodes in round 1
    for (var i = 0; i < 4; i++) {
      final y = yCenter + (i - 1.5) * matchH * 1.2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(round1X - matchW / 2, y - matchH / 2, matchW, matchH),
        const Radius.circular(6),
      );
      final won = i == 0 || i == 2;
      canvas.drawRRect(
          rect, Paint()..color = won ? courtGreen : primary.withValues(alpha: 0.3));
      final name = ['Alice', 'Bob', 'Carol', 'Dave'][i];
      _PainterUtils.drawText(canvas, _textPainters, name,
          Offset(round1X, y),
          size: 10, weight: FontWeight.w700,
          color: won ? Colors.white : Colors.black87);
    }

    // 2 nodes in round 2 (winners advance)
    for (var i = 0; i < 2; i++) {
      final y = yCenter + (i - 0.5) * matchH * 2.4;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(round2X - matchW / 2, y - matchH / 2, matchW, matchH),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = primary);
      final name = i == 0 ? 'Alice' : 'Carol';
      _PainterUtils.drawText(canvas, _textPainters, name,
          Offset(round2X, y),
          size: 10, weight: FontWeight.w800, color: Colors.white);
    }

    // Connecting lines (from round 1 to round 2)
    final connPaint = Paint()
      ..color = primary.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(round1X + matchW / 2, yCenter + (0 - 1.5) * matchH * 1.2),
        Offset(round2X - matchW / 2, yCenter + (0 - 0.5) * matchH * 2.4),
        connPaint);
    canvas.drawLine(
        Offset(round1X + matchW / 2, yCenter + (2 - 1.5) * matchH * 1.2),
        Offset(round2X - matchW / 2, yCenter + (0 - 0.5) * matchH * 2.4),
        connPaint);
    canvas.drawLine(
        Offset(round1X + matchW / 2, yCenter + (1 - 1.5) * matchH * 1.2),
        Offset(round2X - matchW / 2, yCenter + (1 - 0.5) * matchH * 2.4),
        connPaint);
    canvas.drawLine(
        Offset(round1X + matchW / 2, yCenter + (3 - 1.5) * matchH * 1.2),
        Offset(round2X - matchW / 2, yCenter + (1 - 0.5) * matchH * 2.4),
        connPaint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.primary != primary;
}

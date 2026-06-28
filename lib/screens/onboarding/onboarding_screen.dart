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
      icon: Icons.sports_tennis_rounded,
      iconColor: courtGreen,
      title: 'Track Every Point',
      body:
          'Tap to score, swipe up for Team A and down for Team B. '
          'Undo mistakes instantly. The app handles all the serving rules.',
    ),
    _OnboardingSlide(
      icon: Icons.offline_bolt_rounded,
      iconColor: courtBlue,
      title: 'Works Offline',
      body:
          'No internet, no accounts, no ads. Your match history stays '
          'on your phone. Force-close the app mid-match and resume later.',
    ),
    _OnboardingSlide(
      icon: Icons.emoji_events_rounded,
      iconColor: Color(0xFFE8A317),
      title: 'Tournaments & Stats',
      body:
          'Run single-elimination brackets, view win rates, and share '
          'match summaries with friends. Everything is free.',
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) => _buildSlide(_slides[index], theme),
              ),
            ),

            // Page indicators + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Next / Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _nextPage,
                      icon: Icon(
                        _currentPage == _slides.length - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        _currentPage == _slides.length - 1
                            ? 'Get Started'
                            : 'Next',
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
      ),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(32),
            ),
            alignment: Alignment.center,
            child: Icon(slide.icon, size: 56, color: slide.iconColor),
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
          const SizedBox(height: 12),
          Text(
            slide.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _OnboardingSlide {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _OnboardingSlide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });
}

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// Tutorial overlay shown on the first Live Match launch.
///
/// Dismissed by tapping anywhere. Tracks completion via the
/// [onComplete] callback — callers should persist the flag.
class TutorialOverlay extends StatelessWidget {
  final VoidCallback onComplete;

  const TutorialOverlay({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Tutorial overlay. Tap anywhere to dismiss.',
      button: true,
      onTap: onComplete,
      child: GestureDetector(
        onTap: onComplete,
        child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 100),
                // Swipe up indicator
                const _SwipeHint(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Swipe up → Team A scores',
                  color: courtGreen,
                ),
                const Spacer(),
                // Center: tap buttons hint
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 40,
                      color: theme.colorScheme.onSurface,
                    ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap the buttons to score',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Or swipe up/down on the court.\n'
                        'Tap the pause button for more options.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Swipe down indicator
                const _SwipeHint(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Swipe down → Team B scores',
                  color: courtBlue,
                ),
                const SizedBox(height: 40),
                Text(
                  'Tap anywhere to start playing',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}

class _SwipeHint extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SwipeHint({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 28, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

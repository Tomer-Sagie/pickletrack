import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../providers/active_match_provider.dart';
import '../../theme/colors.dart';

class ResumeBanner extends StatelessWidget {
  final ActiveMatchContext match;

  const ResumeBanner({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teamALabel = match.teamANames.join(' & ');
    final teamBLabel = match.teamBNames.join(' & ');
    final typeLabel = match.match.type == 'singles' ? 'Singles' : 'Doubles';
    final ruleLabel =
        match.match.scoringRule == 'sideout' ? 'Side-out' : 'Rally';

    return Semantics(
      button: true,
      label: 'Resume match: $teamALabel vs $teamBLabel, $typeLabel',
      child: Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => context.push('/match/live'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              // Live indicator
              const _LivePulse(color: courtGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIVE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: courtGreen,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$teamALabel  vs  $teamBLabel',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$typeLabel \u{2022} $ruleLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_filled_rounded,
                size: 36,
                color: theme.colorScheme.onPrimaryContainer
                    .withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

/// Static live indicator dot — avoids animation jank.
class _LivePulse extends StatelessWidget {
  final Color color;

  const _LivePulse({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

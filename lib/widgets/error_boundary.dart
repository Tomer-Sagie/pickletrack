import 'package:flutter/material.dart';

/// Production error widget shown when a render tree throws.
/// Replaces the default red error screen with a recovery UI.
///
/// Configured in main.dart via `ErrorWidget.builder = (details) => ...`
class ErrorBoundaryWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const ErrorBoundaryWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The screen encountered an error. Your match data is safe.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  // Navigate home then go back to try recovery
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.home_rounded),
                label: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

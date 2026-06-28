import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main.dart';
import 'providers/database_provider.dart';
import 'providers/theme_provider.dart';
import 'router.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'theme/app_theme.dart';

class PickleTrackApp extends ConsumerStatefulWidget {
  const PickleTrackApp({super.key});

  @override
  ConsumerState<PickleTrackApp> createState() => _PickleTrackAppState();
}

class _PickleTrackAppState extends ConsumerState<PickleTrackApp> {
  bool? _hasSeenOnboarding;
  bool _checkingOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    try {
      final db = ref.read(databaseProvider);
      // Flush any crashes caught before the DB was ready (e.g. FFI
      // init failures, async zone errors, framework build crashes).
      await flushStartupCrashes(db);
      final value = await db.getSetting('has_seen_onboarding');
      if (mounted) {
        setState(() {
          _hasSeenOnboarding = value == 'true';
          _checkingOnboarding = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasSeenOnboarding = false;
          _checkingOnboarding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeAsync = ref.watch(themeModeProvider);

    // Still bootstrapping theme OR onboarding check in flight → splash.
    if (themeAsync.isLoading || _checkingOnboarding) {
      return const _ThemeBootstrapSplash();
    }

    if (themeAsync.hasError) {
      return _ThemeBootstrapError(error: themeAsync.error.toString());
    }

    final mode = themeAsync.requireValue;

    return MaterialApp.router(
      title: 'PickleTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      routerConfig: router,
      builder: (context, child) {
        // Gate the entire app on onboarding completion.
        // Using a builder here keeps the router alive (deep links, back
        // button, etc.) while overlaying the onboarding flow when needed.
        if (_hasSeenOnboarding != true) {
          return OnboardingScreen(
            onComplete: () {
              if (mounted) {
                setState(() => _hasSeenOnboarding = true);
              }
            },
          );
        }
        // Constrain content to phone-like width on tablets/desktop so
        // the UI never stretches full-width on large screens.
        return _AdaptiveShell(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

/// Wraps app content in a centered, phone-width column on tablets/desktop
/// so the UI never stretches to fill a 27" monitor.  On phones the
/// ConstrainedBox is transparent (screen is already narrower than 600).
class _AdaptiveShell extends StatelessWidget {
  final Widget child;
  const _AdaptiveShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: child,
      ),
    );
  }
}

/// Brand-coloured splash used while the theme preference is loading.
/// Intentionally avoids MaterialApp/Material so the platform's default
/// surface colour is never visible to the user.
class _ThemeBootstrapSplash extends StatelessWidget {
  const _ThemeBootstrapSplash();

  @override
  Widget build(BuildContext context) {
    // Respect the platform brightness so dark-mode users don't get
    // flashbanged with a white splash before the theme loads.
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final bgColor = brightness == Brightness.dark
        ? const Color(0xFF13140E) // matches AppTheme.dark scaffold bg
        : const Color(0xFFFDFCF5); // matches AppTheme.light scaffold bg
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: bgColor,
        child: const Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
    );
  }
}

/// Last-ditch fallback if the theme read itself fails (DB corruption etc).
/// Keeps the user on the brand-light background instead of black so the
/// app is at least legible enough to navigate to Settings → Clear Data.
class _ThemeBootstrapError extends StatelessWidget {
  final String error;
  const _ThemeBootstrapError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFFDFCF5),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Theme failed to load: $error',
              style: const TextStyle(color: Color(0xFF1B1C18), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

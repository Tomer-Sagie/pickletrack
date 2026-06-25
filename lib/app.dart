import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class PickleTrackApp extends ConsumerWidget {
  const PickleTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeModeProvider);

    // Resolve the AsyncValue into a single (statusKey, child) pair so the
    // AnimatedSwitcher below can cross-fade when the boot phase changes
    // (splash → app, or splash → error). Without this, the swap from
    // brand-splash to first router frame is instantaneous and jarring on
    // slow devices where the DB read takes a beat.
    //
    // Hand-rolled if/else rather than `themeAsync.when(...)` so we can
    // use plain local assignment (Dart's analyzer treats assignments
    // inside multiple closures as ambiguous and rejects final locals).
    final String statusKey;
    final Widget child;
    if (themeAsync.isLoading) {
      // While the user's stored preference is being read from the DB
      // paint a minimal brand-coloured splash — no MaterialApp wrap, so
      // there is no risk of flashing between system + stored themes.
      statusKey = 'splash';
      child = const _ThemeBootstrapSplash();
    } else if (themeAsync.hasError) {
      statusKey = 'error';
      child = _ThemeBootstrapError(error: themeAsync.error.toString());
    } else {
      final mode = themeAsync.requireValue;
      statusKey = 'app';
      child = MaterialApp.router(
        title: 'PickleTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        routerConfig: router,
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: ValueKey<String>(statusKey), child: child),
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

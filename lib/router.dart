// GoRouter policy: use `context.push(...)` for sub-pages whose caller we
// want users to return to via the system Back button (Settings, Match
// Details, Live Match from the Resume banner, Setup from the Action
// buttons), and use `context.go(...)` only when we explicitly want to
// reset the navigation stack to a single clean route (Go Home from
// error states, "Save & Exit" from the Live Pause Menu).
import 'package:go_router/go_router.dart';
import 'screens/home/home_screen.dart';
import 'screens/setup/setup_screen.dart';
import 'screens/live/live_match_screen.dart';
import 'screens/details/match_details_screen.dart';
import 'screens/settings/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/match/setup',
      builder: (context, state) {
        final quick = state.uri.queryParameters['quick'] == 'true';
        return SetupScreen(quickStart: quick);
      },
    ),
    GoRoute(
      path: '/match/live',
      builder: (context, state) => const LiveMatchScreen(),
    ),
    GoRoute(
      path: '/match/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        if (id <= 0) return const HomeScreen();
        return MatchDetailsScreen(matchId: id);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

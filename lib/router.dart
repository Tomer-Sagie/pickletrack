// GoRouter policy: use `context.push(...)` for sub-pages whose caller we
// want users to return to via the system Back button (Settings, Match
// Details, Live Match from the Resume banner, Setup from the Action
// buttons), and use `context.go(...)` only when we explicitly want to
// reset the navigation stack to a single clean route (Go Home from
// error states, "Pause & Return Later" from the Live Pause Menu).
//
// Bottom-nav tabs use StatefulShellRoute.indexedStack to preserve each
// tab's scroll position and state across switches.  Full-screen routes
// (/match/*, /tournament/*) sit at the root level as siblings to the
// shell so they automatically cover the bottom navigation bar.
import 'package:go_router/go_router.dart';
import 'screens/home/quick_play_tab.dart';
import 'screens/home/history_tab.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/setup/setup_screen.dart';
import 'screens/live/live_match_screen.dart';
import 'screens/details/match_details_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/tournament/tournament_setup_screen.dart';
import 'screens/tournament/tournament_screen.dart';
import 'widgets/app_scaffold.dart';

GoRouter createRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        // ── Bottom-nav tabs (StatefulShellRoute preserves tab state) ──
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppScaffold(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const QuickPlayTab(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/history',
                  builder: (context, state) => const HistoryTab(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Full-screen routes (cover the bottom nav) ──
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => OnboardingScreen(
            onComplete: () => context.go('/'),
          ),
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
            if (id <= 0) return const QuickPlayTab();
            return MatchDetailsScreen(matchId: id);
          },
        ),
        GoRoute(
          path: '/tournament/setup',
          builder: (context, state) => const TournamentSetupScreen(),
        ),
        GoRoute(
          path: '/tournament/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            if (id <= 0) return const QuickPlayTab();
            return TournamentScreen(tournamentId: id);
          },
        ),
      ],
    );

/// Global router instance used by the app.
final router = createRouter();

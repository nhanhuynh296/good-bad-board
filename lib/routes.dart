// GoRouter configuration with responsive tab-based shell.
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/shell/responsive_shell.dart';
import 'package:good_bad_board/features/analytics/analytics.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/features/players/players.dart';
import 'package:good_bad_board/features/registration/registration.dart';
import 'package:good_bad_board/features/sessions/sessions.dart';
import 'package:good_bad_board/features/schedule/schedule.dart';
import 'package:good_bad_board/features/settings/settings.dart';

final router = GoRouter(
  debugLogDiagnostics: kDebugMode,
  navigatorKey: navigatorKey,
  initialLocation: '/dashboard',
  routes: [
    // Redirect legacy routes to new tab-based paths
    GoRoute(path: '/', redirect: (context, state) => '/dashboard'),
    // Standalone self-registration page (REG-01…07) — public-facing, kept
    // outside the admin StatefulShellRoute (no ResponsiveShell chrome).
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegistrationPage(),
    ),
    GoRoute(path: '/game', redirect: (context, state) => '/dashboard'),
    GoRoute(path: '/stats', redirect: (context, state) => '/analytics'),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ResponsiveShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0 — Dashboard (Courts)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
          ],
        ),
        // Tab 1 — Players (with integrated check-in — CHK-01…06)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/players',
              builder: (context, state) => const PlayersPage(),
            ),
          ],
        ),
        // Tab 2 — Sessions
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/sessions',
              builder: (context, state) => const SessionsPage(),
            ),
          ],
        ),
        // Tab 3 — Schedule
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/schedule',
              builder: (context, state) => const SchedulePage(),
            ),
          ],
        ),
        // Tab 4 — Analytics
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsPage(),
            ),
          ],
        ),
        // Tab 5 — Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

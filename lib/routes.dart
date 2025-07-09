// GoRouter configuration
import 'package:go_router/go_router.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/view/game_maker_page.dart';
import 'package:good_bad_board/view/landing_page.dart';
import 'package:good_bad_board/view/player_statistic_page.dart';
import 'package:good_bad_board/view/sign_in_page.dart';

final router = GoRouter(
  debugLogDiagnostics: true,
  navigatorKey: navigatorKey,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingPage(),
      routes: [
        GoRoute(
          path: '/register',
          builder: (context, state) => const SignInPage(),
        ),
        GoRoute(
          path: '/game',
          builder: (context, state) => const GameMakerPage(),
        ),
        GoRoute(
          path: '/stats',
          builder: (context, state) => const PlayerStatisticPage(),
        ),
      ],
    ),
  ],
);

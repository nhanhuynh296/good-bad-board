import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/shell/shell.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

/// Builds the [ResponsiveShell] with the 5 real branches (IMPLEMENTATION
/// 8.6) and a plain page in each, so the shell tests do not depend on the
/// feature pages. Use it with `setUpCourtsSandbox` (temp-dir repositories,
/// the real font).
class ShellHarness {
  ShellHarness(this.tester);

  final WidgetTester tester;
  final TimerData timer = TimerData();
  late final GameData gameData = GameData(timer: timer, random: Random(7));
  final List<Player> players = [];
  late GoRouter router;

  static const pagePaths = [
    '/dashboard',
    '/players',
    '/sessions',
    '/analytics',
    '/settings',
  ];

  /// The key of the plain page of branch [index].
  static Key pageKey(int index) => Key('page-$index');

  /// Checks in [count] new players.
  void checkIn(int count) {
    for (var i = 0; i < count; i++) {
      final number = players.length + 1;
      final player = Player.create(
        firstName: 'Player',
        lastName: '$number',
        elo: Elo.values[number % Elo.values.length],
      );
      PlayerRepository.instance.add(player);
      players.add(player);
      gameData.checkInPlayer(player);
    }
  }

  Future<void> pump({
    Size size = const Size(1280, 720),
    Locale locale = const Locale('en'),
    String initialLocation = '/dashboard',
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              ResponsiveShell(navigationShell: navigationShell),
          branches: [
            for (final (index, path) in pagePaths.indexed)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (context, state) =>
                        SizedBox.expand(key: pageKey(index)),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(timer.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GameData>.value(value: gameData),
          ChangeNotifierProvider<TimerData>.value(value: timer),
          ChangeNotifierProvider<PersistentSetting>.value(
            value: PersistentSetting.instance,
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The branch index the shell shows now.
  int get currentIndex => pagePaths.indexOf(
    router.routerDelegate.currentConfiguration.uri.path,
  );

  /// Opens the branch at [index] through the router, as a tab tap does.
  Future<void> go(int index) async {
    router.go(pagePaths[index]);
    await tester.pumpAndSettle();
  }

  // ── Arrange helpers: the round phases (IMPLEMENTATION 8.2) ──

  void toReady() => gameData.generateFirstRound();

  void toRunning() {
    toReady();
    gameData.startFirstRound();
  }

  void toPaused() {
    toRunning();
    gameData.pause();
  }

  void toTimeUp() {
    toRunning();
    timer.elapse(timer.duration);
  }

  void toChangeover() {
    toRunning();
    gameData.quickSaveNextRound();
    gameData.startNextRound();
  }
}

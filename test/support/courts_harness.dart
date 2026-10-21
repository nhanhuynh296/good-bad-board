import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

import 'prefs_sandbox.dart';
import 'repository_sandbox.dart';

/// Sets up the preferences and a temp-dir repository sandbox for a Courts
/// widget test file. Tests never touch the real data directory
/// (PERSISTENCE.md §2.2).
void setUpCourtsSandbox(String name) {
  late RepositorySandbox sandbox;
  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp(name);
  });
  tearDown(() => sandbox.tearDown());
}

/// Builds the desktop Courts tab (IMPLEMENTATION 8.5) under a 56 px stand-in
/// for the top nav, with one shared [TimerData], as `main.dart` does.
class CourtsHarness {
  CourtsHarness(this.tester);

  final WidgetTester tester;
  final TimerData timer = TimerData();
  late final GameData gameData = GameData(timer: timer, random: Random(7));
  final List<Player> players = [];

  /// Checks in [count] new players, Elo spread evenly.
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
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // A running clock must not outlive the test.
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
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            backgroundColor: AppColors.pageBg,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 56),
                Expanded(child: DashboardPage()),
              ],
            ),
          ),
        ),
      ),
    );
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

  void toChangeover({bool discarded = false}) {
    toRunning();
    if (discarded) {
      gameData.discardAndStartNext();
    } else {
      gameData.quickSaveNextRound();
      gameData.startNextRound();
    }
  }

  void toEditing() {
    toRunning();
    gameData.makeNextRound();
  }

  /// Taps the widget found by [finder] and lets the frame settle.
  Future<void> tap(Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
  }

  /// Taps the text [label] once.
  Future<void> tapText(String label) => tap(find.text(label));
}

/// The slot of [court] (0-based) and [slot] (0-based) on the desktop grid.
Finder slotFinder(int court, int slot) => find.byKey(Key('slot-$court-$slot'));

/// The "⋯" button of that slot.
Finder slotMoreFinder(int court, int slot) =>
    find.byKey(Key('slot-more-$court-$slot'));

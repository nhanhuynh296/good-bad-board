import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

import '../support/prefs_sandbox.dart';
import '../support/repository_sandbox.dart';

/// R45-03: a timer tick rebuilds the rotation bar, not the whole Dashboard.
void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({'gameType': 'timeBased'});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('dashboard_timer_rebuild_test');
  });

  tearDown(() => sandbox.tearDown());

  Future<(GameData, TimerData)> pumpRunningRound(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final gameData = GameData();
    for (var i = 0; i < 8; i++) {
      final p = Player.create(firstName: 'P', lastName: '$i', elo: Elo.b1);
      PlayerRepository.instance.add(p);
      gameData.checkInPlayer(p);
    }
    await gameData.makeGame();
    final timerData = TimerData();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GameData>.value(value: gameData),
          ChangeNotifierProvider<TimerData>.value(value: timerData),
          ChangeNotifierProvider<PersistentSetting>.value(
            value: PersistentSetting.instance,
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: DashboardPage()),
        ),
      ),
    );
    timerData.start();
    await tester.pump();
    return (gameData, timerData);
  }

  testWidgets('should_not_rebuild_the_stat_strip_on_a_timer_tick', (
    tester,
  ) async {
    final (_, timerData) = await pumpRunningRound(tester);
    final before = tester.widget<StatStrip>(find.byType(StatStrip));

    await tester.pump(const Duration(seconds: 1));

    final rebuilt = !identical(
      tester.widget<StatStrip>(find.byType(StatStrip)),
      before,
    );
    timerData.reset();
    expect(rebuilt, isFalse);
  });

  testWidgets('should_update_the_countdown_on_a_timer_tick', (tester) async {
    final (_, timerData) = await pumpRunningRound(tester);
    final before = timerData.remainingLabel;

    await tester.pump(const Duration(seconds: 1));
    final after = timerData.remainingLabel;
    final shown = find.text(after).evaluate().length;
    timerData.reset();

    expect((after != before, shown), (true, 1));
  });
}

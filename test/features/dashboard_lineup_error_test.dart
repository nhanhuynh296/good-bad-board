import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

import '../support/prefs_sandbox.dart';
import '../support/repository_sandbox.dart';

// R45-02 and R45-39: the Dashboard shows a localised message for a refused
// lineup, never the exception text.

void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('dashboard_lineup_error_test');
  });

  tearDown(() => sandbox.tearDown());

  Widget wrap(GameData gameData, {Locale locale = const Locale('en')}) =>
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GameData>.value(value: gameData),
          ChangeNotifierProvider<TimerData>.value(value: TimerData()),
          ChangeNotifierProvider<PersistentSetting>.value(
            value: PersistentSetting.instance,
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: DashboardPage()),
        ),
      );

  void desktop(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<GameData> session(WidgetTester tester, int players) async {
    final gameData = GameData()..setNumberOfCourt(2);
    final created = await tester.runAsync(() => createTestPlayers(players));
    for (final player in created!) {
      gameData.checkInPlayer(player);
    }
    return gameData;
  }

  Future<void> tapGenerate(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('should_show_the_not_enough_players_message_on_generate', (
    tester,
  ) async {
    desktop(tester);
    await tester.pumpWidget(wrap(await session(tester, 2)));

    await tapGenerate(tester, 'Generate Game');

    expect(find.text('Check in at least 4 players. 2 checked in.'), findsOne);
  });

  testWidgets('should_not_show_exception_text_on_generate', (tester) async {
    desktop(tester);
    await tester.pumpWidget(wrap(await session(tester, 2)));

    await tapGenerate(tester, 'Generate Game');

    expect(find.textContaining('Exception'), findsNothing);
  });

  testWidgets('should_show_the_message_in_the_selected_language', (
    tester,
  ) async {
    desktop(tester);
    final gameData = await session(tester, 2);
    await tester.pumpWidget(wrap(gameData, locale: const Locale('fr')));
    final fr = lookupAppLocalizations(const Locale('fr'));

    await tapGenerate(tester, fr.generate_game);

    expect(
      find.text(fr.dashboard_error_not_enough_players(Game.playerPerCourt, 2)),
      findsOne,
    );
  });

  testWidgets('should_show_the_unbalanced_court_message_on_save', (
    tester,
  ) async {
    desktop(tester);
    final gameData = await session(tester, 8);
    await tester.runAsync(gameData.makeGame);
    gameData.removePlayerFromCourt(gameData.stagingMatches[1].players.first);
    await tester.pumpWidget(wrap(gameData));

    await tester.tap(find.byKey(const Key('dashboard-save-all')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Court 2 needs 4 players.'), findsOne);
  });
}

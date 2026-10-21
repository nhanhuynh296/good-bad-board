import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/repository/game_repository.dart';
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

  Widget wrap(
    GameData gameData, {
    Locale locale = const Locale('en'),
    TimerData? timerData,
  }) => MultiProvider(
    providers: [
      ChangeNotifierProvider<GameData>.value(value: gameData),
      ChangeNotifierProvider<TimerData>.value(value: timerData ?? TimerData()),
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

    await tapGenerate(tester, 'Generate round 1');

    expect(find.text('Check in at least 4 players. 2 checked in.'), findsOne);
  });

  testWidgets('should_not_show_exception_text_on_generate', (tester) async {
    desktop(tester);
    await tester.pumpWidget(wrap(await session(tester, 2)));

    await tapGenerate(tester, 'Generate round 1');

    expect(find.textContaining('Exception'), findsNothing);
  });

  testWidgets('should_show_the_message_in_the_selected_language', (
    tester,
  ) async {
    desktop(tester);
    final gameData = await session(tester, 2);
    await tester.pumpWidget(wrap(gameData, locale: const Locale('fr')));
    final fr = lookupAppLocalizations(const Locale('fr'));

    await tapGenerate(tester, fr.courts_generate_round_one);

    expect(
      find.text(fr.dashboard_error_not_enough_players(Game.playerPerCourt, 2)),
      findsOne,
    );
  });

  // R45-01 with R45-02: a failed round log shows one generic message.
  testWidgets('should_show_the_generic_message_when_round_log_fails', (
    tester,
  ) async {
    desktop(tester);
    final timerData = TimerData();
    final created = await tester.runAsync(() => createTestPlayers(8));
    final gameData = GameData(timer: timerData)..setNumberOfCourt(2);
    created!.forEach(gameData.checkInPlayer);
    gameData
      ..generateFirstRound()
      ..startFirstRound()
      ..quickSaveNextRound()
      ..startNextRound();
    await tester.pumpWidget(wrap(gameData, timerData: timerData));
    Directory(
      '${sandbox.tempDir.path}/${GameRepository.databaseFilename}.tmp',
    ).createSync();

    // The write runs real file IO, so the tap runs outside fake time.
    await tester.runAsync(() async {
      await tester.tap(find.text('Start round 2 now'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    expect(find.text('Something went wrong. Try again.'), findsOne);
    timerData.reset();
  });
}

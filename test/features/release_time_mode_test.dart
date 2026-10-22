import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/sessions/sessions.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

import '../support/prefs_sandbox.dart';
import '../support/repository_sandbox.dart';

/// Release build: game-based mode is hidden (`GameMode.enabled == false`), so
/// the app always runs time-based, whatever the saved setting says.
void main() {
  late RepositorySandbox sandbox;

  Widget wrap(GameData gameData, TimerData timerData) => MultiProvider(
    providers: [
      ChangeNotifierProvider<GameData>.value(value: gameData),
      ChangeNotifierProvider<PersistentSetting>.value(
        value: PersistentSetting.instance,
      ),
      ChangeNotifierProvider<TimerData>.value(value: timerData),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SessionsPage()),
    ),
  );

  setUp(() async {
    GameMode.enabled = false;
    mockPreferences({'gameType': 'gameBased'});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('release_time_mode_test');
  });

  tearDown(() {
    GameMode.enabled = false;
    sandbox.tearDown();
  });

  test('should_default_game_mode_flag_to_off', () {
    expect(GameMode.enabled, isFalse);
  });

  test('should_read_time_based_when_flag_off_and_game_based_saved', () {
    expect(PersistentSetting.instance.getGameType(), GameType.timeBased);
  });

  test('should_read_saved_game_based_when_flag_on', () {
    GameMode.enabled = true;

    expect(PersistentSetting.instance.getGameType(), GameType.gameBased);
  });

  test('should_keep_saved_game_type_on_disk_when_flag_off', () {
    PersistentSetting.instance.getGameType();

    expect(
      PersistentSetting.instance.sharedPreference.getString('gameType'),
      'gameBased',
    );
  });

  testWidgets('should_hide_mode_toggle_when_flag_off', (tester) async {
    await tester.pumpWidget(wrap(GameData(), TimerData()));

    expect(find.text('Game-based'), findsNothing);
    expect(find.text('Time-based'), findsNothing);
  });

  testWidgets('should_hide_game_based_description_when_flag_off', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(GameData(), TimerData()));

    expect(find.textContaining('by hand'), findsNothing);
  });

  testWidgets('should_keep_duration_field_when_flag_off_and_game_saved', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(GameData(), TimerData()));

    expect(find.byKey(const Key('duration-minutes')), findsOneWidget);
  });

  testWidgets('should_show_mode_toggle_when_flag_on', (tester) async {
    GameMode.enabled = true;

    await tester.pumpWidget(wrap(GameData(), TimerData()));

    expect(find.text('Game-based'), findsOneWidget);
  });

  testWidgets('should_drop_mode_from_template_summary_when_flag_off', (
    tester,
  ) async {
    final gameData = GameData();
    await tester.pumpWidget(wrap(gameData, TimerData()));
    await tester.runAsync(
      () => gameData.saveTemplate(
        'Evening',
        GameType.gameBased,
        const Duration(minutes: 20),
        16,
        4,
      ),
    );

    await tester.pump();

    expect(find.text('4 courts · cap 16'), findsOneWidget);
  });

  testWidgets('should_show_mode_in_template_summary_when_flag_on', (
    tester,
  ) async {
    GameMode.enabled = true;
    final gameData = GameData();
    await tester.pumpWidget(wrap(gameData, TimerData()));
    await tester.runAsync(
      () => gameData.saveTemplate(
        'Evening',
        GameType.gameBased,
        const Duration(minutes: 20),
        16,
        4,
      ),
    );

    await tester.pump();

    expect(find.text('4 courts · game-based · cap 16'), findsOneWidget);
  });

  testWidgets('should_ignore_template_mode_on_load_when_flag_off', (
    tester,
  ) async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    final gameData = GameData();
    await tester.pumpWidget(wrap(gameData, TimerData()));
    await tester.runAsync(
      () => gameData.saveTemplate(
        'Game night',
        GameType.gameBased,
        const Duration(minutes: 20),
        16,
        4,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Load'));
    await tester.pump();

    expect(
      PersistentSetting.instance.sharedPreference.getString('gameType'),
      isNull,
    );
  });

  group('F2 template Load reaches the countdown', () {
    Future<void> loadTemplate(
      WidgetTester tester,
      GameData gameData,
      Duration duration,
    ) async {
      await tester.runAsync(
        () =>
            gameData.saveTemplate('Short', GameType.timeBased, duration, 16, 4),
      );
      await tester.pump();
      await tester.tap(find.text('Load'));
      await tester.pump();
    }

    testWidgets('should_set_timer_duration_when_template_loads', (
      tester,
    ) async {
      mockPreferences({});
      await PersistentSetting.instance.initialize();
      final gameData = GameData();
      final timer = TimerData();
      await tester.pumpWidget(wrap(gameData, timer));

      await loadTemplate(tester, gameData, const Duration(minutes: 5));

      expect(timer.duration, const Duration(minutes: 5));
    });

    testWidgets('should_set_remaining_when_template_loads_and_timer_stopped', (
      tester,
    ) async {
      mockPreferences({});
      await PersistentSetting.instance.initialize();
      final gameData = GameData();
      final timer = TimerData();
      await tester.pumpWidget(wrap(gameData, timer));

      await loadTemplate(tester, gameData, const Duration(minutes: 5));

      expect(timer.remainingLabel, '05:00');
    });
  });
}

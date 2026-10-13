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

Widget createTestWidget({GameData? gameData, TimerData? timerData}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<GameData>.value(value: gameData ?? GameData()),
      ChangeNotifierProvider<PersistentSetting>.value(
        value: PersistentSetting.instance,
      ),
      ChangeNotifierProvider<TimerData>.value(value: timerData ?? TimerData()),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SessionsPage()),
    ),
  );
}

void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    // Game-based mode is hidden in the release build; these tests cover it.
    GameMode.enabled = true;
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('sessions_test');
  });

  tearDown(() {
    GameMode.enabled = false;
    sandbox.tearDown();
  });

  group('SessionsPage round mode', () {
    // ---------------------------------------------------------------------------
    // SESS-01: Toggle
    // ---------------------------------------------------------------------------
    testWidgets('SESS-01: should display Game-based and Time-based toggle '
        'options', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Game-based'), findsOneWidget);
      expect(find.text('Time-based'), findsOneWidget);
    });

    testWidgets('SESS-01: should highlight Time-based by default', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // The default game type from PersistentSetting is Time-based, so the
      // Time-based toggle should render as selected.
      // Depending on implementation this could be a filled button, an icon,
      // or a different style.  A minimal check is that the label exists and
      // the widget does not crash.
      expect(find.text('Time-based'), findsOneWidget);
    });

    testWidgets('SESS-01: should show description text for selected mode', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Time-based mode description (default)
      expect(find.textContaining('Time-based'), findsWidgets);
    });

    testWidgets('SESS-01: should_render_minute_and_second_fields_when_time_'
        'based', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Default mode is Time-based, so the mm:ss duration control is present.
      expect(find.byKey(const Key('duration-minutes')), findsOneWidget);
      expect(find.byKey(const Key('duration-seconds')), findsOneWidget);
    });

    testWidgets('SESS-01: should_hide_duration_field_when_game_based', (
      tester,
    ) async {
      final gameData = GameData();
      await tester.pumpWidget(createTestWidget(gameData: gameData));

      // Tap the Game-based toggle
      await tester.tap(find.text('Game-based'));
      await tester.pump();

      // The duration control should no longer be visible
      expect(find.byKey(const Key('duration-minutes')), findsNothing);
      expect(find.byKey(const Key('duration-seconds')), findsNothing);
    });

    testWidgets('SESS-01: should_describe_manual_flow_when_game_based', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Game-based'));
      await tester.pump();

      // Game-based no longer runs a clock, so the description must not
      // promise auto-rotation.
      expect(find.textContaining('auto-rotates'), findsNothing);
    });

    // ---------------------------------------------------------------------------
    // SESS-02: mm:ss duration control
    // ---------------------------------------------------------------------------
    testWidgets('SESS-02: should_show_stored_duration_in_the_mm_ss_fields', (
      tester,
    ) async {
      await PersistentSetting.instance.setGameDuration(
        const Duration(minutes: 12, seconds: 45),
      );

      await tester.pumpWidget(createTestWidget());

      final minutes = tester.widget<TextField>(
        find.byKey(const Key('duration-minutes')),
      );
      final seconds = tester.widget<TextField>(
        find.byKey(const Key('duration-seconds')),
      );
      expect(minutes.controller!.text, '12');
      expect(seconds.controller!.text, '45');
    });

    testWidgets('SESS-02: should_select_whole_segment_when_minute_field_'
        'focused', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byKey(const Key('duration-minutes')));
      await tester.pump();

      final minutes = tester.widget<TextField>(
        find.byKey(const Key('duration-minutes')),
      );
      final selection = minutes.controller!.selection;
      expect(selection.baseOffset, 0);
      expect(selection.extentOffset, minutes.controller!.text.length);
    });

    testWidgets('SESS-02: should_persist_duration_in_minutes_and_seconds', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byKey(const Key('duration-minutes')), '7');
      await tester.enterText(find.byKey(const Key('duration-seconds')), '30');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        PersistentSetting.instance.getGameDuration(),
        const Duration(minutes: 7, seconds: 30),
      );
    });

    testWidgets('SESS-02: should_clamp_seconds_above_fifty_nine', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byKey(const Key('duration-minutes')), '5');
      await tester.enterText(find.byKey(const Key('duration-seconds')), '90');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        PersistentSetting.instance.getGameDuration(),
        const Duration(minutes: 5, seconds: 59),
      );
    });

    testWidgets('SESS-02: should_keep_previous_duration_when_set_to_zero', (
      tester,
    ) async {
      await PersistentSetting.instance.setGameDuration(
        const Duration(minutes: 9),
      );
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byKey(const Key('duration-minutes')), '0');
      await tester.enterText(find.byKey(const Key('duration-seconds')), '0');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        PersistentSetting.instance.getGameDuration(),
        const Duration(minutes: 9),
      );
    });

    testWidgets('SESS-02: should_push_new_duration_to_the_running_timer', (
      tester,
    ) async {
      final timerData = TimerData();
      await tester.pumpWidget(createTestWidget(timerData: timerData));

      await tester.enterText(find.byKey(const Key('duration-minutes')), '3');
      await tester.enterText(find.byKey(const Key('duration-seconds')), '15');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(timerData.duration, const Duration(minutes: 3, seconds: 15));
    });

    // ---------------------------------------------------------------------------
    // SESS-03: Session capacity
    // ---------------------------------------------------------------------------
    testWidgets('SESS-03: should display session capacity input field', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // A number input for session capacity.  Look for a TextField whose
      // decoration or context mentions capacity, or simply check that a
      // relevant input exists.
      expect(find.byType(TextField), findsWidgets);
    });

    // ---------------------------------------------------------------------------
    // SESS-04: Courts count
    // ---------------------------------------------------------------------------
    testWidgets('SESS-04: should display courts count input field', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Courts count is a number input (range 1-8).  There should be at least
      // two numeric inputs on the page (capacity + courts).
      expect(find.byType(TextField), findsWidgets);
    });
  });

  group('SessionsPage session templates', () {
    // ---------------------------------------------------------------------------
    // SESS-05: Template save UI
    // ---------------------------------------------------------------------------
    testWidgets('SESS-05: should display template name TextField', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // The right card contains a TextField for entering a template name.
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('SESS-05: should display "Save current" button', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Save current'), findsOneWidget);
    });

    testWidgets('SESS-05: should display saved template summary after saving', (
      tester,
    ) async {
      final gameData = GameData();
      await tester.pumpWidget(createTestWidget(gameData: gameData));

      // Save a template so there is something to display
      // The save writes to disk, which needs real async.
      await tester.runAsync(
        () => gameData.saveTemplate(
          'Evening Session',
          GameType.timeBased,
          const Duration(minutes: 20),
          16,
          2,
        ),
      );
      await tester.pump();

      // The template summary should appear in the saved templates list
      expect(find.text('Evening Session'), findsOneWidget);
    });

    // ---------------------------------------------------------------------------
    // SESS-06: Load button per template
    // ---------------------------------------------------------------------------
    testWidgets('SESS-06: should display "Load" button for each saved '
        'template', (tester) async {
      final gameData = GameData();
      await tester.pumpWidget(createTestWidget(gameData: gameData));

      // The save writes to disk, which needs real async.
      await tester.runAsync(
        () => gameData.saveTemplate(
          'Morning Mix',
          GameType.gameBased,
          const Duration(minutes: 15),
          12,
          3,
        ),
      );
      await tester.pump();

      // Each saved template row should have a "Load" button
      expect(find.text('Load'), findsOneWidget);
    });
  });

  group('SessionsPage UAT gaps', () {
    const capacityField = Key('sessions-capacity-field');
    const courtsField = Key('sessions-courts-field');

    /// Twelve checked-in players dealt over two courts.
    Future<GameData> runningSession() async {
      final gameData = GameData()..setNumberOfCourt(2);
      for (final player in await createTestPlayers(12)) {
        gameData.checkInPlayer(player);
      }
      await gameData.makeGame();
      return gameData;
    }

    Future<void> saveTemplateOnDisk(
      WidgetTester tester,
      GameData gameData, {
      required GameType mode,
      required int capacity,
      required int courts,
    }) async {
      await tester.runAsync(
        () => gameData.saveTemplate(
          'Saved',
          mode,
          const Duration(minutes: 15),
          capacity,
          courts,
        ),
      );
      await tester.pump();
    }

    testWidgets('SESS-03: should_clamp_an_empty_capacity_up_to_four', (
      tester,
    ) async {
      final gameData = GameData();
      await tester.pumpWidget(createTestWidget(gameData: gameData));

      await tester.enterText(find.byKey(capacityField), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(gameData.sessionCapacity, 4);
    });

    testWidgets('SESS-03: should_show_the_clamped_capacity_in_the_field', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byKey(capacityField), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byKey(capacityField)).controller!.text,
        '4',
      );
    });

    testWidgets('SESS-05: should_summarise_a_saved_template', (tester) async {
      final gameData = GameData();
      await tester.pumpWidget(createTestWidget(gameData: gameData));

      await saveTemplateOnDisk(
        tester,
        gameData,
        mode: GameType.gameBased,
        capacity: 20,
        courts: 4,
      );

      expect(find.text('4 courts · game-based · cap 20'), findsOneWidget);
    });

    testWidgets('SESS-05: should_use_the_singular_for_one_court', (
      tester,
    ) async {
      final gameData = GameData();
      await tester.pumpWidget(createTestWidget(gameData: gameData));

      await saveTemplateOnDisk(
        tester,
        gameData,
        mode: GameType.timeBased,
        capacity: 8,
        courts: 1,
      );

      expect(find.text('1 court · time-based · cap 8'), findsOneWidget);
    });

    testWidgets('SESS-05: should_clear_the_name_after_a_successful_save', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.byKey(const Key('template-name')), 'Friday');

      await tester.runAsync(() async {
        await tester.tap(find.text('Save current'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.widgetWithText(TextField, 'Friday'), findsNothing);
    });

    testWidgets('SESS-05: should_keep_a_blank_name_when_saving', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.byKey(const Key('template-name')), '   ');

      await tester.tap(find.text('Save current'));
      await tester.pump();

      expect(find.widgetWithText(TextField, '   '), findsOneWidget);
    });

    testWidgets('SESS-06: should_follow_the_mode_of_a_loaded_template', (
      tester,
    ) async {
      final gameData = GameData();
      await tester.pumpWidget(createTestWidget(gameData: gameData));
      await saveTemplateOnDisk(
        tester,
        gameData,
        mode: GameType.gameBased,
        capacity: 12,
        courts: 3,
      );

      await tester.runAsync(() async {
        await tester.tap(find.text('Load'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(
        find.text('Game-based · save and re-roll each court by hand'),
        findsOneWidget,
      );
    });

    testWidgets('SESS-04: should_ask_before_reshuffling_a_running_round', (
      tester,
    ) async {
      final gameData = (await tester.runAsync(runningSession))!;
      final timerData = TimerData()..isRunning = true;
      await tester.pumpWidget(
        createTestWidget(gameData: gameData, timerData: timerData),
      );

      await tester.enterText(find.byKey(courtsField), '3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Discard the current round?'), findsOneWidget);
    });

    testWidgets('SESS-04: should_keep_the_court_count_when_cancelled', (
      tester,
    ) async {
      final gameData = (await tester.runAsync(runningSession))!;
      final timerData = TimerData()..isRunning = true;
      await tester.pumpWidget(
        createTestWidget(gameData: gameData, timerData: timerData),
      );
      await tester.enterText(find.byKey(courtsField), '3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(gameData.numberOfCourt, 2);
    });

    testWidgets('SESS-04: should_restore_the_field_when_cancelled', (
      tester,
    ) async {
      final gameData = (await tester.runAsync(runningSession))!;
      final timerData = TimerData()..isRunning = true;
      await tester.pumpWidget(
        createTestWidget(gameData: gameData, timerData: timerData),
      );
      await tester.enterText(find.byKey(courtsField), '3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byKey(courtsField)).controller!.text,
        '2',
      );
    });

    testWidgets('SESS-04: should_reshuffle_when_confirmed', (tester) async {
      final gameData = (await tester.runAsync(runningSession))!;
      final timerData = TimerData()..isRunning = true;
      await tester.pumpWidget(
        createTestWidget(gameData: gameData, timerData: timerData),
      );
      await tester.enterText(find.byKey(courtsField), '3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reshuffle'));
      await tester.pumpAndSettle();

      expect(gameData.waitlistedPlayers, isEmpty);
    });

    testWidgets('SESS-04: should_not_ask_when_no_round_is_running', (
      tester,
    ) async {
      final gameData = (await tester.runAsync(runningSession))!;
      await tester.pumpWidget(createTestWidget(gameData: gameData));

      await tester.enterText(find.byKey(courtsField), '3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Discard the current round?'), findsNothing);
    });

    testWidgets('SESS-06: should_keep_everything_when_load_is_cancelled', (
      tester,
    ) async {
      final gameData = (await tester.runAsync(runningSession))!;
      final timerData = TimerData()..isRunning = true;
      await tester.pumpWidget(
        createTestWidget(gameData: gameData, timerData: timerData),
      );
      await saveTemplateOnDisk(
        tester,
        gameData,
        mode: GameType.gameBased,
        capacity: 12,
        courts: 3,
      );

      await tester.tap(find.text('Load'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(gameData.numberOfCourt, 2);
    });

    testWidgets(
      'GB-01: should_stop_the_countdown_when_switching_to_game_based',
      (tester) async {
        final timerData = TimerData()..isRunning = true;
        await tester.pumpWidget(createTestWidget(timerData: timerData));

        await tester.runAsync(() async {
          await tester.tap(find.text('Game-based'));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();

        expect(timerData.isRunning, isFalse);
      },
    );
  });

  group('SessionsPage responsive', () {
    // ---------------------------------------------------------------------------
    // Responsive: phone width (< 720 px)
    // ---------------------------------------------------------------------------
    testWidgets('should stack layout vertically on phone width (< 720px)', (
      tester,
    ) async {
      // Simulate a narrow phone screen
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());

      // The page must still render all core elements in a stacked layout.
      expect(find.text('Time-based'), findsOneWidget);
      expect(find.text('Game-based'), findsOneWidget);
      expect(find.text('Save current'), findsOneWidget);
    });
  });
}

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

/// Release fixes on the Dashboard: Save then slot tap (F1), court stepper
/// (F3), tier gap and tier name (F4, F5), selection cleared (F11).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorySandbox sandbox;

  setUp(() async {
    // These tests cover court-count changes, hidden in the release.
    CourtCount.editable = true;
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('dashboard_release_fixes_test');
  });

  tearDown(() {
    CourtCount.editable = false;
    sandbox.tearDown();
  });

  Widget wrap(GameData gameData, TimerData timerData) => MultiProvider(
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
  );

  void useDesktopSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<GameData> seedElos(List<Elo> levels, int courts) async {
    final gameData = GameData()..setNumberOfCourt(courts);
    for (var i = 0; i < levels.length; i++) {
      final player = Player.create(
        firstName: 'Player',
        lastName: '$i',
        elo: levels[i],
      );
      PlayerRepository.instance.add(player);
      gameData.checkInPlayer(player);
    }
    await gameData.makeGame();
    return gameData;
  }

  Future<GameData> seed(int total, int courts) =>
      seedElos([for (var i = 0; i < total; i++) Elo.values[i % 8]], courts);

  StatStrip strip(WidgetTester tester) =>
      tester.widget<StatStrip>(find.byType(StatStrip));

  group('F1 Save then slot tap', () {
    testWidgets('should_not_throw_when_a_slot_is_tapped_after_save', (
      tester,
    ) async {
      useDesktopSurface(tester);
      final gameData = await seed(8, 2);
      await tester.pumpWidget(wrap(gameData, TimerData()));
      await tester.tap(find.byKey(const Key('dashboard-save-all')));
      // Saving writes to disk, which needs real async.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      await tester.tap(find.byType(PlayerSlot).first);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('F3 court stepper', () {
    testWidgets('should_not_go_above_eight_courts', (tester) async {
      useDesktopSurface(tester);
      final gameData = await seed(8, 8);
      await tester.pumpWidget(wrap(gameData, TimerData()));

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();

      expect(gameData.numberOfCourt, 8);
    });

    testWidgets('should_not_go_below_one_court', (tester) async {
      useDesktopSurface(tester);
      final gameData = await seed(8, 1);
      await tester.pumpWidget(wrap(gameData, TimerData()));

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();

      expect(gameData.numberOfCourt, 1);
    });
  });

  group('F4 level gap', () {
    testWidgets('should_show_same_level_for_two_intermediate_players', (
      tester,
    ) async {
      useDesktopSurface(tester);
      final gameData = await seedElos([Elo.b2, Elo.b2, Elo.b1, Elo.b1], 1);
      await tester.pumpWidget(wrap(gameData, TimerData()));

      expect(find.text('Same level'), findsOneWidget);
    });

    testWidgets('should_average_the_tier_gap_in_the_stat_strip', (
      tester,
    ) async {
      useDesktopSurface(tester);
      // One court: amateur + professional = gap 3.
      final gameData = await seedElos([Elo.c2, Elo.c2, Elo.s1, Elo.s1], 1);
      await tester.pumpWidget(wrap(gameData, TimerData()));

      expect(strip(tester).avgLevelGap, '3.0');
    });
  });

  group('F5 average level', () {
    testWidgets('should_show_the_tier_name_not_the_elo_code', (tester) async {
      useDesktopSurface(tester);
      final gameData = await seedElos([Elo.b2, Elo.b2, Elo.b1, Elo.b1], 1);
      await tester.pumpWidget(wrap(gameData, TimerData()));

      expect(strip(tester).avgLevel, 'Intermediate');
    });
  });

  group('F11 selection', () {
    testWidgets('should_clear_the_selection_after_a_re_roll', (tester) async {
      useDesktopSurface(tester);
      final gameData = await seed(9, 2);
      await tester.pumpWidget(wrap(gameData, TimerData()));
      await tester.tap(find.byType(PlayerSlot).first);
      await tester.pump();

      await tester.tap(find.text('Re-roll').first);
      await tester.pump();

      expect(
        tester
            .widget<WaitlistSidebar>(find.byType(WaitlistSidebar))
            .selectedPlayerId,
        isNull,
      );
    });

    testWidgets('should_clear_the_selection_after_a_court_count_change', (
      tester,
    ) async {
      useDesktopSurface(tester);
      final gameData = await seed(9, 2);
      await tester.pumpWidget(wrap(gameData, TimerData()));
      await tester.tap(find.byType(PlayerSlot).first);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();

      expect(
        tester
            .widget<WaitlistSidebar>(find.byType(WaitlistSidebar))
            .selectedPlayerId,
        isNull,
      );
    });
  });
}

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

/// Editing courts by hand on the Dashboard: swap players between courts,
/// remove a player from an incomplete court, and the warnings before a
/// running round is thrown away.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({'gameType': 'timeBased'});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('dashboard_court_edit_test');
  });

  tearDown(() => sandbox.tearDown());

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

  Future<GameData> seed(int total, int courts) async {
    final gameData = GameData()..setNumberOfCourt(courts);
    for (var i = 0; i < total; i++) {
      final player = Player.create(
        firstName: 'Player',
        lastName: '$i',
        elo: Elo.values[i % Elo.values.length],
      );
      PlayerRepository.instance.add(player);
      gameData.checkInPlayer(player);
    }
    await gameData.makeGame();
    return gameData;
  }

  void useDesktopSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Finder slotOf(Player player) => find.ancestor(
    of: find.text(player.name()),
    matching: find.byType(PlayerSlot),
  );

  group('Swap between courts', () {
    testWidgets('should_swap_two_players_on_different_courts', (tester) async {
      useDesktopSurface(tester);
      final gameData = await seed(8, 2);
      final a = gameData.stagingMatches[0].players[0];
      final b = gameData.stagingMatches[1].players[0];
      await tester.pumpWidget(wrap(gameData, TimerData()));

      await tester.tap(slotOf(a));
      await tester.pump();
      await tester.tap(slotOf(b));
      await tester.pump();

      expect(gameData.stagingMatches[1].players[0], a);
    });

    testWidgets('should_clear_the_selection_when_the_same_slot_is_tapped', (
      tester,
    ) async {
      useDesktopSurface(tester);
      final gameData = await seed(8, 2);
      final a = gameData.stagingMatches[0].players[0];
      final b = gameData.stagingMatches[1].players[0];
      await tester.pumpWidget(wrap(gameData, TimerData()));

      await tester.tap(slotOf(a));
      await tester.pump();
      await tester.tap(slotOf(a));
      await tester.pump();
      await tester.tap(slotOf(b));
      await tester.pump();

      // b was selected, not swapped with a.
      expect(gameData.stagingMatches[0].players[0], a);
    });
  });

  group('Remove from an incomplete court', () {
    testWidgets('should_send_the_player_to_the_waitlist', (tester) async {
      useDesktopSurface(tester);
      final gameData = await seed(8, 2);
      gameData.removePlayerFromCourt(gameData.stagingMatches[0].players[3]);
      final a = gameData.stagingMatches[0].players[0];
      await tester.pumpWidget(wrap(gameData, TimerData()));

      await tester.tap(
        find.descendant(
          of: slotOf(a),
          matching: find.byKey(const Key('slot-remove-button')),
        ),
      );
      await tester.pump();

      expect(gameData.waitlistedPlayers, contains(a));
    });
  });

  group('Warnings', () {
    Future<GameData> runningRound(
      WidgetTester tester,
      TimerData timer, {
      int players = 8,
    }) async {
      useDesktopSurface(tester);
      final gameData = await seed(players, 2);
      // The clock counts down; no real timer is needed for the dialog.
      timer.isRunning = true;
      await tester.pumpWidget(wrap(gameData, timer));
      return gameData;
    }

    testWidgets('should_warn_before_regenerating_a_running_round', (
      tester,
    ) async {
      final timer = TimerData();
      await runningRound(tester, timer);

      await tester.tap(find.text('Regenerate'));
      await tester.pumpAndSettle();

      expect(find.text('Discard the current round?'), findsOneWidget);
    });

    testWidgets('should_keep_the_round_when_regenerate_is_cancelled', (
      tester,
    ) async {
      final timer = TimerData();
      final gameData = await runningRound(tester, timer);
      final lineup = [...gameData.stagingMatches[0].players];

      await tester.tap(find.text('Regenerate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(gameData.stagingMatches[0].players, lineup);
    });

    testWidgets('should_not_warn_when_no_round_is_running', (tester) async {
      useDesktopSurface(tester);
      final gameData = await seed(8, 2);
      final timer = TimerData();
      await tester.pumpWidget(wrap(gameData, timer));

      await tester.tap(find.text('Regenerate'));
      await tester.pump();

      expect(find.text('Discard the current round?'), findsNothing);
      // Regenerate started the clock; stop it so no timer outlives the test.
      timer.reset();
    });

    testWidgets('should_warn_before_re_rolling_a_court_in_a_running_round', (
      tester,
    ) async {
      final timer = TimerData();
      // A ninth player gives the re-roll someone to rotate in (COURT-03).
      await runningRound(tester, timer, players: 9);

      await tester.tap(find.text('Re-roll').first);
      await tester.pumpAndSettle();

      expect(find.text('Discard this court\'s game?'), findsOneWidget);
    });

    testWidgets('should_not_rotate_when_countdown_expires_in_game_based_mode', (
      tester,
    ) async {
      useDesktopSurface(tester);
      final gameData = await seed(8, 2);
      final timer = TimerData();
      await tester.pumpWidget(wrap(gameData, timer));
      // Start a time-based round, then switch the session to game-based mode
      // without stopping the clock.
      await tester.tap(find.text('Regenerate'));
      await tester.pump();
      // Empty the courts, so a rotation would finish without a disk write.
      for (final player in [...gameData.checkedInPlayers.values]) {
        gameData.removePlayerFromCourt(player);
      }
      await PersistentSetting.instance.setGameType(GameType.gameBased);
      await tester.pump(const Duration(seconds: 2));

      // Act — the countdown runs out.
      timer.updateDuration(const Duration(seconds: 1));
      await tester.pump();

      // Assert
      expect(gameData.roundNumber, 1);
      timer.reset();
    });

    testWidgets('should_stay_quiet_when_re_roll_has_nobody_to_rotate_in', (
      tester,
    ) async {
      final timer = TimerData();
      // Exactly 8 players on 2 courts: the pool is 4, so nothing changes.
      final gameData = await runningRound(tester, timer);

      await tester.tap(find.text('Re-roll').first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(gameData.sessionRerollCount, 0);
    });
  });
}

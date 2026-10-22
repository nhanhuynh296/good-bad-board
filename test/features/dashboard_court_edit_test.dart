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

/// Editing courts by hand on the desktop Courts tab (8.5): swap players
/// between courts, move a player to the waitlist, and a quiet Re-roll.
///
/// The old warnings before a running round was thrown away ("Discard the
/// current round?" on Regenerate and Re-roll, and the game-based rotation
/// guard) went with the PR 45 flow in 8.2.2. The new confirm dialogs are in
/// `courts_confirm_dialog_test.dart`.
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
    gameData.generateFirstRound();
    return gameData;
  }

  void useDesktopSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Finder slotOf(Player player) => find.ancestor(
    of: find.text(player.name()),
    matching: find.byType(DesktopPlayerSlot),
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

  group('Move to waitlist', () {
    testWidgets('should_send_the_player_to_the_waitlist', (tester) async {
      useDesktopSurface(tester);
      final gameData = await seed(8, 2);
      gameData.removePlayerFromCourt(gameData.stagingMatches[0].players[3]);
      final a = gameData.stagingMatches[0].players[0];
      await tester.pumpWidget(wrap(gameData, TimerData()));

      await tester.tap(find.byKey(const Key('slot-more-0-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to waitlist'));
      await tester.pumpAndSettle();

      expect(gameData.waitlistedPlayers, contains(a));
    });
  });

  group('Re-roll', () {
    testWidgets('should_stay_quiet_when_re_roll_has_nobody_to_rotate_in', (
      tester,
    ) async {
      useDesktopSurface(tester);
      // Exactly 8 players on 2 courts: the pool is 4, so nothing changes.
      final gameData = await seed(8, 2);
      await tester.pumpWidget(wrap(gameData, TimerData()));

      await tester.tap(find.text('Re-roll').first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(gameData.sessionRerollCount, 0);
    });
  });
}

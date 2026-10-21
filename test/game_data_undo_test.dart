import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

// IMPLEMENTATION 8.3: the swap Undo, one level, 10 s (UAT COURT-17,
// R6-Q6, R7-Q2, R9-Q8).

void main() {
  late RepositorySandbox sandbox;
  late TimerData timer;
  late GameData gameData;
  late List<Player> players;
  late DateTime now;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('game_data_undo_test');
    timer = TimerData()..duration = const Duration(minutes: 10);
    now = DateTime(2026, 10, 21, 19);
    gameData = GameData(timer: timer, random: Random(3), clock: () => now);
    // 18 players on 4 courts: 16 seated, 2 waiting.
    players = await createTestPlayers(18);
    players.forEach(gameData.checkInPlayer);
    gameData.generateFirstRound();
  });

  tearDown(() {
    timer.dispose();
    sandbox.tearDown();
  });

  List<List<String>> ids(GameContainer lineup) => [
    for (final game in lineup) List.of(game.playerIds),
  ];

  Player onCourt(int court, [int slot = 0]) => PlayerRepository.instance.byId(
    gameData.visibleMatches[court].playerIds[slot],
  )!;

  Player waiting() => gameData.visibleWaitlistedPlayers.first;

  group('swap (COURT-08, COURT-10)', () {
    test('should_trade_places_when_two_court_players_swapped', () {
      final a = onCourt(0, 1);
      final b = onCourt(1, 2);

      gameData.swapPlayers(a, b);

      expect(
        [
          gameData.visibleMatches[0].playerIds[1],
          gameData.visibleMatches[1].playerIds[2],
        ],
        [b.id, a.id],
      );
    });

    test('should_seat_waitlisted_player_when_swapped_with_court_player', () {
      final seated = onCourt(2, 3);
      final waiter = waiting();

      gameData.swapPlayers(waiter, seated);

      expect(gameData.visibleMatches[2].playerIds[3], waiter.id);
    });

    test('should_waitlist_court_player_when_swapped_with_waitlisted', () {
      final seated = onCourt(2, 3);
      final waiter = waiting();

      gameData.swapPlayers(waiter, seated);

      expect(gameData.visibleWaitlistedPlayers, contains(seated));
    });

    test('should_refuse_swap_when_neither_player_is_on_a_court', () {
      final [first, second] = gameData.visibleWaitlistedPlayers.toList();

      expect(gameData.swapPlayers(first, second), isFalse);
    });

    test('should_refuse_swap_when_live_clock_runs', () {
      gameData.startFirstRound();

      expect(gameData.swapPlayers(onCourt(0), onCourt(1)), isFalse);
    });

    test('should_swap_round_n_plus_1_when_edit_mode_open', () {
      gameData.startFirstRound();
      final live = ids(gameData.stagingMatches);
      gameData.makeNextRound();

      gameData.swapPlayers(onCourt(0), onCourt(1));

      expect(ids(gameData.stagingMatches), live);
    });
  });

  group('Undo (COURT-17)', () {
    test('should_offer_undo_when_players_swapped', () {
      gameData.swapPlayers(onCourt(0), onCourt(1));

      expect(gameData.canUndoSwap, isTrue);
    });

    test('should_name_both_players_when_swapped', () {
      final a = onCourt(0);
      final b = onCourt(1);

      gameData.swapPlayers(a, b);

      expect(gameData.lastSwap, (a, b));
    });

    test('should_not_offer_undo_before_any_swap', () {
      expect(gameData.canUndoSwap, isFalse);
    });

    test('should_restore_places_when_swap_undone', () {
      final before = ids(gameData.visibleMatches);
      gameData.swapPlayers(onCourt(0), onCourt(1));

      gameData.undoSwap();

      expect(ids(gameData.visibleMatches), before);
    });

    test('should_restore_waitlist_when_waitlisted_swap_undone', () {
      final waiter = waiting();
      gameData.swapPlayers(waiter, onCourt(3));

      gameData.undoSwap();

      expect(gameData.visibleWaitlistedPlayers, contains(waiter));
    });

    test('should_clear_undo_when_swap_undone', () {
      gameData.swapPlayers(onCourt(0), onCourt(1));

      gameData.undoSwap();

      expect(gameData.canUndoSwap, isFalse);
    });

    test('should_keep_undo_when_9_seconds_pass', () {
      gameData.swapPlayers(onCourt(0), onCourt(1));

      now = now.add(const Duration(seconds: 9));

      expect(gameData.canUndoSwap, isTrue);
    });

    test('should_expire_undo_when_10_seconds_pass', () {
      gameData.swapPlayers(onCourt(0), onCourt(1));

      now = now.add(GameData.swapUndoWindow);

      expect(gameData.canUndoSwap, isFalse);
    });

    test('should_keep_swapped_places_when_undo_tried_after_expiry', () {
      gameData.swapPlayers(onCourt(0), onCourt(1));
      final after = ids(gameData.visibleMatches);
      now = now.add(GameData.swapUndoWindow);

      gameData.undoSwap();

      expect(ids(gameData.visibleMatches), after);
    });

    test('should_clear_undo_when_player_checks_in', () async {
      gameData.swapPlayers(onCourt(0), onCourt(1));
      final late = Player.create(firstName: 'Late', lastName: 'X', elo: Elo.b1);
      await PlayerRepository.instance.add(late);

      gameData.checkInPlayer(late);

      expect(gameData.canUndoSwap, isFalse);
    });

    test('should_clear_undo_when_player_checks_out', () {
      gameData.swapPlayers(onCourt(0), onCourt(1));

      gameData.checkOutPlayer(onCourt(2));

      expect(gameData.canUndoSwap, isFalse);
    });

    test('should_clear_undo_when_round_changes', () {
      gameData.swapPlayers(onCourt(0), onCourt(1));

      gameData.startFirstRound();

      expect(gameData.canUndoSwap, isFalse);
    });

    test('should_undo_only_last_swap_when_two_swaps_made', () {
      gameData.swapPlayers(onCourt(0), onCourt(1));
      final afterFirst = ids(gameData.visibleMatches);
      gameData.swapPlayers(onCourt(2), onCourt(3));

      gameData.undoSwap();

      expect(ids(gameData.visibleMatches), afterFirst);
    });

    test('should_not_offer_undo_when_player_moved_to_open_slot', () {
      // 16 seated, no one waiting: a check-out leaves an open slot.
      final full = GameData(timer: TimerData(), clock: () => now);
      players.take(16).forEach(full.checkInPlayer);
      full.generateFirstRound();
      final leaving = PlayerRepository.instance.byId(
        full.visibleMatches[0].playerIds[0],
      )!;
      full.checkOutPlayer(leaving);
      final mover = PlayerRepository.instance.byId(
        full.visibleMatches[1].playerIds[0],
      )!;

      full.placePlayerInSlot(mover, 0, 3);

      expect(full.canUndoSwap, isFalse);
    });

    test('should_log_nothing_when_swap_undone', () {
      gameData.swapPlayers(onCourt(0), onCourt(1));

      gameData.undoSwap();

      expect(gameData.history, isEmpty);
    });
  });
}

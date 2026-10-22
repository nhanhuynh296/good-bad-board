import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';

import 'support/next_round_steps.dart';
import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

/// R13-Q7, R13-Q8 (Nathan 2026-10-22): while the clock runs, the organizer
/// can put a waitlist player on a court that has no players (for example a
/// court just added). Courts with players stay locked (COURT-10). An added
/// court is filled by hand only. The log records the players on the court
/// when the round ends.
void main() {
  late RepositorySandbox sandbox;
  late TimerData timer;
  late GameData gameData;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('game_data_hand_fill_test');
    timer = TimerData()..duration = const Duration(minutes: 10);
    gameData = GameData(timer: timer, random: Random(5));
    for (final player in await createTestPlayers(20)) {
      gameData.checkInPlayer(player);
    }
  });

  tearDown(() {
    timer.dispose();
    sandbox.tearDown();
  });

  /// RUNNING on 4 courts with 4 players waiting, then a 5th court added.
  void runningWithNewCourt() {
    gameData.generateFirstRound();
    gameData.startFirstRound();
    gameData.setNumberOfCourt(5);
  }

  Player waiting(int index) => gameData.waitlistOrder[index];

  test('should_leave_an_added_court_empty', () {
    runningWithNewCourt();

    expect(gameData.stagingMatches[4].playerIds, isEmpty);
  });

  test('should_offer_hand_fill_on_an_empty_court_while_running', () {
    runningWithNewCourt();

    expect(gameData.canHandFillCourt(4), isTrue);
  });

  test('should_not_offer_hand_fill_on_a_court_with_players', () {
    runningWithNewCourt();

    expect(gameData.canHandFillCourt(0), isFalse);
  });

  test('should_put_a_waitlist_player_on_an_empty_court_while_running', () {
    runningWithNewCourt();
    final player = waiting(0);

    gameData.handFillSlot(player, 4, 0);

    expect(gameData.stagingMatches[4].playerIds, [player.id]);
  });

  test('should_keep_filling_a_court_that_was_empty', () {
    runningWithNewCourt();
    final first = waiting(0);
    final second = waiting(1);
    gameData.handFillSlot(first, 4, 0);

    gameData.handFillSlot(second, 4, 1);

    expect(gameData.stagingMatches[4].playerIds, [first.id, second.id]);
  });

  test('should_refuse_a_player_who_is_on_a_court', () {
    runningWithNewCourt();
    final onCourt = gameData.stagingMatches[0].players.first;

    final filled = gameData.handFillSlot(onCourt, 4, 0);

    expect(filled, isFalse);
  });

  test('should_refuse_hand_fill_on_a_court_one_player_short', () async {
    // Arrange — 3 courts with 12 players; in READY one player leaves court
    // 1 and nobody can fill the place. Then the round runs.
    final small = GameData(timer: TimerData(), random: Random(5))
      ..setNumberOfCourt(3);
    for (final player in await createTestPlayers(12)) {
      small.checkInPlayer(player);
    }
    small.generateFirstRound();
    final leaver = small.stagingMatches[0].players.first;
    small.moveToWaitlist(leaver);
    small.startFirstRound();

    // Act
    final filled = small.handFillSlot(leaver, 0, 3);

    // Assert
    expect(filled, isFalse);
  });

  test('should_offer_hand_fill_when_time_up', () {
    runningWithNewCourt();

    timer.elapse(const Duration(minutes: 10));

    expect(gameData.canHandFillCourt(4), isTrue);
  });

  test('should_offer_hand_fill_on_an_added_court_in_the_changeover', () {
    gameData.generateFirstRound();
    gameData.startFirstRound();
    gameData.saveAndStartNextRound();

    gameData.setNumberOfCourt(5);

    expect(gameData.canHandFillCourt(4), isTrue);
  });

  test('should_log_the_hand_filled_court_when_the_round_ends', () async {
    runningWithNewCourt();
    final players = [for (var i = 0; i < 4; i++) waiting(i)];
    for (final (slot, player) in players.indexed) {
      gameData.handFillSlot(player, 4, slot);
    }
    gameData.saveAndStartNextRound();

    await gameData.startNextNow();

    expect(
      gameData.history.last.map((game) => game.playerIds),
      contains([for (final player in players) player.id]),
    );
  });

  test('should_count_a_round_played_for_a_hand_filled_player', () async {
    runningWithNewCourt();
    final player = waiting(0);
    gameData.handFillSlot(player, 4, 0);
    gameData.saveAndStartNextRound();

    await gameData.startNextNow();

    expect(gameData.getCurrentPlayersHistory()[player], 1);
  });
}

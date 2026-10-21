import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

// UAT PLY-17: "{name} is in · waits for round {n}". {n} is the first round
// that has no saved lineup: the next round to start, or the round after a
// saved next round (1 before the first round starts).

void main() {
  late RepositorySandbox sandbox;
  late TimerData timer;
  late GameData gameData;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('game_data_waits_for_round_test');
    timer = TimerData()..duration = const Duration(minutes: 10);
    gameData = GameData(timer: timer, random: Random(3));
    (await createTestPlayers(16)).forEach(gameData.checkInPlayer);
  });

  tearDown(() {
    timer.reset();
    timer.dispose();
    sandbox.tearDown();
  });

  void toRunning() {
    gameData.generateFirstRound();
    gameData.startFirstRound();
  }

  test('should_wait_for_round_1_when_no_lineup', () {
    expect(gameData.waitsForRound, 1);
  });

  test('should_wait_for_round_1_when_round_1_is_a_draft', () {
    gameData.generateFirstRound();

    expect(gameData.waitsForRound, 1);
  });

  test('should_wait_for_next_round_when_running_and_next_not_saved', () {
    toRunning();

    expect(gameData.waitsForRound, 2);
  });

  test('should_wait_for_round_after_saved_round_when_running', () {
    toRunning();
    gameData.quickSaveNextRound();

    expect(gameData.waitsForRound, 3);
  });

  test('should_wait_for_next_round_when_paused_and_next_not_saved', () {
    toRunning();
    gameData.pause();

    expect(gameData.waitsForRound, 2);
  });

  test('should_wait_for_next_round_when_time_up', () {
    toRunning();
    timer.elapse(timer.duration);

    expect(gameData.waitsForRound, 2);
  });

  test('should_wait_for_round_after_the_starting_round_in_changeover', () {
    toRunning();
    gameData.quickSaveNextRound();
    gameData.startNextRound();

    expect(gameData.waitsForRound, 3);
  });

  test('should_wait_for_round_after_the_restarted_round_after_discard', () {
    toRunning();
    gameData.discardAndStartNext();

    expect(gameData.waitsForRound, 2);
  });
}

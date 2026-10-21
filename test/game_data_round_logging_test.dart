import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/session_log_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

// IMPLEMENTATION 8.2.1 and 8.2.4: a round is logged when the next round
// starts (R3-Q8), a discard logs nothing and keeps the number (R2-Q5, R9-Q1),
// and two fast clicks log once (R6-Q18). UAT RND-04, RND-06, RND-16, RND-19,
// RND-20.

void main() {
  late RepositorySandbox sandbox;
  late TimerData timer;
  late GameData gameData;
  late List<Player> players;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('game_data_round_logging_test');
    timer = TimerData()..duration = const Duration(minutes: 10);
    gameData = GameData(timer: timer, random: Random(3));
    players = await createTestPlayers(16);
    for (final player in players) {
      gameData.checkInPlayer(player);
    }
    gameData.generateFirstRound();
    gameData.startFirstRound();
  });

  tearDown(() {
    timer.dispose();
    sandbox.tearDown();
  });

  /// Puts a directory where the write's temp file goes, so the write fails.
  Directory blockWrites(String fileName) =>
      Directory('${sandbox.tempDir.path}/$fileName.tmp')..createSync();

  /// Runs the changeover to its end and waits for the round log.
  Future<void> endChangeover() async {
    timer.elapse(TimerData.changeoverLength);
    await gameData.settle();
  }

  void changeLineup() {
    final first = gameData.visibleMatches[0].players.first;
    gameData.placePlayerInSlot(first, 1, 0);
  }

  group('when a round is logged (R3-Q8, R6-Q2)', () {
    test('should_log_nothing_when_start_next_clicked', () {
      gameData.startNextRound();

      expect(gameData.history, isEmpty);
    });

    test('should_log_nothing_at_zero_when_next_round_saved', () async {
      gameData.quickSaveNextRound();

      timer.elapse(const Duration(minutes: 10));
      await gameData.settle();

      expect(gameData.history, isEmpty);
    });

    test('should_log_nothing_when_time_up', () async {
      timer.elapse(const Duration(minutes: 10));
      await gameData.settle();

      expect(gameData.history, isEmpty);
    });

    test('should_log_round_n_when_changeover_ends', () async {
      gameData.startNextRound();

      await endChangeover();

      expect(gameData.history.length, 1);
    });

    test('should_write_round_n_games_when_changeover_ends', () async {
      final live = gameData.stagingMatches.map((g) => g.id).toSet();
      gameData.startNextRound();

      await endChangeover();

      expect(GameRepository.instance.getAll().map((g) => g.id).toSet(), live);
    });

    test('should_write_one_session_log_when_changeover_ends', () async {
      gameData.startNextRound();

      await endChangeover();

      expect(SessionLogRepository.instance.getAll().length, 1);
    });

    test('should_run_round_n_plus_1_when_changeover_ends', () async {
      gameData.startNextRound();

      await endChangeover();

      expect(gameData.phase, RoundPhase.running);
    });

    test('should_count_full_duration_when_changeover_ends', () async {
      gameData.startNextRound();

      await endChangeover();

      expect(timer.remaining, const Duration(minutes: 10));
    });

    test('should_make_saved_lineup_live_when_changeover_ends', () async {
      gameData.quickSaveNextRound();
      final saved = gameData.nextLineup!.map((g) => g.id).toList();
      gameData.startNextRound();

      await endChangeover();

      expect(gameData.stagingMatches.map((g) => g.id).toList(), saved);
    });

    test('should_have_no_next_round_when_changeover_ends', () async {
      gameData.startNextRound();

      await endChangeover();

      expect(gameData.nextLineup, isNull);
    });

    test('should_leave_edit_mode_when_changeover_ends_with_no_changes',
        () async {
      gameData.quickSaveNextRound();
      gameData.editNextRound();
      timer.elapse(const Duration(minutes: 10));

      await endChangeover();

      expect(gameData.isEditingNext, isFalse);
    });

    test('should_log_round_n_when_start_now_clicked', () async {
      gameData.startNextRound();

      await gameData.startNextNow();

      expect(gameData.history.length, 1);
    });
  });

  group('round number (8.2.1)', () {
    test('should_advance_round_number_when_round_logged', () async {
      gameData.startNextRound();

      await endChangeover();

      expect(gameData.roundNumber, 2);
    });

    test('should_log_nothing_when_discarded_round_changeover_ends', () async {
      gameData.discardAndStartNext();

      await endChangeover();

      expect(gameData.history, isEmpty);
    });

    test('should_keep_round_number_when_discarded_round_restarts', () async {
      gameData.discardAndStartNext();

      await endChangeover();

      expect(gameData.roundNumber, 1);
    });

    test('should_log_once_per_round_over_two_rounds', () async {
      gameData.startNextRound();
      await endChangeover();
      gameData.startNextRound();

      await endChangeover();

      expect(gameData.history.length, 2);
    });
  });

  group('changeover waits for an edit (RND-06, R9-Q4, R11-Q2)', () {
    Future<void> waiting() async {
      gameData.quickSaveNextRound();
      gameData.editNextRound();
      timer.elapse(const Duration(minutes: 10));
      changeLineup();
      await endChangeover();
    }

    test('should_log_nothing_while_changeover_waits', () async {
      await waiting();

      expect(gameData.history, isEmpty);
    });

    test('should_start_round_when_saved_while_changeover_waits', () async {
      await waiting();

      await gameData.saveNextRound();

      expect(
        (gameData.phase, gameData.history.length),
        (RoundPhase.running, 1),
      );
    });

    test('should_start_edited_round_when_saved_while_waiting', () async {
      await waiting();
      final edited = [
        for (final game in gameData.visibleMatches) List.of(game.playerIds),
      ];

      await gameData.saveNextRound();

      expect(
        [for (final game in gameData.stagingMatches) game.playerIds],
        edited,
      );
    });

    test('should_start_saved_round_unchanged_when_edit_closed', () async {
      gameData.quickSaveNextRound();
      final saved = [
        for (final game in gameData.nextLineup!) List.of(game.playerIds),
      ];
      gameData.editNextRound();
      timer.elapse(const Duration(minutes: 10));
      changeLineup();
      await endChangeover();

      await gameData.exitEditNext();

      expect(
        [for (final game in gameData.stagingMatches) game.playerIds],
        saved,
      );
    });

    test('should_not_start_round_when_start_now_clicked_while_waiting',
        () async {
      await waiting();

      await gameData.startNextNow();

      expect(gameData.history, isEmpty);
    });
  });

  group('end session (RND-20, R6-Q5)', () {
    test('should_log_running_round_once_when_session_ends', () async {
      await gameData.endSession();

      expect(gameData.history.length, 1);
    });

    test('should_write_running_round_when_session_ends', () async {
      await gameData.endSession();

      expect(SessionLogRepository.instance.getAll().length, 1);
    });

    test('should_log_ended_round_once_when_session_ends_in_changeover',
        () async {
      final ended = gameData.stagingMatches.map((g) => g.id).toSet();
      gameData.startNextRound();

      await gameData.endSession();

      expect(GameRepository.instance.getAll().map((g) => g.id).toSet(), ended);
    });

    test('should_log_time_up_round_when_session_ends', () async {
      timer.elapse(const Duration(minutes: 10));

      await gameData.endSession();

      expect(gameData.history.length, 1);
    });

    test('should_log_nothing_when_session_ends_after_discard', () async {
      gameData.discardAndStartNext();

      await gameData.endSession();

      expect(SessionLogRepository.instance.getAll(), isEmpty);
    });

    test('should_reset_round_number_when_session_ends', () async {
      gameData.startNextRound();
      await endChangeover();

      await gameData.endSession();

      expect(gameData.roundNumber, 1);
    });

    test('should_log_nothing_when_session_ends_in_ready', () async {
      final ready = GameData(timer: TimerData());
      for (final player in players) {
        ready.checkInPlayer(player);
      }
      ready.generateFirstRound();

      await ready.endSession();

      expect(SessionLogRepository.instance.getAll(), isEmpty);
    });
  });

  group('double-click guard (8.2.4, R6-Q18)', () {
    test('should_log_round_once_when_start_clicked_twice', () async {
      gameData.startNextRound();
      gameData.startNextRound();

      await endChangeover();

      expect(gameData.history.length, 1);
    });

    test('should_report_second_start_click_as_no_op', () {
      gameData.startNextRound();

      final second = gameData.startNextRound();

      expect(second, isFalse);
    });

    test('should_keep_changeover_time_when_start_clicked_twice', () {
      gameData.startNextRound();
      timer.elapse(const Duration(seconds: 5));

      gameData.startNextRound();

      expect(timer.remaining, const Duration(seconds: 15));
    });

    test('should_log_nothing_when_discard_confirmed_twice', () async {
      gameData.discardAndStartNext();
      gameData.discardAndStartNext();

      await endChangeover();

      expect(gameData.history, isEmpty);
    });

    test('should_start_one_changeover_when_time_up_save_clicked_twice',
        () async {
      gameData.makeNextRound();
      timer.elapse(const Duration(minutes: 10));

      await Future.wait([gameData.saveNextRound(), gameData.saveNextRound()]);
      await endChangeover();

      expect(gameData.history.length, 1);
    });

    test('should_log_round_once_when_start_now_clicked_twice', () async {
      gameData.startNextRound();

      await Future.wait([gameData.startNextNow(), gameData.startNextNow()]);

      expect(gameData.history.length, 1);
    });

    test('should_advance_round_once_when_start_now_clicked_twice', () async {
      gameData.startNextRound();

      await Future.wait([gameData.startNextNow(), gameData.startNextNow()]);

      expect(gameData.roundNumber, 2);
    });

    test('should_log_once_when_start_now_clicked_as_changeover_ends',
        () async {
      gameData.startNextRound();

      final click = gameData.startNextNow();
      timer.elapse(TimerData.changeoverLength);
      await click;
      await gameData.settle();

      expect(gameData.history.length, 1);
    });

    test('should_log_once_when_waiting_save_clicked_twice', () async {
      gameData.quickSaveNextRound();
      gameData.editNextRound();
      timer.elapse(const Duration(minutes: 10));
      changeLineup();
      await endChangeover();

      await Future.wait([gameData.saveNextRound(), gameData.saveNextRound()]);

      expect(gameData.history.length, 1);
    });

    test('should_save_one_next_round_when_strip_save_clicked_twice', () {
      gameData.quickSaveNextRound();
      final first = gameData.nextLineup;

      gameData.quickSaveNextRound();

      expect(identical(gameData.nextLineup, first), isTrue);
    });

    test('should_log_once_when_end_session_clicked_twice', () async {
      await Future.wait([gameData.endSession(), gameData.endSession()]);

      expect(SessionLogRepository.instance.getAll().length, 1);
    });
  });

  group('failed write (R45-01)', () {
    test('should_not_start_round_when_the_log_write_fails', () async {
      gameData.startNextRound();
      blockWrites(GameRepository.databaseFilename);

      await expectLater(gameData.startNextNow(), throwsA(anything));

      expect(gameData.phase, RoundPhase.changeover);
    });

    test('should_not_add_to_history_when_the_log_write_fails', () async {
      gameData.startNextRound();
      blockWrites(GameRepository.databaseFilename);

      await expectLater(gameData.startNextNow(), throwsA(anything));

      expect(gameData.history, isEmpty);
    });

    test('should_report_error_when_changeover_end_write_fails', () async {
      gameData.startNextRound();
      blockWrites(GameRepository.databaseFilename);

      await endChangeover();

      expect(gameData.roundLogError, isNotNull);
    });

    test('should_log_once_on_retry_after_a_failed_write', () async {
      gameData.startNextRound();
      final block = blockWrites(GameRepository.databaseFilename);
      await endChangeover();
      block.deleteSync();

      await gameData.startNextNow();

      expect(gameData.history.length, 1);
    });
  });
}

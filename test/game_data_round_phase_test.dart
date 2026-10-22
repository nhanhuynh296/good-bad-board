import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';
import 'support/next_round_steps.dart';

// IMPLEMENTATION 8.2: the round state machine. UAT RND-03…08, RND-10…20.

void main() {
  late RepositorySandbox sandbox;
  late TimerData timer;
  late GameData gameData;
  late List<Player> players;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('game_data_round_phase_test');
    timer = TimerData()..duration = const Duration(minutes: 10);
    gameData = GameData(timer: timer, random: Random(7));
    players = await createTestPlayers(16);
    for (final player in players) {
      gameData.checkInPlayer(player);
    }
  });

  tearDown(() {
    timer.dispose();
    sandbox.tearDown();
  });

  void running() {
    gameData.generateFirstRound();
    gameData.startFirstRound();
  }

  /// Moves the first player of court 1 to court 2, slot 0, in the round on
  /// screen: a swap, so an edit with a change.
  void changeLineup() {
    final first = gameData.visibleMatches[0].players.first;
    gameData.placePlayerInSlot(first, 1, 0);
  }

  List<List<String>> ids(GameContainer lineup) => [
    for (final game in lineup) List.of(game.playerIds),
  ];

  group('no lineup and draft (RND-12, RND-13)', () {
    test('should_start_with_no_lineup', () {
      expect(gameData.phase, RoundPhase.noLineup);
    });

    test('should_enter_ready_when_first_round_generated', () {
      gameData.generateFirstRound();

      expect(gameData.phase, RoundPhase.ready);
    });

    test('should_keep_clock_stopped_when_first_round_generated', () {
      gameData.generateFirstRound();

      expect(timer.isRunning, isFalse);
    });

    test('should_refuse_first_round_when_fewer_than_4_checked_in', () {
      final small = GameData(timer: TimerData());
      for (final player in players.take(3)) {
        small.checkInPlayer(player);
      }

      expect(small.generateFirstRound, throwsA(isA<NotEnoughPlayers>()));
    });

    test('should_stay_no_lineup_when_first_round_refused', () {
      final small = GameData(timer: TimerData());
      for (final player in players.take(3)) {
        small.checkInPlayer(player);
      }

      try {
        small.generateFirstRound();
      } on NotEnoughPlayers {
        // expected
      }

      expect(small.phase, RoundPhase.noLineup);
    });

    test('should_make_new_lineup_when_draft_regenerated', () {
      gameData.generateFirstRound();
      final before = gameData.stagingMatches.first.id;

      gameData.regenerateDraft();

      expect(gameData.stagingMatches.first.id, isNot(before));
    });

    test('should_stay_ready_when_draft_regenerated', () {
      gameData.generateFirstRound();

      gameData.regenerateDraft();

      expect(gameData.phase, RoundPhase.ready);
    });

    test('should_run_at_once_when_first_round_started', () {
      gameData.generateFirstRound();

      gameData.startFirstRound();

      expect(gameData.phase, RoundPhase.running);
    });

    test('should_count_from_full_duration_when_first_round_started', () {
      gameData.generateFirstRound();

      gameData.startFirstRound();

      expect(timer.remaining, const Duration(minutes: 10));
    });

    test('should_not_start_changeover_when_first_round_started', () {
      gameData.generateFirstRound();

      gameData.startFirstRound();

      expect(timer.isChangeover, isFalse);
    });

    test('should_refuse_first_round_start_when_no_lineup', () {
      final started = gameData.startFirstRound();

      expect(started, isFalse);
    });
  });

  group(
    'make, save and edit the next round (RND-05, RND-07, RND-08, RND-14)',
    () {
      test('should_open_edit_mode_when_next_round_made', () {
        running();

        gameData.generateNextRound();

        expect(gameData.isEditingNext, isTrue);
      });

      test('should_keep_live_courts_when_next_round_made', () {
        running();
        final live = ids(gameData.stagingMatches);

        gameData.generateNextRound();

        expect(ids(gameData.stagingMatches), live);
      });

      test('should_show_edit_lineup_when_next_round_made', () {
        running();

        gameData.generateNextRound();

        expect(
          identical(gameData.visibleMatches, gameData.stagingMatches),
          isFalse,
        );
      });

      test('should_refuse_second_next_round_when_one_is_saved', () {
        running();
        gameData.saveNewNextRound();

        final made = gameData.generateNextRound();

        expect(made, isFalse);
      });

      test('should_keep_clock_when_next_round_generated', () {
        running();
        timer.elapse(const Duration(minutes: 2));

        gameData.generateNextRound();

        expect(timer.remaining, const Duration(minutes: 8));
      });

      // R13-Q3 (Nathan 2026-10-22): round n+1 exists only after "Generate
      // next round". Nothing makes it before the click.
      test('should_have_no_next_round_before_generate', () {
        running();

        expect(gameData.nextLineup, isNull);
      });

      test('should_open_edit_mode_when_generated_in_paused', () {
        running();
        gameData.pause();

        gameData.generateNextRound();

        expect(gameData.isEditingNext, isTrue);
      });

      test('should_open_edit_mode_when_generated_in_time_up', () {
        running();
        timer.elapse(const Duration(minutes: 10));

        gameData.generateNextRound();

        expect(gameData.isEditingNext, isTrue);
      });

      test('should_refuse_generate_next_round_when_ready', () {
        gameData.generateFirstRound();

        final made = gameData.generateNextRound();

        expect(made, isFalse);
      });

      test('should_refuse_generate_next_round_in_changeover', () {
        running();
        gameData.saveAndStartNextRound();

        final made = gameData.generateNextRound();

        expect(made, isFalse);
      });

      test('should_save_next_round_and_leave_edit_mode', () async {
        running();
        gameData.generateNextRound();

        await gameData.saveNextRound();

        expect(
          (gameData.isNextRoundSaved, gameData.isEditingNext),
          (true, false),
        );
      });

      test('should_keep_edits_when_next_round_saved', () async {
        running();
        gameData.generateNextRound();
        changeLineup();
        final edited = ids(gameData.visibleMatches);

        await gameData.saveNextRound();

        expect(ids(gameData.nextLineup!), edited);
      });

      test('should_open_saved_lineup_when_next_round_edited', () {
        running();
        gameData.saveNewNextRound();
        final saved = ids(gameData.nextLineup!);

        gameData.editNextRound();

        expect(ids(gameData.visibleMatches), saved);
      });

      test('should_report_no_unsaved_edits_when_edit_mode_opens', () {
        running();

        gameData.generateNextRound();

        expect(gameData.hasUnsavedEdits, isFalse);
      });

      test('should_report_unsaved_edits_when_edit_lineup_changes', () {
        running();
        gameData.generateNextRound();

        changeLineup();

        expect(gameData.hasUnsavedEdits, isTrue);
      });

      test('should_keep_edit_mode_when_next_round_regenerated', () {
        running();
        gameData.generateNextRound();

        gameData.regenerateNext();

        expect(gameData.isEditingNext, isTrue);
      });

      test('should_drop_unsaved_next_round_when_edit_mode_closed', () async {
        running();
        gameData.generateNextRound();

        await gameData.exitEditNext();

        expect(gameData.nextLineup, isNull);
      });

      test('should_keep_saved_next_round_when_edit_mode_closed', () async {
        running();
        gameData.saveNewNextRound();
        final saved = ids(gameData.nextLineup!);
        gameData.editNextRound();
        changeLineup();

        await gameData.exitEditNext();

        expect(ids(gameData.nextLineup!), saved);
      });
    },
  );

  group('pause and resume (RND-17, RND-18)', () {
    test('should_pause_when_running', () {
      running();

      gameData.pause();

      expect(gameData.phase, RoundPhase.paused);
    });

    test('should_keep_edit_mode_when_paused', () {
      running();
      gameData.generateNextRound();

      gameData.pause();

      expect(gameData.isEditingNext, isTrue);
    });

    test('should_run_again_when_resumed', () {
      running();
      gameData.pause();

      gameData.resume();

      expect(gameData.phase, RoundPhase.running);
    });

    test('should_freeze_clock_when_paused', () {
      running();
      timer.elapse(const Duration(minutes: 1));
      gameData.pause();

      timer.elapse(const Duration(minutes: 1));

      expect(timer.remaining, const Duration(minutes: 9));
    });

    test('should_pause_changeover', () {
      running();
      gameData.saveAndStartNextRound();

      gameData.pause();

      expect(
        (gameData.phase, gameData.pausedFrom),
        (RoundPhase.paused, RoundPhase.changeover),
      );
    });

    test('should_resume_changeover', () {
      running();
      gameData.saveAndStartNextRound();
      gameData.pause();

      gameData.resume();

      expect(gameData.phase, RoundPhase.changeover);
    });

    test('should_refuse_pause_when_ready', () {
      gameData.generateFirstRound();

      final paused = gameData.pause();

      expect(paused, isFalse);
    });
  });

  group('0:00 (RND-03, RND-15)', () {
    test('should_start_changeover_at_zero_when_next_round_saved', () {
      running();
      gameData.saveNewNextRound();

      timer.elapse(const Duration(minutes: 10));

      expect(gameData.phase, RoundPhase.changeover);
    });

    test('should_count_20_s_at_zero_when_next_round_saved', () {
      running();
      gameData.saveNewNextRound();

      timer.elapse(const Duration(minutes: 10));

      expect(timer.remaining, TimerData.changeoverLength);
    });

    test('should_show_next_round_in_changeover', () {
      running();
      gameData.saveNewNextRound();

      timer.elapse(const Duration(minutes: 10));

      expect(identical(gameData.visibleMatches, gameData.nextLineup), isTrue);
    });

    test('should_keep_edit_mode_at_zero_when_next_round_saved', () {
      running();
      gameData.saveNewNextRound();
      gameData.editNextRound();

      timer.elapse(const Duration(minutes: 10));

      expect(gameData.isEditingNext, isTrue);
    });

    test('should_enter_time_up_at_zero_when_next_round_not_saved', () {
      running();

      timer.elapse(const Duration(minutes: 10));

      expect(gameData.phase, RoundPhase.timeUp);
    });

    // R13-Q4 (Nathan 2026-10-22): 0:00 makes no round n+1.
    test('should_make_no_next_round_at_zero_when_not_saved', () {
      running();

      timer.elapse(const Duration(minutes: 10));

      expect(gameData.nextLineup, isNull);
    });

    test('should_show_round_n_when_time_up', () {
      running();

      timer.elapse(const Duration(minutes: 10));

      expect(
        identical(gameData.visibleMatches, gameData.stagingMatches),
        isTrue,
      );
    });

    test('should_stop_the_clock_when_time_up', () {
      running();

      timer.elapse(const Duration(minutes: 10));

      expect(timer.isRunning, isFalse);
    });

    test('should_lock_round_n_courts_when_time_up', () {
      running();

      timer.elapse(const Duration(minutes: 10));

      expect(gameData.canEditCourts, isFalse);
    });

    test('should_keep_round_n_lineup_for_the_log_when_time_up', () {
      running();
      final live = ids(gameData.stagingMatches);

      timer.elapse(const Duration(minutes: 10));

      expect(ids(gameData.stagingMatches), live);
    });

    test('should_keep_edit_mode_at_zero_when_next_round_not_saved', () {
      running();
      gameData.generateNextRound();
      changeLineup();

      timer.elapse(const Duration(minutes: 10));

      expect(
        (gameData.phase, gameData.hasUnsavedEdits),
        (RoundPhase.timeUp, true),
      );
    });

    test('should_start_changeover_when_saved_in_time_up', () async {
      running();
      gameData.generateNextRound();
      timer.elapse(const Duration(minutes: 10));

      await gameData.saveNextRound();

      expect(gameData.phase, RoundPhase.changeover);
    });

    test(
      'should_drop_unsaved_next_round_when_edit_closed_in_time_up',
      () async {
        running();
        gameData.generateNextRound();
        timer.elapse(const Duration(minutes: 10));

        await gameData.exitEditNext();

        expect(gameData.nextLineup, isNull);
      },
    );
  });

  group('duration change while paused (R9-Q6, SESS-02)', () {
    test('should_enter_time_up_when_paused_past_new_duration', () {
      running();
      timer.elapse(const Duration(minutes: 3));
      gameData.pause();

      timer.updateDuration(const Duration(minutes: 2));

      expect(gameData.phase, RoundPhase.timeUp);
    });

    test('should_stay_paused_when_new_duration_leaves_time', () {
      running();
      timer.elapse(const Duration(minutes: 3));
      gameData.pause();

      timer.updateDuration(const Duration(minutes: 5));

      expect(gameData.phase, RoundPhase.paused);
    });
  });

  group('start round n+1 (RND-04, R12-Q1)', () {
    test('should_start_changeover_when_start_next_clicked_in_running', () {
      running();

      gameData.saveAndStartNextRound();

      expect(gameData.phase, RoundPhase.changeover);
    });

    test('should_start_changeover_when_start_next_clicked_in_paused', () {
      running();
      gameData.pause();

      gameData.saveAndStartNextRound();

      expect(gameData.phase, RoundPhase.changeover);
    });

    // R13-Q5 (Nathan 2026-10-22): "Start round n+1" only after round n+1
    // is saved.
    test('should_refuse_start_next_when_not_saved_in_running', () {
      running();

      final started = gameData.startNextRound();

      expect(started, isFalse);
    });

    test('should_refuse_start_next_when_not_saved_in_paused', () {
      running();
      gameData.pause();

      final started = gameData.startNextRound();

      expect(started, isFalse);
    });

    test('should_refuse_start_next_when_time_up', () {
      running();
      timer.elapse(const Duration(minutes: 10));

      final started = gameData.startNextRound();

      expect(started, isFalse);
    });

    test('should_refuse_start_next_in_paused_edit_of_a_new_round', () {
      running();
      gameData.generateNextRound();
      gameData.pause();

      final started = gameData.startNextRound();

      expect(started, isFalse);
    });

    test('should_use_saved_round_when_start_next_clicked', () {
      running();
      gameData.saveNewNextRound();
      final saved = ids(gameData.nextLineup!);

      gameData.saveAndStartNextRound();

      expect(ids(gameData.nextLineup!), saved);
    });

    test('should_save_edits_when_start_next_clicked_in_paused_edit_mode', () {
      running();
      gameData.saveNewNextRound();
      gameData.editNextRound();
      changeLineup();
      final edited = ids(gameData.visibleMatches);
      gameData.pause();

      gameData.startNextRound();

      expect(ids(gameData.nextLineup!), edited);
    });

    test(
      'should_leave_edit_mode_when_start_next_clicked_in_paused_edit_mode',
      () {
        running();
        gameData.saveNewNextRound();
        gameData.editNextRound();
        gameData.pause();

        gameData.startNextRound();

        expect(gameData.isEditingNext, isFalse);
      },
    );

    test('should_refuse_start_next_when_editing_while_running', () {
      running();
      gameData.generateNextRound();

      final started = gameData.saveAndStartNextRound();

      expect(started, isFalse);
    });

    test('should_refuse_start_next_when_ready', () {
      gameData.generateFirstRound();

      final started = gameData.saveAndStartNextRound();

      expect(started, isFalse);
    });

    test('should_need_confirm_when_running_with_time_left', () {
      running();

      expect(gameData.startNeedsConfirm, isTrue);
    });

    test('should_not_need_confirm_when_paused', () {
      running();

      gameData.pause();

      expect(gameData.startNeedsConfirm, isFalse);
    });

    test('should_not_need_confirm_when_time_up', () {
      running();

      timer.elapse(const Duration(minutes: 10));

      expect(gameData.startNeedsConfirm, isFalse);
    });

    test('should_report_time_left_for_the_confirm_text', () {
      running();

      timer.elapse(const Duration(minutes: 5, seconds: 48));

      expect(gameData.timeLeft, const Duration(minutes: 4, seconds: 12));
    });
  });

  group('discard round n and start again (RND-16)', () {
    test('should_start_changeover_when_discarded', () {
      running();

      gameData.discardAndStartNext();

      expect(gameData.phase, RoundPhase.changeover);
    });

    test('should_mark_changeover_discarded_when_discarded', () {
      running();

      gameData.discardAndStartNext();

      expect(gameData.discarded, isTrue);
    });

    test('should_label_new_round_with_same_number_when_discarded', () {
      running();

      gameData.discardAndStartNext();

      expect(gameData.displayRoundNumber, 1);
    });

    test('should_label_next_number_in_changeover_after_start', () {
      running();

      gameData.saveAndStartNextRound();

      expect(gameData.displayRoundNumber, 2);
    });

    test('should_refuse_discard_in_edit_mode', () {
      running();
      gameData.generateNextRound();
      gameData.pause();

      final discarded = gameData.discardAndStartNext();

      expect(discarded, isFalse);
    });
  });

  group('changeover end with edits (RND-06, R9-Q4)', () {
    test('should_wait_at_zero_when_changeover_ends_with_unsaved_edits', () {
      running();
      gameData.saveNewNextRound();
      gameData.editNextRound();
      timer.elapse(const Duration(minutes: 10));
      changeLineup();

      timer.elapse(TimerData.changeoverLength);

      expect(
        (gameData.phase, gameData.waitingForEdit),
        (RoundPhase.changeover, true),
      );
    });

    test('should_keep_waiting_when_next_round_regenerated', () {
      running();
      gameData.saveNewNextRound();
      gameData.editNextRound();
      timer.elapse(const Duration(minutes: 10));
      changeLineup();
      timer.elapse(TimerData.changeoverLength);

      gameData.regenerateNext();

      expect(gameData.waitingForEdit, isTrue);
    });

    test('should_refuse_pause_while_changeover_waits', () {
      running();
      gameData.saveNewNextRound();
      gameData.editNextRound();
      timer.elapse(const Duration(minutes: 10));
      changeLineup();
      timer.elapse(TimerData.changeoverLength);

      final paused = gameData.pause();

      expect(paused, isFalse);
    });
  });

  group('end session (RND-20)', () {
    test('should_return_to_no_lineup_when_session_ends', () async {
      running();

      await gameData.endSession();

      expect(gameData.phase, RoundPhase.noLineup);
    });

    test('should_check_out_everyone_when_session_ends', () async {
      running();

      await gameData.endSession();

      expect(gameData.checkedInCount, 0);
    });

    test('should_stop_clock_when_session_ends', () async {
      running();

      await gameData.endSession();

      expect(timer.isRunning, isFalse);
    });

    test('should_leave_empty_courts_when_session_ends', () async {
      running();

      await gameData.endSession();

      expect(gameData.hasAnyCourtLineup, isFalse);
    });

    test('should_leave_edit_mode_when_session_ends', () async {
      running();
      gameData.generateNextRound();

      await gameData.endSession();

      expect(gameData.isEditingNext, isFalse);
    });

    test('should_clear_rounds_played_when_session_ends', () async {
      running();
      gameData.saveAndStartNextRound();
      await gameData.startNextNow();

      await gameData.endSession();

      expect(gameData.history, isEmpty);
    });

    test('should_refuse_end_session_when_no_lineup', () async {
      final ended = await gameData.endSession();

      expect(ended, isFalse);
    });

    test('should_name_running_round_to_log', () {
      running();

      expect(gameData.roundToLog, 1);
    });

    test('should_name_ended_round_to_log_in_changeover', () {
      running();

      gameData.saveAndStartNextRound();

      expect(gameData.roundToLog, 1);
    });

    test('should_name_ended_round_to_log_in_paused_changeover', () {
      running();
      gameData.saveAndStartNextRound();

      gameData.pause();

      expect(gameData.roundToLog, 1);
    });

    test('should_name_no_round_to_log_in_changeover_after_discard', () {
      running();

      gameData.discardAndStartNext();

      expect(gameData.roundToLog, isNull);
    });

    test('should_name_no_round_to_log_when_ready', () {
      gameData.generateFirstRound();

      expect(gameData.roundToLog, isNull);
    });

    test('should_name_time_up_round_to_log', () {
      running();

      timer.elapse(const Duration(minutes: 10));

      expect(gameData.roundToLog, 1);
    });
  });

  test('should_hold_four_players_per_court_in_round_one', () {
    gameData.generateFirstRound();

    expect(
      gameData.stagingMatches.map((g) => g.playerIds.length),
      everyElement(Game.playerPerCourt),
    );
  });
}

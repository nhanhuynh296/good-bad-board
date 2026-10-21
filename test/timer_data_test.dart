import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/state/timer_data.dart';

/// F2: a new round length must reach the countdown, running or not.
void main() {
  test('should_set_remaining_to_new_duration_when_timer_is_stopped', () {
    final timer = TimerData()..reset();

    timer.updateDuration(const Duration(minutes: 5));

    expect(timer.remaining, const Duration(minutes: 5));
  });

  test('should_show_new_duration_label_when_timer_is_stopped', () {
    final timer = TimerData()..reset();

    timer.updateDuration(const Duration(minutes: 5, seconds: 30));

    expect(timer.remainingLabel, '05:30');
  });

  test('should_set_remaining_when_new_duration_equals_old_one', () {
    final timer = TimerData();

    timer.updateDuration(timer.duration);

    expect(timer.remaining, timer.duration);
  });

  testWidgets('should_keep_elapsed_time_when_timer_is_running', (tester) async {
    final timer = TimerData()..duration = const Duration(minutes: 10);
    timer.startRound();
    await tester.pump(const Duration(minutes: 1));

    timer.updateDuration(const Duration(minutes: 5));

    expect(timer.remaining, const Duration(minutes: 4));
    timer.dispose();
  });

  test('should_count_down_from_new_duration_when_started_after_update', () {
    final timer = TimerData()..reset();
    timer.updateDuration(const Duration(minutes: 5));

    timer.startRound();

    expect(timer.remaining, const Duration(minutes: 5));
    timer.dispose();
  });

  roundClockTests();
}

/// IMPLEMENTATION 8.2.3: the round clock and the 20 s changeover clock.
void roundClockTests() {
  group('default', () {
    test('should_default_to_10_minute_rounds', () {
      final timer = TimerData();

      expect(timer.duration, const Duration(minutes: 10));
    });
  });

  group('round clock', () {
    test('should_count_from_full_duration_when_round_starts', () {
      final timer = TimerData()..duration = const Duration(minutes: 10);

      timer.startRound();

      expect(timer.remaining, const Duration(minutes: 10));
      timer.dispose();
    });

    test('should_fill_progress_with_elapsed_time', () {
      final timer = TimerData()..duration = const Duration(minutes: 10);
      timer.startRound();

      timer.elapse(const Duration(minutes: 4));

      expect(timer.progress, closeTo(0.4, 1e-9));
      timer.dispose();
    });

    test('should_call_on_expired_when_round_reaches_zero', () {
      var expired = 0;
      final timer = TimerData()..duration = const Duration(seconds: 3);
      timer.startRound(onExpired: () => expired++);

      timer.elapse(const Duration(seconds: 3));

      expect(expired, 1);
      timer.dispose();
    });

    testWidgets('should_tick_once_per_second_when_round_runs', (tester) async {
      final timer = TimerData()..duration = const Duration(minutes: 10);
      timer.startRound();

      await tester.pump(const Duration(seconds: 3));

      expect(timer.remaining, const Duration(minutes: 9, seconds: 57));
      timer.dispose();
    });
  });

  group('pause', () {
    test('should_keep_remaining_time_when_paused', () {
      final timer = TimerData()..duration = const Duration(minutes: 10);
      timer.startRound();
      timer.elapse(const Duration(minutes: 1));

      timer.pause();
      timer.elapse(const Duration(minutes: 1));

      expect(timer.remaining, const Duration(minutes: 9));
      timer.dispose();
    });

    test('should_report_paused_when_paused', () {
      final timer = TimerData()..startRound();

      timer.pause();

      expect(timer.isPaused, isTrue);
      timer.dispose();
    });

    test('should_continue_from_paused_time_when_resumed', () {
      final timer = TimerData()..duration = const Duration(minutes: 10);
      timer.startRound();
      timer.elapse(const Duration(minutes: 1));
      timer.pause();

      timer.resume();
      timer.elapse(const Duration(seconds: 30));

      expect(timer.remaining, const Duration(minutes: 8, seconds: 30));
      timer.dispose();
    });
  });

  group('urgent (UX-09, R6-Q8)', () {
    test('should_be_urgent_when_running_with_60_s_left', () {
      final timer = TimerData()..duration = const Duration(minutes: 2);
      timer.startRound();

      timer.elapse(const Duration(minutes: 1));

      expect(timer.isUrgent, isTrue);
      timer.dispose();
    });

    test('should_not_be_urgent_when_running_with_61_s_left', () {
      final timer = TimerData()..duration = const Duration(seconds: 61);

      timer.startRound();

      expect(timer.isUrgent, isFalse);
      timer.dispose();
    });

    test('should_not_be_urgent_when_paused_with_60_s_left', () {
      final timer = TimerData()..duration = const Duration(minutes: 2);
      timer.startRound();
      timer.elapse(const Duration(minutes: 1));

      timer.pause();

      expect(timer.isUrgent, isFalse);
      timer.dispose();
    });

    test('should_not_be_urgent_during_changeover', () {
      final timer = TimerData();

      timer.startChangeover();

      expect(timer.isUrgent, isFalse);
      timer.dispose();
    });
  });

  group('changeover (R3-Q7, R4-Q5)', () {
    test('should_count_down_20_s_when_changeover_starts', () {
      final timer = TimerData();

      timer.startChangeover();

      expect(timer.remaining, const Duration(seconds: 20));
      timer.dispose();
    });

    test('should_report_changeover_when_changeover_starts', () {
      final timer = TimerData();

      timer.startChangeover();

      expect(timer.isChangeover, isTrue);
      timer.dispose();
    });

    test('should_fill_progress_over_20_s_when_changeover_runs', () {
      final timer = TimerData();
      timer.startChangeover();

      timer.elapse(const Duration(seconds: 5));

      expect(timer.progress, closeTo(0.25, 1e-9));
      timer.dispose();
    });

    test('should_freeze_changeover_when_paused', () {
      final timer = TimerData()..startChangeover();
      timer.elapse(const Duration(seconds: 5));

      timer.pause();
      timer.elapse(const Duration(seconds: 5));

      expect(timer.remaining, const Duration(seconds: 15));
      timer.dispose();
    });

    test('should_stop_at_zero_when_changeover_ends', () {
      final timer = TimerData()..startChangeover();

      timer.elapse(const Duration(seconds: 25));

      expect(timer.remaining, Duration.zero);
      timer.dispose();
    });

    test('should_keep_20_s_changeover_when_duration_changes', () {
      final timer = TimerData()..startChangeover();

      timer.updateDuration(const Duration(minutes: 5));

      expect(timer.remaining, const Duration(seconds: 20));
      timer.dispose();
    });

    test('should_count_round_from_full_duration_after_changeover', () {
      final timer = TimerData()..duration = const Duration(minutes: 10);
      timer.startChangeover();
      timer.elapse(const Duration(seconds: 20));

      timer.startRound();

      expect(timer.isChangeover, isFalse);
      timer.dispose();
    });
  });

  group('duration change while paused (R9-Q6, SESS-02)', () {
    test('should_apply_new_duration_minus_elapsed_when_paused', () {
      final timer = TimerData()..duration = const Duration(minutes: 10);
      timer.startRound();
      timer.elapse(const Duration(minutes: 3));
      timer.pause();

      timer.updateDuration(const Duration(minutes: 5));

      expect(timer.remaining, const Duration(minutes: 2));
      timer.dispose();
    });

    test('should_stay_paused_when_duration_changes_while_paused', () {
      final timer = TimerData()..duration = const Duration(minutes: 10);
      timer.startRound();
      timer.elapse(const Duration(minutes: 3));
      timer.pause();

      timer.updateDuration(const Duration(minutes: 5));
      timer.elapse(const Duration(minutes: 1));

      expect(timer.remaining, const Duration(minutes: 2));
      timer.dispose();
    });

    test('should_reach_zero_at_once_when_paused_past_new_duration', () {
      var expired = 0;
      final timer = TimerData()..duration = const Duration(minutes: 10);
      timer.startRound(onExpired: () => expired++);
      timer.elapse(const Duration(minutes: 3));
      timer.pause();

      timer.updateDuration(const Duration(minutes: 2));

      expect(expired, 1);
      timer.dispose();
    });
  });
}

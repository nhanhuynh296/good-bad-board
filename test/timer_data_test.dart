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
    timer.start();
    await tester.pump(const Duration(minutes: 1));

    timer.updateDuration(const Duration(minutes: 5));

    expect(timer.remaining, const Duration(minutes: 4));
    timer.dispose();
  });

  test('should_count_down_from_new_duration_when_started_after_update', () {
    final timer = TimerData()..reset();
    timer.updateDuration(const Duration(minutes: 5));

    timer.start();

    expect(timer.remaining, const Duration(minutes: 5));
    timer.dispose();
  });
}

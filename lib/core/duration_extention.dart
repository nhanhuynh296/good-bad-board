import 'package:intl/intl.dart';

extension DurationDisplay on Duration {
  static final template = NumberFormat('00');

  String toDisplayString() {
    final minutes = template.format(
      inMinutes.remainder(Duration.minutesPerHour),
    );
    final seconds = template.format(
      inSeconds.remainder(Duration.secondsPerMinute),
    );
    return '$minutes:$seconds';
  }
}

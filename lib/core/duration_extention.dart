import 'package:intl/intl.dart';

extension DurationDisplay on Duration {
  static final template = NumberFormat('00');

  int get inDisplayMinutes => inMinutes.remainder(Duration.minutesPerHour);

  int get inDisplaySeconds => inSeconds.remainder(Duration.secondsPerMinute);

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

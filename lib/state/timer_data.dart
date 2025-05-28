import 'package:flutter/material.dart';

class TimerData extends ChangeNotifier {
  Duration duration = const Duration(seconds: 10);
  Duration elapsed = Duration.zero;

  void setDuration(Duration newDuration) {
    duration = newDuration;
    notifyListeners();
  }

  void saveTimeElapsed(Duration elapsed) {
    this.elapsed = elapsed;
  }
}

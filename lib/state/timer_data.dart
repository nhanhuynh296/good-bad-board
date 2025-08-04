import 'package:flutter/material.dart';

class TimerData extends ChangeNotifier {
  Duration elapsed = Duration.zero;

  void saveTimeElapsed(Duration elapsed) {
    this.elapsed = elapsed;
  }
}

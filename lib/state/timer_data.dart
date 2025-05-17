import 'package:flutter/material.dart';

class TimerData extends ChangeNotifier {
  Duration duration = const Duration(minutes: 12);

  void setDuration(Duration newDuration) {
    duration = newDuration;
    notifyListeners();
  }
}

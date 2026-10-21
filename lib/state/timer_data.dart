import 'dart:async';

import 'package:flutter/material.dart';

/// Counts down the round clock and the changeover clock.
///
/// It only counts. [GameData] owns the round phase and decides what 0:00
/// means (IMPLEMENTATION 8.2): it starts the clock with [startRound] or
/// [startChangeover] and gets the `onExpired` call at 0:00.
///
/// Registered as a [ChangeNotifier] via Provider so the round bar can watch
/// it for live UI updates.
class TimerData extends ChangeNotifier {
  // ── Configuration ──────────────────────────────────────────────

  /// Default round length (R2-Q24).
  static const Duration defaultDuration = Duration(minutes: 10);

  /// Length of the changeover between two rounds, fixed (R3-Q7).
  static const Duration changeoverLength = Duration(seconds: 20);

  /// Round length.
  Duration duration = defaultDuration;

  /// Whether the clock is counting down now.
  bool isRunning = false;

  // ── Internal state ─────────────────────────────────────────────

  Timer? _timer;
  Duration _remaining = Duration.zero;
  VoidCallback? _onExpired;
  bool _isPaused = false;
  bool _isChangeover = false;

  // ── Derived getters ────────────────────────────────────────────

  /// Remaining time as a [Duration].
  Duration get remaining => _remaining;

  /// Whether the clock was paused and keeps its time for [resume].
  bool get isPaused => _isPaused;

  /// Whether the clock counts the 20 s changeover, not a round.
  bool get isChangeover => _isChangeover;

  /// Length of what the clock counts now: the round or the changeover.
  Duration get _length => _isChangeover ? changeoverLength : duration;

  /// Time counted since the round (or the changeover) started.
  Duration get elapsed {
    final value = _length - _remaining;
    return value.isNegative ? Duration.zero : value;
  }

  /// Elapsed ÷ length, from 0.0 to 1.0. The progress bar fills with it
  /// (R4-Q7).
  double get progress {
    if (_length == Duration.zero) return 0.0;
    return (elapsed.inMilliseconds / _length.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Whether the round is in its final minute: only while a round runs,
  /// never while paused or in the changeover (UX-09, R6-Q8).
  bool get isUrgent =>
      isRunning && !_isChangeover && _remaining.inSeconds <= 60;

  /// Formatted remaining time as `MM:SS`.
  String get remainingLabel {
    final mins = _remaining.inMinutes
        .remainder(60)
        .abs()
        .toString()
        .padLeft(2, '0');
    final secs = _remaining.inSeconds
        .remainder(60)
        .abs()
        .toString()
        .padLeft(2, '0');
    return '$mins:$secs';
  }

  // ── Lifecycle ──────────────────────────────────────────────────

  /// Starts a round clock from the full [duration].
  ///
  /// [onExpired] is called once when the round reaches 0:00.
  void startRound({VoidCallback? onExpired}) =>
      _begin(duration, changeover: false, onExpired: onExpired);

  /// Starts the 20 s changeover clock (R3-Q7).
  ///
  /// [onExpired] is called once when the changeover reaches 0:00.
  void startChangeover({VoidCallback? onExpired}) =>
      _begin(changeoverLength, changeover: true, onExpired: onExpired);

  void _begin(
    Duration length, {
    required bool changeover,
    VoidCallback? onExpired,
  }) {
    _onExpired = onExpired;
    _isChangeover = changeover;
    _isPaused = false;
    _remaining = length;
    isRunning = true;
    _startTicking();
    notifyListeners();
  }

  /// Pauses the countdown without resetting it (R3-Q1, R4-Q5).
  void pause() {
    _timer?.cancel();
    _timer = null;
    if (isRunning) _isPaused = true;
    isRunning = false;
    notifyListeners();
  }

  /// Continues a paused countdown from the paused time.
  void resume() {
    if (!_isPaused) return;
    _isPaused = false;
    isRunning = true;
    _startTicking();
    notifyListeners();
  }

  /// Stops the countdown and resets remaining time to the full [duration].
  void reset() {
    _timer?.cancel();
    _timer = null;
    isRunning = false;
    _isPaused = false;
    _isChangeover = false;
    _remaining = duration;
    notifyListeners();
  }

  /// Recalculates the countdown against a new duration.
  ///
  /// A round that runs or is paused keeps its elapsed time: remaining = new
  /// duration − elapsed (R9-Q6). At or below 0 the round reaches 0:00 at once
  /// and `onExpired` is called (SESS-02). A stopped clock shows the new
  /// duration at once. The changeover stays 20 s (R3-Q7).
  void updateDuration(Duration newDuration) {
    if (newDuration == duration && isRunning) return;
    final oldDuration = duration;
    duration = newDuration;

    if (_isChangeover && (isRunning || _isPaused)) {
      notifyListeners();
      return;
    }

    if (!isRunning && !_isPaused) {
      _remaining = newDuration;
      notifyListeners();
      return;
    }

    // Running or paused: keep the elapsed time (or expire now if the new
    // duration is shorter than the time already elapsed).
    final elapsed = oldDuration - _remaining;
    if (elapsed >= newDuration) {
      _expire();
      return;
    }
    _remaining = newDuration - elapsed;
    if (isRunning) _startTicking();
    notifyListeners();
  }

  /// Advances the clock by [time], one second at a time, as the periodic
  /// tick does. Tests use it instead of waiting.
  @visibleForTesting
  void elapse(Duration time) {
    for (var s = 0; s < time.inSeconds && isRunning; s++) {
      _tick();
    }
  }

  // ── Internal ───────────────────────────────────────────────────

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_remaining.inSeconds <= 0) {
      _expire();
      return;
    }
    _remaining -= const Duration(seconds: 1);
    if (_remaining.inSeconds <= 0) {
      _expire();
      return;
    }
    notifyListeners();
  }

  /// Stops the clock at 0:00 and calls `onExpired`.
  void _expire() {
    _timer?.cancel();
    _timer = null;
    isRunning = false;
    _isPaused = false;
    _remaining = Duration.zero;
    notifyListeners();
    _onExpired?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

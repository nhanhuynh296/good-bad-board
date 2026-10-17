import 'dart:async';

import 'package:flutter/material.dart';

/// Manages the countdown timer for round rotation.
///
/// Drives the [RoundRotationBar] with periodic ticks, urgency detection,
/// and an auto-rotation callback when the countdown reaches zero.
///
/// Registered as a [ChangeNotifier] via Provider so the dashboard can
/// watch it for live UI updates.
class TimerData extends ChangeNotifier {
  // ── Configuration ──────────────────────────────────────────────

  /// Round rotation duration.
  Duration duration = const Duration(minutes: 20);

  /// Whether the timer is currently running.
  bool isRunning = false;

  // ── Internal state ─────────────────────────────────────────────

  Timer? _timer;
  Duration _remaining = Duration.zero;
  VoidCallback? _onExpired;

  // ── Derived getters ────────────────────────────────────────────

  /// Remaining time as a [Duration].
  Duration get remaining => _remaining;

  /// Whether the countdown is in the urgent zone (≤ 60 seconds).
  bool get isUrgent => _remaining.inSeconds <= 60;

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

  /// Remaining time as a percentage (0.0 – 100.0).
  double get pct {
    if (duration == Duration.zero) return 0.0;
    return (_remaining.inMilliseconds / duration.inMilliseconds * 100.0).clamp(
      0.0,
      100.0,
    );
  }

  // ── Lifecycle ──────────────────────────────────────────────────

  /// Starts (or resumes) the countdown from the configured [duration].
  /// If the timer is already running this is a no-op.
  ///
  /// [onExpired] is called once when the countdown reaches zero,
  /// triggering auto-rotation (RND-03).
  void start({VoidCallback? onExpired}) {
    if (isRunning) return;
    _onExpired = onExpired;

    // If we're resuming from a paused state, keep the remaining time.
    // Otherwise, start fresh from the full duration.
    if (_remaining == Duration.zero) {
      _remaining = duration;
    }

    isRunning = true;
    _startTicking();
    notifyListeners();
  }

  /// Pauses the countdown without resetting it.
  void pause() {
    _timer?.cancel();
    _timer = null;
    isRunning = false;
    notifyListeners();
  }

  /// Stops the countdown and resets remaining time to the full [duration].
  void reset() {
    _timer?.cancel();
    _timer = null;
    isRunning = false;
    _remaining = duration;
    notifyListeners();
  }

  /// Recalculates the countdown against a new duration.
  ///
  /// A timer that is not running shows the new duration as its remaining
  /// time at once, so the next start counts down from it.
  ///
  /// If the new duration is shorter than the time already elapsed,
  /// remaining is clamped to zero and the timer fires immediately on
  /// the next tick (SESS-02).
  void updateDuration(Duration newDuration) {
    if (newDuration == duration && isRunning) return;
    final oldDuration = duration;
    duration = newDuration;

    if (!isRunning) {
      _remaining = newDuration;
      notifyListeners();
      return;
    }

    // Running: keep the elapsed time (or expire now if the new duration is
    // shorter than the time already elapsed).
    final elapsed = oldDuration - _remaining;
    if (elapsed >= newDuration) {
      _remaining = Duration.zero;
      _timer?.cancel();
      _timer = null;
      isRunning = false;
      notifyListeners();
      _onExpired?.call();
      return;
    }
    _remaining = newDuration - elapsed;
    _timer?.cancel();
    _timer = null;
    _startTicking();
    notifyListeners();
  }

  // ── Internal ───────────────────────────────────────────────────

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 0) {
        // Timer expired — trigger auto-rotation (RND-03).
        _timer?.cancel();
        _timer = null;
        isRunning = false;
        _remaining = Duration.zero;
        notifyListeners();
        _onExpired?.call();
        return;
      }

      _remaining -= const Duration(seconds: 1);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

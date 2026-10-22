import 'package:flutter/material.dart';
import 'package:good_bad_board/core/duration_extension.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/timer_data.dart';

/// The state chip, the time and the time colour of a round phase. The
/// Courts round bar and the session bar on the other tabs show the same
/// values (UAT RND-01, RND-02, NAV-10, NAV-11).
class RoundStatus {
  const RoundStatus(this.phase);

  final RoundPhase phase;

  /// The chip text: READY, RUNNING, PAUSED, TIME UP or CHANGEOVER
  /// (R6-Q12).
  String chip(AppLocalizations l10n) => switch (phase) {
    RoundPhase.noLineup || RoundPhase.ready => l10n.courts_chip_ready,
    RoundPhase.running => l10n.courts_chip_running,
    RoundPhase.paused => l10n.courts_chip_paused,
    RoundPhase.timeUp => l10n.courts_chip_time_up,
    RoundPhase.changeover => l10n.courts_chip_changeover,
  };

  /// The chip fill and text colour (ARCHITECTURE §1.1; TIME UP R11-Q5).
  (Color, Color) get chipColours => switch (phase) {
    RoundPhase.noLineup ||
    RoundPhase.ready => (AppColors.barTrack, AppColors.headerText),
    RoundPhase.running => (AppColors.success, AppColors.headerText),
    RoundPhase.paused => (AppColors.warningBg, AppColors.warningText),
    RoundPhase.timeUp => (AppColors.timeUpBg, AppColors.timeUpText),
    RoundPhase.changeover => (
      AppColors.accentPrimary,
      AppColors.accentOnPrimary,
    ),
  };

  /// Whether the clock has not started: no lineup or READY.
  bool get clockStopped =>
      phase == RoundPhase.noLineup || phase == RoundPhase.ready;

  /// The time as `mm:ss`: the full duration before the clock starts, else
  /// the time left.
  String time(TimerData timer) {
    if (clockStopped) return timer.duration.toDisplayString();
    return timer.remainingLabel;
  }

  /// The time colour, also the round bar progress fill (RND-02, R6-Q8,
  /// R11-Q5). Amber in the final minute while RUNNING, never PAUSED.
  Color timeColour(TimerData timer) => switch (phase) {
    RoundPhase.noLineup || RoundPhase.ready => AppColors.headerText,
    RoundPhase.running =>
      timer.isUrgent ? AppColors.urgentOnDark : AppColors.headerText,
    RoundPhase.paused => AppColors.headerSub,
    RoundPhase.timeUp => AppColors.timeUpTime,
    RoundPhase.changeover => AppColors.accentPrimary,
  };
}

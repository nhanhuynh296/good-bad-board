import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/courts/courts.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/shell/inset_focus_ring.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

/// The 40 px session bar under the desktop top nav, on every tab except
/// Courts (IMPLEMENTATION 8.6.2, ARCHITECTURE §2.1 SessionBar; UAT NAV-10,
/// NAV-11).
///
/// From the left: "ROUND n", the time, the state chip (the order of the
/// round bar, F29), the counts with "round n+1 saved" or "not saved", and
/// "View courts →". The whole bar is one link to Courts. A round change
/// shows no other message (R4-Q4).
///
/// It watches [GameData]; the time watches [TimerData] through its own
/// [Consumer], so a clock tick rebuilds only the time (R45-03).
class SessionBar extends StatefulWidget {
  const SessionBar({super.key, required this.onOpenCourts});

  /// Opens the Courts tab.
  final VoidCallback onOpenCourts;

  static const double height = 40;

  @override
  State<SessionBar> createState() => _SessionBarState();
}

class _SessionBarState extends State<SessionBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final gameData = context.watch<GameData>();
    final l10n = AppLocalizations.of(context)!;
    final viewCourts = l10n.shell_view_courts;
    return Semantics(
      link: true,
      child: Material(
        color: AppColors.barBg,
        child: InkWell(
          key: const Key('session-bar'),
          onTap: widget.onOpenCourts,
          onFocusChange: (value) => setState(() => _focused = value),
          splashFactory: NoSplash.splashFactory,
          focusColor: Colors.transparent,
          hoverColor: AppColors.headerBg,
          child: InsetFocusRing(
            focused: _focused,
            ringKey: const Key('session-bar-focus-ring'),
            child: SizedBox(
              height: SessionBar.height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  children: [
                    ..._status(gameData, l10n),
                    Expanded(
                      child: Text(
                        _counts(gameData, l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: AppColors.headerSub,
                        ),
                      ),
                    ),
                    const SizedBox(width: _gap),
                    Text(
                      viewCourts,
                      style: AppTypography.md.copyWith(
                        color: AppColors.headerText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const double _gap = 16;

  /// "ROUND n", the time and the chip; "No round yet" before the first
  /// lineup (NAV-11).
  List<Widget> _status(GameData gameData, AppLocalizations l10n) {
    final phase = gameData.phase;
    if (phase == RoundPhase.noLineup) {
      return [
        Text(
          l10n.shell_no_round_yet,
          style: AppTypography.md.copyWith(color: AppColors.headerText),
        ),
        const SizedBox(width: _gap),
      ];
    }
    final status = RoundStatus(phase);
    final (chipFill, chipText) = status.chipColours;
    return [
      Text(
        l10n.dashboard_round_label(gameData.displayRoundNumber),
        key: const Key('session-bar-round'),
        style: AppTypography.statLabel.copyWith(color: AppColors.headerSub),
      ),
      const SizedBox(width: _gap),
      Consumer<TimerData>(
        builder: (context, timer, _) => Text(
          status.time(timer),
          key: const Key('session-bar-time'),
          style: AppTypography.title.copyWith(
            color: status.timeColour(timer),
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1,
          ),
        ),
      ),
      const SizedBox(width: _gap),
      // The chip is a polite live region; the time is not (F24).
      Semantics(
        liveRegion: true,
        container: true,
        child: Container(
          key: const Key('session-bar-chip'),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: chipFill,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          child: Text(
            status.chip(l10n),
            style: AppTypography.statLabel.copyWith(color: chipText),
          ),
        ),
      ),
      const SizedBox(width: _gap),
    ];
  }

  /// "{in}/{capacity} in · {waiting} waiting", then "· round n+1 saved" or
  /// "· round n+1 not saved" while round n has its clock: RUNNING, PAUSED
  /// and TIME UP (R6-Q12). READY and the changeover show the counts only.
  String _counts(GameData gameData, AppLocalizations l10n) {
    final counts = l10n.courts_counts_in_waiting(
      gameData.checkedInCount,
      gameData.sessionCapacity,
      gameData.waitlistOrder.length,
    );
    final phase = gameData.phase;
    final roundClock =
        phase == RoundPhase.running ||
        phase == RoundPhase.timeUp ||
        (phase == RoundPhase.paused &&
            gameData.pausedFrom == RoundPhase.running);
    if (!roundClock) return counts;
    final next = gameData.roundNumber + 1;
    return gameData.isNextRoundSaved
        ? l10n.shell_session_bar_saved(counts, next)
        : l10n.shell_session_bar_not_saved(counts, next);
  }
}

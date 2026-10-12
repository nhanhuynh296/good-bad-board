import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/state/game_data.dart';

/// The round rotation bar displayed between the stat strip and the court grid.
///
/// Displays round progress with a live countdown timer, progress bar, and
/// rotation controls (Pre-make next round, Rotate now, Cancel next).
///
/// The two panels — the live round and the pre-made next round — act as radio
/// buttons: the selected one is the round the court grid shows and edits.
///
/// Purely presentational — all state is passed in as props. The parent
/// (DashboardPage) owns the timer and state management.
class RoundRotationBar extends StatelessWidget {
  const RoundRotationBar({
    super.key,
    required this.roundNumber,
    required this.modeLabel,
    required this.remainingLabel,
    required this.pct,
    required this.isUrgent,
    required this.isStaged,
    this.stagedSummary = '',
    this.stagedPct = 0.0,
    this.selectedView = RoundView.current,
    this.onSelectView,
    this.onRotateNow,
    this.onStageNext,
    this.onCancelStaged,
  });

  /// Identifies the live-round panel.
  static const Key currentPanelKey = Key('round-panel-current');

  /// Identifies the pre-made-round panel.
  static const Key nextPanelKey = Key('round-panel-next');

  /// Current round number (1-indexed).
  final int roundNumber;

  /// Descriptive label for the current round mode
  /// (e.g. "Game-based · auto-rotates when the set clock ends").
  final String modeLabel;

  /// Formatted remaining time as MM:SS.
  final String remainingLabel;

  /// Remaining time as a percentage (0.0 – 100.0). Drives the progress bar.
  final double pct;

  /// Whether the countdown is in the urgent zone (≤ 60 s remaining).
  final bool isUrgent;

  /// Whether a round has been pre-staged for the next rotation.
  final bool isStaged;

  /// Human-readable summary of the staged round shown in the staged panel.
  final String stagedSummary;

  /// Elapsed percentage for the staged round's progress bar (fills up).
  final double stagedPct;

  /// Which round the court grid is showing.
  final RoundView selectedView;

  /// Callback when the organizer taps one of the two panels.
  final ValueChanged<RoundView>? onSelectView;

  /// Callback when the organizer taps "Rotate now".
  final VoidCallback? onRotateNow;

  /// Callback when the organizer taps "Pre-make next round".
  final VoidCallback? onStageNext;

  /// Callback when the organizer taps "Cancel next".
  final VoidCallback? onCancelStaged;

  /// The accent / urgent amber color from the design tokens.
  static const Color _amber = Color(0xFFFFB38A);

  @override
  Widget build(BuildContext context) {
    final fillColor = isUrgent ? _amber : AppColors.accentPrimary;
    final countdownColor = isUrgent ? _amber : Colors.white;
    final currentSelected = selectedView == RoundView.current;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: AppRadii.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Current round panel ───────────────────────────
          _SelectablePanel(
            panelKey: currentPanelKey,
            label: l10n.dashboard_current_round,
            selected: currentSelected,
            accent: AppColors.accentPrimary,
            // Without a staged round there is no choice to make.
            onTap: isStaged && onSelectView != null
                ? () => onSelectView!(RoundView.current)
                : null,
            child: _buildCurrentRow(l10n, countdownColor, fillColor),
          ),

          // ── Next round panel ──────────────────────────────
          if (isStaged) ...[
            const Divider(
              color: Color(0x1FFFFFFF), // rgba(255,255,255,0.12)
              height: 1,
              thickness: 1,
            ),
            _SelectablePanel(
              panelKey: nextPanelKey,
              label: l10n.dashboard_next_round,
              selected: !currentSelected,
              accent: _amber,
              onTap: onSelectView != null
                  ? () => onSelectView!(RoundView.next)
                  : null,
              child: _buildNextPanel(l10n),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  /// The live round: round number, mode label, countdown, actions, and the
  /// depleting progress bar.
  Widget _buildCurrentRow(
    AppLocalizations l10n,
    Color countdownColor,
    Color fillColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Main row ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              // Left: round number + mode label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.dashboard_round_label(roundNumber),
                      style: const TextStyle(
                        fontFamily: AppTypography.displayFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      modeLabel,
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 12,
                        color: AppColors.headerSub,
                      ),
                    ),
                  ],
                ),
              ),

              // Right: countdown + buttons. Flexible so that long labels
              // (e.g. French) wrap the buttons instead of overflowing.
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Countdown timer
                    Text(
                      remainingLabel,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFont,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: countdownColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.dashboard_until_rotation,
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.headerSub,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Action buttons
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        // Once a round is staged the next panel owns its own
                        // controls, so this button is only offered while there
                        // is nothing planned yet.
                        if (!isStaged)
                          _GhostButton(
                            label: l10n.dashboard_premake_next,
                            onTap: onStageNext,
                          ),
                        // Rotate now (always visible)
                        _AccentButton(
                          label: l10n.dashboard_rotate_now,
                          onTap: onRotateNow,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Main progress bar (depleting) ────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            child: LinearProgressIndicator(
              value: (pct / 100.0).clamp(0.0, 1.0),
              backgroundColor: const Color(0x24FFFFFF), // rgba(255,255,255,.14)
              valueColor: AlwaysStoppedAnimation<Color>(fillColor),
              minHeight: 10,
            ),
          ),
        ),
      ],
    );
  }

  /// The pre-made round: badge, summary, its own progress bar, and the
  /// control that discards it.
  Widget _buildNextPanel(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: const BoxDecoration(
                  color: _amber,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: Text(
                  l10n.dashboard_next_round_ready,
                  style: const TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.06 * 10,
                    color: AppColors.headerBg,
                  ),
                ),
              ),
              const Spacer(),
              _GhostButton(
                label: l10n.dashboard_cancel_next,
                onTap: onCancelStaged,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Summary text
          Text(
            stagedSummary,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 12,
              color: AppColors.headerSub,
            ),
          ),
          const SizedBox(height: 4),
          // Striped progress bar (fills up)
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            child: LinearProgressIndicator(
              value: (stagedPct / 100.0).clamp(0.0, 1.0),
              backgroundColor: const Color(0x24FFFFFF),
              valueColor: const AlwaysStoppedAnimation<Color>(_amber),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the two round panels, behaving as a radio button.
///
/// The selected panel is the round the court grid shows and edits, so the
/// selected state has to read at a glance from across the hall: an accent
/// ring, a filled radio dot, and a dimmed unselected sibling.
class _SelectablePanel extends StatelessWidget {
  const _SelectablePanel({
    required this.panelKey,
    required this.label,
    required this.selected,
    required this.accent,
    required this.child,
    this.onTap,
  });

  final Key panelKey;
  final String label;
  final bool selected;
  final Color accent;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: panelKey,
      button: onTap != null,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.mdRadius,
          child: Opacity(
            // A plan the organizer is not looking at recedes.
            opacity: selected || onTap == null ? 1.0 : 0.55,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadii.mdRadius,
                border: Border.all(
                  color: selected && onTap != null
                      ? accent
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [if (onTap != null) _buildHeader(), child],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The radio dot + panel name, only shown once there is a choice to make.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? accent : AppColors.headerSub,
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.06 * 10,
              color: selected ? accent : AppColors.headerSub,
            ),
          ),
        ],
      ),
    );
  }
}

/// A ghost button with a semi-transparent white background.
class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0x1FFFFFFF), // rgba(255,255,255,0.12)
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// An accent-filled primary action button.
class _AccentButton extends StatelessWidget {
  const _AccentButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: const BoxDecoration(
            color: AppColors.accentPrimary,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.accentOnPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

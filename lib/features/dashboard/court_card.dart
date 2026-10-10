import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/model/player.dart';

/// A card representing a single badminton court with 4 player slots.
///
/// Header row shows: "COURT N" title + [SpreadPill] + an optional PLAYING
/// badge + re-roll and (game-based mode) save buttons.
/// Body contains 4 [PlayerSlot] rows.
class CourtCard extends StatelessWidget {
  const CourtCard({
    super.key,
    required this.courtNumber,
    required this.players,
    this.spreadLevel = 0,
    this.isSelectionActive = false,
    this.isPlaying = false,
    this.isNextRound = false,
    this.onReroll,
    this.onSlotTap,
    this.onSave,
  });

  /// 1-indexed court number displayed in the header.
  final int courtNumber;

  /// Players currently assigned to this court. The list may contain 0–4 entries;
  /// the widget always renders 4 slots, showing empty state for missing indices.
  final List<Player> players;

  /// The level gap between highest and lowest player on this court.
  final int spreadLevel;

  /// Whether a waitlist selection is active (slots become tappable targets).
  final bool isSelectionActive;

  /// Whether this court's lineup has been saved and the game is under way.
  ///
  /// While playing, the lineup is locked and the save button is replaced by a
  /// PLAYING badge — only a re-roll ends the game.
  final bool isPlaying;

  /// Whether this card shows the pre-made next round rather than the round
  /// being played.
  ///
  /// The plan is editable, so it must never be mistaken for the live court —
  /// it carries a NEXT badge in place of the PLAYING badge.
  final bool isNextRound;

  /// Called when the user taps the re-roll button.
  final VoidCallback? onReroll;

  /// Called with the 0-based slot index when a slot is tapped.
  final void Function(int slotIndex)? onSlotTap;

  /// Called when the user taps the save button (game-based mode only).
  ///
  /// When null, no save button is rendered.
  final VoidCallback? onSave;

  static const _slotCount = 4;

  /// The save button only appears on a court that holds a full, savable
  /// lineup and is not already in play.
  bool get _showSave =>
      onSave != null && !isPlaying && players.length == _slotCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Text(
                  l10n.dashboard_court_title(courtNumber),
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(child: SpreadPill(levelGap: spreadLevel)),
                if (isNextRound) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const _NextRoundBadge(),
                ] else if (isPlaying) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const _PlayingBadge(),
                ],
                const Spacer(),
                if (_showSave) ...[
                  _CourtActionButton(
                    key: const Key('court-save-button'),
                    label: l10n.save,
                    icon: Icons.check_rounded,
                    isPrimary: true,
                    onTap: onSave,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                _CourtActionButton(
                  label: l10n.dashboard_reroll,
                  icon: Icons.refresh_rounded,
                  // Save is the primary action while the lineup is still
                  // being tuned; once saved, re-roll is what ends the game.
                  isPrimary: !_showSave,
                  onTap: onReroll,
                ),
              ],
            ),
          ),
          // ── Player Slots ────────────────────────────────
          for (var i = 0; i < _slotCount; i++)
            PlayerSlot(
              player: i < players.length ? players[i] : null,
              isSelectionActive: isSelectionActive,
              onTap: onSlotTap != null ? () => onSlotTap!(i) : null,
            ),
        ],
      ),
    );
  }
}

/// A compact action button in a court card header (re-roll / save).
class _CourtActionButton extends StatelessWidget {
  const _CourtActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isPrimary,
    this.onTap,
  });

  final String label;
  final IconData icon;

  /// Accent fill when true, muted pill fill when false. A null [onTap]
  /// always renders as disabled regardless of this flag.
  final bool isPrimary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final background = isEnabled && isPrimary
        ? AppColors.accentPrimary
        : AppColors.pillBg;
    final foreground = isEnabled
        ? (isPrimary ? AppColors.accentOnPrimary : AppColors.textPrimary)
        : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.mdRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadii.mdRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.buttonSm.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The badge shown on a court that holds the pre-made next round.
class _NextRoundBadge extends StatelessWidget {
  const _NextRoundBadge();

  /// The amber the rotation bar uses for the staged round.
  static const Color _amber = Color(0xFFFFB38A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.chipPadding,
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.25),
        borderRadius: AppRadii.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 10, color: _amber),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context)!.dashboard_badge_next,
            style: AppTypography.chip.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// The badge shown on a court whose saved game is under way.
class _PlayingBadge extends StatelessWidget {
  const _PlayingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.chipPadding,
      decoration: const BoxDecoration(
        color: AppColors.successBg,
        borderRadius: AppRadii.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 7, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context)!.dashboard_badge_playing,
            style: AppTypography.chip.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

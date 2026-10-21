import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/l10n/skill_tier_l10n.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/player.dart';

/// A single player position within a [CourtCard].
///
/// Two visual states:
/// - **Occupied**: player name (14px, 600) + level group (13px, 800,
///   accent). The exact Elo stays hidden on court.
/// - **Empty**: "Open slot" (13px, italic, textSubtle)
///
/// When [isSelectionActive] is true, the slot shows an accent-tinted
/// background to indicate it is a valid drop target. A slot whose player is
/// selected (to move them to another slot) shows a stronger tint.
///
/// When [onRemove] is set, an occupied slot shows a remove button.
class PlayerSlot extends StatelessWidget {
  const PlayerSlot({
    super.key,
    this.player,
    this.compact = false,
    this.isSelectionActive = false,
    this.isSelected = false,
    this.onTap,
    this.onRemove,
  });

  /// The player occupying this slot, or null if empty.
  final Player? player;

  /// Tighter padding, for a court card that is short on height.
  final bool compact;

  /// Whether a waitlist selection is currently active (makes slots tappable).
  final bool isSelectionActive;

  /// Whether this slot's player is the one selected to move.
  final bool isSelected;

  /// Called when the slot is tapped.
  final VoidCallback? onTap;

  /// Called when the remove button is tapped. When null, no button shows.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = (isSelectionActive || player != null) ? onTap : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: effectiveOnTap,
        splashColor: AppColors.accentPrimary.withValues(alpha: 0.12),
        highlightColor: AppColors.accentPrimary.withValues(alpha: 0.06),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 3 : 10,
          ),
          decoration: BoxDecoration(
            border: const Border(top: BorderSide(color: AppColors.pillBg)),
            color: isSelected
                ? AppColors.accentPrimary.withValues(alpha: 0.18)
                : isSelectionActive
                ? AppColors.accentPrimary.withValues(alpha: 0.06)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: player != null
                    ? Text(
                        player!.name(),
                        style: AppTypography.md,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        AppLocalizations.of(context)!.dashboard_open_slot,
                        style: const TextStyle(
                          fontFamily: AppTypography.family,
                          fontSize: AppTypography.sizeBody,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSubtle,
                        ),
                      ),
              ),
              if (player != null) ...[
                const SizedBox(width: 8),
                Text(
                  player!.elo.skillTier.localizedLabel(
                    AppLocalizations.of(context)!,
                  ),
                  style: const TextStyle(
                    fontFamily: AppTypography.family,
                    fontSize: AppTypography.sizeBody,
                    fontWeight: AppTypography.semibold,
                    color: AppColors.accentPrimary,
                  ),
                ),
                if (onRemove != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    key: const Key('slot-remove-button'),
                    onPressed: onRemove,
                    tooltip: AppLocalizations.of(
                      context,
                    )!.dashboard_remove_from_court,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    color: AppColors.textMuted,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: compact ? 18 : 24,
                      height: compact ? 18 : 24,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

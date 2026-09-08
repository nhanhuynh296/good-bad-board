import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/model/player.dart';

/// A single player position within a [CourtCard].
///
/// Two visual states:
/// - **Occupied**: player name (14px, 600) + level/ELO (13px, 800, accent)
/// - **Empty**: "Open slot" (13px, italic, textSubtle)
///
/// When [isSelectionActive] is true, the slot shows an accent-tinted
/// background to indicate it is a valid drop target.
class PlayerSlot extends StatelessWidget {
  const PlayerSlot({
    super.key,
    this.player,
    this.isSelectionActive = false,
    this.onTap,
  });

  /// The player occupying this slot, or null if empty.
  final Player? player;

  /// Whether a waitlist selection is currently active (makes slots tappable).
  final bool isSelectionActive;

  /// Called when the slot is tapped.
  final VoidCallback? onTap;

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: const Border(top: BorderSide(color: AppColors.pillBg)),
            color: isSelectionActive
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
                    : const Text(
                        'Open slot',
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSubtle,
                        ),
                      ),
              ),
              if (player != null) ...[
                const SizedBox(width: 8),
                Text(
                  player!.elo.toDisplayName(),
                  style: const TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

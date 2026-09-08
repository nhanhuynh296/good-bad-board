import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/model/player.dart';

/// Tablet/phone waitlist — a horizontal wrapping row of selectable chips.
///
/// Each chip shows: position number + player name + level.
/// Selected chip: accent background with white text.
/// Unselected chip: pillBg with textPrimary.
class WaitlistChips extends StatelessWidget {
  const WaitlistChips({
    super.key,
    required this.players,
    this.selectedPlayerId,
    this.onPlayerSelect,
  });

  /// Waitlisted players in display order.
  final List<Player> players;

  /// The currently selected player ID (for click-to-place).
  final String? selectedPlayerId;

  /// Called when a chip is tapped to begin the placement flow.
  final void Function(Player player)? onPlayerSelect;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No one waiting',
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: AppColors.textSubtle,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Section label ────────────────────────────────
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text('Waitlist', style: AppTypography.helperBold),
        ),
        // ── Chips ────────────────────────────────────────
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: List.generate(players.length, (i) {
            final player = players[i];
            final isSelected = player.id == selectedPlayerId;
            final label =
                '${i + 1}. ${player.name()} ${player.elo.toDisplayName()}';

            return AppChip(
              label: label,
              isSelected: isSelected,
              compact: false,
              onTap: () => onPlayerSelect?.call(player),
            );
          }),
        ),
        // ── Hint ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            selectedPlayerId != null
                ? 'Tap a court slot to place this player'
                : 'Tap a player, then tap a court slot',
            style: AppTypography.helper,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    if (players.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.dashboard_waitlist_empty,
          style: const TextStyle(
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
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(l10n.dashboard_waitlist, style: AppTypography.helperBold),
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
                ? l10n.dashboard_waitlist_hint_place
                : l10n.dashboard_waitlist_hint_select,
            style: AppTypography.helper,
          ),
        ),
      ],
    );
  }
}

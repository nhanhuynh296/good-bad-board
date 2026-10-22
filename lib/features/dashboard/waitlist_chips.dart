import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/l10n/skill_tier_l10n.dart';
import 'package:good_bad_board/model/elo.dart';
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
    this.selectedPlayerName,
    this.onPlayerSelect,
  });

  /// Waitlisted players in display order.
  final List<Player> players;

  /// The currently selected player ID (for click-to-place).
  final String? selectedPlayerId;

  /// Name shown in the placing hint. Falls back to the waitlisted player with
  /// [selectedPlayerId] — pass it when the selection may be on a court.
  final String? selectedPlayerName;

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
            fontFamily: AppTypography.family,
            fontSize: AppTypography.sizeBody,
            fontStyle: FontStyle.italic,
            color: AppColors.textMuted,
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
                '${i + 1}. ${player.name()} '
                '${player.elo.skillTier.localizedLabel(AppLocalizations.of(context)!)}';

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
                ? l10n.dashboard_waitlist_hint_place(
                    selectedPlayerName ??
                        players
                            .firstWhereOrNull((p) => p.id == selectedPlayerId)
                            ?.name() ??
                        '',
                  )
                : l10n.dashboard_waitlist_hint_select,
            style: AppTypography.helper,
          ),
        ),
      ],
    );
  }
}

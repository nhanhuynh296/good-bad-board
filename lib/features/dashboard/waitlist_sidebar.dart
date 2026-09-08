import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/model/player.dart';

/// Desktop waitlist sidebar — a fixed 270px card listing waitlisted players.
///
/// Displays player name, ELO level, and position number. The selected player
/// highlights with accent background.
///
/// When empty, shows an italic "No one waiting" message.
class WaitlistSidebar extends StatelessWidget {
  const WaitlistSidebar({
    super.key,
    required this.players,
    this.selectedPlayerId,
    this.onPlayerSelect,
  });

  /// Waitlisted players in display order.
  final List<Player> players;

  /// The currently selected player ID (for click-to-place).
  final String? selectedPlayerId;

  /// Called when a player is tapped to begin the placement flow.
  final void Function(Player player)? onPlayerSelect;

  static const _width = 270.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────
            const Text('Waitlist', style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.md),
            // ── Scrollable List / Empty State ─────────────
            if (players.isEmpty)
              const Text(
                'No one waiting',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSubtle,
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, i) {
                    final player = players[i];
                    final isSelected = player.id == selectedPlayerId;
                    return _WaitlistItem(
                      position: i + 1,
                      player: player,
                      isSelected: isSelected,
                      onTap: () => onPlayerSelect?.call(player),
                    );
                  },
                ),
              ),
            // ── Hint text ──────────────────────────────────
            const SizedBox(height: AppSpacing.lg),
            Text(
              selectedPlayerId != null
                  ? 'Tap a court slot to place this player'
                  : 'Tap a player, then tap a court slot',
              style: AppTypography.helper,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single selectable row in the waitlist sidebar.
class _WaitlistItem extends StatelessWidget {
  const _WaitlistItem({
    required this.position,
    required this.player,
    required this.isSelected,
    required this.onTap,
  });

  final int position;
  final Player player;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.mdRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentPrimary : null,
              borderRadius: AppRadii.mdRadius,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    '$position',
                    style: AppTypography.helper.copyWith(
                      color: isSelected
                          ? AppColors.white.withValues(alpha: 0.8)
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    player.name(),
                    style: AppTypography.md.copyWith(
                      color: isSelected ? AppColors.white : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  player.elo.toDisplayName(),
                  style: AppTypography.statLabel.copyWith(
                    color: isSelected
                        ? AppColors.white.withValues(alpha: 0.85)
                        : AppColors.accentPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

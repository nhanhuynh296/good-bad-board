import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/membership_l10n.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/features/players/level_adjuster.dart';
import 'package:good_bad_board/model/player.dart';

/// A single row in the players table.
///
/// The whole row is tappable and opens or closes the player profile below
/// it. A trailing arrow shows whether the profile is open. The controls in
/// the row keep their own taps.
///
/// Renders five logical columns plus the arrow:
/// - **Name** (14px, 600, accent when the profile is open)
/// - **ID** (12px, subtle — the player's sign-in code)
/// - **Level** ([LevelAdjuster] with −/+ buttons)
/// - **Membership** pill (cycles Member → Casual → Disabled → Member)
/// - **Checked In** toggle (In / Out)
///
/// The row is designed for desktop-width tables. On narrower screens the
/// parent should wrap it in a horizontal [SingleChildScrollView].
class PlayerRow extends StatelessWidget {
  const PlayerRow({
    super.key,
    required this.player,
    required this.isExpanded,
    required this.membership,
    required this.isCheckedIn,
    this.onToggleProfile,
    this.onLevelUp,
    this.onLevelDown,
    this.onCycleMembership,
    this.onToggleCheckin,
  });

  final Player player;

  /// Whether the profile card below this row is expanded.
  final bool isExpanded;

  /// This player's current club-membership status.
  final MembershipStatus membership;

  /// Whether this player is checked in for the current session.
  final bool isCheckedIn;

  /// Called when the row is tapped to toggle profile expansion.
  final VoidCallback? onToggleProfile;

  /// Called when the level [+] button is tapped.
  final VoidCallback? onLevelUp;

  /// Called when the level [−] button is tapped.
  final VoidCallback? onLevelDown;

  /// Called when the membership pill is tapped, to advance to the next
  /// status (see [MembershipStatus.next]).
  final VoidCallback? onCycleMembership;

  /// Called when the check-in toggle changes.
  final ValueChanged<bool>? onToggleCheckin;

  @override
  Widget build(BuildContext context) {
    final elo = player.elo;

    return Material(
      color: isExpanded
          ? AppColors.pillBg.withValues(alpha: 0.4)
          : Colors.transparent,
      child: InkWell(
        onTap: onToggleProfile,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.cardBorder, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: LayoutBuilder(
            builder: (context, _) {
              // The trailing controls have fixed widths that, on a phone, add up
              // to more than the row has — squeezing the name to nothing and
              // overflowing. Give them their natural size there instead, so the
              // name keeps what is left.
              // Viewport width, like the table header, so the columns agree
              // (UAT NAV-08).
              final compact = isPhone(MediaQuery.sizeOf(context).width);
              final gap = compact ? AppSpacing.sm : AppSpacing.md;

              return Row(
                children: [
                  // ── Name + ID ──────────────────────────────────
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          player.name(),
                          style: AppTypography.md.copyWith(
                            color: isExpanded
                                ? AppColors.accentPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          player.signInId ?? '—',
                          style: AppTypography.sm.copyWith(
                            color: AppColors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: gap),

                  // ── Level Adjuster ─────────────────────────────
                  SizedBox(
                    width: compact ? null : 155,
                    child: LevelAdjuster(
                      currentLevel: elo,
                      onDecrease: () => onLevelDown?.call(),
                      onIncrease: () => onLevelUp?.call(),
                    ),
                  ),
                  SizedBox(width: gap),

                  // ── Membership pill ─────────────────────────────
                  SizedBox(
                    width: compact ? null : 88,
                    child: _MembershipPill(
                      status: membership,
                      onTap: onCycleMembership,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // ── Check-in toggle ────────────────────────────
                  SizedBox(
                    width: compact ? null : 76,
                    child: _CompactToggle(
                      value: isCheckedIn,
                      onLabel: AppLocalizations.of(context)!.players_checkin_in,
                      offLabel: AppLocalizations.of(
                        context,
                      )!.players_checkin_out,
                      activeColor: AppColors.success,
                      onChanged: onToggleCheckin,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),

                  // ── Expand / collapse arrow ────────────────────
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: isExpanded
                        ? AppColors.accentPrimary
                        : AppColors.textMuted,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A compact pill-shaped toggle used in [PlayerRow].
///
/// Renders as a small rounded button with short text labels (e.g., "Active"
/// / "Inactive"). Uses green-on-grey colouring like [AppToggleButton] but in
/// a reduced footprint suitable for table rows.
class _CompactToggle extends StatelessWidget {
  const _CompactToggle({
    required this.value,
    required this.onLabel,
    required this.offLabel,
    required this.activeColor,
    this.onChanged,
  });

  final bool value;
  final String onLabel;
  final String offLabel;
  final Color activeColor;
  final ValueChanged<bool>? onChanged;

  static const _textStyle = TextStyle(
    fontFamily: AppTypography.bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    final isOn = value;
    final bgColor = isOn ? activeColor : AppColors.toggleOff;
    final textColor = isOn ? AppColors.white : AppColors.toggleOffText;
    final label = isOn ? onLabel : offLabel;

    return Material(
      color: bgColor,
      borderRadius: AppRadii.smRadius,
      child: InkWell(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        borderRadius: AppRadii.smRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: _textStyle.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}

/// A pill-shaped control showing the player's [MembershipStatus], tappable
/// to advance to the next status ([MembershipStatus.next]).
class _MembershipPill extends StatelessWidget {
  const _MembershipPill({required this.status, this.onTap});

  final MembershipStatus status;
  final VoidCallback? onTap;

  static const _textStyle = TextStyle(
    fontFamily: AppTypography.bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    final (Color bgColor, Color textColor) = switch (status) {
      MembershipStatus.member => (AppColors.accentPrimary, AppColors.white),
      MembershipStatus.casual => (AppColors.warningBg, AppColors.warningText),
      MembershipStatus.disabled => (
        AppColors.toggleOff,
        AppColors.toggleOffText,
      ),
    };

    return Material(
      color: bgColor,
      borderRadius: AppRadii.smRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.smRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          child: Text(
            status.localizedLabel(AppLocalizations.of(context)!),
            textAlign: TextAlign.center,
            style: _textStyle.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}

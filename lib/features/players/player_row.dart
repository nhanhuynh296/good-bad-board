import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/membership_l10n.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/features/players/level_adjuster.dart';
import 'package:good_bad_board/model/player.dart';

/// A single row in the players table.
///
/// The whole row is a toggle: tapping it checks the player in or out (see
/// [onToggleCheckin]). A Disabled player cannot be checked in, so tapping
/// their row does nothing. The controls inside the row keep their own taps
/// and never toggle the check-in. The "More" button opens or closes the
/// player profile below the row.
///
/// Look (UX-Redesign/ARCHITECTURE.md, player row):
/// - Checked in: [AppColors.successBg] fill, 1px [AppColors.success] border
///   at 45% alpha, 4px [AppColors.deltaPositive] bar on the left, and a bold
///   name. No check icon: the colour shows the state.
/// - Disabled: no bar, subtle text and a forbidden cursor.
///
/// Columns: **Name + ID** on one baseline, **Level** ([LevelAdjuster]),
/// **Membership** pill (cycles Member → Casual → Disabled → Member), **More**.
/// All controls are [controlHeight] tall.
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

  /// Width of the "More" column. The table header uses the same width.
  static const double moreColumnWidth = 100;

  /// Width of the left accent bar.
  static const double barWidth = 4;

  /// Distance from the row's left edge to the player name. The table header
  /// uses this to line its first label up with the name.
  static const double nameInset = barWidth + 12;

  /// Height of every control in the row (level −/+, membership, More).
  static const double controlHeight = 28;

  final Player player;

  /// Whether the profile card below this row is expanded.
  final bool isExpanded;

  /// This player's current club-membership status.
  final MembershipStatus membership;

  /// Whether this player is checked in for the current session.
  final bool isCheckedIn;

  /// Called when the "More" button is tapped, to open or close the profile.
  final VoidCallback? onToggleProfile;

  /// Called when the level [+] button is tapped.
  final VoidCallback? onLevelUp;

  /// Called when the level [−] button is tapped.
  final VoidCallback? onLevelDown;

  /// Called when the membership pill is tapped, to advance to the next
  /// status (see [MembershipStatus.next]).
  final VoidCallback? onCycleMembership;

  /// Called when the row is tapped, to check the player in or out. Not
  /// called for a Disabled player.
  final VoidCallback? onToggleCheckin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final elo = player.elo;
    final isDisabled = membership == MembershipStatus.disabled;
    final checked = isCheckedIn && !isDisabled;

    final background = checked
        ? AppColors.successBg
        : isExpanded
        ? AppColors.pillBg.withValues(alpha: 0.4)
        : Colors.transparent;
    final hover = isDisabled
        ? Colors.transparent
        : checked
        ? AppColors.successBgHover
        : AppColors.cardBg;

    const sideNone = BorderSide(color: Colors.transparent);
    final border = checked
        ? Border.all(color: AppColors.success.withValues(alpha: 0.45))
        : const Border(
            left: sideNone,
            top: sideNone,
            right: sideNone,
            bottom: BorderSide(color: AppColors.cardBorder, width: 0.5),
          );

    final nameColor = isDisabled
        ? AppColors.textSubtle
        : isExpanded
        ? AppColors.accentPrimary
        : AppColors.textPrimary;

    return Semantics(
      key: const Key('player-row-toggle'),
      container: true,
      button: true,
      checked: checked,
      enabled: !isDisabled,
      child: Material(
        color: background,
        child: InkWell(
          onTap: isDisabled ? null : onToggleCheckin,
          hoverColor: hover,
          mouseCursor: isDisabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(border: border),
                padding: const EdgeInsets.fromLTRB(nameInset, 8, 12, 8),
                child: LayoutBuilder(
                  builder: (context, _) {
                    // The trailing controls have fixed widths that, on a
                    // phone, add up to more than the row has — squeezing the
                    // name to nothing and overflowing. Give them their
                    // natural size there instead, so the name keeps what is
                    // left. Viewport width, like the table header, so the
                    // columns agree (UAT NAV-08).
                    final compact = isPhone(MediaQuery.sizeOf(context).width);
                    final gap = compact ? AppSpacing.sm : AppSpacing.md;

                    return Row(
                      children: [
                        // ── Name + ID, on one baseline ───────────
                        Expanded(
                          flex: 3,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: Text(
                                  player.name(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.md.copyWith(
                                    color: nameColor,
                                    fontWeight: checked
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                player.signInId ?? '—',
                                maxLines: 1,
                                style: AppTypography.sm.copyWith(
                                  color: AppColors.textSubtle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: gap),

                        // ── Level Adjuster ───────────────────────
                        SizedBox(
                          width: compact ? null : 155,
                          child: LevelAdjuster(
                            currentLevel: elo,
                            onDecrease: () => onLevelDown?.call(),
                            onIncrease: () => onLevelUp?.call(),
                          ),
                        ),
                        SizedBox(width: gap),

                        // ── Membership pill ───────────────────────
                        SizedBox(
                          width: compact ? null : 88,
                          child: _MembershipPill(
                            status: membership,
                            onTap: onCycleMembership,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),

                        // ── More (opens the profile) ─────────────
                        SizedBox(
                          width: compact ? null : moreColumnWidth,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              height: controlHeight,
                              child: AppButton.secondary(
                                label: l10n.players_more,
                                trailingIcon: isExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                onPressed: onToggleProfile,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (checked)
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: barWidth,
                  child: ColoredBox(
                    key: Key('player-row-bar'),
                    color: AppColors.deltaPositive,
                  ),
                ),
            ],
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
          height: PlayerRow.controlHeight,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 9),
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

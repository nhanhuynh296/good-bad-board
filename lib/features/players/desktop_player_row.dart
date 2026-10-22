import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_button.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/l10n/membership_l10n.dart';
import 'package:good_bad_board/l10n/skill_tier_l10n.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/player.dart';

/// The column widths of the desktop player table (ARCHITECTURE §2.4):
/// NAME 1fr | SIGN-IN ID 140 | LEVEL 140 | TYPE 120 | More 88, gap 16.
abstract final class PlayerTableColumns {
  static const double id = 140;
  static const double level = 140;
  static const double type = 120;
  static const double more = 88;
  static const double gap = 16;

  /// From the row edge to the NAME text: the 1 px border and 16 px.
  static const double nameInset = 17;
}

/// One 48 px row of the desktop player table (IMPLEMENTATION 8.7.3, UAT
/// PLY-08). The row is one check-in toggle, except the "More" button. It
/// has no level stepper and no membership pill: those are in the More
/// panel (R2-Q17). LEVEL shows the tier name only (R2-Q18).
class DesktopPlayerRow extends StatefulWidget {
  const DesktopPlayerRow({
    super.key,
    required this.player,
    required this.isCheckedIn,
    required this.isExpanded,
    required this.onToggleCheckin,
    required this.onToggleMore,
    this.inPanel = false,
  });

  final Player player;
  final bool isCheckedIn;

  /// Whether the More panel under this row is open.
  final bool isExpanded;

  /// The row tap. Also called for a Disabled player, so the page can say
  /// why the check-in is refused (R4-Q1).
  final VoidCallback onToggleCheckin;
  final VoidCallback onToggleMore;

  /// The row sits in the rounded panel of an open More panel, which draws
  /// the border and the corners.
  final bool inPanel;

  static const double height = 48;
  static const double barWidth = 6;

  @override
  State<DesktopPlayerRow> createState() => _DesktopPlayerRowState();
}

class _DesktopPlayerRowState extends State<DesktopPlayerRow> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final player = widget.player;
    final disabled = player.membership == MembershipStatus.disabled;
    final checked = widget.isCheckedIn && !disabled;

    final base = checked ? AppColors.checkedInBg : AppColors.cardBg;
    // Hover tints the whole row, not a box inside it.
    final fill = _hovered && !disabled
        ? Color.alphaBlend(AppColors.black.withValues(alpha: 0.03), base)
        : base;
    final text = disabled ? AppColors.textMuted : AppColors.textPrimary;
    final typeColour = checked
        ? AppColors.textMutedOnCheckedIn
        : AppColors.textMuted;
    final border = widget.inPanel
        ? null
        : Border.all(color: checked ? AppColors.success : AppColors.cardBorder);
    final radius = widget.inPanel ? BorderRadius.zero : AppRadii.mdRadius;

    final label = disabled
        ? l10n.players_row_disabled(player.name())
        : checked
        ? l10n.players_row_checked_in(player.name())
        : l10n.players_row_not_checked_in(player.name());

    final type = switch (player.membership) {
      MembershipStatus.member => '',
      final other => other.localizedLabel(l10n),
    };

    return SizedBox(
      height: DesktopPlayerRow.height,
      child: DecoratedBox(
        key: const Key('player-row-decoration'),
        decoration: BoxDecoration(
          color: fill,
          border: border,
          borderRadius: radius,
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    container: true,
                    button: true,
                    toggled: disabled ? null : checked,
                    enabled: !disabled,
                    label: label,
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        key: const Key('player-row-toggle'),
                        onTap: widget.onToggleCheckin,
                        onFocusChange: (value) =>
                            setState(() => _focused = value),
                        borderRadius: radius,
                        mouseCursor: disabled
                            ? SystemMouseCursors.forbidden
                            : SystemMouseCursors.click,
                        onHover: (value) => setState(() => _hovered = value),
                        // The row fill shows hover, and the ring over the
                        // whole row shows focus (below).
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        splashColor: disabled ? Colors.transparent : null,
                        highlightColor: disabled ? Colors.transparent : null,
                        child: ExcludeSemantics(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: PlayerTableColumns.nameInset - 1,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    player.name(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.subtitle.copyWith(
                                      color: text,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: PlayerTableColumns.gap),
                                _Cell(
                                  width: PlayerTableColumns.id,
                                  text: player.signInId ?? '',
                                  color: text,
                                  tabular: true,
                                ),
                                const SizedBox(width: PlayerTableColumns.gap),
                                _Cell(
                                  width: PlayerTableColumns.level,
                                  text: player.elo.skillTier.localizedLabel(
                                    l10n,
                                  ),
                                  color: text,
                                ),
                                const SizedBox(width: PlayerTableColumns.gap),
                                _Cell(
                                  width: PlayerTableColumns.type,
                                  text: type,
                                  color: typeColour,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: PlayerTableColumns.gap),
                SizedBox(
                  width: PlayerTableColumns.more,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _MoreButton(
                      expanded: widget.isExpanded,
                      label: l10n.players_more,
                      semanticsLabel: l10n.players_more_about(player.name()),
                      onPressed: widget.onToggleMore,
                    ),
                  ),
                ),
              ],
            ),
            if (checked)
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: DesktopPlayerRow.barWidth,
                child: IgnorePointer(
                  child: ColoredBox(
                    key: Key('player-row-bar'),
                    color: AppColors.success,
                  ),
                ),
              ),
            // One focus ring over the whole row, inside its edge, so the
            // list does not clip it.
            if (_focused &&
                FocusManager.instance.highlightMode ==
                    FocusHighlightMode.traditional)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const Key('player-row-focus-ring'),
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color: AppColors.focusOnLight,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.width,
    required this.text,
    required this.color,
    this.tabular = false,
  });

  final double width;
  final String text;
  final Color color;
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.body.copyWith(
          color: color,
          fontFeatures: tabular
              ? const [FontFeature.tabularFigures()]
              : const <FontFeature>[],
        ),
      ),
    );
  }
}

/// The 72 × 36 "More" outline button. It tells screen readers whether its
/// panel is open (F23).
class _MoreButton extends StatefulWidget {
  const _MoreButton({
    required this.expanded,
    required this.label,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final bool expanded;
  final String label;
  final String semanticsLabel;
  final VoidCallback onPressed;

  @override
  State<_MoreButton> createState() => _MoreButtonState();
}

class _MoreButtonState extends State<_MoreButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      expanded: widget.expanded,
      label: widget.semanticsLabel,
      child: FocusRing(
        focused: _focused,
        color: AppColors.focusOnLight,
        radius: AppRadii.md,
        child: Material(
          color: AppColors.pageBg,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.mdRadius,
            side: BorderSide(color: AppColors.controlBorder),
          ),
          child: InkWell(
            key: const Key('player-more'),
            onTap: widget.onPressed,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: AppRadii.mdRadius,
            // The ring shows focus; no grey fill as well.
            focusColor: Colors.transparent,
            child: ExcludeSemantics(
              child: SizedBox(
                width: 72,
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.button.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      widget.expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 14,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The header of the desktop player table: NAME · SIGN-IN ID · LEVEL ·
/// TYPE · (blank), 12/600 caps, `#6f6352`.
class DesktopPlayerTableHeader extends StatelessWidget {
  const DesktopPlayerTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget cell(String text, double? width) {
      final label = Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.statLabel,
      );
      return width == null
          ? Expanded(child: label)
          : SizedBox(width: width, child: label);
    }

    return Padding(
      padding: const EdgeInsets.only(left: PlayerTableColumns.nameInset),
      child: Row(
        children: [
          cell(l10n.players_header_name, null),
          const SizedBox(width: PlayerTableColumns.gap),
          cell(l10n.players_header_sign_in_id, PlayerTableColumns.id),
          const SizedBox(width: PlayerTableColumns.gap),
          cell(l10n.players_header_level, PlayerTableColumns.level),
          const SizedBox(width: PlayerTableColumns.gap),
          cell(l10n.players_header_type, PlayerTableColumns.type),
          const SizedBox(
            width: PlayerTableColumns.gap + PlayerTableColumns.more,
          ),
        ],
      ),
    );
  }
}

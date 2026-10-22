import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_button.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_menu.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/l10n/skill_tier_l10n.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/player.dart';

/// What the slot "⋯" menu offers (ARCHITECTURE §2.3 SlotActionMenu).
enum SlotMenu {
  /// No "⋯": an open slot, or a checked-out player on a live court while
  /// the clock runs (R11-Q4).
  none,

  /// "Check out" only: a live court while the clock runs (R7-Q4).
  checkOutOnly,

  /// "Move to waitlist" and "Check out" (COURT-15).
  full,
}

/// One slot of a [DesktopCourtCard], with the callbacks it needs.
class CourtSlotData {
  const CourtSlotData({
    required this.player,
    required this.menu,
    this.isSelected = false,
    this.onTap,
    this.onMoveToWaitlist,
    this.onCheckOut,
  });

  final Player? player;
  final SlotMenu menu;
  final bool isSelected;

  /// `null`: the slot is not a tap button (F11, COURT-09).
  final VoidCallback? onTap;
  final VoidCallback? onMoveToWaitlist;
  final VoidCallback? onCheckOut;
}

/// A court on the desktop Courts tab (IMPLEMENTATION 8.5.4, ARCHITECTURE
/// §2.3 CourtCard; UAT COURT-01, COURT-14).
///
/// Header: "Court {k}", the level gap as plain text, the tags and
/// "Re-roll". Under it 4 slots share the card height. In edit mode
/// ([isNextRound]) the card has the `#fffaf2` fill and a 2 px dashed
/// `#c2410c` border.
class DesktopCourtCard extends StatelessWidget {
  const DesktopCourtCard({
    super.key,
    required this.courtIndex,
    required this.slots,
    required this.levelGap,
    this.isNextRound = false,
    this.onReroll,
  });

  /// 0-based; the title shows `courtIndex + 1`.
  final int courtIndex;
  final List<CourtSlotData> slots;

  /// The tier gap (`Game.tierGap()`), shown when the court holds a player.
  final int levelGap;

  /// Edit mode for round n+1: dashed border and "NEXT" tag (RND-10).
  final bool isNextRound;

  /// `null`: no "Re-roll" button (R3-Q10, COURT-14).
  final VoidCallback? onReroll;

  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = slots.where((slot) => slot.player != null).length;
    final short = count > 0 && count < slots.length;
    final card = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Text(
                  l10n.courts_court_title(courtIndex + 1),
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(width: AppSpacing.sm),
                if (count > 0)
                  Flexible(
                    child: Text(
                      l10n.dashboard_spread(levelGap),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sm,
                    ),
                  ),
                if (isNextRound) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _Tag(l10n.courts_tag_next),
                ],
                if (short) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _Tag(l10n.courts_tag_players(count)),
                ],
                const Spacer(),
                if (onReroll != null)
                  CourtsButton.secondary(
                    label: l10n.dashboard_reroll,
                    icon: Icons.refresh_rounded,
                    semanticsLabel: l10n.courts_reroll_court(courtIndex + 1),
                    onPressed: onReroll,
                  ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slotHeight = min(
                  DesktopPlayerSlot.height,
                  constraints.maxHeight / slots.length,
                );
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, slot) in slots.indexed)
                      SizedBox(
                        height: slotHeight,
                        child: DesktopPlayerSlot(
                          key: Key('slot-$courtIndex-$index'),
                          moreKey: Key('slot-more-$courtIndex-$index'),
                          player: slot.player,
                          menu: slot.menu,
                          isSelected: slot.isSelected,
                          onTap: slot.onTap,
                          onMoveToWaitlist: slot.onMoveToWaitlist,
                          onCheckOut: slot.onCheckOut,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: l10n.courts_court_title(courtIndex + 1),
      explicitChildNodes: true,
      child: isNextRound
          ? CustomPaint(
              foregroundPainter: const _DashedBorderPainter(
                color: AppColors.accentStrong,
                radius: _radius,
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceNext,
                  borderRadius: BorderRadius.all(Radius.circular(_radius)),
                ),
                child: card,
              ),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: const BorderRadius.all(Radius.circular(_radius)),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: card,
            ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: const BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      child: Text(
        text,
        maxLines: 1,
        style: AppTypography.statLabel.copyWith(color: AppColors.warningText),
      ),
    );
  }
}

/// The 2 px dashed edit-mode border (RND-10).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _width = 2;
  static const double _dash = 6;
  static const double _space = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width;
    final rect = (Offset.zero & size).deflate(_width / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
        distance += _dash + _space;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// One slot row on a [DesktopCourtCard] (ARCHITECTURE §2.3 PlayerSlot;
/// UAT COURT-01, COURT-10, COURT-15).
///
/// 40 px, radius 6. A filled slot shows the name and the tier name. The
/// "⋯" shows on hover and when the slot or the "⋯" has keyboard focus
/// (F06); its hit area is 40 × 40 (F27). With no [onTap] the slot is not a
/// tap button (F11).
class DesktopPlayerSlot extends StatefulWidget {
  const DesktopPlayerSlot({
    super.key,
    required this.player,
    required this.menu,
    this.moreKey,
    this.isSelected = false,
    this.onTap,
    this.onMoveToWaitlist,
    this.onCheckOut,
  });

  static const double height = 40;

  final Player? player;
  final SlotMenu menu;
  final Key? moreKey;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onMoveToWaitlist;
  final VoidCallback? onCheckOut;

  @override
  State<DesktopPlayerSlot> createState() => _DesktopPlayerSlotState();
}

class _DesktopPlayerSlotState extends State<DesktopPlayerSlot> {
  final _moreFocus = FocusNode();
  bool _hovered = false;
  bool _focusWithin = false;
  bool _slotFocused = false;

  @override
  void dispose() {
    _moreFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final player = widget.player;
    final tier = player?.elo.skillTier.localizedLabel(l10n) ?? '';

    final label = Row(
      children: [
        Expanded(
          child: player == null
              ? Text(
                  l10n.dashboard_open_slot,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMuted,
                  ),
                )
              : Text(
                  player.name(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.md,
                ),
        ),
        if (player != null)
          SizedBox(
            width: 96,
            child: Text(
              tier,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          ),
      ],
    );

    final onTap = widget.onTap;
    final Widget body = onTap == null
        ? Semantics(
            container: true,
            label: player == null ? null : '${player.name()}, $tier',
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: label,
              ),
            ),
          )
        : Semantics(
            container: true,
            button: true,
            selected: widget.isSelected,
            label: player == null
                ? l10n.dashboard_open_slot
                : l10n.courts_slot_select(player.name(), tier),
            child: ExcludeSemantics(
              child: FocusRing(
                focused: _slotFocused,
                color: AppColors.focusOnLight,
                radius: AppRadii.sm,
                child: InkWell(
                  onTap: onTap,
                  onFocusChange: (value) =>
                      setState(() => _slotFocused = value),
                  borderRadius: AppRadii.smRadius,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: label,
                  ),
                ),
              ),
            ),
          );

    final showMore = _hovered || _focusWithin;
    final Widget more = switch (widget.menu) {
      SlotMenu.none => const SizedBox(width: 40),
      _ when player == null => const SizedBox(width: 40),
      _ => Opacity(
        opacity: showMore ? 1 : 0,
        child: courtsMenuAnchor(
          focusNode: _moreFocus,
          items: [
            if (widget.menu == SlotMenu.full)
              (
                label: l10n.courts_slot_move_to_waitlist,
                onPressed: () => widget.onMoveToWaitlist?.call(),
                danger: false,
              ),
            (
              label: l10n.courts_slot_check_out,
              onPressed: () => widget.onCheckOut?.call(),
              danger: false,
            ),
          ],
          builder: (context, toggle) => CourtsIconButton(
            key: widget.moreKey,
            icon: Icons.more_horiz_rounded,
            iconSize: 16,
            tooltip: l10n.courts_slot_open_actions(player.name(), tier),
            color: AppColors.textMuted,
            ringColor: AppColors.focusOnLight,
            focusNode: _moreFocus,
            onPressed: toggle,
          ),
        ),
      ),
    };

    final selected = widget.isSelected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (value) => setState(() => _focusWithin = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: AppRadii.smRadius,
            color: selected
                ? AppColors.warningBg
                : (_hovered ? AppColors.surfaceHover : null),
            border: selected
                ? Border.all(color: AppColors.accentStrong, width: 3)
                : null,
          ),
          child: Row(
            children: [
              Expanded(child: body),
              more,
            ],
          ),
        ),
      ),
    );
  }
}

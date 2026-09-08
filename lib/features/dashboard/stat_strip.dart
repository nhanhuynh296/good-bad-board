import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

/// A responsive stat strip that adapts column count to the breakpoint.
///
/// Desktop (≥1080px): 6 columns | Tablet (720–1079px): 3 columns | Phone (<720px): 2 columns
///
/// Displays key session metrics as [AppStatCell] widgets:
/// Checked In, Remaining Slots, Waitlist, Avg Level, Avg Level Gap, Re-rolls.
class StatStrip extends StatelessWidget {
  const StatStrip({
    super.key,
    this.checkedIn = '0',
    this.remainingSlots = '0',
    this.waitlist = '0',
    this.avgLevel = '—',
    this.avgLevelGap = '—',
    this.rerolls = '0',
  });

  final String checkedIn;
  final String remainingSlots;
  final String waitlist;
  final String avgLevel;
  final String avgLevelGap;
  final String rerolls;

  static const _divider = VerticalDivider(
    width: 1,
    thickness: 1,
    color: AppColors.cardBorder,
    indent: 4,
    endIndent: 4,
  );

  /// Builds a row of stat cells separated by vertical dividers.
  Widget _buildCellRow(List<Widget> cells) {
    final children = <Widget>[];
    for (var i = 0; i < cells.length; i++) {
      children.add(Expanded(child: cells[i]));
      if (i < cells.length - 1) {
        children.add(_divider);
      }
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cells = [
      AppStatCell(label: 'Checked In', value: checkedIn),
      AppStatCell(label: 'Remaining Slots', value: remainingSlots),
      AppStatCell(label: 'Waitlist', value: waitlist, isAccent: true),
      AppStatCell(label: 'Avg Level', value: avgLevel),
      AppStatCell(label: 'Avg Level Gap', value: avgLevelGap),
      AppStatCell(label: 'Re-rolls', value: rerolls),
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (isDesktop(width)) {
            // 6 columns in one row
            return _buildCellRow(cells);
          } else if (isTablet(width)) {
            // 2 rows × 3 columns
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCellRow(cells.sublist(0, 3)),
                const Divider(height: 1, color: AppColors.cardBorder),
                _buildCellRow(cells.sublist(3, 6)),
              ],
            );
          } else {
            // 2 rows × 2 columns (phone) — per UAT NAV-06:
            // Checked In, Waitlist, Avg Level, Remaining
            final phoneCells = [
              cells[0], // Checked In
              cells[2], // Waitlist
              cells[3], // Avg Level
              cells[1], // Remaining Slots
            ];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCellRow(phoneCells.sublist(0, 2)),
                const Divider(height: 1, color: AppColors.cardBorder),
                _buildCellRow(phoneCells.sublist(2, 4)),
              ],
            );
          }
        },
      ),
    );
  }
}

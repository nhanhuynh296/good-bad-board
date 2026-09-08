import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/features/analytics/bar_chart.dart';

/// ANA-06 — per-court average level-gap comparison, flagging courts that
/// consistently absorb overflow (wider gaps).
class CourtGapComparisonCard extends StatelessWidget {
  const CourtGapComparisonCard({super.key, required this.courts});

  final List<CourtGapSummary> courts;

  @override
  Widget build(BuildContext context) {
    final flagged = courts.where((c) => c.isOverflowAbsorber).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(title: 'Per-court fairness'),
          const SizedBox(height: AppSpacing.md),
          HorizontalBarList(
            entries: courts
                .map(
                  (c) => ChartPoint(
                    label: 'Court ${c.courtNumber}',
                    value: c.averageGap,
                    valueLabel: c.averageGap.toStringAsFixed(1),
                  ),
                )
                .toList(),
            barColor: AppColors.barSecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            flagged.isEmpty
                ? 'No court consistently runs a wider gap than the rest.'
                : 'Court${flagged.length > 1 ? 's' : ''} '
                      '${flagged.map((c) => c.courtNumber).join(', ')} '
                      'regularly absorb overflow with wider gaps.',
            style: AppTypography.helper,
          ),
        ],
      ),
    );
  }
}

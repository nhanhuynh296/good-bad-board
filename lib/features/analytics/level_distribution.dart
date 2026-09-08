import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/features/analytics/bar_chart.dart';

/// ANA-09 — player counts per tier across the whole club, with median tier
/// and an optional stagnation callout.
class LevelDistributionCard extends StatelessWidget {
  const LevelDistributionCard({super.key, required this.result});

  final LevelDistributionResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(title: 'Level distribution'),
          const SizedBox(height: AppSpacing.md),
          BarChart(points: result.points, barColor: AppColors.barSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Median tier: ${result.medianTierLabel}',
            style: AppTypography.helper,
          ),
          if (result.stagnationNote != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '⚠ ${result.stagnationNote}',
              style: AppTypography.helperBold.copyWith(
                color: AppColors.warningText,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

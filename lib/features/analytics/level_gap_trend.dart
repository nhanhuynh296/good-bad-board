import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/features/analytics/bar_chart.dart';

/// ANA-05 — average level-gap per court over time, expressed as tier-gap
/// (never raw ELO), with an improving/worsening note.
class LevelGapTrendChart extends StatelessWidget {
  const LevelGapTrendChart({super.key, required this.result});

  final TrendResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(title: 'Level-gap trend'),
          const SizedBox(height: AppSpacing.md),
          BarChart(points: result.points, barColor: AppColors.barSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(result.note, style: AppTypography.helper),
        ],
      ),
    );
  }
}

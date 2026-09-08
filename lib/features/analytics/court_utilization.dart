import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/features/analytics/bar_chart.dart';

/// ANA-07 — per-session court fill rate, plus a full-4 fill-rate summary
/// and average idle-court time.
class CourtUtilizationCard extends StatelessWidget {
  const CourtUtilizationCard({super.key, required this.result});

  final CourtUtilizationResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(title: 'Court utilization'),
          const SizedBox(height: AppSpacing.md),
          BarChart(points: result.points, barColor: AppColors.success),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Full-4 fill rate: ${result.fullFillRatePct.toStringAsFixed(0)}% · '
            'avg ${result.avgIdleCourtsPerSession.toStringAsFixed(1)} idle courts/session',
            style: AppTypography.helper,
          ),
        ],
      ),
    );
  }
}

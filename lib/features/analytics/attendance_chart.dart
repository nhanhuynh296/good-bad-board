import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/features/analytics/bar_chart.dart';

/// ANA-03 — per-session attendance rate trend, most recent session
/// emphasized, with a growth note.
class AttendanceChart extends StatelessWidget {
  const AttendanceChart({super.key, required this.result});

  final TrendResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(title: 'Attendance trend'),
          const SizedBox(height: AppSpacing.md),
          BarChart(points: result.points, emphasizeLastBar: true),
          const SizedBox(height: AppSpacing.sm),
          Text(result.note, style: AppTypography.helper),
        ],
      ),
    );
  }
}

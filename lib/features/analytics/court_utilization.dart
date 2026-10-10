import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/features/analytics/bar_chart.dart';

/// ANA-07 — per-session court fill rate, plus a full-4 fill-rate summary
/// and average idle-court time.
class CourtUtilizationCard extends StatelessWidget {
  const CourtUtilizationCard({super.key, required this.result});

  final CourtUtilizationResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(title: l10n.analytics_court_utilization),
          const SizedBox(height: AppSpacing.md),
          BarChart(points: result.points, barColor: AppColors.success),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.analytics_court_util_summary(
              result.fullFillRatePct.toStringAsFixed(0),
              result.avgIdleCourtsPerSession.toStringAsFixed(1),
            ),
            style: AppTypography.helper,
          ),
        ],
      ),
    );
  }
}

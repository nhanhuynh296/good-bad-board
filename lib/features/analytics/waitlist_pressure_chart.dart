import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/features/analytics/bar_chart.dart';

/// ANA-04 — per-session waitlist counts with a capacity-planning note.
class WaitlistPressureChart extends StatelessWidget {
  const WaitlistPressureChart({super.key, required this.result});

  final TrendResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(
            title: AppLocalizations.of(context)!.analytics_waitlist_pressure,
          ),
          const SizedBox(height: AppSpacing.md),
          BarChart(points: result.points, barColor: AppColors.barTertiary),
          const SizedBox(height: AppSpacing.sm),
          Text(result.note, style: AppTypography.helper),
        ],
      ),
    );
  }
}

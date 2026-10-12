import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/features/analytics/bar_chart.dart';

/// ANA-09 — player counts per tier across the whole club, with median tier,
/// a trend note and an optional stagnation callout.
class LevelDistributionCard extends StatelessWidget {
  const LevelDistributionCard({super.key, required this.result});

  final LevelDistributionResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(title: l10n.analytics_level_distribution),
          const SizedBox(height: AppSpacing.md),
          BarChart(points: result.points, barColor: AppColors.barSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.analytics_median_tier(result.medianTierLabel),
            style: AppTypography.helper,
          ),
          if (result.trendNote != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(result.trendNote!, style: AppTypography.helper),
          ],
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

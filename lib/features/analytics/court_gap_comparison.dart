import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/features/analytics/bar_chart.dart';

/// ANA-06 — per-court average level-gap comparison, flagging courts that
/// consistently absorb overflow (wider gaps).
class CourtGapComparisonCard extends StatelessWidget {
  const CourtGapComparisonCard({super.key, required this.courts});

  final List<CourtGapSummary> courts;

  @override
  Widget build(BuildContext context) {
    final flagged = courts.where((c) => c.isOverflowAbsorber).toList();
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(title: l10n.analytics_per_court_fairness),
          const SizedBox(height: AppSpacing.md),
          HorizontalBarList(
            entries: courts
                .map(
                  (c) => ChartPoint(
                    label: l10n.court_n(c.courtNumber),
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
                ? l10n.analytics_no_court_wider_gap
                : l10n.analytics_courts_absorb_overflow(
                    flagged.length,
                    flagged.map((c) => c.courtNumber).join(', '),
                  ),
            style: AppTypography.helper,
          ),
        ],
      ),
    );
  }
}

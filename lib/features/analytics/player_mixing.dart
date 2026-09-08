import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/features/analytics/bar_chart.dart';

/// ANA-12 — 0–1 mixing score per player (distinct partners ÷ games played),
/// tagged connector / clique / isolated.
class PlayerMixingCard extends StatelessWidget {
  const PlayerMixingCard({super.key, required this.entries});

  final List<MixingEntry> entries;

  @override
  Widget build(BuildContext context) {
    // Cap the list to a readable sample per the ARCHITECTURE.md spec.
    final sample = entries.take(10).toList();
    final connectors = entries.where((e) => e.tag == 'connector').length;
    final isolated = entries.where((e) => e.tag == 'isolated').length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(title: 'Player mixing'),
          const SizedBox(height: AppSpacing.md),
          HorizontalBarList(
            entries: sample
                .map(
                  (e) => ChartPoint(
                    label: e.name,
                    value: e.score,
                    valueLabel: e.score.toStringAsFixed(2),
                  ),
                )
                .toList(),
            barColor: AppColors.accentPrimary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$connectors connector${connectors == 1 ? '' : 's'} bridging the club, '
            '$isolated player${isolated == 1 ? '' : 's'} playing a narrow circle.',
            style: AppTypography.helper,
          ),
        ],
      ),
    );
  }
}

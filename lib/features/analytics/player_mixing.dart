import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/features/analytics/bar_chart.dart';

/// ANA-12 — 0–1 mixing score per player (distinct partners ÷ games played),
/// tagged connector / clique / isolated. Lists a sample: the highest and
/// lowest scores.
class PlayerMixingCard extends StatelessWidget {
  const PlayerMixingCard({super.key, required this.entries});

  final List<MixingEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String? tagLabel(MixingTag? tag) => switch (tag) {
      MixingTag.connector => l10n.analytics_mixing_tag_connector,
      MixingTag.clique => l10n.analytics_mixing_tag_clique,
      MixingTag.isolated => l10n.analytics_mixing_tag_isolated,
      null => null,
    };
    int count(MixingTag tag) => entries.where((e) => e.tag == tag).length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(title: l10n.analytics_player_mixing),
          const SizedBox(height: AppSpacing.md),
          HorizontalBarList(
            entries: sampleMixing(entries)
                .map(
                  (e) => ChartPoint(
                    label: e.name,
                    value: e.score,
                    valueLabel: e.score.toStringAsFixed(2),
                    caption: tagLabel(e.tag),
                  ),
                )
                .toList(),
            barColor: AppColors.accentPrimary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.analytics_mixing_summary(
              l10n.analytics_mixing_connectors(count(MixingTag.connector)),
              l10n.analytics_mixing_cliques(count(MixingTag.clique)),
              l10n.analytics_mixing_isolated(count(MixingTag.isolated)),
            ),
            style: AppTypography.helper,
          ),
        ],
      ),
    );
  }
}

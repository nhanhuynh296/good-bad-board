import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

/// ANA-11 — regular attendees not seen in 3+ weeks.
class AtRiskPlayersCard extends StatelessWidget {
  const AtRiskPlayersCard({super.key, required this.result});

  final AtRiskResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(
            title: l10n.analytics_at_risk_players(result.lapsedCount),
          ),
          const SizedBox(height: AppSpacing.md),
          if (result.entries.isEmpty)
            Text(
              l10n.analytics_no_lapsed,
              style: const TextStyle(
                fontFamily: AppTypography.family,
                fontSize: AppTypography.sizeBody,
                fontStyle: FontStyle.italic,
                color: AppColors.textSubtle,
              ),
            )
          else
            for (final entry in result.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: const TextStyle(
                          fontFamily: AppTypography.family,
                          fontSize: AppTypography.sizeBody,
                          fontWeight: AppTypography.semibold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      l10n.analytics_usually_per_month(
                        entry.usualFrequencyPerMonth.toStringAsFixed(1),
                      ),
                      style: AppTypography.helper,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.analytics_weeks_since_seen(entry.weeksSinceLastSeen),
                      style: AppTypography.helperBold.copyWith(
                        color: AppColors.warningText,
                        fontSize: AppTypography.sizeCaption,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

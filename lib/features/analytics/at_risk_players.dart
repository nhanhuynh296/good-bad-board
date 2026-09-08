import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';

/// ANA-11 — regular attendees not seen in 3+ weeks.
class AtRiskPlayersCard extends StatelessWidget {
  const AtRiskPlayersCard({super.key, required this.result});

  final AtRiskResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(title: 'At-risk players (${result.lapsedCount})'),
          const SizedBox(height: AppSpacing.md),
          if (result.entries.isEmpty)
            const Text(
              'No regular attendees have lapsed',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 13,
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
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      'usually ${entry.usualFrequencyPerMonth.toStringAsFixed(1)}x/mo',
                      style: AppTypography.helper,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${entry.weeksSinceLastSeen}w since last seen',
                      style: AppTypography.helperBold.copyWith(
                        color: AppColors.warningText,
                        fontSize: 11,
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

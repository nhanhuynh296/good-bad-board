import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';

/// ANA-13 — recently joined players, their attendance, and how much of
/// their play has been alongside regulars.
class NewPlayerIntegrationCard extends StatelessWidget {
  const NewPlayerIntegrationCard({super.key, required this.entries});

  final List<NewPlayerEntry> entries;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(title: 'New player integration'),
          const SizedBox(height: AppSpacing.md),
          if (entries.isEmpty)
            const Text(
              'No new players in this window',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textSubtle,
              ),
            )
          else
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.name,
                            style: const TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Joined ${entry.joinDate.month}/${entry.joinDate.day} · '
                            '${entry.sessionsAttended} sessions',
                            style: AppTypography.helper,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: entry.isFavorable
                            ? AppColors.successBg
                            : AppColors.warningBg,
                        borderRadius: AppRadii.fullRadius,
                      ),
                      child: Text(
                        '${entry.pctWithRegulars.toStringAsFixed(0)}% with regulars',
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: entry.isFavorable
                              ? AppColors.success
                              : AppColors.warningText,
                        ),
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

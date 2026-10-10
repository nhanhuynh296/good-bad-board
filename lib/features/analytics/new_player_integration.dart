import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

/// ANA-13 — recently joined players, their attendance, and how much of
/// their play has been alongside regulars.
class NewPlayerIntegrationCard extends StatelessWidget {
  const NewPlayerIntegrationCard({super.key, required this.entries});

  final List<NewPlayerEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(title: l10n.analytics_new_player_integration),
          const SizedBox(height: AppSpacing.md),
          if (entries.isEmpty)
            Text(
              l10n.analytics_no_new_players,
              style: const TextStyle(
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
                            l10n.analytics_joined_sessions(
                              l10n.analytics_short_date(
                                entry.joinDate.month,
                                entry.joinDate.day,
                              ),
                              entry.sessionsAttended,
                            ),
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
                        l10n.analytics_pct_with_regulars(
                          entry.pctWithRegulars.toStringAsFixed(0),
                        ),
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

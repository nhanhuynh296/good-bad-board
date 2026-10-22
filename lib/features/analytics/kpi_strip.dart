import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

/// Responsive grid of [AppKpiCard]s — ANA-02. 7 cols desktop (one row with
/// the Members tile, R13-Q10), 3 tablet, 1 phone (ANA-14).
class KpiStrip extends StatelessWidget {
  const KpiStrip({super.key, required this.kpis});

  final List<KpiEntry> kpis;

  @override
  Widget build(BuildContext context) {
    // Window width, not the width left after shell padding (ANA-14).
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = isDesktop(width) ? 7 : (isTablet(width) ? 3 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        // A fixed height, not an aspect ratio: at phone width a card is
        // narrow, the context line wraps, and a ratio-based height
        // overflows. 144, not 140: with 7 desktop columns a two-line
        // context line needs the extra pixels (R13-Q10).
        mainAxisExtent: 144,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        final kpi = kpis[index];
        return AppKpiCard(
          label: kpi.label,
          value: kpi.value,
          delta: kpi.contextLine,
          deltaPositive: kpi.deltaPositive,
        );
      },
    );
  }
}

/// Time-range switcher for ANA-01: 4 / 12 / 26 weeks.
class AnalyticsRangeSwitcher extends StatelessWidget {
  const AnalyticsRangeSwitcher({
    super.key,
    required this.selectedWeeks,
    required this.onChanged,
  });

  final int selectedWeeks;
  final void Function(int weeks) onChanged;

  static const _options = [4, 12, 26];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final weeks in _options) ...[
          _RangeChip(
            label: l10n.analytics_weeks_short(weeks),
            isSelected: weeks == selectedWeeks,
            onTap: () => onChanged(weeks),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.fullRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentPrimary : AppColors.pillBg,
            borderRadius: AppRadii.fullRadius,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.family,
              fontSize: AppTypography.sizeCaption,
              fontWeight: AppTypography.semibold,
              color: isSelected
                  ? AppColors.accentOnPrimary
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

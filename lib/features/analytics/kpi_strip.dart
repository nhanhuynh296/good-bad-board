import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';

/// Responsive grid of [AppKpiCard]s — ANA-02. 6 cols desktop, 3 tablet,
/// 2 phone.
class KpiStrip extends StatelessWidget {
  const KpiStrip({super.key, required this.kpis});

  final List<KpiEntry> kpis;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = isDesktop(width) ? 6 : (isTablet(width) ? 3 : 2);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.4,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final weeks in _options) ...[
          _RangeChip(
            label: '$weeks wks',
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
              fontFamily: AppTypography.bodyFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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

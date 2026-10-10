import 'package:flutter/widgets.dart';
import 'package:good_bad_board/design/design.dart';

/// Larger stat card for analytics dashboards.
///
/// Label: 10.5px, 800, uppercase, textMuted.
/// Value: 26px, Space Grotesk 800, textPrimary.
/// Delta: optional 11px, 700 — green when [deltaPositive] is `true`, red
/// when `false`, or neutral (muted) when `null` — e.g. for a purely
/// descriptive context line with no real trend to report.
class AppKpiCard extends StatelessWidget {
  const AppKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.deltaPositive,
  });

  final String label;
  final String value;
  final String? delta;
  final bool? deltaPositive;

  static const _labelStyle = TextStyle(
    fontFamily: AppTypography.bodyFont,
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    color: AppColors.textMuted,
    letterSpacing: 0.05 * 10,
  );

  static const _deltaPositiveStyle = TextStyle(
    fontFamily: AppTypography.bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.deltaPositive,
  );

  static const _deltaNegativeStyle = TextStyle(
    fontFamily: AppTypography.bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.deltaNegative,
  );

  static const _deltaNeutralStyle = TextStyle(
    fontFamily: AppTypography.bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: _labelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.kpiValueLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (delta != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              delta!,
              style: switch (deltaPositive) {
                true => _deltaPositiveStyle,
                false => _deltaNegativeStyle,
                null => _deltaNeutralStyle,
              },
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

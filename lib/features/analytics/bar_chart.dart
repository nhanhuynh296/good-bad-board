import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

/// A generic horizontal/vertical bar chart. Bars are bottom-aligned; the
/// tallest bar fills [height]. No external chart library — a `Row` of
/// fractional-height `Container`s per ARCHITECTURE.md §2.7.
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.points,
    this.height = 140,
    this.emphasizeLastBar = false,
    this.barColor = AppColors.accentPrimary,
  });

  final List<ChartPoint> points;
  final double height;

  /// Visually emphasizes the most recent (last) bar — used by ANA-03.
  final bool emphasizeLastBar;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.analytics_no_session_data,
            style: const TextStyle(
              fontFamily: AppTypography.family,
              fontSize: AppTypography.sizeBody,
              fontStyle: FontStyle.italic,
              color: AppColors.textSubtle,
            ),
          ),
        ),
      );
    }

    final maxValue = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < points.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (points[i].valueLabel != null)
                      Text(
                        points[i].valueLabel!,
                        style: const TextStyle(
                          fontFamily: AppTypography.family,
                          fontSize: AppTypography.sizeCaption,
                          fontWeight: AppTypography.semibold,
                          color: AppColors.textMuted,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: (points[i].value / safeMax).clamp(
                            0.02,
                            1.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: emphasizeLastBar && i == points.length - 1
                                  ? barColor
                                  : barColor.withValues(
                                      alpha: emphasizeLastBar ? 0.55 : 1,
                                    ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      points[i].label,
                      style: const TextStyle(
                        fontFamily: AppTypography.family,
                        fontSize: AppTypography.sizeCaption,
                        color: AppColors.textSubtle,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A horizontal bar-per-item list (used by ANA-06, ANA-07, ANA-12).
class HorizontalBarList extends StatelessWidget {
  const HorizontalBarList({
    super.key,
    required this.entries,
    this.barColor = AppColors.accentPrimary,
  });

  final List<ChartPoint> entries;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.analytics_no_data,
        style: const TextStyle(
          fontFamily: AppTypography.family,
          fontSize: AppTypography.sizeBody,
          fontStyle: FontStyle.italic,
          color: AppColors.textSubtle,
        ),
      );
    }
    final maxValue = entries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries) ...[
          Row(
            children: [
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: const TextStyle(
                        fontFamily: AppTypography.family,
                        fontSize: AppTypography.sizeCaption,
                        fontWeight: AppTypography.semibold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.caption != null)
                      Text(
                        entry.caption!,
                        style: const TextStyle(
                          fontFamily: AppTypography.family,
                          fontSize: AppTypography.sizeCaption,
                          color: AppColors.textSubtle,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadii.smRadius,
                  child: LinearProgressIndicator(
                    value: (entry.value / safeMax).clamp(0, 1),
                    minHeight: 10,
                    backgroundColor: AppColors.pillBg,
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 40,
                child: Text(
                  entry.valueLabel ?? entry.value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: AppTypography.family,
                    fontSize: AppTypography.sizeCaption,
                    fontWeight: AppTypography.semibold,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

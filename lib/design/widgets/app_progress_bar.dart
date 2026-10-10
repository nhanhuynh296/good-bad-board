import 'package:flutter/widgets.dart';
import 'package:good_bad_board/design/design.dart';

/// Horizontal progress bar with fill.
///
/// Track: pillBg background, configurable [height], fully rounded ends.
/// Fill: accentPrimary, width driven by [fraction] (0.0–1.0).
///
/// When [showLabel] is true, a percentage label (e.g. "75%") is rendered
/// above the bar.
///
/// The bar fills its parent's width. Place it inside a widget that provides
/// a definite horizontal constraint (e.g. [SizedBox], [Expanded], or a
/// [Column] with `crossAxisAlignment: CrossAxisAlignment.stretch`).
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.fraction,
    this.height = 10,
    this.showLabel = false,
  });

  final double fraction;
  final double height;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    // Guard against NaN which passes through clamp unchanged
    final clampedFraction = fraction.isNaN ? 0.0 : fraction.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              '${(clampedFraction * 100).round()}%',
              style: AppTypography.helperBold,
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(height / 2)),
            child: Stack(
              children: [
                // Track
                Positioned.fill(child: Container(color: AppColors.pillBg)),
                // Fill
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: clampedFraction,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary,
                      borderRadius: BorderRadius.all(
                        Radius.circular(height / 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

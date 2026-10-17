import 'package:flutter/widgets.dart';
import 'package:good_bad_board/design/design.dart';

/// A label + value pair used in stat strips.
///
/// Label: 10px, 700, uppercase, textMuted, 0.05em letter-spacing.
/// Value: 19px, 800, textPrimary (or accent when [isAccent] is true).
class AppStatCell extends StatelessWidget {
  const AppStatCell({
    super.key,
    required this.label,
    required this.value,
    this.isAccent = false,
  });

  final String label;
  final String value;
  final bool isAccent;

  static final _accentValueStyle = AppTypography.statValue.copyWith(
    color: AppColors.accentPrimary,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.statLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: isAccent ? _accentValueStyle : AppTypography.statValue,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

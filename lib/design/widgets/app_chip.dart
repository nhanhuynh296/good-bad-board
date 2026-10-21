import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

/// Pill-shaped chip for spread indicators, waitlist chips, and status badges.
///
/// Two padding variants: compact (8h/4v) for spread/inline chips, and
/// non-compact (11h/7v) for waitlist chips.
///
/// Selected state uses accent background with white text; unselected uses
/// pill background with primary text.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.compact = true,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool compact;

  static final _selectedStyle = AppTypography.chip.copyWith(
    color: AppColors.accentOnPrimary,
  );

  static const _unselectedStyle = AppTypography.chip;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? AppColors.accentPrimary
        : AppColors.pillBg;
    final textStyle = isSelected ? _selectedStyle : _unselectedStyle;
    final padding = compact
        ? AppSpacing.chipPadding
        : AppSpacing.waitlistChipPadding;

    final chip = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.fullRadius,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      ),
    );

    if (onTap != null) {
      return ClipRRect(
        borderRadius: AppRadii.fullRadius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.fullRadius,
            child: chip,
          ),
        ),
      );
    }

    return chip;
  }
}

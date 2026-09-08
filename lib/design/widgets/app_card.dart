import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

/// A card container matching the design system spec.
///
/// Defaults: bg=cardBg, border=1px solid cardBorder, borderRadius=xlRadius,
/// padding=cardPadding. All can be overridden via constructor parameters.
///
/// When [onTap] is provided, the card wraps its child in an [InkWell] for
/// tap interaction with ink splash clipping.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  static const _defaultBorder = Border(
    top: BorderSide(color: AppColors.cardBorder),
    left: BorderSide(color: AppColors.cardBorder),
    right: BorderSide(color: AppColors.cardBorder),
    bottom: BorderSide(color: AppColors.cardBorder),
  );

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadii.xlRadius;

    final container = Container(
      clipBehavior: Clip.antiAlias,
      padding: padding ?? AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBg,
        border: _defaultBorder,
        borderRadius: effectiveRadius,
      ),
      child: child,
    );

    if (onTap != null) {
      return ClipRRect(
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          child: container,
        ),
      );
    }

    return container;
  }
}

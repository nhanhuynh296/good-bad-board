import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/theme.dart';
import 'package:good_bad_board/view/component/button.dart';

class ShadedContainer extends StatelessWidget {
  final Widget child;
  final bool shaded;
  final bool bordered;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? shadedColor;

  const ShadedContainer({
    super.key,
    required this.child,
    this.shaded = true,
    this.bordered = true,
    this.borderColor,
    this.backgroundColor,
    this.shadedColor,
  });

  @override
  Widget build(BuildContext context) {
    const baseDecoration = BoxDecoration(borderRadius: outlinedBorderRadius);

    final borderedDecoration = baseDecoration.copyWith(
      border: bordered
          ? BoxBorder.fromBorderSide(
              outlinedBorderSide.copyWith(
                color: borderColor ?? context.theme.colorScheme.onSurface,
              ),
            )
          : null,
    );

    final backgroundDecoration = baseDecoration.copyWith(
      color: backgroundColor ?? context.colorScheme.surface,
      boxShadow: [
        if (shaded)
          OutlinedButtonWidget.buttonBoxShadow.copyWith(
            color: shadedColor ?? Theme.of(context).colorScheme.inverseSurface,
          ),
      ],
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      foregroundDecoration: borderedDecoration,
      decoration: backgroundDecoration,
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

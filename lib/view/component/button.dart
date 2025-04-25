import 'package:flutter/material.dart';
import 'package:good_bad_board/theme.dart';

enum ButtonType { filled, outlined, text }

class Button extends StatelessWidget {
  final ButtonType type;
  final bool disabled;
  final Widget? child;
  final Icon? icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final TextStyle? textStyle;
  final Color? backgroundColor;

  const Button({
    super.key,
    this.type = ButtonType.text,
    this.disabled = false,
    this.child,
    this.icon,
    this.onPressed,
    this.onLongPress,
    this.textStyle,
    this.backgroundColor,
  }) : assert(icon != null || child != null, 'icon or child must be provided');

  static const buttonBoxShadow = BoxShadow(offset: Offset(4, 4));

  @override
  Widget build(BuildContext context) {
    final onlyIcon = icon != null && child == null;
    final onTapLogic = disabled ? null : onPressed ?? () {};
    final onSecondaryTapLogic = disabled ? null : onLongPress;
    final allStateTextStyle = WidgetStatePropertyAll(textStyle);

    final outlinedButtonStyle = ButtonStyle(
      textStyle: allStateTextStyle,
      backgroundColor: WidgetStatePropertyAll(
        backgroundColor ?? Theme.of(context).colorScheme.surface,
      ),
      side: WidgetStatePropertyAll(
        outlinedBorderSide.copyWith(
          color: Theme.of(context).colorScheme.inverseSurface,
        ),
      ),
    );

    return switch (type) {
      ButtonType.filled => Container(
        decoration: BoxDecoration(
          borderRadius: outlinedBorderRadius,
          boxShadow: [
            buttonBoxShadow.copyWith(
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ],
        ),
        child:
            onlyIcon
                ? IconButton.filled(onPressed: onPressed, icon: icon!)
                : FilledButton(
                  style: ButtonStyle(textStyle: allStateTextStyle),
                  onPressed: onTapLogic,
                  onLongPress: onSecondaryTapLogic,
                  child: child,
                ),
      ),
      ButtonType.outlined => Container(
        decoration: BoxDecoration(
          borderRadius: outlinedBorderRadius,
          boxShadow: [
            buttonBoxShadow.copyWith(
              color: Theme.of(context).colorScheme.inverseSurface,
            ),
          ],
        ),
        child:
            onlyIcon
                ? IconButton.outlined(
                  onPressed: onPressed,
                  icon: icon!,
                  style: outlinedButtonStyle,
                )
                : OutlinedButton(
                  style: outlinedButtonStyle,
                  onPressed: onTapLogic,
                  onLongPress: onSecondaryTapLogic,
                  child: child,
                ),
      ),
      ButtonType.text =>
        onlyIcon
            ? IconButton(onPressed: onPressed, icon: icon!)
            : TextButton(
              style: ButtonStyle(textStyle: allStateTextStyle),
              onPressed: onTapLogic,
              onLongPress: onSecondaryTapLogic,
              child: child!,
            ),
    };
  }
}

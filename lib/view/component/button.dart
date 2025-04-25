import 'package:flutter/material.dart';

enum ButtonType { filled, outlined, text }

class Button extends StatelessWidget {
  final ButtonType type;
  final bool disabled;
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final TextStyle? textStyle;

  const Button({
    super.key,
    this.type = ButtonType.text,
    this.disabled = false,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.textStyle,
  });

  static const buttonBoxShadow = BoxShadow(offset: Offset(4, 4));

  @override
  Widget build(BuildContext context) {
    final onTapLogic = disabled ? null : onPressed ?? () {};
    final onSecondaryTapLogic = disabled ? null : onLongPress;
    final allStateTextStyle = WidgetStatePropertyAll(textStyle);

    return switch (type) {
      ButtonType.filled => Container(
        decoration: BoxDecoration(
          boxShadow: [
            buttonBoxShadow.copyWith(
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ],
        ),
        child: FilledButton(
          style: ButtonStyle(textStyle: allStateTextStyle),
          onPressed: onTapLogic,
          onLongPress: onSecondaryTapLogic,
          child: child,
        ),
      ),
      ButtonType.outlined => Container(
        decoration: BoxDecoration(
          boxShadow: [
            buttonBoxShadow.copyWith(
              color: Theme.of(context).colorScheme.inverseSurface,
            ),
          ],
        ),
        child: OutlinedButton(
          style: ButtonStyle(textStyle: allStateTextStyle),
          onPressed: onTapLogic,
          onLongPress: onSecondaryTapLogic,
          child: child,
        ),
      ),
      ButtonType.text => TextButton(
        style: ButtonStyle(textStyle: allStateTextStyle),
        onPressed: onTapLogic,
        onLongPress: onSecondaryTapLogic,
        child: child,
      ),
    };
  }
}

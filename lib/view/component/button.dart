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

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      ButtonType.filled => FilledButtonWidget(
        disabled: disabled,
        icon: icon,
        onPressed: onPressed,
        onLongPress: onLongPress,
        textStyle: textStyle,
        backgroundColor: backgroundColor,
        child: child,
      ),
      ButtonType.outlined => OutlinedButtonWidget(
        disabled: disabled,
        icon: icon,
        onPressed: onPressed,
        onLongPress: onLongPress,
        textStyle: textStyle,
        backgroundColor: backgroundColor,
        child: child,
      ),
      ButtonType.text => TextButtonWidget(
        disabled: disabled,
        icon: icon,
        onPressed: onPressed,
        onLongPress: onLongPress,
        textStyle: textStyle,
        child: child,
      ),
    };
  }
}

class FilledButtonWidget extends StatelessWidget {
  final bool disabled;
  final Widget? child;
  final Icon? icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final TextStyle? textStyle;
  final Color? backgroundColor;

  const FilledButtonWidget({
    super.key,
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
    final hasBoth = icon != null && child != null;
    final onTapLogic = disabled ? null : onPressed ?? () {};
    final onSecondaryTapLogic = disabled ? null : onLongPress;

    final filledButtonStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(backgroundColor),
      textStyle: WidgetStatePropertyAll(textStyle),
    );

    return Container(
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
              ? IconButton.filled(
                style: filledButtonStyle,
                onPressed: onPressed,
                icon: icon!,
              )
              : hasBoth
              ? FilledButton.icon(
                style: filledButtonStyle,
                onPressed: onTapLogic,
                onLongPress: onSecondaryTapLogic,
                icon: icon!,
                label: child!,
              )
              : FilledButton(
                style: filledButtonStyle,
                onPressed: onTapLogic,
                onLongPress: onSecondaryTapLogic,
                child: child,
              ),
    );
  }
}

class OutlinedButtonWidget extends StatelessWidget {
  final bool disabled;
  final Widget? child;
  final Icon? icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final TextStyle? textStyle;
  final Color? backgroundColor;

  const OutlinedButtonWidget({
    super.key,
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
    final hasBoth = icon != null && child != null;
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

    return Container(
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
              : hasBoth
              ? OutlinedButton.icon(
                style: outlinedButtonStyle,
                onPressed: onTapLogic,
                onLongPress: onSecondaryTapLogic,
                icon: icon!,
                label: child!,
              )
              : OutlinedButton(
                style: outlinedButtonStyle,
                onPressed: onTapLogic,
                onLongPress: onSecondaryTapLogic,
                child: child,
              ),
    );
  }
}

class TextButtonWidget extends StatelessWidget {
  final bool disabled;
  final Widget? child;
  final Icon? icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final TextStyle? textStyle;

  const TextButtonWidget({
    super.key,
    this.disabled = false,
    this.child,
    this.icon,
    this.onPressed,
    this.onLongPress,
    this.textStyle,
  }) : assert(icon != null || child != null, 'icon or child must be provided');

  @override
  Widget build(BuildContext context) {
    final onlyIcon = icon != null && child == null;
    final hasBoth = icon != null && child != null;
    final onTapLogic = disabled ? null : onPressed ?? () {};
    final onSecondaryTapLogic = disabled ? null : onLongPress;
    final allStateTextStyle = WidgetStatePropertyAll(textStyle);

    return onlyIcon
        ? IconButton(onPressed: onPressed, icon: icon!)
        : hasBoth
        ? TextButton.icon(
          style: ButtonStyle(textStyle: allStateTextStyle),
          onPressed: onTapLogic,
          onLongPress: onSecondaryTapLogic,
          icon: icon!,
          label: child!,
        )
        : TextButton(
          style: ButtonStyle(textStyle: allStateTextStyle),
          onPressed: onTapLogic,
          onLongPress: onSecondaryTapLogic,
          child: child!,
        );
  }
}

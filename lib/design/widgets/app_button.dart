import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

/// A button with six predefined visual variants matching the design spec.
///
/// Variants are created via named factory constructors:
/// - [AppButton.primary] — accent bg, onAccent text, 12px/700
/// - [AppButton.secondary] — pillBg, textPrimary, 11px/700
/// - [AppButton.success] — success bg, white text, 11px/700
/// - [AppButton.dangerOutline] — transparent, dangerOutline text + border
/// - [AppButton.ghost] — transparent, textSubtle, no padding
/// - [AppButton.icon] — square pillBg button with an icon
///
/// For full control, use the default [AppButton] constructor directly.
class AppButton extends StatelessWidget {
  /// Base constructor — prefer named factory constructors for standard variants.
  const AppButton({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.backgroundColor = AppColors.accentPrimary,
    this.foregroundColor = AppColors.accentOnPrimary,
    this.borderRadius = AppRadii.mdRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.textStyle = AppTypography.button,
    this.border,
  }) : assert(
         label != null || icon != null,
         'Either label or icon must be provided',
       );

  /// Accent-filled primary action button.
  factory AppButton.primary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
  }) {
    return AppButton(key: key, label: label, onPressed: onPressed);
  }

  /// Pill-background secondary button.
  factory AppButton.secondary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      backgroundColor: AppColors.pillBg,
      foregroundColor: AppColors.textPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      textStyle: AppTypography.buttonSm,
    );
  }

  /// Success (green) confirmation button.
  factory AppButton.success({
    Key? key,
    required String label,
    VoidCallback? onPressed,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      backgroundColor: AppColors.success,
      foregroundColor: AppColors.white,
      borderRadius: AppRadii.smRadius,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      textStyle: AppTypography.buttonSm,
    );
  }

  /// Transparent danger/outline button with grey border.
  factory AppButton.dangerOutline({
    Key? key,
    required String label,
    VoidCallback? onPressed,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.dangerOutline,
      borderRadius: AppRadii.smRadius,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      textStyle: AppTypography.buttonSm,
      border: const BorderSide(color: AppColors.dangerOutline),
    );
  }

  /// Transparent ghost button — subtle, no chrome.
  factory AppButton.ghost({
    Key? key,
    required String label,
    VoidCallback? onPressed,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textSubtle,
      padding: EdgeInsets.zero,
      textStyle: AppTypography.buttonSm,
    );
  }

  /// Square icon button with pill background.
  ///
  /// A 22×22px square with a 14px glyph (ARCHITECTURE.md §2.6).
  factory AppButton.icon({
    Key? key,
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return AppButton(
      key: key,
      icon: icon,
      onPressed: onPressed,
      backgroundColor: AppColors.pillBg,
      foregroundColor: AppColors.textPrimary,
      borderRadius: AppRadii.smRadius,
      padding: EdgeInsets.zero,
    );
  }

  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry padding;
  final TextStyle textStyle;
  final BorderSide? border;

  static const _disabledOpacity = 0.38;
  static const _iconBoxSize = 22.0;
  static const _iconGlyphSize = 14.0;

  @override
  Widget build(BuildContext context) {
    final isIcon = icon != null;
    final effectiveRadius = borderRadius ?? BorderRadius.zero;
    final effectiveBorder = border ?? BorderSide.none;

    final child = isIcon
        ? Icon(icon, color: foregroundColor, size: _iconGlyphSize)
        : Text(label!, style: textStyle.copyWith(color: foregroundColor));

    return SizedBox(
      width: isIcon ? _iconBoxSize : null,
      height: isIcon ? _iconBoxSize : null,
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return backgroundColor.withValues(alpha: _disabledOpacity);
            }
            return backgroundColor;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return foregroundColor.withValues(alpha: _disabledOpacity);
            }
            return foregroundColor;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: effectiveRadius,
              side: effectiveBorder,
            ),
          ),
          padding: WidgetStatePropertyAll(padding),
          minimumSize: WidgetStatePropertyAll(
            isIcon ? const Size.square(_iconBoxSize) : Size.zero,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: child,
      ),
    );
  }
}

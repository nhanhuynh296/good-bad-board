import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

/// On/Off toggle button for settings.
///
/// On state: success (green) background, white text.
/// Off state: toggleOff (#e5e5e5) background, toggleOffText (#555) text.
///
/// An optional [label] renders beside the toggle for context
/// (e.g., "Session reminders").
///
/// [onLabel] and [offLabel] customize the text inside the toggle itself;
/// defaults are the localized "ON" and "OFF".
///
/// When [onChanged] is null the toggle renders in a disabled state with
/// reduced opacity.
class AppToggleButton extends StatelessWidget {
  const AppToggleButton({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.onLabel,
    this.offLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final String? onLabel;
  final String? offLabel;

  static const _onStyle = TextStyle(
    fontFamily: AppTypography.bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static const _offStyle = TextStyle(
    fontFamily: AppTypography.bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.toggleOffText,
  );

  static const _disabledOpacity = 0.5;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = value ? AppColors.success : AppColors.toggleOff;
    final textStyle = value ? _onStyle : _offStyle;
    final l10n = AppLocalizations.of(context)!;
    final displayLabel = value
        ? onLabel ?? l10n.on.toUpperCase()
        : offLabel ?? l10n.off.toUpperCase();
    final isDisabled = onChanged == null;

    final toggle = Semantics(
      checked: value,
      label: label ?? l10n.common_toggle,
      child: Opacity(
        opacity: isDisabled ? _disabledOpacity : 1.0,
        child: Material(
          color: backgroundColor,
          borderRadius: AppRadii.smRadius,
          child: InkWell(
            onTap: onChanged != null ? () => onChanged!(!value) : null,
            borderRadius: AppRadii.smRadius,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Text(displayLabel, style: textStyle),
            ),
          ),
        ),
      ),
    );

    if (label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          toggle,
          const SizedBox(width: AppSpacing.sm),
          Text(label!, style: AppTypography.body),
        ],
      );
    }

    return toggle;
  }
}

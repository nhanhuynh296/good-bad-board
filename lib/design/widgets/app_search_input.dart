import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

/// Full-width search text field matching the design system spec.
///
/// Border: 1px solid inputBorder (#e2d8c8), radius: 8px (md).
/// Font: 14px, body font.
/// Padding: 10–14px content padding.
///
/// Both [controller] and [onChanged] are optional — provide whichever
/// fits your use case. The caller is responsible for [controller] and
/// [focusNode] disposal.
///
/// When [placeholder] is null a localized "Search players…" hint is shown.
class AppSearchInput extends StatelessWidget {
  const AppSearchInput({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.placeholder,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final String? placeholder;

  static const _enabledBorder = OutlineInputBorder(
    borderRadius: AppRadii.mdRadius,
    borderSide: BorderSide(color: AppColors.inputBorder, width: 1),
  );

  static const _focusedBorder = OutlineInputBorder(
    borderRadius: AppRadii.mdRadius,
    borderSide: BorderSide(color: AppColors.accentPrimary, width: 1),
  );

  static const _errorBorder = OutlineInputBorder(
    borderRadius: AppRadii.mdRadius,
    borderSide: BorderSide(color: Colors.red, width: 1),
  );

  static const _inputStyle = TextStyle(
    fontFamily: AppTypography.bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const _hintStyle = TextStyle(
    fontFamily: AppTypography.bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSubtle,
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText:
            placeholder ?? AppLocalizations.of(context)!.common_search_players,
        hintStyle: _hintStyle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: _enabledBorder,
        enabledBorder: _enabledBorder,
        focusedBorder: _focusedBorder,
        errorBorder: _errorBorder,
        focusedErrorBorder: _errorBorder,
        disabledBorder: _enabledBorder,
      ),
      style: _inputStyle,
    );
  }
}

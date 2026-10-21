import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

// Re-export design tokens for backward compatibility.
// New code should import 'package:good_bad_board/design/design.dart' directly.
export 'package:good_bad_board/design/design.dart' show AppColors;

/// Legacy outlined border constants — kept for backward compatibility
/// with existing widget code that references them directly.
const outlinedBorderSide = BorderSide(width: 2);

const outlinedBorderRadius = BorderRadius.all(Radius.circular(5));

const noOutlinedBorder = RoundedRectangleBorder(
  borderRadius: outlinedBorderRadius,
);

const lightOutlinedBorder = RoundedRectangleBorder(
  side: outlinedBorderSide,
  borderRadius: outlinedBorderRadius,
);

const commonButtonTheme = ButtonStyle(
  shape: WidgetStatePropertyAll(lightOutlinedBorder),
);

/// Light theme — delegates to [AppTheme.light].
ThemeData get lightTheme => lightThemeFor(null);

final _lightThemes = <Locale?, ThemeData>{};

/// Light theme with the Chinese font fallback for [locale] (R3-Q6).
ThemeData lightThemeFor(Locale? locale) =>
    _lightThemes.putIfAbsent(locale, () => AppTheme.light(locale: locale));

import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

// Re-export design tokens for backward compatibility.
// New code should import 'package:good_bad_board/design/design.dart' directly.
export 'package:good_bad_board/design/design.dart' show AppColors;

/// The app's single font family (body font — OpenSans, bundled as asset).
const String fontFamily = 'OpenSans';

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

final darkOutlinedBorder = lightOutlinedBorder.copyWith(
  side: outlinedBorderSide.copyWith(color: AppColors.white),
);

const commonButtonTheme = ButtonStyle(
  shape: WidgetStatePropertyAll(lightOutlinedBorder),
);

/// Light theme — delegates to [AppTheme.light].
ThemeData? _cachedLightTheme;
ThemeData get lightTheme => _cachedLightTheme ??= AppTheme.light();

/// Dark theme — delegates to [AppTheme.dark].
ThemeData? _cachedDarkTheme;
ThemeData get darkTheme => _cachedDarkTheme ??= AppTheme.dark();

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:good_bad_board/design/app_colors.dart';
import 'package:good_bad_board/design/app_radii.dart';
import 'package:good_bad_board/design/app_spacing.dart';
import 'package:good_bad_board/design/app_typography.dart';

/// Border side used for outlined borders throughout the app.
const _outlinedBorderSide = BorderSide(width: 2);

const _outlinedBorderRadius = BorderRadius.all(Radius.circular(5));

const _noOutlinedBorder = RoundedRectangleBorder(
  borderRadius: _outlinedBorderRadius,
);

const _lightOutlinedBorder = RoundedRectangleBorder(
  side: _outlinedBorderSide,
  borderRadius: _outlinedBorderRadius,
);

final _darkOutlinedBorder = _lightOutlinedBorder.copyWith(
  side: _outlinedBorderSide.copyWith(color: AppColors.white),
);

final _cardShadowColor = AppColors.grey.withValues(alpha: 0.25);

const _badgeTheme = BadgeThemeData(
  padding: EdgeInsets.all(AppSpacing.sm),
  smallSize: 0,
);

/// Theme factory that wires design tokens into Material [ThemeData].
abstract class AppTheme {
  static TextTheme _textTheme(Color textColor, Color labelColor) {
    return TextTheme(
      displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: textColor),
      headlineMedium: TextStyle(color: textColor),
      headlineSmall: TextStyle(color: textColor),
      titleLarge: TextStyle(color: textColor),
      titleMedium: TextStyle(color: textColor),
      titleSmall: TextStyle(color: textColor),
      bodyLarge: TextStyle(color: textColor),
      bodyMedium: TextStyle(color: textColor),
      bodySmall: TextStyle(color: textColor),
      labelLarge: TextStyle(color: labelColor),
      labelMedium: TextStyle(color: labelColor),
      labelSmall: TextStyle(color: labelColor),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color accentColor,
    bool scaleFocusedBorder = false,
  }) {
    final greySide = _outlinedBorderSide.copyWith(color: AppColors.grey);
    final redSide = _outlinedBorderSide.copyWith(color: AppColors.error);
    final focusedSide = scaleFocusedBorder
        ? _outlinedBorderSide.scale(1.5).copyWith(color: accentColor)
        : _outlinedBorderSide.copyWith(color: accentColor);

    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: greySide,
        borderRadius: _outlinedBorderRadius,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: greySide,
        borderRadius: _outlinedBorderRadius,
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: greySide,
        borderRadius: _outlinedBorderRadius,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: focusedSide,
        borderRadius: _outlinedBorderRadius,
      ),
      errorBorder: OutlineInputBorder(
        borderSide: redSide,
        borderRadius: _outlinedBorderRadius,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: redSide,
        borderRadius: _outlinedBorderRadius,
      ),
      floatingLabelStyle: TextStyle(color: accentColor),
    );
  }

  /// Clubhouse light theme.
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentPrimary,
        onPrimary: AppColors.white,
        secondary: AppColors.headerBg,
        onSecondary: AppColors.white,
        tertiary: AppColors.pillBg,
        onTertiary: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.white,
        surface: AppColors.cardBg,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: AppTypography.bodyFont,
      scaffoldBackgroundColor: AppColors.pageBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.displayFont,
          color: AppColors.textPrimary,
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.pageBg,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        shadowColor: _cardShadowColor,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.xlRadius),
      ),
      textTheme: _textTheme(AppColors.textPrimary, AppColors.textPrimary),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.xlRadius),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        accentColor: AppColors.accentPrimary,
      ),
      elevatedButtonTheme: const ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.accentPrimary),
          foregroundColor: WidgetStatePropertyAll(AppColors.white),
          shape: WidgetStatePropertyAll(_lightOutlinedBorder),
        ),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(_noOutlinedBorder),
          foregroundColor: WidgetStatePropertyAll(AppColors.textPrimary),
        ),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(_lightOutlinedBorder),
          backgroundColor: WidgetStatePropertyAll(AppColors.white),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(shape: WidgetStatePropertyAll(_noOutlinedBorder)),
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(shape: WidgetStatePropertyAll(_noOutlinedBorder)),
      ),
      searchBarTheme: const SearchBarThemeData(
        shape: WidgetStatePropertyAll(_noOutlinedBorder),
      ),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.xlRadius),
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thickness: WidgetStatePropertyAll(AppSpacing.sm),
        thumbColor: WidgetStatePropertyAll(AppColors.black),
        minThumbLength: AppSpacing.xl2 * 2, // 64
        mainAxisMargin: -AppSpacing.sm,
      ),
      badgeTheme: _badgeTheme,
    );
  }

  /// Clubhouse dark theme.
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkAccent,
        onPrimary: AppColors.black,
        secondary: AppColors.darkSecondaryAccent,
        onSecondary: AppColors.black,
        tertiary: AppColors.darkCardBorder,
        onTertiary: AppColors.white,
        error: AppColors.error,
        onError: AppColors.white,
        surface: AppColors.darkCardBg,
        onSurface: AppColors.white,
      ),
      fontFamily: AppTypography.bodyFont,
      scaffoldBackgroundColor: AppColors.darkPageBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.displayFont,
          color: AppColors.darkAccent,
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkAccent),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.darkPageBg,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCardBg,
        shadowColor: _cardShadowColor,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.xlRadius),
      ),
      textTheme: _textTheme(AppColors.white, AppColors.darkAccent),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.xlRadius),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        accentColor: AppColors.darkAccent,
        scaleFocusedBorder: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.darkAccent),
          foregroundColor: const WidgetStatePropertyAll(AppColors.black),
          shape: WidgetStatePropertyAll(_darkOutlinedBorder),
        ),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(_noOutlinedBorder),
          foregroundColor: WidgetStatePropertyAll(AppColors.darkAccent),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.black),
          shape: WidgetStatePropertyAll(_darkOutlinedBorder),
        ),
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(shape: WidgetStatePropertyAll(_noOutlinedBorder)),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(shape: WidgetStatePropertyAll(_noOutlinedBorder)),
      ),
      searchBarTheme: SearchBarThemeData(
        shape: WidgetStatePropertyAll(_darkOutlinedBorder),
      ),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.xlRadius),
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thickness: WidgetStatePropertyAll(AppSpacing.sm),
        thumbColor: WidgetStatePropertyAll(AppColors.white),
        minThumbLength: AppSpacing.xl2 * 2, // 64
        mainAxisMargin: -AppSpacing.sm,
      ),
      badgeTheme: _badgeTheme,
    );
  }
}

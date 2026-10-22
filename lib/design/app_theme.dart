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

final _cardShadowColor = AppColors.grey.withValues(alpha: 0.25);

const _badgeTheme = BadgeThemeData(
  padding: EdgeInsets.all(AppSpacing.sm),
  smallSize: 0,
);

/// Theme factory that wires design tokens into Material [ThemeData].
abstract class AppTheme {
  /// Every Material text style on the 6-size scale (ARCHITECTURE.md §1.2),
  /// in Source Sans 3, with the locale's Chinese fallback.
  static TextTheme _textTheme(
    Color textColor,
    Color labelColor,
    List<String> fallback,
  ) {
    TextStyle style(double size, FontWeight weight, Color color) => TextStyle(
      fontFamily: AppTypography.family,
      fontFamilyFallback: fallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
    );

    const regular = AppTypography.regular;
    const semibold = AppTypography.semibold;
    return TextTheme(
      displayLarge: style(AppTypography.sizeTimer, semibold, textColor),
      displayMedium: style(AppTypography.sizeDisplay, semibold, textColor),
      displaySmall: style(AppTypography.sizeDisplay, semibold, textColor),
      headlineLarge: style(AppTypography.sizeDisplay, regular, textColor),
      headlineMedium: style(AppTypography.sizeDisplay, regular, textColor),
      headlineSmall: style(AppTypography.sizeTitle, regular, textColor),
      titleLarge: style(AppTypography.sizeTitle, semibold, textColor),
      titleMedium: style(AppTypography.sizeSubtitle, semibold, textColor),
      titleSmall: style(AppTypography.sizeBody, semibold, textColor),
      bodyLarge: style(AppTypography.sizeSubtitle, regular, textColor),
      bodyMedium: style(AppTypography.sizeBody, regular, textColor),
      bodySmall: style(AppTypography.sizeCaption, regular, textColor),
      labelLarge: style(AppTypography.sizeBody, semibold, labelColor),
      labelMedium: style(AppTypography.sizeCaption, semibold, labelColor),
      labelSmall: style(AppTypography.sizeCaption, semibold, labelColor),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color accentColor,
  }) {
    final greySide = _outlinedBorderSide.copyWith(
      color: AppColors.controlBorder,
    );
    final redSide = _outlinedBorderSide.copyWith(color: AppColors.error);
    final focusedSide = _outlinedBorderSide.copyWith(color: accentColor);

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
  ///
  /// [locale] picks the Chinese system font fallback (R3-Q6).
  static ThemeData light({Locale? locale}) {
    final fallback = AppTypography.fallbackFor(locale);
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentPrimary,
        onPrimary: AppColors.accentOnPrimary,
        secondary: AppColors.headerBg,
        onSecondary: AppColors.white,
        tertiary: AppColors.pillBg,
        onTertiary: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.white,
        surface: AppColors.cardBg,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: AppTypography.family,
      fontFamilyFallback: fallback,
      scaffoldBackgroundColor: AppColors.pageBg,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        titleTextStyle: AppTypography.title.copyWith(
          fontFamilyFallback: fallback,
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
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
      textTheme: _textTheme(
        AppColors.textPrimary,
        AppColors.textPrimary,
        fallback,
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.xlRadius),
      ),
      // The focused field gets the light-surface focus ring (F07).
      inputDecorationTheme: _inputDecorationTheme(
        accentColor: AppColors.focusOnLight,
      ),
      elevatedButtonTheme: const ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.accentPrimary),
          foregroundColor: WidgetStatePropertyAll(AppColors.accentOnPrimary),
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
}

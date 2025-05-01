import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class AppColors {
  // Primary Colors
  static const Color stAndrewsBlue = Color(0xFF060D87); // Ōrangitea
  static const Color goldRush = Color(0xFFF4B142); // Rere Tārewa Kōura
  static const Color black = Color(0xFF000000); // Pango
  static const Color white = Color(0xFFFFFFFF); // Mā

  // Derived Colors
  static const Color lightGold = Color(0xFFFFE4B5); // Lightened Gold Rush
  static const Color darkBlue = Color(0xFF04085C); // Darkened St Andrew’s Blue
  static const Color grey = Color(0xFF9E9E9E); // Neutral Grey
}

const String fontFamily = 'Gotham';

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

ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.stAndrewsBlue,
      onPrimary: AppColors.white,
      secondary: AppColors.goldRush,
      onSecondary: AppColors.black,
      tertiary: AppColors.lightGold,
      onTertiary: AppColors.stAndrewsBlue,
      error: Colors.red,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.black,
    ),
    fontFamily: fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.stAndrewsBlue,
      ),
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.stAndrewsBlue),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),
    scaffoldBackgroundColor: AppColors.white,
    cardTheme: CardTheme(
      color: AppColors.white,
      shadowColor: AppColors.grey.withValues(alpha: 0.25),
      elevation: 2,
      shape: lightOutlinedBorder,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.stAndrewsBlue,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: AppColors.stAndrewsBlue,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: AppColors.stAndrewsBlue,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(color: AppColors.stAndrewsBlue),
      headlineMedium: TextStyle(color: AppColors.stAndrewsBlue),
      headlineSmall: TextStyle(color: AppColors.stAndrewsBlue),
      titleLarge: TextStyle(color: AppColors.stAndrewsBlue),
      titleMedium: TextStyle(color: AppColors.stAndrewsBlue),
      titleSmall: TextStyle(color: AppColors.stAndrewsBlue),
      bodyLarge: TextStyle(color: AppColors.black),
      bodyMedium: TextStyle(color: AppColors.black),
      bodySmall: TextStyle(color: AppColors.black),
      labelLarge: TextStyle(color: AppColors.stAndrewsBlue),
      labelMedium: TextStyle(color: AppColors.stAndrewsBlue),
      labelSmall: TextStyle(color: AppColors.stAndrewsBlue),
    ),
    dialogTheme: const DialogThemeData(shape: lightOutlinedBorder),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: outlinedBorderSide.copyWith(color: AppColors.grey),
        borderRadius: outlinedBorderRadius,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: outlinedBorderSide.copyWith(color: AppColors.grey),
        borderRadius: outlinedBorderRadius,
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: outlinedBorderSide.copyWith(color: AppColors.grey),
        borderRadius: outlinedBorderRadius,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: outlinedBorderSide.copyWith(color: AppColors.stAndrewsBlue),
        borderRadius: outlinedBorderRadius,
      ),
      errorBorder: OutlineInputBorder(
        borderSide: outlinedBorderSide.copyWith(color: Colors.red),
        borderRadius: outlinedBorderRadius,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: outlinedBorderSide.copyWith(color: Colors.red),
        borderRadius: outlinedBorderRadius,
      ),
      floatingLabelStyle: const TextStyle(color: AppColors.stAndrewsBlue),
    ),
    elevatedButtonTheme: const ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.stAndrewsBlue),
        foregroundColor: WidgetStatePropertyAll(AppColors.white),
        shape: WidgetStatePropertyAll(lightOutlinedBorder),
      ),
    ),
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(lightOutlinedBorder),
        foregroundColor: WidgetStatePropertyAll(AppColors.stAndrewsBlue),
      ),
    ),
    outlinedButtonTheme: const OutlinedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(lightOutlinedBorder),
        backgroundColor: WidgetStatePropertyAll(AppColors.white),
      ),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(shape: WidgetStatePropertyAll(noOutlinedBorder)),
    ),
    filledButtonTheme: const FilledButtonThemeData(
      style: ButtonStyle(shape: WidgetStatePropertyAll(noOutlinedBorder)),
    ),
    searchBarTheme: const SearchBarThemeData(
      shape: WidgetStatePropertyAll(noOutlinedBorder),
    ),
    chipTheme: const ChipThemeData(shape: lightOutlinedBorder),
  );
}

ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.goldRush,
      onPrimary: AppColors.black,
      secondary: AppColors.stAndrewsBlue,
      onSecondary: AppColors.white,
      tertiary: AppColors.darkBlue,
      onTertiary: AppColors.goldRush,
      error: Colors.red,
      onError: AppColors.white,
      surface: AppColors.black,
      onSurface: AppColors.white,
    ),
    fontFamily: fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        color: AppColors.goldRush,
      ),
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.goldRush),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    scaffoldBackgroundColor: AppColors.black,
    cardTheme: CardTheme(
      color: AppColors.darkBlue,
      shadowColor: AppColors.grey.withValues(alpha: 0.25),
      elevation: 2,
      shape: darkOutlinedBorder,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.goldRush,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: AppColors.goldRush,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: AppColors.goldRush,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(color: AppColors.goldRush),
      headlineMedium: TextStyle(color: AppColors.goldRush),
      headlineSmall: TextStyle(color: AppColors.goldRush),
      titleLarge: TextStyle(color: AppColors.goldRush),
      titleMedium: TextStyle(color: AppColors.goldRush),
      titleSmall: TextStyle(color: AppColors.goldRush),
      bodyLarge: TextStyle(color: AppColors.white),
      bodyMedium: TextStyle(color: AppColors.white),
      bodySmall: TextStyle(color: AppColors.white),
      labelLarge: TextStyle(color: AppColors.goldRush),
      labelMedium: TextStyle(color: AppColors.goldRush),
      labelSmall: TextStyle(color: AppColors.goldRush),
    ),
    dialogTheme: DialogThemeData(shape: darkOutlinedBorder),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: outlinedBorderSide.copyWith(color: AppColors.grey),
        borderRadius: outlinedBorderRadius,
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: outlinedBorderSide.copyWith(color: AppColors.grey),
        borderRadius: outlinedBorderRadius,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: outlinedBorderSide.copyWith(color: AppColors.grey),
        borderRadius: outlinedBorderRadius,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: outlinedBorderSide
            .scale(1.5)
            .copyWith(color: AppColors.goldRush),
        borderRadius: outlinedBorderRadius,
      ),
      errorBorder: OutlineInputBorder(
        borderSide: outlinedBorderSide.copyWith(color: Colors.red),
        borderRadius: outlinedBorderRadius,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: outlinedBorderSide.copyWith(color: Colors.red),
        borderRadius: outlinedBorderRadius,
      ),
      floatingLabelStyle: const TextStyle(color: AppColors.goldRush),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.goldRush),
        foregroundColor: const WidgetStatePropertyAll(AppColors.black),
        shape: WidgetStatePropertyAll(darkOutlinedBorder),
      ),
    ),
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(noOutlinedBorder),
        foregroundColor: WidgetStatePropertyAll(AppColors.goldRush),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.black),
        shape: WidgetStatePropertyAll(darkOutlinedBorder),
      ),
    ),
    filledButtonTheme: const FilledButtonThemeData(
      style: ButtonStyle(shape: WidgetStatePropertyAll(noOutlinedBorder)),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(shape: WidgetStatePropertyAll(noOutlinedBorder)),
    ),
    searchBarTheme: SearchBarThemeData(
      shape: WidgetStatePropertyAll(darkOutlinedBorder),
    ),
    chipTheme: ChipThemeData(shape: darkOutlinedBorder),
  );
}

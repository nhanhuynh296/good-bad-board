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
const commonButtonTheme = ButtonStyle(
  shape: WidgetStatePropertyAll(RoundedRectangleBorder()),
);

ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
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
        fontWeight: FontWeight.w600,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      headlineLarge: TextStyle(
        color: AppColors.stAndrewsBlue,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: AppColors.stAndrewsBlue,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: AppColors.stAndrewsBlue,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: AppColors.stAndrewsBlue,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: AppColors.stAndrewsBlue,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: AppColors.stAndrewsBlue,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(color: AppColors.black),
      bodyMedium: TextStyle(color: AppColors.black),
      bodySmall: TextStyle(color: AppColors.black),
      labelLarge: TextStyle(
        color: AppColors.stAndrewsBlue,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: AppColors.stAndrewsBlue,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: AppColors.stAndrewsBlue,
        fontWeight: FontWeight.w500,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.stAndrewsBlue),
        borderRadius: BorderRadius.circular(8.0),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(8.0),
      ),
      floatingLabelStyle: const TextStyle(color: AppColors.stAndrewsBlue),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: commonButtonTheme.copyWith(
        backgroundColor: WidgetStateProperty.all(AppColors.stAndrewsBlue),
        foregroundColor: WidgetStateProperty.all(AppColors.white),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: commonButtonTheme.copyWith(
        foregroundColor: WidgetStateProperty.all(AppColors.stAndrewsBlue),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: commonButtonTheme.copyWith(
        backgroundColor: const WidgetStatePropertyAll(AppColors.white),
        side: const WidgetStatePropertyAll(BorderSide(width: 2)),
      ),
    ),
    filledButtonTheme: const FilledButtonThemeData(style: commonButtonTheme),
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
        fontWeight: FontWeight.w600,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      headlineLarge: TextStyle(
        color: AppColors.goldRush,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: AppColors.goldRush,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: AppColors.goldRush,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: AppColors.goldRush,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: AppColors.goldRush,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: AppColors.goldRush,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(color: AppColors.white),
      bodyMedium: TextStyle(color: AppColors.white),
      bodySmall: TextStyle(color: AppColors.white),
      labelLarge: TextStyle(
        color: AppColors.goldRush,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: AppColors.goldRush,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: AppColors.goldRush,
        fontWeight: FontWeight.w500,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.goldRush),
        borderRadius: BorderRadius.circular(8.0),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(8.0),
      ),
      floatingLabelStyle: const TextStyle(color: AppColors.goldRush),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: commonButtonTheme.copyWith(
        backgroundColor: WidgetStateProperty.all(AppColors.goldRush),
        foregroundColor: WidgetStateProperty.all(AppColors.black),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: commonButtonTheme.copyWith(
        foregroundColor: WidgetStateProperty.all(AppColors.goldRush),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: commonButtonTheme.copyWith(
        backgroundColor: const WidgetStatePropertyAll(AppColors.black),
      ),
    ),
    filledButtonTheme: const FilledButtonThemeData(style: commonButtonTheme),
  );
}

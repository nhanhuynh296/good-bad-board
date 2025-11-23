import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:good_bad_board/spacing.dart';

abstract class AppColors {
  // Primary Colors
  static const Color stAndrewsBlue = Color(0xFF060D87); // Ōrangitea
  static const Color goldRush = Color(0xFFF4B142); // Rere Tārewa Kōura
  static const Color black = shadow; // Pango
  static const Color white = Color(0xFFFFFFFF); // Mā

  // Derived Colors
  static const Color lightGold = Color(0xFFFFE4B5); // Lightened Gold Rush
  static const Color darkBlue = Color(0xFF04085C); // Darkened St Andrew’s Blue
  static const Color grey = Color(0xFF9E9E9E); // Neutral Grey

  static const Color orange = Color.fromARGB(0xFF, 255, 140, 40); // Orange
  static const Color teal = Color.fromARGB(0xFF, 67, 171, 174);
  static const Color yellow = Color.fromARGB(0xFF, 253, 221, 98);
  static const Color shadow = Color(0xFF1E1E1E);
}

const String fontFamily = 'Gotham';

const outlinedBorderSide = BorderSide(width: 4);
const shadowedOutlinedOffset = Offset(8.0, 8.0);

const outlinedBorderRadius = BorderRadius.all(Radius.circular(40));
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
  const titleTextStyle = TextStyle(color: AppColors.black);
  final defaultTextStyle = titleTextStyle.copyWith(color: AppColors.black);

  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.teal,
      onPrimary: AppColors.white,
      secondary: AppColors.orange,
      onSecondary: AppColors.black,
      tertiary: AppColors.yellow,
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
    cardTheme: CardThemeData(
      color: AppColors.white,
      shadowColor: AppColors.grey.withValues(alpha: 0.25),
      elevation: 2,
      shape: lightOutlinedBorder,
    ),
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        color: AppColors.stAndrewsBlue,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: const TextStyle(
        color: AppColors.stAndrewsBlue,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: const TextStyle(
        color: AppColors.stAndrewsBlue,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: titleTextStyle,
      headlineMedium: titleTextStyle,
      headlineSmall: titleTextStyle,
      titleLarge: titleTextStyle,
      titleMedium: titleTextStyle,
      titleSmall: titleTextStyle,
      bodyLarge: defaultTextStyle,
      bodyMedium: defaultTextStyle,
      bodySmall: defaultTextStyle,
      labelLarge: titleTextStyle,
      labelMedium: titleTextStyle,
      labelSmall: titleTextStyle,
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
      floatingLabelStyle: titleTextStyle,
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
        shape: WidgetStatePropertyAll(noOutlinedBorder),
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
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(noOutlinedBorder),
        textStyle: WidgetStatePropertyAll(defaultTextStyle),
      ),
    ),
    searchBarTheme: const SearchBarThemeData(
      shape: WidgetStatePropertyAll(lightOutlinedBorder),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: space16),
      ),
    ),
    chipTheme: const ChipThemeData(shape: lightOutlinedBorder),
    scrollbarTheme: const ScrollbarThemeData(
      thickness: WidgetStatePropertyAll(space8),
      thumbColor: WidgetStatePropertyAll(AppColors.black),
      minThumbLength: space64,
      mainAxisMargin: -space8,
    ),
    badgeTheme: const BadgeThemeData(
      padding: EdgeInsets.all(space8),
      smallSize: 0,
    ),
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
    cardTheme: CardThemeData(
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
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: space16),
      ),
    ),
    chipTheme: ChipThemeData(shape: darkOutlinedBorder),
    scrollbarTheme: const ScrollbarThemeData(
      thickness: WidgetStatePropertyAll(space8),
      thumbColor: WidgetStatePropertyAll(AppColors.white),
      minThumbLength: space64,
      // crossAxisMargin: -space8,
    ),
    badgeTheme: const BadgeThemeData(
      padding: EdgeInsets.all(space8),
      smallSize: 0,
    ),
  );
}

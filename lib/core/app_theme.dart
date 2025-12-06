import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.neonBlue,
      brightness: Brightness.light,
    ).copyWith(
      secondary: AppColors.neonMagenta,
      tertiary: AppColors.neonPurple,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgLight,
      cardColor: AppColors.cardLight,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.primary,
        surfaceTintColor: AppColors.neonCyan,
        centerTitle: true,
      ),
      fontFamily: AppFonts.primary,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(letterSpacing: 0.5),
        titleLarge: TextStyle(letterSpacing: 0.5),
        labelLarge: TextStyle(letterSpacing: 1.0, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppColors.radius)),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.neonCyan,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: AppColors.neonMagenta,
      tertiary: AppColors.neonPurple,
      surface: AppColors.bgDarkDeep,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgDarkDeep,
      cardColor: AppColors.cardDark,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(elevation: 0, backgroundColor: Colors.transparent),
      fontFamily: AppFonts.primary,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(letterSpacing: 0.5),
        titleLarge: TextStyle(letterSpacing: 0.5),
        labelLarge: TextStyle(letterSpacing: 1.0, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppColors.radius)),
      ),
    );
  }
}
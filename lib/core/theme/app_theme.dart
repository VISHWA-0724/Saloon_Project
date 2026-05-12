import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTheme {
  static const cardRadius = 16.0;
  static const buttonRadius = 12.0;
  static const inputRadius = 8.0;

  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryPurple,
      brightness: Brightness.light,
      primary: AppColors.primaryPurple,
      secondary: AppColors.primaryPink,
      surface: Colors.white,
      error: AppColors.danger,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide:
            const BorderSide(color: AppColors.primaryPurple, width: 1.6),
      ),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryPurple,
      brightness: Brightness.dark,
      primary: AppColors.primaryPurple,
      secondary: AppColors.primaryPink,
      surface: const Color(0xFF16213E),
      error: AppColors.danger,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    cardTheme: CardThemeData(
      color: const Color(0xFF16213E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF16213E),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: Color(0xFF2C2C44)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: Color(0xFF2C2C44)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: AppColors.primaryPink, width: 1.6),
      ),
    ),
  );
}

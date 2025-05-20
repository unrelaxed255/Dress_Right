// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Shared
  static const error = Color(0xFFD32F2F);
  static const success = Color(0xFF388E3C);
  static const warning = Color(0xFFFFA000);

  // Light Theme
  static const primaryLight = Color(0xFF0F2C5C);
  static const secondaryLight = Color(0xFF263F73);
  static const accentLight = Color(0xFFCC2936);
  static const backgroundLight = Color(0xFFF5F7FA);
  static const surfaceLight = Colors.white;
  static const textPrimaryLight = Color(0xFF212121);
  static const textSecondaryLight = Color(0xFF757575);

  // Dark Theme
  static const primaryDark = Color(0xFF0A1F40);
  static const secondaryDark = Color(0xFF1A2E56);
  static const accentDark = Color(0xFFAD2430);
  static const backgroundDark = Colors.black;
  static const surfaceDark = Color(0xFF1A2535);
  static const textPrimaryDark = Color(0xFFEEEEEE);
  static const textSecondaryDark = Color(0xFFB0B0B0);
}

class AppTheme {
  static ThemeData buildTheme({required bool isDark}) {
    final colors = isDark ? _darkColors : _lightColors;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors['primary']!,
        onPrimary: Colors.white,
        secondary: colors['secondary']!,
        onSecondary: Colors.white,
        tertiary: colors['accent']!,
        onTertiary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        background: colors['background']!,
        onBackground: colors['textPrimary']!,
        surface: colors['surface']!,
        onSurface: colors['textPrimary']!,
      ),
      textTheme: GoogleFonts.openSansTextTheme().apply(
        bodyColor: colors['textPrimary'],
        displayColor: colors['textPrimary'],
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: colors['primary'],
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors['accent'],
          side: BorderSide(color: colors['accent']!),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors['accent'],
        ),
      ),
      cardTheme: CardTheme(
        color: colors['surface'],
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: colors['surface'],
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors['accent']!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors['accent']!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors['primary']!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static final Map<String, Color> _lightColors = {
    'primary': AppColors.primaryLight,
    'secondary': AppColors.secondaryLight,
    'accent': AppColors.accentLight,
    'background': AppColors.backgroundLight,
    'surface': AppColors.surfaceLight,
    'textPrimary': AppColors.textPrimaryLight,
    'textSecondary': AppColors.textSecondaryLight,
  };

  static final Map<String, Color> _darkColors = {
    'primary': AppColors.primaryDark,
    'secondary': AppColors.secondaryDark,
    'accent': AppColors.accentDark,
    'background': AppColors.backgroundDark,
    'surface': AppColors.surfaceDark,
    'textPrimary': AppColors.textPrimaryDark,
    'textSecondary': AppColors.textSecondaryDark,
  };
}

import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color accentGreen = Color(0xFF34A853);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF10243E);
  static const Color textSecondary = Color(0xFF5F6B7A);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue).copyWith(
        primary: primaryBlue,
        secondary: accentGreen,
        surface: surface,
        background: background,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shadowColor: primaryBlue.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentGreen,
        linearTrackColor: Color(0xFFDCE7F8),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        titleLarge: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontFamily: 'Roboto',
          color: textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontFamily: 'Roboto',
          color: textSecondary,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors matching the premium White & Blue Light Theme
  static const Color primaryColor = Color(0xFF2563EB); // Royal Blue
  static const Color secondaryColor = Color(0xFF3B82F6); // Sky Blue
  static const Color primaryHover = Color(0xFF1D4ED8);
  static const Color backgroundColor = Color(0xFFF8FAFC); // Clean off-white background
  static const Color surfaceColor = Colors.white; // Pure white surface card
  static const Color surfaceColorLevel2 = Color(0xFFF1F5F9); // Light grey surface
  static const Color surfaceColorLevel3 = Color(0xFFE2E8F0); // Border line/separator
  static const Color hairlineColor = Color(0x1F0F172A); // Precision grid line (12% slate)
  static const Color hairlineStrongColor = Color(0x3D2563EB); // Accent grid line (24% Blue)
  
  static const Color textMainColor = Color(0xFF0F172A); // High-contrast reading (Slate 900)
  static const Color textMutedColor = Color(0xFF475569); // Explanatory type (Slate 600)
  static const Color textSubtleColor = Color(0xFF64748B); // Secondary identifiers (Slate 500)

  // Helper method to get theme data
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textMainColor, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textMainColor, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: textMainColor, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: textMainColor, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textMainColor, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: textMainColor, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textMainColor, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textMainColor, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textMainColor, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textMainColor),
        bodyMedium: TextStyle(color: textMutedColor),
        bodySmall: TextStyle(color: textSubtleColor),
      ),
    );
  }
}

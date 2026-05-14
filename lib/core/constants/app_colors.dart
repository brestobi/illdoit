import 'package:flutter/material.dart';

/// Application Color Palette
/// Dark mode first design with yellow, black, and white colors
class AppColors {
  // Brand Colors (Consistent across themes)
  static const Color primary = Color(0xFFFFD700); // Yellow (main accent)
  static const Color primaryDark = Color(0xFFE6B800);
  static const Color primaryLight = Color(0xFFFFF44F);
  static const Color secondary = Color(0xFF00BCD4); // Complementary cyan
  static const Color secondaryDark = Color(0xFF0097A7);

  // Dark Theme Colors
  static const Color darkBg = Color(0xFF0F0F0F); // Near black background
  static const Color surface = Color(0xFF1A1A1A); // Slightly lighter surface
  static const Color surfaceAlt = Color(0xFF242424); // Alternative surface
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFB3B3B3); // Light gray
  static const Color textTertiary = Color(0xFF808080); // Medium gray
  static const Color borderColor = Color(0xFF333333);
  static const Color dividerColor = Color(0xFF2A2A2A);

  // Light Theme Colors
  static const Color lightBg = Color(0xFFF8F9FA); // Off-white background
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white surface
  static const Color lightSurfaceAlt = Color(0xFFF1F3F5); // Slightly darker white
  static const Color lightTextPrimary = Color(0xFF1A1A1A); // Near black text
  static const Color lightTextSecondary = Color(0xFF4A4A4A); // Dark gray text
  static const Color lightTextTertiary = Color(0xFF717171); // Gray text
  static const Color lightBorder = Color(0xFFDEE2E6); // Light gray border
  static const Color lightDivider = Color(0xFFE9ECEF);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Shadow Colors
  static const Color shadow = Color(0x29000000);
  static const Color shadowDark = Color(0x52000000);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFD700),
      Color(0xFFFFA500),
    ],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A1A),
      Color(0xFF0F0F0F),
    ],
  );
}

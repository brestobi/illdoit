import 'package:flutter/material.dart';

/// Application Color Palette
/// Dark mode first design with yellow, black, and white colors
class AppColors {
  // Background Colors
  static const Color darkBg = Color(0xFF0F0F0F); // Near black background
  static const Color surface = Color(0xFF1A1A1A); // Slightly lighter surface
  static const Color surfaceAlt = Color(0xFF242424); // Alternative surface

  // Primary & Accent Colors
  static const Color primary = Color(0xFFFFD700); // Yellow (main accent)
  static const Color primaryDark = Color(0xFFE6B800);
  static const Color primaryLight = Color(0xFFFFF44F);

  // Secondary Colors
  static const Color secondary = Color(0xFF00BCD4); // Complementary cyan
  static const Color secondaryDark = Color(0xFF0097A7);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFB3B3B3); // Light gray
  static const Color textTertiary = Color(0xFF808080); // Medium gray
  static const Color textDisabled = Color(0xFF4D4D4D); // Darker gray

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Border & Divider Colors
  static const Color borderColor = Color(0xFF333333);
  static const Color dividerColor = Color(0xFF2A2A2A);

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

  // Utility method for opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}

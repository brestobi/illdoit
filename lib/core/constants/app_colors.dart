import 'package:flutter/material.dart';

/// Application Color Palette
/// Brand Palette: Gold, Blue, Black, Red
class AppColors {
  // Brand Colors (Consistent across themes)
  static const Color gold = Color(0xFFFFD700); // Main Accent & CTA
  static const Color primary = gold; // Alias for backward compatibility
  static const Color blue = Color(0xFF0056b3); // Primary Brand Color
  static const Color black = Color(0xFF121212); // Primary Text/Background
  static const Color red = Color(0xFFD32F2F); // Errors & Alerts

  // Dark Theme Colors
  static const Color darkBg = black;
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceAlt = Color(0xFF2C2C2C);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF757575);
  static const Color borderColor = Color(0xFF424242);
  static const Color dividerColor = Color(0xFF424242);

  // Light Theme Colors
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEEEEEE);
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF616161);
  static const Color lightTextTertiary = Color(0xFF9E9E9E);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightDivider = Color(0xFFE0E0E0);

  // Status Colors (mapped to brand palette where possible)
  static const Color success = Color(0xFF388E3C);
  static const Color error = red;
  static const Color warning = Color(0xFFFBC02D);
  static const Color info = blue;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, Color(0xFF007bff)],
  );
}

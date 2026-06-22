import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      primaryColor: AppColors.primary,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.blue,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.darkBg,
        onSecondary: AppColors.darkBg,
        onSurface: AppColors.textPrimary,
        outline: AppColors.borderColor,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
      ),

      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.darkBg,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          elevation: 0,
          splashFactory: InkRipple.splashFactory,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.pressed)) return Colors.black.withValues(alpha: 0.1);
              return null;
            },
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 2),
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          splashFactory: InkRipple.splashFactory,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 15,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textTertiary),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );

  static ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      primaryColor: AppColors.primary,
      
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.blue,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: AppColors.darkBg,
        onSecondary: AppColors.darkBg,
        onSurface: AppColors.lightTextPrimary,
        outline: AppColors.lightBorder,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
      ),

      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.darkBg,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          elevation: 0,
          splashFactory: InkRipple.splashFactory,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 2),
          foregroundColor: AppColors.darkBg,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          splashFactory: InkRipple.splashFactory,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: const TextStyle(
          color: AppColors.lightTextTertiary,
          fontSize: 15,
        ),
        prefixIconColor: AppColors.lightTextSecondary,
        suffixIconColor: AppColors.lightTextSecondary,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary, letterSpacing: -1),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.lightTextSecondary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.lightTextTertiary),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
}

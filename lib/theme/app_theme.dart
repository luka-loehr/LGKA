// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';

// App-specific colors based on the Kotlin version
class AppColors {
  static const Color appBackground = Color(0xFF000000); // Pure black
  static const Color appSurface = Color(0xFF1E1E1E); // Dark surface for cards
  static const Color appOnBackground = Colors.white; // White text on black
  static const Color appOnSurface = Colors.white; // White text on surface
  static const Color appBlueAccent = Color(0xFF3770D4); // Blue for icons

  // Icon colors
  static const Color calendarIconBackground = Color(0xFF3770D4); // Blue icon background
  static const Color iconTint = Color(0xFF8E8E93); // Gray for username/password icons

  // Text colors
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xB3FFFFFF); // White with 70% opacity (ARGB format)

  // Accent color mapping - Aesthetic pastel Gen Z colors
  static Color getAccentColor(String colorName) {
    switch (colorName) {
      case 'blue':
        return appBlueAccent;
      case 'lavender':
        return Color(0xFF9B6BDF); // More saturated lavender - elegant and vibrant
      case 'mint':
        return Color(0xFF45A88A); // A bit more darker mint green - trendy and vibrant
      case 'peach':
        return Color(0xFFD4945A); // More saturated peach - warm and vibrant
      case 'rose':
        return Color(0xFFC47A7A); // More saturated rose - gentle and vibrant
      default:
        return appBlueAccent;
    }
  }
}

class AppTheme {
  static ThemeData get darkTheme => getDarkThemeWithAccent('blue');

  static ThemeData getDarkThemeWithAccent(String accentColorName) {
    final accentColor = AppColors.getAccentColor(accentColorName);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: ColorScheme.dark(
        surface: AppColors.appBackground,
        surfaceContainer: AppColors.appSurface,
        onSurface: AppColors.appOnBackground,
        primary: accentColor,
        onPrimary: Colors.white,
        secondary: AppColors.iconTint,
        onSecondary: Colors.white,
      ),

      scaffoldBackgroundColor: AppColors.appBackground,
      
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.appBackground,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
      ),

      cardTheme: const CardThemeData(
        color: AppColors.appSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.primaryText,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        headlineMedium: TextStyle(
          color: AppColors.primaryText,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        headlineSmall: TextStyle(
          color: AppColors.primaryText,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
        titleMedium: TextStyle(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: AppColors.primaryText,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: AppColors.secondaryText,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: AppColors.secondaryText,
          fontSize: 12,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          side: const BorderSide(color: AppColors.iconTint),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.appSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor),
        ),
        hintStyle: const TextStyle(color: AppColors.secondaryText),
        labelStyle: const TextStyle(color: AppColors.secondaryText),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0x1AFFFFFF), // White with 10% opacity
        thickness: 1,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return AppColors.iconTint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor.withValues(alpha: 0.5);
          }
          return AppColors.iconTint.withValues(alpha: 0.3);
        }),
      ),
    );
  }
} 
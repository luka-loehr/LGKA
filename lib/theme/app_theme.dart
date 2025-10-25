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

  // New vibrant accent color palette
  static const Color goldenYellow = Color(0xFFF9C80E); // #f9c80e
  static const Color vibrantOrange = Color(0xFFF86624); // #f86624
  static const Color electricRed = Color(0xFFEA3546); // #ea3546
  static const Color deepPurple = Color(0xFF662E9B); // #662e9b
  static const Color cyanBlue = Color(0xFF43BCCD); // #43bccd

  // Accent color mapping - New vibrant palette
  static Color getAccentColor(String colorName) {
    switch (colorName) {
      case 'golden':
        return goldenYellow;
      case 'orange':
        return vibrantOrange;
      case 'red':
        return electricRed;
      case 'purple':
        return deepPurple;
      case 'cyan':
        return cyanBlue;
      case 'blue': // Keep blue as default for backward compatibility
        return cyanBlue; // Use cyan as the new "blue"
      default:
        return cyanBlue; // Default to cyan
    }
  }
}

class AppTheme {
  static ThemeData get darkTheme => getDarkThemeWithAccent('cyan');

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
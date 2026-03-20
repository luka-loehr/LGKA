// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import '../providers/color_provider.dart';

/// Theme-aware color helpers — use these instead of AppColors constants
/// so colors adapt to light/dark mode automatically.
extension AppThemeX on BuildContext {
  Color get appBgColor => Theme.of(this).colorScheme.surface;
  Color get appSurfaceColor => Theme.of(this).colorScheme.surfaceContainer;
  Color get appPrimaryText => Theme.of(this).colorScheme.onSurface;
  Color get appSecondaryText => Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.6);
  Color get appDividerColor => Theme.of(this).dividerTheme.color ?? Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.1);
  Brightness get appBrightness => Theme.of(this).brightness;
}

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

  // Legacy method for backward compatibility - now uses ColorProvider
  static Color getAccentColor(String colorName) {
    return ColorProvider.getColorByName(colorName);
  }
}

class AppTheme {
  static ThemeData get darkTheme => getDarkThemeWithAccent(ColorProvider.defaultColorName);
  static ThemeData get lightTheme => getLightThemeWithAccent(ColorProvider.defaultColorName);

  static ThemeData getDarkThemeWithAccent(String accentColorName) {
    final accentColor = ColorProvider.getColorByName(accentColorName);

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

  static ThemeData getLightThemeWithAccent(String accentColorName) {
    final accentColor = ColorProvider.getColorByName(accentColorName);
    const lightBackground = Color(0xFFF2F2F7);
    const lightSurface = Color(0xFFFFFFFF);
    const lightOnBackground = Color(0xFF1A1A1A);
    const lightSecondaryText = Color(0xFF6B6B6B);
    const lightIconTint = Color(0xFF8E8E93);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.light(
        surface: lightBackground,
        surfaceContainer: lightSurface,
        onSurface: lightOnBackground,
        primary: accentColor,
        onPrimary: Colors.white,
        secondary: lightIconTint,
        onSecondary: lightOnBackground,
      ),

      scaffoldBackgroundColor: lightBackground,

      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightOnBackground,
        elevation: 0,
      ),

      cardTheme: const CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: lightOnBackground,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        headlineMedium: TextStyle(
          color: lightOnBackground,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        headlineSmall: TextStyle(
          color: lightOnBackground,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: lightOnBackground,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
        titleMedium: TextStyle(
          color: lightOnBackground,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: lightOnBackground,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: lightSecondaryText,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: lightSecondaryText,
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
          foregroundColor: lightOnBackground,
          side: const BorderSide(color: lightIconTint),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor),
        ),
        hintStyle: const TextStyle(color: lightSecondaryText),
        labelStyle: const TextStyle(color: lightSecondaryText),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0x1A000000), // Black with 10% opacity
        thickness: 1,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return lightIconTint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor.withValues(alpha: 0.5);
          }
          return lightIconTint.withValues(alpha: 0.3);
        }),
      ),
    );
  }
} 
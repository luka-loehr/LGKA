// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/preferences_manager.dart';
import 'app_providers.dart';

/// Centralized color system provider
/// Manages 5 colors: first is default, others are choosable
class ColorProvider extends StateNotifier<String> {
  ColorProvider(this._preferencesManager) : super('blue') {
    _loadSavedColor();
  }

  final PreferencesManager _preferencesManager;

  /// The 15-color palette - first color is always the default
  static const List<ColorPalette> colorPalette = [
    ColorPalette(name: 'blue', displayName: 'Blau', color: Color(0xFF2F80ED)), // Default Blue
    ColorPalette(name: 'cyan', displayName: 'Cyan', color: Color(0xFF00BCD4)), // Cyan (darker)
    ColorPalette(name: 'turquoise', displayName: 'Türkis', color: Color(0xFF1EB8AA)), // Turquoise
    ColorPalette(name: 'green', displayName: 'Grün', color: Color(0xFF27AE60)), // Green
    ColorPalette(name: 'lime', displayName: 'Limette', color: Color(0xFF9CCC65)), // Lime (darker)
    ColorPalette(name: 'yellow', displayName: 'Gelb', color: Color(0xFFFFCA28)), // Yellow (darker)
    ColorPalette(name: 'amber', displayName: 'Bernstein', color: Color(0xFFFF9800)), // Amber
    ColorPalette(name: 'orange', displayName: 'Orange', color: Color(0xFFFF6B00)), // Orange
    ColorPalette(name: 'red', displayName: 'Rot', color: Color(0xFFEA3546)), // Red
    ColorPalette(name: 'pink', displayName: 'Pink', color: Color(0xFFEA526F)), // Pink
    ColorPalette(name: 'rose', displayName: 'Rose', color: Color(0xFFE91E63)), // Rose
    ColorPalette(name: 'purple', displayName: 'Lila', color: Color(0xFF662E9B)), // Purple/Lila
    ColorPalette(name: 'deep_purple', displayName: 'Dunkel Lila', color: Color(0xFF4A148C)), // Deep Purple
    ColorPalette(name: 'indigo', displayName: 'Indigo', color: Color(0xFF3F51B5)), // Indigo
    ColorPalette(name: 'gray', displayName: 'Grau', color: Color(0xFF727272)), // Neutral Gray
  ];

  /// Get the default color (first in palette)
  static Color get defaultColor => colorPalette.first.color;

  /// Get the default color name (first in palette)
  static String get defaultColorName => colorPalette.first.name;

  /// Get current selected color
  Color get currentColor => getColorByName(state);

  /// Get color by name
  static Color getColorByName(String colorName) {
    try {
      return colorPalette.firstWhere((palette) => palette.name == colorName).color;
    } catch (e) {
      return defaultColor; // Fallback to default
    }
  }

  /// Get color palette by name
  static ColorPalette? getPaletteByName(String colorName) {
    try {
      return colorPalette.firstWhere((palette) => palette.name == colorName);
    } catch (e) {
      return null;
    }
  }

  /// Get all choosable colors (including default - all 5 colors)
  static List<ColorPalette> get choosableColors => colorPalette;

  /// Get all colors including default
  static List<ColorPalette> get allColors => colorPalette;

  /// Change the selected color
  Future<void> setColor(String colorName) async {
    if (colorPalette.any((palette) => palette.name == colorName)) {
      state = colorName;
      await _preferencesManager.setAccentColor(colorName);
    }
  }

  /// Load saved color from preferences
  Future<void> _loadSavedColor() async {
    final savedColor = _preferencesManager.accentColor;
    if (savedColor.isNotEmpty && colorPalette.any((palette) => palette.name == savedColor)) {
      state = savedColor;
    } else {
      state = defaultColorName; // Use default if no valid saved color
    }
  }

  /// Reset to default color
  Future<void> resetToDefault() async {
    await setColor(defaultColorName);
  }
}

/// Color palette data class
class ColorPalette {
  final String name;
  final String displayName;
  final Color color;

  const ColorPalette({
    required this.name,
    required this.displayName,
    required this.color,
  });
}

/// Provider for the color system
final colorProvider = StateNotifierProvider<ColorProvider, String>((ref) {
  final preferencesManager = ref.watch(preferencesManagerProvider);
  return ColorProvider(preferencesManager);
});

/// Provider to get current color directly
final currentColorProvider = Provider<Color>((ref) {
  final colorName = ref.watch(colorProvider);
  return ColorProvider.getColorByName(colorName);
});

/// Provider to get all choosable colors
final choosableColorsProvider = Provider<List<ColorPalette>>((ref) {
  return ColorProvider.choosableColors;
});

/// Provider to get all colors
final allColorsProvider = Provider<List<ColorPalette>>((ref) {
  return ColorProvider.allColors;
});

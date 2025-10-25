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
    ColorPalette(name: 'sky', displayName: 'Himmel', color: Color(0xFF3A9FCF)), // Sky Blue (darker)
    ColorPalette(name: 'teal', displayName: 'Türkis', color: Color(0xFF2A8FC3)), // Teal (darker)
    ColorPalette(name: 'aqua', displayName: 'Aqua', color: Color(0xFF1F9952)), // Aqua Green (darker)
    ColorPalette(name: 'mint', displayName: 'Minze', color: Color(0xFF57B87A)), // Mint (darker)
    ColorPalette(name: 'lime', displayName: 'Limette', color: Color(0xFF91CF2C)), // Lime (darker)
    ColorPalette(name: 'yellow', displayName: 'Gelb', color: Color(0xFFDBB440)), // Yellow (darker)
    ColorPalette(name: 'orange', displayName: 'Orange', color: Color(0xFFDD893C)), // Orange (darker)
    ColorPalette(name: 'deep_orange', displayName: 'Dunkel Orange', color: Color(0xFFD3454A)), // Deep Orange (darker)
    ColorPalette(name: 'coral', displayName: 'Koralle', color: Color(0xFFDC5D85)), // Coral Pink (darker)
    ColorPalette(name: 'magenta', displayName: 'Magenta', color: Color(0xFFA558C2)), // Magenta (darker)
    ColorPalette(name: 'violet', displayName: 'Violett', color: Color(0xFF8644C9)), // Violet (darker)
    ColorPalette(name: 'indigo', displayName: 'Indigo', color: Color(0xFF4D5CD8)), // Indigo (darker)
    ColorPalette(name: 'burgundy', displayName: 'Burgund', color: Color(0xFF891927)), // Dark Red / Burgundy (darker)
    ColorPalette(name: 'gray', displayName: 'Grau', color: Color(0xFF727272)), // Neutral Gray (darker)
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

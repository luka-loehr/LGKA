// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';

/// Centralized color system provider
/// Manages 5 colors: blue (default), mint, lavender, rose, peach
class ColorProvider extends Notifier<String> {
  PreferencesManagerState get _preferencesManagerState => ref.watch(preferencesManagerProvider);

  @override
  String build() {
    final savedColor = _preferencesManagerState.accentColor;
    if (savedColor.isNotEmpty && colorPalette.any((palette) => palette.name == savedColor)) {
      return savedColor;
    }
    return defaultColorName;
  }

  /// The 5-color palette - first color is always the default
  static const List<ColorPalette> colorPalette = [
    ColorPalette(name: 'blue', displayName: 'Blau', color: Color(0xFF3770D4)), // Default Blue
    ColorPalette(name: 'mint', displayName: 'Mint', color: Color(0xFF45A88A)), // Mint green
    ColorPalette(name: 'lavender', displayName: 'Lavendel', color: Color(0xFF9B6BDF)), // Lavender
    ColorPalette(name: 'rose', displayName: 'Rose', color: Color(0xFFC47A7A)), // Rose
    ColorPalette(name: 'peach', displayName: 'Pfirsich', color: Color(0xFFBF7F46)), // Peach
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
      await ref.read(preferencesManagerProvider.notifier).setAccentColor(colorName);
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
final colorProvider = NotifierProvider<ColorProvider, String>(ColorProvider.new);

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

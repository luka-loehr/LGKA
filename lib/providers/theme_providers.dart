// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'preferences_provider.dart';

/// Provider for the light [ThemeData] derived from the current accent color.
final lightThemeProvider = Provider<ThemeData>((ref) {
  final prefs = ref.watch(preferencesManagerProvider);
  return AppTheme.getLightThemeWithAccent(prefs.accentColor);
});

/// Provider for the dark [ThemeData] derived from the current accent color.
final themeProvider = Provider<ThemeData>((ref) {
  final prefs = ref.watch(preferencesManagerProvider);
  return AppTheme.getDarkThemeWithAccent(prefs.accentColor);
});

/// Provider for the current [ThemeMode] setting.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final prefs = ref.watch(preferencesManagerProvider);
  switch (prefs.themeMode) {
    case 'light':
      return ThemeMode.light;
    case 'system':
      return ThemeMode.system;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
});

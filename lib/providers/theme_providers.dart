// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'preferences_provider.dart';

/// Provider for the light [ThemeData] derived from the current accent color.
///
/// Watches only the accent color (via `.select`) so unrelated preference
/// writes — e.g. saving the last PDF page on every navigation — don't rebuild
/// the theme and, through it, the whole root [MaterialApp].
final lightThemeProvider = Provider<ThemeData>((ref) {
  final accentColor =
      ref.watch(preferencesManagerProvider.select((p) => p.accentColor));
  return AppTheme.getLightThemeWithAccent(accentColor);
});

/// Provider for the dark [ThemeData] derived from the current accent color.
final themeProvider = Provider<ThemeData>((ref) {
  final accentColor =
      ref.watch(preferencesManagerProvider.select((p) => p.accentColor));
  return AppTheme.getDarkThemeWithAccent(accentColor);
});

/// Provider for the current [ThemeMode] setting.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final themeMode =
      ref.watch(preferencesManagerProvider.select((p) => p.themeMode));
  switch (themeMode) {
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

// Copyright Luka Löhr 2025

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../data/preferences_manager.dart';
import '../data/pdf_repository.dart';
import '../providers/schedule_provider.dart';
import '../services/schedule_service.dart';
import '../theme/app_theme.dart';

// Preferences Manager Provider
final preferencesManagerProvider = ChangeNotifierProvider<PreferencesManager>((ref) {
  throw UnimplementedError('PreferencesManager must be overridden');
});

// Theme Provider - listens to accent color changes
final themeProvider = Provider<ThemeData>((ref) {
  final preferencesManager = ref.watch(preferencesManagerProvider);
  return AppTheme.getDarkThemeWithAccent(preferencesManager.accentColor);
});

// PDF Repository Provider
final pdfRepositoryProvider = ChangeNotifierProvider<PdfRepository>((ref) {
  return PdfRepository(ref);
});

// App State Providers
final isFirstLaunchProvider = StateProvider<bool>((ref) => true);
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);
final isLoadingProvider = StateProvider<bool>((ref) => false);

// Navigation State Provider
final currentRouteProvider = StateProvider<String>((ref) => '/welcome');

// Schedule Provider
final scheduleProvider = StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  return ScheduleNotifier(ref.read(scheduleServiceProvider));
});

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService();
});
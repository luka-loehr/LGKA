// Copyright Luka Löhr 2026

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../data/preferences_manager.dart';
import '../features/schedule/data/schedule_service.dart';
import '../features/news/data/news_service.dart';
import '../features/substitution/data/substitution_service.dart';
import '../theme/app_theme.dart';

/// State class for preferences manager
class PreferencesManagerState {
  final bool isInitialized;
  final bool isFirstLaunch;
  final bool isAuthenticated;
  final bool onboardingCompleted;
  final bool isDebugMode;
  final bool showNavigationDebug;
  final String accentColor;
  final bool vibrationEnabled;
  final bool krankmeldungInfoShown;
  final String? lastPdfSearchQuery;
  final int? lastPdfSearchPage;
  final int? lastSchedulePage5to10;
  final int? lastSchedulePageJ11J12;
  final String? lastScheduleQuery5to10;
  final String? lastScheduleQueryJ11J12;

  const PreferencesManagerState({
    this.isInitialized = false,
    this.isFirstLaunch = true,
    this.isAuthenticated = false,
    this.onboardingCompleted = false,
    this.isDebugMode = false,
    this.showNavigationDebug = false,
    this.accentColor = 'blue',
    this.vibrationEnabled = true,
    this.krankmeldungInfoShown = false,
    this.lastPdfSearchQuery,
    this.lastPdfSearchPage,
    this.lastSchedulePage5to10,
    this.lastSchedulePageJ11J12,
    this.lastScheduleQuery5to10,
    this.lastScheduleQueryJ11J12,
  });

  PreferencesManagerState copyWith({
    bool? isInitialized,
    bool? isFirstLaunch,
    bool? isAuthenticated,
    bool? onboardingCompleted,
    bool? isDebugMode,
    bool? showNavigationDebug,
    String? accentColor,
    bool? vibrationEnabled,
    bool? krankmeldungInfoShown,
    String? lastPdfSearchQuery,
    int? lastPdfSearchPage,
    int? lastSchedulePage5to10,
    int? lastSchedulePageJ11J12,
    String? lastScheduleQuery5to10,
    String? lastScheduleQueryJ11J12,
  }) {
    return PreferencesManagerState(
      isInitialized: isInitialized ?? this.isInitialized,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isDebugMode: isDebugMode ?? this.isDebugMode,
      showNavigationDebug: showNavigationDebug ?? this.showNavigationDebug,
      accentColor: accentColor ?? this.accentColor,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      krankmeldungInfoShown: krankmeldungInfoShown ?? this.krankmeldungInfoShown,
      lastPdfSearchQuery: lastPdfSearchQuery ?? this.lastPdfSearchQuery,
      lastPdfSearchPage: lastPdfSearchPage ?? this.lastPdfSearchPage,
      lastSchedulePage5to10: lastSchedulePage5to10 ?? this.lastSchedulePage5to10,
      lastSchedulePageJ11J12: lastSchedulePageJ11J12 ?? this.lastSchedulePageJ11J12,
      lastScheduleQuery5to10: lastScheduleQuery5to10 ?? this.lastScheduleQuery5to10,
      lastScheduleQueryJ11J12: lastScheduleQueryJ11J12 ?? this.lastScheduleQueryJ11J12,
    );
  }
}

/// Notifier for preferences manager
class PreferencesManagerNotifier extends Notifier<PreferencesManagerState> {
  final PreferencesManager _manager = PreferencesManager();

  @override
  PreferencesManagerState build() {
    // Initialize asynchronously
    Future.microtask(() async {
      if (!_manager.isInitialized) {
        await _manager.init();
        _refreshState();
      }
    });
    return const PreferencesManagerState();
  }

  Future<void> init() async {
    await _manager.init();
    _refreshState();
  }

  void _refreshState() {
    if (!_manager.isInitialized) return;
    state = PreferencesManagerState(
      isInitialized: _manager.isInitialized,
      isFirstLaunch: _manager.isFirstLaunch,
      isAuthenticated: _manager.isAuthenticated,
      onboardingCompleted: _manager.onboardingCompleted,
      isDebugMode: _manager.isDebugMode,
      showNavigationDebug: _manager.showNavigationDebug,
      accentColor: _manager.accentColor,
      vibrationEnabled: _manager.vibrationEnabled,
      krankmeldungInfoShown: _manager.krankmeldungInfoShown,
      lastPdfSearchQuery: _manager.lastPdfSearchQuery,
      lastPdfSearchPage: _manager.lastPdfSearchPage,
      lastSchedulePage5to10: _manager.lastSchedulePage5to10,
      lastSchedulePageJ11J12: _manager.lastSchedulePageJ11J12,
      lastScheduleQuery5to10: _manager.lastScheduleQuery5to10,
      lastScheduleQueryJ11J12: _manager.lastScheduleQueryJ11J12,
    );
  }

  Future<void> setFirstLaunch(bool value) async {
    await _manager.setFirstLaunch(value);
    _refreshState();
  }

  Future<void> setAuthenticated(bool value) async {
    await _manager.setAuthenticated(value);
    _refreshState();
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _manager.setOnboardingCompleted(value);
    _refreshState();
  }

  Future<void> setDebugMode(bool value) async {
    await _manager.setDebugMode(value);
    _refreshState();
  }

  Future<void> setShowNavigationDebug(bool value) async {
    await _manager.setShowNavigationDebug(value);
    _refreshState();
  }

  Future<void> setAccentColor(String color) async {
    await _manager.setAccentColor(color);
    _refreshState();
  }

  Future<void> setVibrationEnabled(bool value) async {
    await _manager.setVibrationEnabled(value);
    _refreshState();
  }

  Future<void> setKrankmeldungInfoShown(bool value) async {
    await _manager.setKrankmeldungInfoShown(value);
    _refreshState();
  }

  Future<void> setLastPdfSearchQuery(String? value) async {
    await _manager.setLastPdfSearchQuery(value);
    _refreshState();
  }

  Future<void> setLastPdfSearchPage(int? page) async {
    await _manager.setLastPdfSearchPage(page);
    _refreshState();
  }

  Future<void> setLastSchedulePage5to10(int? page) async {
    await _manager.setLastSchedulePage5to10(page);
    _refreshState();
  }

  Future<void> setLastSchedulePageJ11J12(int? page) async {
    await _manager.setLastSchedulePageJ11J12(page);
    _refreshState();
  }

  Future<void> setLastScheduleQuery5to10(String? value) async {
    await _manager.setLastScheduleQuery5to10(value);
    _refreshState();
  }

  Future<void> setLastScheduleQueryJ11J12(String? value) async {
    await _manager.setLastScheduleQueryJ11J12(value);
    _refreshState();
  }

  Future<void> clearAllPreferences() async {
    await _manager.clearAllPreferences();
    _refreshState();
  }

  // Expose manager for direct access (for compatibility)
  PreferencesManager get manager => _manager;
}

// Preferences Manager Provider
final preferencesManagerProvider = NotifierProvider<PreferencesManagerNotifier, PreferencesManagerState>(PreferencesManagerNotifier.new);

// Theme Provider - listens to accent color changes
final themeProvider = Provider<ThemeData>((ref) {
  final preferencesManagerState = ref.watch(preferencesManagerProvider);
  return AppTheme.getDarkThemeWithAccent(preferencesManagerState.accentColor);
});

// App State Providers
class IsFirstLaunchNotifier extends Notifier<bool> {
  @override
  bool build() => true;
}

class IsAuthenticatedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}

class IsLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}

class CurrentRouteNotifier extends Notifier<String> {
  @override
  String build() => '/welcome';
}

final isFirstLaunchProvider = NotifierProvider<IsFirstLaunchNotifier, bool>(IsFirstLaunchNotifier.new);
final isAuthenticatedProvider = NotifierProvider<IsAuthenticatedNotifier, bool>(IsAuthenticatedNotifier.new);
final isLoadingProvider = NotifierProvider<IsLoadingNotifier, bool>(IsLoadingNotifier.new);
final currentRouteProvider = NotifierProvider<CurrentRouteNotifier, String>(CurrentRouteNotifier.new);

// Schedule Provider
final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return scheduleService;
});

// News Service Provider
final newsServiceProvider = Provider<NewsService>((ref) {
  return NewsService();
});

// Substitution Service Provider
final substitutionServiceProvider = Provider<SubstitutionService>((ref) {
  return SubstitutionService();
});
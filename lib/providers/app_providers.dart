// Copyright Luka Löhr 2025

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../data/preferences_manager.dart';
import '../services/weather_service.dart';
import '../services/schedule_service.dart';
import '../services/news_service.dart';
import '../services/substitution_service.dart';
import '../services/cache_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_logger.dart';
import '../services/haptic_service.dart';

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

// Weather Service Provider
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

// Weather Data State Provider - manages weather data
class WeatherDataState {
  final List<WeatherData> chartData;
  final WeatherData? latestData;
  final bool isLoading;
  final bool isPreloaded;
  final String? error;
  final DateTime? lastUpdateTime;
  final int fullDataCount; // Track full data count before downsampling

  const WeatherDataState({
    this.chartData = const [],
    this.latestData,
    this.isLoading = false,
    this.isPreloaded = false,
    this.error,
    this.lastUpdateTime,
    this.fullDataCount = 0,
  });

  WeatherDataState copyWith({
    List<WeatherData>? chartData,
    WeatherData? latestData,
    bool? isLoading,
    bool? isPreloaded,
    String? error,
    DateTime? lastUpdateTime,
    int? fullDataCount,
  }) {
    return WeatherDataState(
      chartData: chartData ?? this.chartData,
      latestData: latestData ?? this.latestData,
      isLoading: isLoading ?? this.isLoading,
      isPreloaded: isPreloaded ?? this.isPreloaded,
      error: error,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      fullDataCount: fullDataCount ?? this.fullDataCount,
    );
  }
}

// Weather Data Provider
final weatherDataProvider = NotifierProvider<WeatherDataNotifier, WeatherDataState>(() {
  return WeatherDataNotifier();
});

class WeatherDataNotifier extends Notifier<WeatherDataState> {
  final _cacheService = CacheService();

  WeatherService get _weatherService => ref.read(weatherServiceProvider);

  @override
  WeatherDataState build() => const WeatherDataState();

  /// Preload weather data from network
  Future<void> preloadWeatherData() async {
    if (state.chartData.isNotEmpty && state.lastUpdateTime != null) {
      if (_cacheService.isCacheValid(CacheKey.weather, lastFetchTime: state.lastUpdateTime)) {
        return;
      }

      unawaited(updateDataInBackground());
      return;
    }

    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final chartDataFuture = _weatherService.fetchWeatherData();
      final latestDataFuture = _weatherService.getLatestWeatherData();

      final results = await Future.wait([chartDataFuture, latestDataFuture]);
      final fullData = results[0] as List<WeatherData>;
      final latestData = results[1] as WeatherData?;

      // Downsample for chart performance - shows full day from 0:00 to 23:59
      final downsampledData = _weatherService.downsampleForChart(fullData);

      final updateTime = DateTime.now();
      state = state.copyWith(
        chartData: downsampledData,
        latestData: latestData ?? (fullData.isNotEmpty ? fullData.last : null),
        isLoading: false,
        isPreloaded: true,
        lastUpdateTime: updateTime,
        fullDataCount: fullData.length,
      );
      _cacheService.updateCacheTimestamp(CacheKey.weather, updateTime);
    } catch (e) {
      // Handle errors gracefully - don't freeze the app
      AppLogger.error('Failed to preload weather data', module: 'WeatherProvider', error: e);
      final errorMessage = e.toString().contains('too large') || e.toString().contains('timed out')
          ? 'CSV-Datei zu groß oder beschädigt'
          : 'Fehler beim Laden der Wetterdaten';
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        // Keep existing data if available, don't clear it on error
        chartData: state.chartData.isNotEmpty ? state.chartData : const [],
      );
      
      // Trigger medium haptic feedback on initial load failure
      HapticService.medium();
    }
  }

  /// Refresh weather data (called from weather page)
  Future<void> refreshWeatherData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final chartDataFuture = _weatherService.fetchWeatherData();
      final latestDataFuture = _weatherService.getLatestWeatherData();

      final results = await Future.wait([chartDataFuture, latestDataFuture]);
      final fullData = results[0] as List<WeatherData>;
      final latestData = results[1] as WeatherData?;
      final downsampledData = _weatherService.downsampleForChart(fullData);

      final updateTime = DateTime.now();
      state = state.copyWith(
        chartData: downsampledData,
        latestData: latestData ?? (fullData.isNotEmpty ? fullData.last : null),
        isLoading: false,
        isPreloaded: true,
        lastUpdateTime: updateTime,
        fullDataCount: fullData.length,
      );
      _cacheService.updateCacheTimestamp(CacheKey.weather, updateTime);
    } catch (e) {
      // Handle errors gracefully - don't freeze the app
      AppLogger.error('Failed to refresh weather data', module: 'WeatherProvider', error: e);
      final errorMessage = e.toString().contains('too large') || e.toString().contains('timed out')
          ? 'CSV-Datei zu groß oder beschädigt'
          : 'Fehler beim Laden der Wetterdaten';
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        // Keep existing data if available, don't clear it on error
        chartData: state.chartData.isNotEmpty ? state.chartData : const [],
      );
      
      // Trigger medium haptic feedback on retry failure
      HapticService.medium();
    }
  }

  /// Update data in background (silent refresh)
  Future<void> updateDataInBackground() async {
    try {
      final chartDataFuture = _weatherService.fetchWeatherData();
      final latestDataFuture = _weatherService.getLatestWeatherData();

      final results = await Future.wait([chartDataFuture, latestDataFuture]);
      final fullData = results[0] as List<WeatherData>;
      final latestData = results[1] as WeatherData?;

      if (fullData.isNotEmpty) {
        final downsampledData = _weatherService.downsampleForChart(fullData);
        final updateTime = DateTime.now();
        state = state.copyWith(
          chartData: downsampledData,
          latestData: latestData ?? fullData.last,
          lastUpdateTime: updateTime,
          fullDataCount: fullData.length,
        );
        _cacheService.updateCacheTimestamp(CacheKey.weather, updateTime);
      }
    } catch (e) {
      // Silent failure for background updates
    }
  }
}

// Schedule Provider
final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService();
});

// News Service Provider
final newsServiceProvider = Provider<NewsService>((ref) {
  return NewsService();
});

// Substitution Service Provider
final substitutionServiceProvider = Provider<SubstitutionService>((ref) {
  return SubstitutionService();
});
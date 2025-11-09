// Copyright Luka Löhr 2025

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../data/preferences_manager.dart';
import '../data/pdf_repository.dart';
import '../services/weather_service.dart';
import '../providers/schedule_provider.dart';
import '../services/schedule_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_logger.dart';

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
final weatherDataProvider = StateNotifierProvider<WeatherDataNotifier, WeatherDataState>((ref) {
  return WeatherDataNotifier(ref.read(weatherServiceProvider));
});

class WeatherDataNotifier extends StateNotifier<WeatherDataState> {
  final WeatherService _weatherService;
  static const Duration _cacheValidity = Duration(minutes: 5);

  WeatherDataNotifier(this._weatherService) : super(const WeatherDataState());

  /// Preload weather data from network
  Future<void> preloadWeatherData() async {
    if (state.chartData.isNotEmpty && state.lastUpdateTime != null) {
      final isFresh = DateTime.now().difference(state.lastUpdateTime!) < _cacheValidity;
      if (isFresh) {
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

      state = state.copyWith(
        chartData: downsampledData,
        latestData: latestData ?? (fullData.isNotEmpty ? fullData.last : null),
        isLoading: false,
        isPreloaded: true,
        lastUpdateTime: DateTime.now(),
        fullDataCount: fullData.length,
      );
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

      state = state.copyWith(
        chartData: downsampledData,
        latestData: latestData ?? (fullData.isNotEmpty ? fullData.last : null),
        isLoading: false,
        isPreloaded: true,
        lastUpdateTime: DateTime.now(),
        fullDataCount: fullData.length,
      );
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
        state = state.copyWith(
          chartData: downsampledData,
          latestData: latestData ?? fullData.last,
          lastUpdateTime: DateTime.now(),
          fullDataCount: fullData.length,
        );
      }
    } catch (e) {
      // Silent failure for background updates
    }
  }
}

// Schedule Provider
final scheduleProvider = StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  return ScheduleNotifier(ref.read(scheduleServiceProvider));
});

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService();
});
// Copyright Luka Löhr 2026

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/cache_service.dart';
import '../../../../services/haptic_service.dart';
import '../../../../utils/app_logger.dart';
import '../domain/weather_models.dart';
import '../data/weather_service.dart';

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
    AppLogger.info('Background refresh: Weather data', module: 'WeatherProvider');
    final wasCacheValid = state.lastUpdateTime != null && 
                          _cacheService.isCacheValid(CacheKey.weather, lastFetchTime: state.lastUpdateTime);
    
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
        AppLogger.success('Background refresh complete: Weather data', module: 'WeatherProvider');
      }
    } catch (e) {
      AppLogger.error('Background refresh failed: Weather data', module: 'WeatherProvider', error: e);
      
      // If cache was invalid (app was backgrounded), clear cached data and show error
      if (!wasCacheValid) {
        AppLogger.info('Refresh failed with invalid cache - clearing cached weather data', module: 'WeatherProvider');
        state = state.copyWith(
          chartData: const [],
          latestData: null,
          error: 'Fehler beim Laden der Wetterdaten',
          isLoading: false,
        );
      }
      // If cache was valid, keep existing data (silent failure)
    }
  }
}

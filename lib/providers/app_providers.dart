// Copyright Luka Löhr 2025

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/preferences_manager.dart';
import '../data/pdf_repository.dart';

import '../services/weather_service.dart';

// Preferences Manager Provider
final preferencesManagerProvider = Provider<PreferencesManager>((ref) {
  throw UnimplementedError('PreferencesManager must be overridden');
});

// PDF Repository Provider
final pdfRepositoryProvider = ChangeNotifierProvider<PdfRepository>((ref) {
  return PdfRepository();
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

  const WeatherDataState({
    this.chartData = const [],
    this.latestData,
    this.isLoading = false,
    this.isPreloaded = false,
    this.error,
    this.lastUpdateTime,
  });

  WeatherDataState copyWith({
    List<WeatherData>? chartData,
    WeatherData? latestData,
    bool? isLoading,
    bool? isPreloaded,
    String? error,
    DateTime? lastUpdateTime,
  }) {
    return WeatherDataState(
      chartData: chartData ?? this.chartData,
      latestData: latestData ?? this.latestData,
      isLoading: isLoading ?? this.isLoading,
      isPreloaded: isPreloaded ?? this.isPreloaded,
      error: error ?? this.error,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    );
  }
}

// Weather Data Provider
final weatherDataProvider = StateNotifierProvider<WeatherDataNotifier, WeatherDataState>((ref) {
  return WeatherDataNotifier(ref.read(weatherServiceProvider));
});

class WeatherDataNotifier extends StateNotifier<WeatherDataState> {
  final WeatherService _weatherService;

  WeatherDataNotifier(this._weatherService) : super(const WeatherDataState());

  /// Preload weather data from network
  Future<void> preloadWeatherData() async {
    if (state.isPreloaded && state.chartData.isNotEmpty) {
      print('🌤️ [WeatherDataNotifier] Data already preloaded, skipping');
      return;
    }

    print('🌤️ [WeatherDataNotifier] Starting weather data preload');

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Fetch fresh data from network
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
      );

      print('✅ [WeatherDataNotifier] Fresh weather data loaded successfully (${fullData.length} points, ${downsampledData.length} for chart)');
    } catch (e) {
      print('❌ [WeatherDataNotifier] Preload failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh weather data (called from weather page)
  /// Always fetches fresh network data
  Future<void> refreshWeatherData() async {
    print('🌤️ [WeatherDataNotifier] Starting weather data refresh');

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
      );

      print('✅ [WeatherDataNotifier] Fresh weather data refresh completed (${fullData.length} points, ${downsampledData.length} for chart)');
    } catch (e) {
      print('❌ [WeatherDataNotifier] Refresh failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update data in background (silent refresh)
  /// Fetches fresh network data silently
  Future<void> updateDataInBackground() async {
    print('🌤️ [WeatherDataNotifier] Starting background update');

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
        );
        print('✅ [WeatherDataNotifier] Fresh background update completed (${fullData.length} points, ${downsampledData.length} for chart)');
      }
    } catch (e) {
      print('❌ [WeatherDataNotifier] Background update failed: $e');
      // Don't update error state for background updates to avoid disrupting UI
    }
  }
}
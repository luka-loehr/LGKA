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

// Global Connectivity State Manager
class ConnectivityState {
  final bool hasWeatherData;
  final bool hasPdfData;
  final bool weatherHasError;
  final bool allPdfsHaveError;
  final DateTime? lastUpdateTime;

  const ConnectivityState({
    this.hasWeatherData = false,
    this.hasPdfData = false,
    this.weatherHasError = false,
    this.allPdfsHaveError = false,
    this.lastUpdateTime,
  });

  ConnectivityState copyWith({
    bool? hasWeatherData,
    bool? hasPdfData,
    bool? weatherHasError,
    bool? allPdfsHaveError,
    DateTime? lastUpdateTime,
  }) {
    return ConnectivityState(
      hasWeatherData: hasWeatherData ?? this.hasWeatherData,
      hasPdfData: hasPdfData ?? this.hasPdfData,
      weatherHasError: weatherHasError ?? this.weatherHasError,
      allPdfsHaveError: allPdfsHaveError ?? this.allPdfsHaveError,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    );
  }

  // Core logic: show connection error only when ALL data sources fail
  bool get hasAnyData => hasWeatherData || hasPdfData;
  bool get shouldShowWeatherConnectionError => weatherHasError && !hasPdfData;
  bool get shouldShowPdfConnectionError => allPdfsHaveError && !hasWeatherData;
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  ConnectivityNotifier() : super(const ConnectivityState());

  void updateWeatherState({required bool hasData, required bool hasError}) {
    state = state.copyWith(
      hasWeatherData: hasData,
      weatherHasError: hasError,
      lastUpdateTime: DateTime.now(),
    );
  }

  void updatePdfState({required bool hasData, required bool allHaveError}) {
    state = state.copyWith(
      hasPdfData: hasData,
      allPdfsHaveError: allHaveError,
      lastUpdateTime: DateTime.now(),
    );
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});

// Global Retry Service
class GlobalRetryService {
  final Ref _ref;

  GlobalRetryService(this._ref);

  /// Retry both weather and PDF downloads simultaneously
  Future<void> retryAll() async {
    print('🔄 [GlobalRetryService] Starting unified retry for both weather and PDFs');

    // Run both retries in parallel for faster recovery
    await Future.wait([
      _retryWeatherData(),
      _retryPdfData(),
    ]);

    print('✅ [GlobalRetryService] Unified retry completed');
  }

  /// Retry only weather data
  Future<void> retryWeatherOnly() async {
    print('🔄 [GlobalRetryService] Retrying weather data only');
    await _retryWeatherData();
  }

  /// Retry only PDF data
  Future<void> retryPdfOnly() async {
    print('🔄 [GlobalRetryService] Retrying PDF data only');
    await _retryPdfData();
  }

  Future<void> _retryWeatherData() async {
    try {
      final weatherNotifier = _ref.read(weatherDataProvider.notifier);
      await weatherNotifier.refreshWeatherData();
    } catch (e) {
      print('❌ [GlobalRetryService] Weather retry failed: $e');
    }
  }

  Future<void> _retryPdfData() async {
    try {
      final pdfRepository = _ref.read(pdfRepositoryProvider);
      await pdfRepository.retryLoadPdfs();
    } catch (e) {
      print('❌ [GlobalRetryService] PDF retry failed: $e');
    }
  }
}

final globalRetryServiceProvider = Provider<GlobalRetryService>((ref) {
  return GlobalRetryService(ref);
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
  return WeatherDataNotifier(ref.read(weatherServiceProvider), ref);
});

class WeatherDataNotifier extends StateNotifier<WeatherDataState> {
  final WeatherService _weatherService;
  final Ref _ref;

  WeatherDataNotifier(this._weatherService, this._ref) : super(const WeatherDataState());

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

      // Update connectivity state - weather data loaded successfully
      _ref.read(connectivityProvider.notifier).updateWeatherState(
        hasData: true,
        hasError: false,
      );

      print('✅ [WeatherDataNotifier] Fresh weather data loaded successfully (${fullData.length} points, ${downsampledData.length} for chart)');
    } catch (e) {
      print('❌ [WeatherDataNotifier] Preload failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      // Update connectivity state - weather data failed to load
      _ref.read(connectivityProvider.notifier).updateWeatherState(
        hasData: state.chartData.isNotEmpty, // Check if we have cached data
        hasError: true,
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

      // Update connectivity state - weather data refreshed successfully
      _ref.read(connectivityProvider.notifier).updateWeatherState(
        hasData: true,
        hasError: false,
      );

      print('✅ [WeatherDataNotifier] Fresh weather data refresh completed (${fullData.length} points, ${downsampledData.length} for chart)');
    } catch (e) {
      print('❌ [WeatherDataNotifier] Refresh failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      // Update connectivity state - weather refresh failed
      _ref.read(connectivityProvider.notifier).updateWeatherState(
        hasData: state.chartData.isNotEmpty, // Check if we have cached data
        hasError: true,
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

        // Update connectivity state - background update successful
        _ref.read(connectivityProvider.notifier).updateWeatherState(
          hasData: true,
          hasError: false,
        );

        print('✅ [WeatherDataNotifier] Fresh background update completed (${fullData.length} points, ${downsampledData.length} for chart)');
      }
    } catch (e) {
      print('❌ [WeatherDataNotifier] Background update failed: $e');
      // Don't update error state for background updates to avoid disrupting UI
    }
  }
}
// Copyright Luka Löhr 2025

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/preferences_manager.dart';
import '../data/pdf_repository.dart';
import '../services/review_service.dart';
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

// Review Service Provider
final reviewServiceProvider = Provider<ReviewService>((ref) {
  final preferencesManager = ref.watch(preferencesManagerProvider);
  return ReviewService(preferencesManager);
});

// Weather Service Provider
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

// Weather Data State Provider - manages cached weather data
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

  /// Preload weather data for instant app startup with background refresh
  Future<void> preloadWeatherData() async {
    if (state.isPreloaded && state.chartData.isNotEmpty) {
      print('🌤️ [WeatherDataNotifier] Data already preloaded, skipping');
      return;
    }

    print('🌤️ [WeatherDataNotifier] Starting weather data preload');
    
    // First, load instant startup data from persistent cache (regardless of age)
    try {
      final instantData = await _weatherService.getInstantStartupData();
      final instantLatest = await _weatherService.getInstantLatestData();
      
      if (instantData != null && instantData.isNotEmpty) {
        print('🚀 [WeatherDataNotifier] Showing instant data (${instantData.length} points)');
        state = state.copyWith(
          chartData: instantData,
          latestData: instantLatest ?? instantData.last,
          isLoading: false,
          isPreloaded: true,
          lastUpdateTime: DateTime.now(),
        );
        
        // Start background refresh without blocking UI
        _backgroundRefresh();
        return;
      }
    } catch (e) {
      print('❌ [WeatherDataNotifier] Error loading instant data: $e');
    }
    
    // If no instant data available, show loading and fetch fresh data
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Try to load from valid cache first
      final cachedData = await _weatherService.getCachedData();
      if (cachedData != null && cachedData.isNotEmpty) {
        print('🌤️ [WeatherDataNotifier] Loaded valid cached data (${cachedData.length} points)');
        final latestData = await _weatherService.getLatestWeatherData();
        state = state.copyWith(
          chartData: cachedData,
          latestData: latestData ?? (cachedData.isNotEmpty ? cachedData.last : null),
          isLoading: false,
          isPreloaded: true,
          lastUpdateTime: DateTime.now(),
        );
        return;
      }

      // Load fresh data if no cache available
      final chartDataFuture = _weatherService.fetchWeatherData();
      final latestDataFuture = _weatherService.getLatestWeatherData();
      
      final results = await Future.wait([chartDataFuture, latestDataFuture]);
      final chartData = results[0] as List<WeatherData>;
      final latestData = results[1] as WeatherData?;
      
      state = state.copyWith(
        chartData: chartData,
        latestData: latestData ?? (chartData.isNotEmpty ? chartData.last : null),
        isLoading: false,
        isPreloaded: true,
        lastUpdateTime: DateTime.now(),
      );
      
      print('🌤️ [WeatherDataNotifier] Preload completed successfully (${chartData.length} points)');
    } catch (e) {
      print('❌ [WeatherDataNotifier] Preload failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Background refresh without UI indicators
  Future<void> _backgroundRefresh() async {
    print('🔄 [WeatherDataNotifier] Starting background refresh');
    
    try {
      final chartDataFuture = _weatherService.fetchWeatherData();
      final latestDataFuture = _weatherService.getLatestWeatherData();
      
      final results = await Future.wait([chartDataFuture, latestDataFuture]);
      final chartData = results[0] as List<WeatherData>;
      final latestData = results[1] as WeatherData?;
      
      if (chartData.isNotEmpty) {
        state = state.copyWith(
          chartData: chartData,
          latestData: latestData ?? chartData.last,
          lastUpdateTime: DateTime.now(),
          error: null, // Clear any previous errors
        );
        print('🔄 [WeatherDataNotifier] Background refresh completed successfully');
      }
    } catch (e) {
      print('❌ [WeatherDataNotifier] Background refresh failed: $e');
      // Don't update error state for background updates to avoid disrupting UI
    }
  }

  /// Refresh weather data (called from weather page)
  Future<void> refreshWeatherData() async {
    print('🌤️ [WeatherDataNotifier] Starting weather data refresh');
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final chartDataFuture = _weatherService.fetchWeatherData();
      final latestDataFuture = _weatherService.getLatestWeatherData();
      
      final results = await Future.wait([chartDataFuture, latestDataFuture]);
      final chartData = results[0] as List<WeatherData>;
      final latestData = results[1] as WeatherData?;
      
      state = state.copyWith(
        chartData: chartData,
        latestData: latestData ?? (chartData.isNotEmpty ? chartData.last : null),
        isLoading: false,
        isPreloaded: true,
        lastUpdateTime: DateTime.now(),
      );
      
      print('🌤️ [WeatherDataNotifier] Refresh completed successfully');
    } catch (e) {
      print('❌ [WeatherDataNotifier] Refresh failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update data in background (silent refresh) - same as _backgroundRefresh
  Future<void> updateDataInBackground() async {
    await _backgroundRefresh();
  }
}
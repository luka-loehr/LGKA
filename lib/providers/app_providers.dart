// Copyright Luka Löhr 2025

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/preferences_manager.dart';
import '../data/pdf_repository.dart';

import '../services/weather_service.dart';
import '../services/offline_cache_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

// Weather Data State Provider - manages cached weather data
class WeatherDataState {
  final List<WeatherData> chartData;
  final WeatherData? latestData;
  final bool isLoading;
  final bool isPreloaded;
  final String? error;
  final DateTime? lastUpdateTime;
  final DateTime? cacheTime;
  final bool isOfflineMode;
  final DateTime? offlineDataTime;

  const WeatherDataState({
    this.chartData = const [],
    this.latestData,
    this.isLoading = false,
    this.isPreloaded = false,
    this.error,
    this.lastUpdateTime,
    this.cacheTime,
    this.isOfflineMode = false,
    this.offlineDataTime,
  });

  WeatherDataState copyWith({
    List<WeatherData>? chartData,
    WeatherData? latestData,
    bool? isLoading,
    bool? isPreloaded,
    String? error,
    DateTime? lastUpdateTime,
    DateTime? cacheTime,
    bool? isOfflineMode,
    DateTime? offlineDataTime,
  }) {
    return WeatherDataState(
      chartData: chartData ?? this.chartData,
      latestData: latestData ?? this.latestData,
      isLoading: isLoading ?? this.isLoading,
      isPreloaded: isPreloaded ?? this.isPreloaded,
      error: error ?? this.error,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      cacheTime: cacheTime ?? this.cacheTime,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      offlineDataTime: offlineDataTime ?? this.offlineDataTime,
    );
  }
}

// Weather Data Provider
final weatherDataProvider = StateNotifierProvider<WeatherDataNotifier, WeatherDataState>((ref) {
  return WeatherDataNotifier(ref.read(weatherServiceProvider));
});

class WeatherDataNotifier extends StateNotifier<WeatherDataState> {
  final WeatherService _weatherService;
  Timer? _retryTimer;

  WeatherDataNotifier(this._weatherService) : super(const WeatherDataState());

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  /// Check if device has internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      print('❌ [WeatherDataNotifier] Error checking connectivity: $e');
      return false;
    }
  }

  /// Start retry timer that checks every 5 seconds for connection
  void _startRetryTimer() {
    _retryTimer?.cancel();
    print('🔄 [WeatherDataNotifier] Starting retry timer (5 second intervals)');
    
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!state.isOfflineMode) {
        timer.cancel();
        return;
      }
      
      print('🔄 [WeatherDataNotifier] Checking for internet connection...');
      final hasConnection = await hasInternetConnection();
      
      if (hasConnection) {
        print('✅ [WeatherDataNotifier] Connection restored, attempting to refresh data');
        timer.cancel();
        await refreshWeatherData();
      }
    });
  }

  /// Stop retry timer
  void _stopRetryTimer() {
    _retryTimer?.cancel();
    print('⏹️ [WeatherDataNotifier] Retry timer stopped');
  }

  /// Load weather data from offline cache
  Future<bool> _loadFromOfflineCache() async {
    try {
      print('💾 [WeatherDataNotifier] Attempting to load from offline cache');
      
      final offlineData = await OfflineCache.getWeatherData();
      final offlineTime = await OfflineCache.getWeatherLastUpdateTime();
      
      if (offlineData != null && offlineData.isNotEmpty) {
        final downsampledData = _weatherService.downsampleForChart(offlineData);
        state = state.copyWith(
          chartData: downsampledData,
          latestData: offlineData.isNotEmpty ? offlineData.last : null,
          isLoading: false,
          isOfflineMode: true,
          offlineDataTime: offlineTime,
          error: null,
        );
        
        // Start retry timer
        _startRetryTimer();
        
        print('💾 [WeatherDataNotifier] Loaded ${offlineData.length} items from offline cache');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ [WeatherDataNotifier] Error loading from offline cache: $e');
      return false;
    }
  }

  /// Preload weather data using fresh-first strategy
  /// Online: Show loading → download fresh → display fresh
  /// Offline: Immediately show cached + offline notification
  Future<void> preloadWeatherData() async {
    if (state.isPreloaded && state.chartData.isNotEmpty) {
      print('🌤️ [WeatherDataNotifier] Data already preloaded, skipping');
      return;
    }

    print('🌤️ [WeatherDataNotifier] Starting weather data preload');

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check internet connection first
      final hasConnection = await hasInternetConnection();

      if (!hasConnection) {
        print('📱 [WeatherDataNotifier] OFFLINE MODE: Loading cached weather data');
        final success = await _loadFromOfflineCache();
        if (success) {
          return;
        } else {
          print('❌ [WeatherDataNotifier] No offline data available');
          state = state.copyWith(
            isLoading: false,
            error: 'Keine Internetverbindung und keine Offline-Daten verfügbar',
          );
          return;
        }
      }

      // ONLINE MODE: Fresh-first strategy
      print('🌐 [WeatherDataNotifier] ONLINE MODE: Loading fresh weather data');

      // Always fetch fresh data when online (force network to bypass 10-minute cache)
      final chartDataFuture = _weatherService.fetchWeatherData(forceNetwork: true);
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
        isOfflineMode: false,
        lastUpdateTime: DateTime.now(),
      );

      _stopRetryTimer(); // Stop retry timer if we have fresh data
      print('✅ [WeatherDataNotifier] Fresh weather data loaded successfully (${fullData.length} points, ${downsampledData.length} for chart)');
    } catch (e) {
      print('❌ [WeatherDataNotifier] Preload failed: $e');

      // Try offline cache as fallback
      final success = await _loadFromOfflineCache();
      if (!success) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  /// Refresh weather data (called from weather page)
  /// Always forces fresh network fetch to ensure latest data
  Future<void> refreshWeatherData() async {
    print('🌤️ [WeatherDataNotifier] Starting weather data refresh');

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Always force network fetch for refresh to bypass 10-minute cache
      final chartDataFuture = _weatherService.fetchWeatherData(forceNetwork: true);
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
        isOfflineMode: false, // Exit offline mode on successful refresh
        offlineDataTime: null,
        lastUpdateTime: DateTime.now(),
      );

      _stopRetryTimer(); // Stop retry timer if refresh was successful
      print('✅ [WeatherDataNotifier] Fresh weather data refresh completed (${fullData.length} points, ${downsampledData.length} for chart)');
    } catch (e) {
      print('❌ [WeatherDataNotifier] Refresh failed: $e');

      // If we're not in offline mode yet, try to load from offline cache
      if (!state.isOfflineMode) {
        final success = await _loadFromOfflineCache();
        if (!success) {
          state = state.copyWith(
            isLoading: false,
            error: e.toString(),
          );
        }
      } else {
        // If already in offline mode, just update loading state
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Update data in background (silent refresh)
  /// Forces fresh network fetch for background updates
  Future<void> updateDataInBackground() async {
    print('🌤️ [WeatherDataNotifier] Starting background update');

    try {
      // Force network fetch for background updates to ensure fresh data
      final chartDataFuture = _weatherService.fetchWeatherData(forceNetwork: true);
      final latestDataFuture = _weatherService.getLatestWeatherData();

      final results = await Future.wait([chartDataFuture, latestDataFuture]);
      final fullData = results[0] as List<WeatherData>;
      final latestData = results[1] as WeatherData?;

      if (fullData.isNotEmpty) {
        final downsampledData = _weatherService.downsampleForChart(fullData);
        state = state.copyWith(
          chartData: downsampledData,
          latestData: latestData ?? fullData.last,
          isOfflineMode: false, // Exit offline mode on successful background update
          offlineDataTime: null,
          lastUpdateTime: DateTime.now(),
        );
        _stopRetryTimer(); // Stop retry timer if background update was successful
        print('✅ [WeatherDataNotifier] Fresh background update completed (${fullData.length} points, ${downsampledData.length} for chart)');
      }
    } catch (e) {
      print('❌ [WeatherDataNotifier] Background update failed: $e');
      // Don't update error state for background updates to avoid disrupting UI
    }
  }
}
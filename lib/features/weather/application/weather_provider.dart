// Copyright Luka Löhr 2026

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../utils/app_logger.dart';
import '../domain/weather_models.dart';
import '../data/weather_service.dart';

class WeatherDataState {
  final CurrentWeather? current;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;
  final bool isLoading;
  final bool hasError;
  final DateTime? lastUpdateTime;

  const WeatherDataState({
    this.current,
    this.hourly = const [],
    this.daily = const [],
    this.isLoading = false,
    this.hasError = false,
    this.lastUpdateTime,
  });

  WeatherDataState copyWith({
    CurrentWeather? current,
    List<HourlyForecast>? hourly,
    List<DailyForecast>? daily,
    bool? isLoading,
    bool? hasError,
    DateTime? lastUpdateTime,
  }) {
    return WeatherDataState(
      current: current ?? this.current,
      hourly: hourly ?? this.hourly,
      daily: daily ?? this.daily,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    );
  }
}

final weatherDataProvider =
    NotifierProvider<WeatherDataNotifier, WeatherDataState>(
        WeatherDataNotifier.new);

class WeatherDataNotifier extends Notifier<WeatherDataState> {
  @override
  WeatherDataState build() => const WeatherDataState();

  Future<void> preloadWeatherData() async {
    // If service cache is still hot, hydrate state without a network call
    if (WeatherService.instance.hasValidCache) {
      final r = WeatherService.instance.cachedResult!;
      state = WeatherDataState(
        current: r.current,
        hourly: r.hourly,
        daily: r.daily,
        lastUpdateTime: WeatherService.instance.lastUpdateTime,
      );
      return;
    }

    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, hasError: false);

    try {
      final r = await WeatherService.instance.fetchAll();
      state = WeatherDataState(
        current: r.current,
        hourly: r.hourly,
        daily: r.daily,
        lastUpdateTime: WeatherService.instance.lastUpdateTime,
      );
    } catch (e) {
      AppLogger.error('Failed to preload weather', error: e, module: 'WeatherProvider');
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }

  /// Silent background refresh — keeps current data visible.
  Future<void> updateDataInBackground() async {
    WeatherService.instance.invalidateCache();
    try {
      final r = await WeatherService.instance.fetchAll();
      state = WeatherDataState(
        current: r.current,
        hourly: r.hourly,
        daily: r.daily,
        lastUpdateTime: WeatherService.instance.lastUpdateTime,
      );
      AppLogger.success('Background weather refresh done', module: 'WeatherProvider');
    } catch (e) {
      AppLogger.error('Background weather refresh failed', error: e, module: 'WeatherProvider');
      // Keep existing data — silent failure
    }
  }

  /// User-triggered full refresh (shows loading spinner).
  Future<void> refreshWeatherData() async {
    WeatherService.instance.invalidateCache();
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      final r = await WeatherService.instance.fetchAll();
      state = WeatherDataState(
        current: r.current,
        hourly: r.hourly,
        daily: r.daily,
        lastUpdateTime: WeatherService.instance.lastUpdateTime,
      );
    } catch (e) {
      AppLogger.error('Weather refresh failed', error: e, module: 'WeatherProvider');
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }
}

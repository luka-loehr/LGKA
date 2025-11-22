// Copyright Luka Löhr 2025

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';


/// Centralized service for retrying all data sources
class RetryService {
  final Ref _ref;

  RetryService(this._ref);

  /// Retry all data sources simultaneously
  /// This method just triggers the retries and doesn't wait for results
  void retryAllDataSources() {
    try {
      // Retry weather data - fire and forget
      _ref.read(weatherDataProvider.notifier).refreshWeatherData();
    } catch (e) {
      // Silently ignore any errors - don't crash the retry service
    }
    
    try {
      // Retry PDF substitution plans - fire and forget
      final pdfRepo = _ref.read(pdfRepositoryProvider);
      pdfRepo.retryAll();
    } catch (e) {
      // Silently ignore any errors - don't crash the retry service
    }
    
    try {
      // Retry schedule data - fire and forget
      _ref.read(scheduleProvider.notifier).refreshSchedules();
    } catch (e) {
      // Silently ignore any errors - don't crash the retry service
    }
  }

  /// Retry only weather data
  void retryWeatherData() {
    try {
      _ref.read(weatherDataProvider.notifier).refreshWeatherData();
    } catch (e) {
      // Silently ignore any errors - don't crash the retry service
    }
  }

  /// Retry only PDF substitution plans
  void retryPdfData() {
    try {
      final pdfRepo = _ref.read(pdfRepositoryProvider);
      pdfRepo.retryAll();
    } catch (e) {
      // Silently ignore any errors - don't crash the retry service
    }
  }

  /// Retry only schedule data
  void retryScheduleData() {
    try {
      _ref.read(scheduleProvider.notifier).refreshSchedules();
    } catch (e) {
      // Silently ignore any errors - don't crash the retry service
    }
  }
}

/// Provider for the retry service
final retryServiceProvider = Provider<RetryService>((ref) {
  return RetryService(ref);
});

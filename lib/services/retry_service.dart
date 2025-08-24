// Copyright Luka Löhr 2025

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../data/pdf_repository.dart';
import '../providers/schedule_provider.dart';

/// Centralized service for retrying all data sources
class RetryService {
  final Ref _ref;

  RetryService(this._ref);

  /// Retry all data sources simultaneously
  Future<void> retryAllDataSources() async {
    // Trigger all retries in parallel without waiting for results
    // This ensures the user doesn't have to wait for each one to complete
    
    // Retry weather data
    _ref.read(weatherDataProvider.notifier).refreshWeatherData();
    
    // Retry PDF substitution plans
    final pdfRepo = _ref.read(pdfRepositoryProvider);
    pdfRepo.retryAll();
    
    // Retry schedule data
    _ref.read(scheduleProvider.notifier).refreshSchedules();
  }

  /// Retry only weather data
  Future<void> retryWeatherData() async {
    _ref.read(weatherDataProvider.notifier).refreshWeatherData();
  }

  /// Retry only PDF substitution plans
  Future<void> retryPdfData() async {
    final pdfRepo = _ref.read(pdfRepositoryProvider);
    pdfRepo.retryAll();
  }

  /// Retry only schedule data
  Future<void> retryScheduleData() async {
    _ref.read(scheduleProvider.notifier).refreshSchedules();
  }
}

/// Provider for the retry service
final retryServiceProvider = Provider<RetryService>((ref) {
  return RetryService(ref);
});

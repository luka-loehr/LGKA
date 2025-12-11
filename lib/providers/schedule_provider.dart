// Copyright Luka Löhr 2025

import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/schedule_service.dart';
import '../utils/app_logger.dart';
import 'app_providers.dart';

/// State class for schedule data
class ScheduleState {
  final List<ScheduleItem> schedules;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const ScheduleState({
    this.schedules = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  ScheduleState copyWith({
    List<ScheduleItem>? schedules,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? lastUpdated,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Check if there are any schedules available
  bool get hasSchedules => schedules.isNotEmpty;
  
  /// Check if there's an error
  bool get hasError => error != null;
  
  /// Get schedules by halbjahr
  List<ScheduleItem> getSchedulesByHalbjahr(String halbjahr) {
    return schedules.where((s) => s.halbjahr == halbjahr).toList();
  }
  
  /// Get first halbjahr schedules
  List<ScheduleItem> get firstHalbjahrSchedules => getSchedulesByHalbjahr('1. Halbjahr');
  
  /// Get second halbjahr schedules
  List<ScheduleItem> get secondHalbjahrSchedules => getSchedulesByHalbjahr('2. Halbjahr');
}

/// Notifier for managing schedule state
class ScheduleNotifier extends Notifier<ScheduleState> {
  ScheduleService get _scheduleService => ref.read(scheduleServiceProvider);

  @override
  ScheduleState build() => const ScheduleState();

  /// Load schedules from the web or cache
  Future<void> loadSchedules({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;

    final cachedSchedules = _scheduleService.cachedSchedules;
    final lastFetchTime = _scheduleService.lastFetchTime;

    if (!forceRefresh && cachedSchedules != null) {
      state = state.copyWith(
        schedules: cachedSchedules,
        isLoading: false,
        clearError: true,
        lastUpdated: lastFetchTime ?? state.lastUpdated,
      );

      if (_scheduleService.hasValidCache) {
        return;
      }

      unawaited(_refreshSchedulesSilently());
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final schedules = await _scheduleService.getSchedules(forceRefresh: true);

      if (schedules.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Serververbindung fehlgeschlagen',
        );
        return;
      }

      state = state.copyWith(
        schedules: schedules,
        isLoading: false,
        clearError: true,
        lastUpdated: _scheduleService.lastFetchTime ?? DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Serververbindung fehlgeschlagen',
      );
    }
  }

  /// Refresh schedules (force reload)
  Future<void> refreshSchedules() async {
    await loadSchedules(forceRefresh: true);
  }

  Future<void> _refreshSchedulesSilently() async {
    await _scheduleService.refreshInBackground();
    final updatedSchedules = _scheduleService.cachedSchedules;
    if (updatedSchedules != null) {
      state = state.copyWith(
        schedules: updatedSchedules,
        isLoading: false,
        clearError: true,
        lastUpdated: _scheduleService.lastFetchTime ?? DateTime.now(),
      );
    }
  }

  Future<void> refreshInBackground() async {
    await _refreshSchedulesSilently();
  }

  /// Download a specific schedule PDF
  Future<File?> downloadSchedule(ScheduleItem schedule) async {
    try {
      AppLogger.schedule('Downloading schedule PDF: ${schedule.title}');
      final result = await _scheduleService.downloadSchedule(schedule);

      // If result is null, the PDF is not available yet (404 error)
      if (result == null) {
        AppLogger.warning('Schedule PDF not available: ${schedule.title}', module: 'ScheduleProvider');
        return null;
      }

      AppLogger.success('Schedule PDF downloaded: ${schedule.title}', module: 'ScheduleProvider');
      return result;
    } catch (e) {
      AppLogger.error('Failed to download schedule PDF', module: 'ScheduleProvider', error: e);
      state = state.copyWith(
        error: 'Serververbindung fehlgeschlagen',
      );
      return null;
    }
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }
  /// Check if a schedule PDF is available and valid (>1000 bytes)
  Future<bool> isScheduleAvailable(ScheduleItem schedule) async {
    try {
      return await _scheduleService.isScheduleAvailable(schedule);
    } catch (e) {
      return false; // If check fails, assume not available
    }
  }
  
  /// Get available schedules (those with valid PDFs)
  Future<List<ScheduleItem>> getAvailableSchedules() async {
    final availableSchedules = <ScheduleItem>[];
    
    for (final schedule in state.schedules) {
      if (await isScheduleAvailable(schedule)) {
        availableSchedules.add(schedule);
      }
    }
    
    return availableSchedules;
  }
}

/// Provider for schedule state
final scheduleProvider = NotifierProvider<ScheduleNotifier, ScheduleState>(ScheduleNotifier.new); 
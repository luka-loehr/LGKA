// Copyright Luka Löhr 2025

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/schedule_service.dart';

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
    DateTime? lastUpdated,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
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
class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final ScheduleService _scheduleService;

  ScheduleNotifier(this._scheduleService) : super(const ScheduleState());

  /// Load schedules from the web
  Future<void> loadSchedules() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final schedules = await _scheduleService.getSchedules();
      
      // Check if we got any schedules
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
        lastUpdated: DateTime.now(),
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
    _scheduleService.clearCache();
    await loadSchedules();
  }

  /// Download a specific schedule PDF
  Future<File?> downloadSchedule(ScheduleItem schedule) async {
    try {
      return await _scheduleService.downloadSchedule(schedule);
    } catch (e) {
      // Update error state
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
}

/// Provider for schedule service
final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService();
});

/// Provider for schedule state
final scheduleProvider = StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  final scheduleService = ref.watch(scheduleServiceProvider);
  return ScheduleNotifier(scheduleService);
}); 
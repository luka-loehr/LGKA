// Copyright Luka Löhr 2025

import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import '../services/schedule_service.dart';
import '../utils/app_logger.dart';
import '../services/haptic_service.dart';
import 'app_providers.dart';

/// State class for schedule data
class ScheduleState {
  final List<ScheduleItem> schedules;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  final Set<String> classIndex5to10; // Index of all valid classes for 5-10 schedule
  final bool isIndexBuilt;

  const ScheduleState({
    this.schedules = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
    this.classIndex5to10 = const {},
    this.isIndexBuilt = false,
  });

  ScheduleState copyWith({
    List<ScheduleItem>? schedules,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? lastUpdated,
    Set<String>? classIndex5to10,
    bool? isIndexBuilt,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      classIndex5to10: classIndex5to10 ?? this.classIndex5to10,
      isIndexBuilt: isIndexBuilt ?? this.isIndexBuilt,
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
        
        // Trigger medium haptic feedback on initial load failure
        if (!forceRefresh) {
          HapticService.medium();
        }
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
      
      // Trigger medium haptic feedback on failure (both initial load and retry)
      HapticService.medium();
    }
  }

  /// Refresh schedules (force reload)
  Future<void> refreshSchedules() async {
    await loadSchedules(forceRefresh: true);
  }

  Future<void> _refreshSchedulesSilently() async {
    AppLogger.info('Background refresh: Schedules', module: 'ScheduleProvider');
    final wasCacheValid = _scheduleService.hasValidCache;
    await _scheduleService.refreshInBackground();
    final updatedSchedules = _scheduleService.cachedSchedules;
    
    if (updatedSchedules != null) {
      state = state.copyWith(
        schedules: updatedSchedules,
        isLoading: false,
        clearError: true,
        lastUpdated: _scheduleService.lastFetchTime ?? DateTime.now(),
      );
      AppLogger.success('Background refresh complete: Schedules', module: 'ScheduleProvider');
    } else if (!wasCacheValid) {
      // Cache was invalid and refresh failed - clear data and show error
      AppLogger.info('Refresh failed with invalid cache - showing error for schedules', module: 'ScheduleProvider');
      state = state.copyWith(
        schedules: const [],
        isLoading: false,
        error: 'Serververbindung fehlgeschlagen',
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
  
  /// Build class index from a 5-10 schedule PDF file
  /// Searches for classes 5a-5e, 6a-6e, ... up to 10a-10e
  Future<void> buildClassIndex(File pdfFile) async {
    if (state.isIndexBuilt) return; // Already built
    
    try {
      AppLogger.info('Building class index from PDF...', module: 'ScheduleProvider');
      final stopwatch = Stopwatch()..start();
      
      final bytes = await pdfFile.readAsBytes();
      final document = syncfusion.PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      
      final textExtractor = syncfusion.PdfTextExtractor(document);
      final allText = textExtractor.extractText(
        startPageIndex: 0,
        endPageIndex: pageCount - 1,
      ).toLowerCase();
      
      document.dispose();
      
      final foundClasses = <String>{};
      
      // Search for classes: 5a-5e, 6a-6e, ... 10a-10e
      for (int grade = 5; grade <= 10; grade++) {
        for (final letter in ['a', 'b', 'c', 'd', 'e']) {
          final className = '$grade$letter';
          if (allText.contains(className)) {
            foundClasses.add(className);
          } else {
            // If this letter not found, skip to next grade
            break;
          }
        }
      }
      
      stopwatch.stop();
      AppLogger.success(
        'Class index built: ${foundClasses.length} classes found in ${stopwatch.elapsedMilliseconds}ms',
        module: 'ScheduleProvider',
      );
      // Sort classes by grade (5-10) then letter (a-e)
      final sortedClasses = foundClasses.toList()..sort((a, b) {
        final gradeA = int.tryParse(a.replaceAll(RegExp(r'[a-z]'), '')) ?? 0;
        final gradeB = int.tryParse(b.replaceAll(RegExp(r'[a-z]'), '')) ?? 0;
        if (gradeA != gradeB) return gradeA.compareTo(gradeB);
        return a.compareTo(b);
      });
      AppLogger.debug('Classes: $sortedClasses', module: 'ScheduleProvider');
      
      state = state.copyWith(
        classIndex5to10: foundClasses,
        isIndexBuilt: true,
      );
    } catch (e) {
      AppLogger.error('Failed to build class index', module: 'ScheduleProvider', error: e);
      // Don't fail - just mark as built with empty index (will fall back to PDF search)
      state = state.copyWith(isIndexBuilt: true);
    }
  }
  
  /// Check if a class exists in the index (instant check, no PDF parsing)
  bool isClassInIndex(String className) {
    if (!state.isIndexBuilt) return true; // If index not built, assume valid
    return state.classIndex5to10.contains(className.toLowerCase());
  }
}

/// Provider for schedule state
final scheduleProvider = NotifierProvider<ScheduleNotifier, ScheduleState>(ScheduleNotifier.new); 
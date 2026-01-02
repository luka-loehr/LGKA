// Copyright Luka Löhr 2025

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import '../services/schedule_service.dart';
import '../utils/app_logger.dart';
import '../services/haptic_service.dart';
import 'app_providers.dart';

/// Top-level function for building class index in background isolate
/// This must be a top-level function to work with compute()
Future<Map<String, int>> _buildClassIndexInIsolate(String pdfPath) async {
  try {
    final file = File(pdfPath);
    final bytes = await file.readAsBytes();
    final document = syncfusion.PdfDocument(inputBytes: bytes);
    final pageCount = document.pages.count;
    
    final classToPage = <String, int>{};
    
    // Build list of classes to search for
    final classesToFind = <String>[];
    for (int grade = 5; grade <= 10; grade++) {
      for (final letter in ['a', 'b', 'c', 'd', 'e']) {
        classesToFind.add('$grade$letter');
      }
    }
    
    // Search each page and record which classes are found on which page
    final textExtractor = syncfusion.PdfTextExtractor(document);
    for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
      try {
        final pageText = textExtractor.extractText(
          startPageIndex: pageIndex,
          endPageIndex: pageIndex,
        ).toLowerCase();
        
        for (final className in classesToFind) {
          // Only record first occurrence (don't overwrite if already found)
          if (!classToPage.containsKey(className) && pageText.contains(className)) {
            // Page numbers are 1-based, but PDF uses offset so +2 for display
            classToPage[className] = pageIndex + 2;
          }
        }
      } catch (e) {
        // Skip pages with extraction errors
        continue;
      }
    }
    
    document.dispose();
    return classToPage;
  } catch (e) {
    // Return empty map on error
    return {};
  }
}

/// State class for schedule data
class ScheduleState {
  final List<ScheduleItem> schedules;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  final Map<String, int> classIndex5to10; // Maps class name -> page number (1-based)
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
    Map<String, int>? classIndex5to10,
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
  /// Searches for classes 5a-5e, 6a-6e, ... up to 10a-10e and maps them to page numbers
  /// Runs in a background isolate to avoid blocking the main thread
  Future<void> buildClassIndex(File pdfFile) async {
    if (state.isIndexBuilt) return; // Already built
    
    try {
      AppLogger.info('Building class index from PDF in background isolate...', module: 'ScheduleProvider');
      final stopwatch = Stopwatch()..start();
      
      // Run the heavy PDF processing in a background isolate
      final classToPage = await compute(_buildClassIndexInIsolate, pdfFile.path);
      
      stopwatch.stop();
      AppLogger.success(
        'Class index built: ${classToPage.length} classes found in ${stopwatch.elapsedMilliseconds}ms',
        module: 'ScheduleProvider',
      );
      
      // Sort and log classes by grade (5-10) then letter (a-e)
      final sortedEntries = classToPage.entries.toList()..sort((a, b) {
        final gradeA = int.tryParse(a.key.replaceAll(RegExp(r'[a-z]'), '')) ?? 0;
        final gradeB = int.tryParse(b.key.replaceAll(RegExp(r'[a-z]'), '')) ?? 0;
        if (gradeA != gradeB) return gradeA.compareTo(gradeB);
        return a.key.compareTo(b.key);
      });
      AppLogger.debug('Classes: ${sortedEntries.map((e) => "${e.key}:p${e.value}").join(", ")}', module: 'ScheduleProvider');
      
      state = state.copyWith(
        classIndex5to10: classToPage,
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
    return state.classIndex5to10.containsKey(className.toLowerCase());
  }
  
  /// Get the page number for a class (1-based), or null if not found
  int? getClassPage(String className) {
    return state.classIndex5to10[className.toLowerCase()];
  }
  
  /// Invalidate the class index (called on app resume to force rebuild)
  void invalidateClassIndex() {
    state = state.copyWith(
      classIndex5to10: {},
      isIndexBuilt: false,
    );
    AppLogger.debug('Class index invalidated', module: 'ScheduleProvider');
  }
  
  /// Preload the class index by finding, downloading, and indexing the 5-10 schedule
  Future<void> preloadClassIndex() async {
    if (state.isIndexBuilt) return; // Already built
    
    try {
      // Find the 5-10 schedule from available schedules
      final schedules = state.schedules;
      if (schedules.isEmpty) {
        AppLogger.debug('No schedules loaded yet, skipping class index preload', module: 'ScheduleProvider');
        return;
      }
      
      // Find a 5-10 schedule (prefer first halbjahr, then second)
      ScheduleItem? schedule5to10;
      for (final schedule in schedules) {
        if (schedule.gradeLevel == 'Klassen 5-10') {
          // Check availability
          if (await isScheduleAvailable(schedule)) {
            schedule5to10 = schedule;
            break;
          }
        }
      }
      
      if (schedule5to10 == null) {
        AppLogger.debug('No available 5-10 schedule found for indexing', module: 'ScheduleProvider');
        return;
      }
      
      // Download the PDF
      AppLogger.info('Downloading 5-10 schedule for class index...', module: 'ScheduleProvider');
      final pdfFile = await _scheduleService.downloadSchedule(schedule5to10);
      
      if (pdfFile == null) {
        AppLogger.error('Failed to download 5-10 schedule for indexing', module: 'ScheduleProvider');
        return;
      }
      
      // Build the index
      await buildClassIndex(pdfFile);
    } catch (e) {
      AppLogger.error('Failed to preload class index', module: 'ScheduleProvider', error: e);
    }
  }
  
  /// Silently rebuild the class index in the background (app resume scenario)
  /// This method is designed to be non-intrusive and won't trigger loading states
  Future<void> rebuildClassIndexSilently() async {
    if (state.isIndexBuilt) {
      AppLogger.debug('Class index already built, skipping silent rebuild', module: 'ScheduleProvider');
      return;
    }
    
    try {
      AppLogger.info('Silent rebuild: Starting class index rebuild in background', module: 'ScheduleProvider');
      
      // Find the 5-10 schedule from available schedules
      final schedules = state.schedules;
      if (schedules.isEmpty) {
        AppLogger.debug('Silent rebuild: No schedules available, skipping', module: 'ScheduleProvider');
        return;
      }
      
      // Find a 5-10 schedule (prefer first halbjahr, then second)
      ScheduleItem? schedule5to10;
      for (final schedule in schedules) {
        if (schedule.gradeLevel == 'Klassen 5-10') {
          schedule5to10 = schedule;
          break;
        }
      }
      
      if (schedule5to10 == null) {
        AppLogger.debug('Silent rebuild: No 5-10 schedule found', module: 'ScheduleProvider');
        return;
      }
      
      // Try to use cached PDF or download silently (no loading state changes)
      final pdfFile = await _scheduleService.downloadSchedule(schedule5to10);
      
      if (pdfFile == null) {
        AppLogger.debug('Silent rebuild: PDF not available, will retry later', module: 'ScheduleProvider');
        return;
      }
      
      // Build the index in background isolate
      await buildClassIndex(pdfFile);
      AppLogger.success('Silent rebuild: Class index rebuilt successfully', module: 'ScheduleProvider');
    } catch (e) {
      // Fail silently - don't disrupt user experience
      AppLogger.debug('Silent rebuild: Failed quietly ($e), will retry on next app resume', module: 'ScheduleProvider');
    }
  }
}

/// Provider for schedule state
final scheduleProvider = NotifierProvider<ScheduleNotifier, ScheduleState>(ScheduleNotifier.new); 
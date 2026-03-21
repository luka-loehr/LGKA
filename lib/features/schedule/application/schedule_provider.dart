// Copyright Luka Löhr 2026

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import '../domain/schedule_models.dart';
import '../data/schedule_service.dart';
import '../../../../utils/app_logger.dart';
import '../../../../services/haptic_service.dart';

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


/// How long between automatic availability re-checks.
const Duration kScheduleAvailabilityCheckInterval = Duration(minutes: 15);

/// State class for schedule data
class ScheduleState {
  final List<ScheduleItem> schedules;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  final Map<String, int> classIndex5to10;  // Maps 5a-10e → page number in 5-10 PDF
  final Map<String, int> classIndexJ11J12; // Maps j11/j12 → page number in J11/J12 PDF
  final bool isIndexBuilt;

  // Availability — which PDFs are reachable/cached right now
  final List<ScheduleItem> availableFirstHalbjahr;
  final List<ScheduleItem> availableSecondHalbjahr;
  final bool isCheckingAvailability;
  final DateTime? lastAvailabilityCheck;

  const ScheduleState({
    this.schedules = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
    this.classIndex5to10 = const {},
    this.classIndexJ11J12 = const {},
    this.isIndexBuilt = false,
    this.availableFirstHalbjahr = const [],
    this.availableSecondHalbjahr = const [],
    this.isCheckingAvailability = false,
    this.lastAvailabilityCheck,
  });

  ScheduleState copyWith({
    List<ScheduleItem>? schedules,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? lastUpdated,
    Map<String, int>? classIndex5to10,
    Map<String, int>? classIndexJ11J12,
    bool? isIndexBuilt,
    List<ScheduleItem>? availableFirstHalbjahr,
    List<ScheduleItem>? availableSecondHalbjahr,
    bool? isCheckingAvailability,
    DateTime? lastAvailabilityCheck,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      classIndex5to10: classIndex5to10 ?? this.classIndex5to10,
      classIndexJ11J12: classIndexJ11J12 ?? this.classIndexJ11J12,
      isIndexBuilt: isIndexBuilt ?? this.isIndexBuilt,
      availableFirstHalbjahr: availableFirstHalbjahr ?? this.availableFirstHalbjahr,
      availableSecondHalbjahr: availableSecondHalbjahr ?? this.availableSecondHalbjahr,
      isCheckingAvailability: isCheckingAvailability ?? this.isCheckingAvailability,
      lastAvailabilityCheck: lastAvailabilityCheck ?? this.lastAvailabilityCheck,
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
  List<ScheduleItem> get firstHalbjahrSchedules =>
      getSchedulesByHalbjahr('1. Halbjahr');

  /// Get second halbjahr schedules
  List<ScheduleItem> get secondHalbjahrSchedules =>
      getSchedulesByHalbjahr('2. Halbjahr');

  /// Returns true when availability should be re-checked.
  ///
  /// Mirrors the original per-screen logic (including its operator-precedence
  /// quirk) so behaviour is preserved exactly.
  bool get shouldCheckAvailability {
    // ignore: dead_code — intentional: mirrors original precedence quirk
    if (lastAvailabilityCheck != null &&
            availableFirstHalbjahr.isNotEmpty ||
        availableSecondHalbjahr.isNotEmpty) {
      final elapsed =
          DateTime.now().difference(lastAvailabilityCheck ?? DateTime.now());
      if (elapsed < kScheduleAvailabilityCheckInterval) return false;
    }
    return true;
  }
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
      // Deduplicate cached schedules
      final uniqueSchedules = cachedSchedules.toSet().toList();
      
      state = state.copyWith(
        schedules: uniqueSchedules,
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

      // Deduplicate schedules by converting to Set and back to List
      final uniqueSchedules = schedules.toSet().toList();

      state = state.copyWith(
        schedules: uniqueSchedules,
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
      // Deduplicate schedules
      final uniqueSchedules = updatedSchedules.toSet().toList();
      
      state = state.copyWith(
        schedules: uniqueSchedules,
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
  
  // ── Availability ────────────────────────────────────────────────────────────

  /// Check which schedule PDFs are reachable/cached and store the result in
  /// state.  Safe to call concurrently — early-returns if already running.
  Future<void> checkAvailability() async {
    if (state.isCheckingAvailability) return;

    state = state.copyWith(isCheckingAvailability: true);

    try {
      final allSchedules = {
        ...state.firstHalbjahrSchedules,
        ...state.secondHalbjahrSchedules,
      }.toList();

      final results = await Future.wait(allSchedules.map((s) async {
        final ok = await isScheduleAvailable(s);
        return {'schedule': s, 'ok': ok};
      }));

      final first = <ScheduleItem>{};
      final second = <ScheduleItem>{};
      for (final r in results) {
        if (r['ok'] as bool) {
          final s = r['schedule'] as ScheduleItem;
          if (s.halbjahr == '1. Halbjahr') first.add(s);
          if (s.halbjahr == '2. Halbjahr') second.add(s);
        }
      }

      AppLogger.success(
        'Schedule availability: ${first.length + second.length} available',
        module: 'ScheduleProvider',
      );

      state = state.copyWith(
        availableFirstHalbjahr: first.toList(),
        availableSecondHalbjahr: second.toList(),
        isCheckingAvailability: false,
        lastAvailabilityCheck: DateTime.now(),
      );

      // Preload PDFs for available schedules in the background
      preloadAvailableSchedulePDFs();
    } catch (_) {
      state = state.copyWith(
        isCheckingAvailability: false,
        lastAvailabilityCheck: DateTime.now(),
      );
    }
  }

  /// Restore which schedules are available from the local PDF cache
  /// (used when availability was recently checked and re-check isn't needed).
  Future<void> restoreAvailabilityFromCache() async {
    final all = {
      ...state.firstHalbjahrSchedules,
      ...state.secondHalbjahrSchedules,
    }.toList();

    final first = <ScheduleItem>[];
    final second = <ScheduleItem>[];

    for (final s in all) {
      final cached = await getCachedScheduleFile(s);
      if (cached != null && await cached.exists()) {
        if (s.halbjahr == '1. Halbjahr' &&
            !first.contains(s)) {
          first.add(s);
        } else if (s.halbjahr == '2. Halbjahr' &&
            !second.contains(s)) {
          second.add(s);
        }
      }
    }

    state = state.copyWith(
      availableFirstHalbjahr: first,
      availableSecondHalbjahr: second,
    );
  }

  /// Start background PDF downloads for all currently-available schedules.
  void preloadAvailableSchedulePDFs() {
    final all = [
      ...state.availableFirstHalbjahr,
      ...state.availableSecondHalbjahr,
    ];
    for (final s in all) {
      unawaited(getCachedScheduleFile(s).then((cached) async {
        if (cached != null && await cached.exists()) return;
        try {
          await _scheduleService.downloadSchedule(s);
        } catch (_) {}
      }));
    }
  }

  /// Returns the [File] where [schedule]'s PDF is (or would be) cached.
  Future<File?> getCachedScheduleFile(ScheduleItem schedule) async {
    try {
      final dir = await getTemporaryDirectory();
      final grade = schedule.gradeLevel.replaceAll('/', '_');
      final half = schedule.halbjahr.replaceAll('.', '_');
      return File('${dir.path}/${grade}_$half.pdf');
    } catch (_) {
      return null;
    }
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
  
  /// Check if a class exists in either index
  bool isClassInIndex(String className) {
    if (!state.isIndexBuilt) return true; // If index not built, assume valid
    final lc = className.toLowerCase();
    return state.classIndex5to10.containsKey(lc) ||
        state.classIndexJ11J12.containsKey(lc);
  }

  /// Page number for a 5a-10e class in the 5-10 PDF, or null if not found
  int? getClassPage(String className) {
    return state.classIndex5to10[className.toLowerCase()];
  }

  /// Page number for a j11/j12 class in the J11/J12 PDF, or null if not found
  int? getClassPageJ(String className) {
    return state.classIndexJ11J12[className.toLowerCase()];
  }
  
  /// Invalidate the class index (called on app resume to force rebuild)
  void invalidateClassIndex() {
    state = state.copyWith(
      classIndex5to10: {},
      isIndexBuilt: false,
    );
    AppLogger.debug('Class index invalidated', module: 'ScheduleProvider');
  }
  
  /// Preload the class index by scanning both the 5-10 PDF and the J11/J12 PDF.
  /// j11/j12 entries in the index are page numbers within the J11/J12 PDF.
  Future<void> preloadClassIndex() async {
    if (state.isIndexBuilt) return; // Already built

    try {
      final schedules = state.schedules;
      if (schedules.isEmpty) {
        AppLogger.debug('No schedules loaded yet, skipping class index preload', module: 'ScheduleProvider');
        return;
      }

      // Find a 5-10 schedule (prefer 2nd halbjahr, then 1st)
      ScheduleItem? schedule5to10;
      ScheduleItem? scheduleJ11J12;
      for (final schedule in schedules) {
        if (schedule.gradeLevel == 'Klassen 5-10' && schedule5to10 == null) {
          if (await isScheduleAvailable(schedule)) schedule5to10 = schedule;
        }
        if (schedule.gradeLevel == 'J11/J12' && scheduleJ11J12 == null) {
          if (await isScheduleAvailable(schedule)) scheduleJ11J12 = schedule;
        }
      }

      if (schedule5to10 == null) {
        AppLogger.debug('No available 5-10 schedule found for indexing', module: 'ScheduleProvider');
        return;
      }

      // Download and scan the 5-10 PDF for class pages
      AppLogger.info('Downloading 5-10 schedule for class index...', module: 'ScheduleProvider');
      final pdf5to10 = await _scheduleService.downloadSchedule(schedule5to10);
      if (pdf5to10 == null) return;

      final stopwatch = Stopwatch()..start();
      final index5to10 = await compute(_buildClassIndexInIsolate, pdf5to10.path);

      // Download J11/J12 PDF for caching (so it opens instantly later)
      if (scheduleJ11J12 != null) {
        unawaited(_scheduleService.downloadSchedule(scheduleJ11J12!));
      }

      // j11 is always page 1 and j12 is always page 2 of the J11/J12 PDF
      const indexJ11J12 = {'j11': 2, 'j12': 3};

      stopwatch.stop();
      AppLogger.success(
        'Class index built: ${index5to10.length} classes (5-10) + j11/j12 in ${stopwatch.elapsedMilliseconds}ms',
        module: 'ScheduleProvider',
      );

      state = state.copyWith(
        classIndex5to10: index5to10,
        classIndexJ11J12: indexJ11J12,
        isIndexBuilt: true,
      );
    } catch (e) {
      AppLogger.error('Failed to preload class index', module: 'ScheduleProvider', error: e);
      state = state.copyWith(isIndexBuilt: true);
    }
  }

  /// Silently rebuild the class index in the background (app resume scenario)
  Future<void> rebuildClassIndexSilently() async {
    if (state.isIndexBuilt) {
      AppLogger.debug('Class index already built, skipping silent rebuild', module: 'ScheduleProvider');
      return;
    }

    try {
      AppLogger.info('Silent rebuild: Starting class index rebuild in background', module: 'ScheduleProvider');

      final schedules = state.schedules;
      if (schedules.isEmpty) {
        AppLogger.debug('Silent rebuild: No schedules available, skipping', module: 'ScheduleProvider');
        return;
      }

      ScheduleItem? schedule5to10;
      ScheduleItem? scheduleJ11J12;
      for (final schedule in schedules) {
        if (schedule.gradeLevel == 'Klassen 5-10' && schedule5to10 == null) {
          schedule5to10 = schedule;
        } else if (schedule.gradeLevel == 'J11/J12' && scheduleJ11J12 == null) {
          scheduleJ11J12 = schedule;
        }
        if (schedule5to10 != null && scheduleJ11J12 != null) break;
      }

      if (schedule5to10 == null) {
        AppLogger.debug('Silent rebuild: No 5-10 schedule found', module: 'ScheduleProvider');
        return;
      }

      final pdf5to10 = await _scheduleService.downloadSchedule(schedule5to10);
      if (pdf5to10 == null) return;

      final index5to10 = await compute(_buildClassIndexInIsolate, pdf5to10.path);

      if (scheduleJ11J12 != null) {
        unawaited(_scheduleService.downloadSchedule(scheduleJ11J12!));
      }

      state = state.copyWith(
        classIndex5to10: index5to10,
        classIndexJ11J12: const {'j11': 2, 'j12': 3},
        isIndexBuilt: true,
      );
      AppLogger.success('Silent rebuild: Class index rebuilt successfully', module: 'ScheduleProvider');
    } catch (e) {
      AppLogger.debug('Silent rebuild: Failed quietly ($e), will retry on next app resume', module: 'ScheduleProvider');
    }
  }
}

/// Provider for schedule state
final scheduleProvider = NotifierProvider<ScheduleNotifier, ScheduleState>(ScheduleNotifier.new);

/// Provider for the shared [ScheduleService] instance.
final scheduleServiceProvider = Provider<ScheduleService>((ref) => ScheduleService()); 
// Copyright Luka Löhr 2026

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/substitution_models.dart';
import '../data/substitution_service.dart';
import '../../../../services/haptic_service.dart';
import '../../../../services/cache_service.dart';
import '../../../../utils/app_logger.dart';
import '../../../../providers/app_providers.dart';

/// State class for substitution data
class SubstitutionProviderState {
  final SubstitutionState todayState;
  final SubstitutionState tomorrowState;
  final bool isInitialized;
  final DateTime? lastFetchTime;
  final bool isLoading;
  final bool hasAnyError;
  final bool hasAnyData;

  const SubstitutionProviderState({
    required this.todayState,
    required this.tomorrowState,
    this.isInitialized = false,
    this.lastFetchTime,
    this.isLoading = false,
    this.hasAnyError = false,
    this.hasAnyData = false,
  });

  bool get isCacheValid {
    if (lastFetchTime == null) return false;
    return CacheService().isCacheValid(CacheKey.substitutions, lastFetchTime: lastFetchTime);
  }

  /// Get today's parsed data
  ParsedSubstitutionData? get todayData => todayState.parsedData;
  
  /// Get tomorrow's parsed data
  ParsedSubstitutionData? get tomorrowData => tomorrowState.parsedData;
  
  /// Get all unique classes from both today and tomorrow
  List<String> get allClasses {
    final classes = <String>{};
    if (todayData != null) {
      classes.addAll(todayData!.uniqueClasses);
    }
    if (tomorrowData != null) {
      classes.addAll(tomorrowData!.uniqueClasses);
    }
    final sorted = classes.toList()..sort(_compareClasses);
    return sorted;
  }
  
  /// Get entries for a specific class (combines today and tomorrow)
  Map<String, List<SubstitutionEntry>> getEntriesForClass(String className) {
    final result = <String, List<SubstitutionEntry>>{};
    
    if (todayData != null && todayData!.hasEntriesForClass(className)) {
      result['today'] = todayData!.getEntriesForClass(className);
    }
    
    if (tomorrowData != null && tomorrowData!.hasEntriesForClass(className)) {
      result['tomorrow'] = tomorrowData!.getEntriesForClass(className);
    }
    
    return result;
  }
  
  /// Compare class names for sorting
  static int _compareClasses(String a, String b) {
    final aMatch = RegExp(r'(\d+|[A-Z]+)([a-z]?)').firstMatch(a);
    final bMatch = RegExp(r'(\d+|[A-Z]+)([a-z]?)').firstMatch(b);
    
    if (aMatch == null || bMatch == null) return a.compareTo(b);
    
    final aNum = int.tryParse(aMatch.group(1) ?? '');
    final bNum = int.tryParse(bMatch.group(1) ?? '');
    final aLetter = aMatch.group(2) ?? '';
    final bLetter = bMatch.group(2) ?? '';
    
    if (aNum != null && bNum != null) {
      if (aNum != bNum) return aNum.compareTo(bNum);
      return aLetter.compareTo(bLetter);
    }
    
    if (aNum == null && bNum != null) return 1;
    if (aNum != null && bNum == null) return -1;
    
    return a.compareTo(b);
  }

  SubstitutionProviderState copyWith({
    SubstitutionState? todayState,
    SubstitutionState? tomorrowState,
    bool? isInitialized,
    DateTime? lastFetchTime,
    bool? isLoading,
    bool? hasAnyError,
    bool? hasAnyData,
  }) {
    return SubstitutionProviderState(
      todayState: todayState ?? this.todayState,
      tomorrowState: tomorrowState ?? this.tomorrowState,
      isInitialized: isInitialized ?? this.isInitialized,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      isLoading: isLoading ?? this.isLoading,
      hasAnyError: hasAnyError ?? this.hasAnyError,
      hasAnyData: hasAnyData ?? this.hasAnyData,
    );
  }
}

/// Notifier for managing substitution state
class SubstitutionNotifier extends Notifier<SubstitutionProviderState> {
  SubstitutionService get _substitutionService => ref.read(substitutionServiceProvider);

  @override
  SubstitutionProviderState build() {
    return SubstitutionProviderState(
      todayState: _substitutionService.todayState,
      tomorrowState: _substitutionService.tomorrowState,
      isInitialized: _substitutionService.isInitialized,
      lastFetchTime: _substitutionService.lastFetchTime,
      isLoading: _substitutionService.isLoading,
      hasAnyError: _substitutionService.hasAnyError,
      hasAnyData: _substitutionService.hasAnyData,
    );
  }

  void _refreshState() {
    state = SubstitutionProviderState(
      todayState: _substitutionService.todayState,
      tomorrowState: _substitutionService.tomorrowState,
      isInitialized: _substitutionService.isInitialized,
      lastFetchTime: _substitutionService.lastFetchTime,
      isLoading: _substitutionService.isLoading,
      hasAnyError: _substitutionService.hasAnyError,
      hasAnyData: _substitutionService.hasAnyData,
    );
  }

  /// Initialize the substitution service
  Future<void> initialize() async {
    await _substitutionService.initialize();
    _refreshState();
  }

  /// Retry loading a specific PDF
  Future<void> retryPdf(bool isToday) async {
    _substitutionService.setLoadingStateForPdf(isToday, true);
    _refreshState();
    
    await _substitutionService.retryPdf(isToday);
    _refreshState();
    
    final pdfState = isToday ? state.todayState : state.tomorrowState;
    if (pdfState.error != null) {
      HapticService.medium();
    }
  }

  /// Retry loading both PDFs
  Future<void> retryAll() async {
    _substitutionService.setLoadingState(true);
    _refreshState();
    
    await _substitutionService.retryAll();
    _refreshState();
  }

  /// Refresh all PDFs (force reload)
  Future<void> refresh() async {
    await _substitutionService.refresh();
    _refreshState();
  }

  /// Refresh in background
  Future<void> refreshInBackground() async {
    AppLogger.info('Background refresh: Substitution plans', module: 'SubstitutionProvider');
    _refreshState();
    await _substitutionService.refreshInBackground();
    _refreshState();
    AppLogger.success('Background refresh complete: Substitution plans', module: 'SubstitutionProvider');
  }

  /// Get the file for a specific PDF if available
  File? getPdfFile(bool isToday) {
    return _substitutionService.getPdfFile(isToday);
  }
  
  /// Get parsed data for a specific day
  ParsedSubstitutionData? getParsedData(bool isToday) {
    return _substitutionService.getParsedData(isToday);
  }

  /// Check if a PDF can be opened
  bool canOpenPdf(bool isToday) {
    return _substitutionService.canOpenPdf(isToday);
  }
}

/// Provider for substitution state
final substitutionProvider = NotifierProvider<SubstitutionNotifier, SubstitutionProviderState>(SubstitutionNotifier.new);

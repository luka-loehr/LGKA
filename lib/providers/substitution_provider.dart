// Copyright Luka Löhr 2025

import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/substitution_service.dart';
import '../services/haptic_service.dart';
import '../services/cache_service.dart';
import '../utils/app_logger.dart';
import 'app_providers.dart';

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
    // Set loading state immediately so UI shows loading indicator
    _substitutionService.setLoadingStateForPdf(isToday, true);
    _refreshState();
    
    // Then perform the actual retry
    await _substitutionService.retryPdf(isToday);
    _refreshState();
    
    // Check if retry failed and trigger haptic feedback
    final pdfState = isToday ? state.todayState : state.tomorrowState;
    if (pdfState.error != null) {
      HapticService.medium();
    }
  }

  /// Retry loading both PDFs
  Future<void> retryAll() async {
    // Set loading state immediately so UI shows loading indicator
    _substitutionService.setLoadingState(true);
    _refreshState();
    
    // Then perform the actual retry
    await _substitutionService.retryAll();
    _refreshState();
  }

  /// Refresh all PDFs (force reload)
  Future<void> refresh() async {
    await _substitutionService.refresh();
    _refreshState();
  }

  /// Refresh in background - shows loading spinner and disables interaction
  Future<void> refreshInBackground() async {
    AppLogger.info('Background refresh: Substitution plans', module: 'SubstitutionProvider');
    // Update state immediately to show loading spinner
    _refreshState();
    await _substitutionService.refreshInBackground();
    // Update state again after refresh completes
    _refreshState();
    AppLogger.success('Background refresh complete: Substitution plans', module: 'SubstitutionProvider');
  }

  /// Get the file for a specific PDF if available
  File? getPdfFile(bool isToday) {
    return _substitutionService.getPdfFile(isToday);
  }

  /// Check if a PDF can be opened
  bool canOpenPdf(bool isToday) {
    return _substitutionService.canOpenPdf(isToday);
  }
}

/// Provider for substitution state
final substitutionProvider = NotifierProvider<SubstitutionNotifier, SubstitutionProviderState>(SubstitutionNotifier.new);

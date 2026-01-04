// Copyright Luka Löhr 2025

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/news_models.dart';
import '../data/news_service.dart';
import '../../../../utils/app_logger.dart';
import '../../../../providers/app_providers.dart';

/// State class for news data
class NewsState {
  final List<NewsEvent> events;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const NewsState({
    this.events = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  NewsState copyWith({
    List<NewsEvent>? events,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? lastUpdated,
  }) {
    return NewsState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Check if there are any news events available
  bool get hasEvents => events.isNotEmpty;
  
  /// Check if there's an error
  bool get hasError => error != null;
}

/// Notifier for managing news state
class NewsNotifier extends Notifier<NewsState> {
  NewsService get _newsService => ref.read(newsServiceProvider);

  @override
  NewsState build() => const NewsState();

  /// Load news events from the web or cache
  Future<void> loadNews({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;

    // Check cache first if not forcing refresh
    final cachedEvents = _newsService.cachedEvents;
    final lastFetchTime = _newsService.lastFetchTime;

    if (!forceRefresh && cachedEvents != null) {
      state = state.copyWith(
        events: cachedEvents,
        isLoading: false,
        clearError: true,
        lastUpdated: lastFetchTime ?? state.lastUpdated,
      );

      if (_newsService.hasValidCache) {
        return;
      }

      // Cache is stale, refresh in background
      unawaited(_refreshNewsSilently());
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final events = await _newsService.fetchNewsEvents(forceRefresh: forceRefresh);

      if (events.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Keine Neuigkeiten gefunden',
        );
        return;
      }

      state = state.copyWith(
        events: events,
        isLoading: false,
        clearError: true,
        lastUpdated: _newsService.lastFetchTime ?? DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('Failed to load news', module: 'NewsProvider', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Laden der Neuigkeiten',
      );
    }
  }

  Future<void> _refreshNewsSilently() async {
    AppLogger.info('Background refresh: News', module: 'NewsProvider');
    final wasCacheValid = _newsService.hasValidCache;
    
    try {
      await _newsService.fetchNewsEvents(forceRefresh: true);
      final updatedEvents = _newsService.cachedEvents;
      if (updatedEvents != null) {
        state = state.copyWith(
          events: updatedEvents,
          isLoading: false,
          clearError: true,
          lastUpdated: _newsService.lastFetchTime ?? state.lastUpdated,
        );
        AppLogger.success('Background refresh complete: News', module: 'NewsProvider');
      }
    } catch (e) {
      AppLogger.error('Background refresh failed: News', module: 'NewsProvider', error: e);
      
      // If cache was invalid (app was backgrounded), clear cached data and show error
      if (!wasCacheValid) {
        AppLogger.info('Refresh failed with invalid cache - clearing cached news', module: 'NewsProvider');
        state = state.copyWith(
          events: const [],
          isLoading: false,
          error: 'Fehler beim Laden der Neuigkeiten',
        );
      }
      // If cache was valid, keep existing data (silent failure)
    }
  }

  Future<void> refreshInBackground() async {
    await _refreshNewsSilently();
  }

  /// Refresh news (force reload)
  Future<void> refreshNews() async {
    await loadNews(forceRefresh: true);
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for news state
final newsProvider = NotifierProvider<NewsNotifier, NewsState>(NewsNotifier.new);


// Copyright Luka Löhr 2025

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/news_service.dart';
import '../utils/app_logger.dart';
import 'app_providers.dart';

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

  /// Load news events from the web
  Future<void> loadNews({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final events = await _newsService.fetchNewsEvents();

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
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('Failed to load news', module: 'NewsProvider', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Laden der Neuigkeiten',
      );
    }
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


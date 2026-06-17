// Copyright Luka Löhr 2026

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/event_model.dart';
import '../data/events_service.dart';

/// State for the events section.
class EventsState {
  final List<SchoolEvent> events;
  final bool isLoading;
  final bool hasError;

  const EventsState({
    this.events = const [],
    this.isLoading = false,
    this.hasError = false,
  });

  EventsState copyWith({
    List<SchoolEvent>? events,
    bool? isLoading,
    bool? hasError,
  }) {
    return EventsState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
    );
  }
}

/// Notifier that loads and exposes school events.
class EventsNotifier extends Notifier<EventsState> {
  @override
  EventsState build() {
    // Trigger load asynchronously after build
    Future.microtask(() => _load());
    return const EventsState(isLoading: true);
  }

  Future<void> _load({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      final events = await EventsService.instance
          .fetchUpcomingEvents(forceRefresh: forceRefresh);
      state = EventsState(events: events, isLoading: false, hasError: false);
    } catch (_) {
      state = EventsState(
        events: state.events,
        isLoading: false,
        hasError: true,
      );
    }
  }

  /// Refreshes events by bypassing the cache (forces a re-fetch).
  /// Use for user-initiated refresh (pull-to-refresh).
  Future<void> refresh() => _load(forceRefresh: true);

  /// Re-fetches only if the cached events have expired. Cheap to call
  /// repeatedly — used by the startup preload and the periodic cache timer.
  Future<void> loadIfStale() async {
    if (!EventsService.instance.hasValidCache) {
      await _load();
    }
  }
}

final eventsProvider =
    NotifierProvider<EventsNotifier, EventsState>(EventsNotifier.new);

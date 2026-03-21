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

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      final events = await EventsService.instance.fetchUpcomingEvents();
      state = EventsState(events: events, isLoading: false, hasError: false);
    } catch (_) {
      state = EventsState(
        events: state.events,
        isLoading: false,
        hasError: true,
      );
    }
  }

  /// Refreshes events by bypassing cache (forces re-fetch).
  Future<void> refresh() => _load();
}

final eventsProvider =
    NotifierProvider<EventsNotifier, EventsState>(EventsNotifier.new);

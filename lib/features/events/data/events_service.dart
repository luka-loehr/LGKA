// Copyright Luka Löhr 2026

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../domain/event_model.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/parser_guard.dart';
import '../../../services/cache_service.dart';
import '../../../services/disk_cache.dart';

/// Fetches upcoming school events by scraping the school's JEvents calendar.
///
/// Scraping strategy:
///   - Fetch 3 consecutive week-list pages (this week + next 2 weeks).
///   - Each <li class="ev_td_li"> contains:
///       • optional time text "HH:MM Uhr - HH:MM Uhr" before the <a>
///       • <a class="ev_link_row" href="…/icalrepeat.detail/YYYY/MM/DD/…" title="Event Title">
///   - Date is extracted from the href URL.
///   - Title comes from the <a> title attribute.
///   - Deduplicate by (date, title) — the same event appears twice from two category feeds.
class EventsService {
  EventsService._();
  static final EventsService instance = EventsService._();

  static const String _base =
      'https://lessing-gymnasium-karlsruhe.de/cm3/index.php/termine/week.listevents';

  static const int _weeksToFetch = 3;

  List<SchoolEvent>? _cachedEvents;
  Future<List<SchoolEvent>>? _inFlight;
  final _shapeTracker = ParserChangeTracker();

  /// Whether cached events are present and still within the cache window.
  bool get hasValidCache => _isCacheValid();

  // ── Public API ──────────────────────────────────────────────────────────────

  Future<List<SchoolEvent>> fetchUpcomingEvents({bool forceRefresh = false}) async {
    // Prime the in-memory cache from disk on first access after a cold start.
    if (_cachedEvents == null) await hydrateFromDisk();
    if (!forceRefresh && _isCacheValid()) {
      AppLogger.debug(
        'Events: returning cached ${_cachedEvents!.length} events',
        module: 'EventsService',
      );
      return _cachedEvents!;
    }

    // Coalesce concurrent fetches so overlapping callers (startup preload,
    // periodic timer, pull-to-refresh) don't fan out into duplicate
    // multi-week request storms.
    final existing = _inFlight;
    if (existing != null) return existing;

    final future = _fetchAndCache();
    _inFlight = future;
    try {
      return await future;
    } finally {
      _inFlight = null;
    }
  }

  Future<List<SchoolEvent>> _fetchAndCache() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final allEvents = <SchoolEvent>[];
      final seen = <String>{};
      var parsedWeeks = 0;

      // Fetch all weeks in parallel
      final urls = List.generate(_weeksToFetch, (week) {
        final target = today.add(Duration(days: week * 7));
        return _weekUrl(target);
      });

      AppLogger.debug(
        'Events: fetching ${urls.length} weeks in parallel',
        module: 'EventsService',
      );

      final responses = await Future.wait(
        urls.map(
          (url) =>
              http.get(Uri.parse(url)).timeout(const Duration(seconds: 10)),
        ),
      );

      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        if (response.statusCode != 200) {
          AppLogger.warning(
            'Events: HTTP ${response.statusCode} for week $i',
            module: 'EventsService',
          );
          continue;
        }
        try {
          final parsed = _parseWeekHtml(response.body, today);
          if (_shapeTracker.didShapeChange(
            key: 'events:week:$i',
            fingerprint: parsed.fingerprint,
          )) {
            AppLogger.warning(
              'Events page shape changed for week $i: ${parsed.fingerprint}',
              module: 'EventsService',
            );
          }

          for (final event in parsed.events) {
            final key =
                '${event.date.toIso8601String()}|${event.title.toLowerCase().trim()}';
            if (seen.add(key)) allEvents.add(event);
          }
          parsedWeeks++;
        } on ParserSchemaException catch (e) {
          AppLogger.warning(
            'Events parser warning for week $i: $e',
            module: 'EventsService',
          );
        }
      }

      ParserGuard.requireMin(
        parser: 'Events parser',
        field: 'successfully parsed week pages',
        actual: parsedWeeks,
        min: 1,
      );

      allEvents.sort((a, b) => a.date.compareTo(b.date));

      AppLogger.success(
        'Events: loaded ${allEvents.length} upcoming events',
        module: 'EventsService',
      );

      _cachedEvents = allEvents;
      CacheService().updateCacheTimestamp(CacheKey.events, DateTime.now());
      unawaited(DiskCache.instance.write(
        _cacheBlob,
        jsonEncode(allEvents.map((e) => e.toJson()).toList()),
      ));
      return allEvents;
    } catch (e, st) {
      AppLogger.error(
        'Events: fetch failed',
        error: e,
        stackTrace: st,
        module: 'EventsService',
      );
      if (_cachedEvents != null) {
        AppLogger.debug(
          'Events: returning stale cache',
          module: 'EventsService',
        );
        return _cachedEvents!;
      }
      rethrow;
    }
  }

  static const String _cacheBlob = 'events';

  /// Loads last-persisted events from disk into the in-memory cache so the app
  /// can show them instantly on a cold start. Validity is gated by the
  /// persisted CacheService timestamp.
  Future<void> hydrateFromDisk() async {
    if (_cachedEvents != null) return;
    final raw = await DiskCache.instance.read(_cacheBlob);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _cachedEvents = list.map(SchoolEvent.fromJson).toList();
      AppLogger.debug('Events: hydrated ${_cachedEvents!.length} from disk',
          module: 'EventsService');
    } catch (e) {
      AppLogger.debug('Events: disk hydrate failed: $e', module: 'EventsService');
    }
  }

  void invalidateCache() {
    _cachedEvents = null;
    CacheService().clearCache(CacheKey.events);
    unawaited(DiskCache.instance.delete(_cacheBlob));
  }

  // ── Internals ───────────────────────────────────────────────────────────────

  bool _isCacheValid() =>
      _cachedEvents != null &&
      !CacheService().isCacheExpired(CacheKey.events);

  String _weekUrl(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$_base/$y/$m/$d/-?catids=';
  }

  // Regex patterns compiled once
  static final _liPattern = RegExp(
    "<li\\s+class=[\"']ev_td_li[\"'][^>]*>(.*?)</li>",
    dotAll: true,
    caseSensitive: false,
  );
  static final _hrefPattern = RegExp(
    r'href="[^"]*?/icalrepeat\.detail/(\d{4})/(\d{2})/(\d{2})/',
  );
  static final _titlePattern = RegExp(r'title="([^"]+)"');
  static final _timePattern = RegExp(r'(\d{1,2}:\d{2})\s*Uhr');

  _WeekParseResult _parseWeekHtml(String html, DateTime today) {
    final events = <SchoolEvent>[];
    var liCount = 0;
    var hrefCount = 0;
    var titleCount = 0;

    for (final match in _liPattern.allMatches(html)) {
      liCount++;
      final li = match.group(1)!;

      // Extract date from href
      final hrefMatch = _hrefPattern.firstMatch(li);
      if (hrefMatch == null) continue;
      hrefCount++;
      final year = int.parse(hrefMatch.group(1)!);
      final month = int.parse(hrefMatch.group(2)!);
      final day = int.parse(hrefMatch.group(3)!);
      final date = DateTime(year, month, day);

      // Skip events in the past
      if (date.isBefore(today)) continue;

      // Extract title from the <a title="..."> attribute
      final titleMatch = _titlePattern.firstMatch(li);
      if (titleMatch == null) continue;
      titleCount++;
      final title = _decodeHtmlEntities(titleMatch.group(1)!.trim());
      if (title.isEmpty) continue;

      // Extract optional start time (first time found in the li text)
      final timeMatch = _timePattern.firstMatch(li);
      final time = timeMatch?.group(1);

      events.add(SchoolEvent(date: date, time: time, title: title));
    }

    ParserGuard.requireMin(
      parser: 'Events week parser',
      field: '<li class="ev_td_li"> entries',
      actual: liCount,
      min: 1,
    );

    return _WeekParseResult(
      events: events,
      fingerprint: ParserGuard.buildFingerprint({
        'liCount': liCount,
        'hrefCount': hrefCount,
        'titleCount': titleCount,
        'futureEvents': events.length,
      }),
    );
  }

  /// Decodes common HTML entities in event titles.
  String _decodeHtmlEntities(String input) => input
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&auml;', 'ä')
      .replaceAll('&ouml;', 'ö')
      .replaceAll('&uuml;', 'ü')
      .replaceAll('&Auml;', 'Ä')
      .replaceAll('&Ouml;', 'Ö')
      .replaceAll('&Uuml;', 'Ü')
      .replaceAll('&szlig;', 'ß');
}

class _WeekParseResult {
  const _WeekParseResult({required this.events, required this.fingerprint});

  final List<SchoolEvent> events;
  final String fingerprint;
}

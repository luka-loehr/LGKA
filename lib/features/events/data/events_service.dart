// Copyright Luka Löhr 2026

import 'package:http/http.dart' as http;
import '../domain/event_model.dart';
import '../../../utils/app_logger.dart';

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

  static const Duration _cacheDuration = Duration(hours: 1);
  static const int _weeksToFetch = 3;

  List<SchoolEvent>? _cachedEvents;
  DateTime? _cacheTimestamp;

  // ── Public API ──────────────────────────────────────────────────────────────

  Future<List<SchoolEvent>> fetchUpcomingEvents() async {
    if (_isCacheValid()) {
      AppLogger.debug('Events: returning cached ${_cachedEvents!.length} events',
          module: 'EventsService');
      return _cachedEvents!;
    }

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final allEvents = <SchoolEvent>[];
      final seen = <String>{};

      // Fetch all weeks in parallel
      final urls = List.generate(_weeksToFetch, (week) {
        final target = today.add(Duration(days: week * 7));
        return _weekUrl(target);
      });

      AppLogger.debug('Events: fetching ${urls.length} weeks in parallel',
          module: 'EventsService');

      final responses = await Future.wait(
        urls.map((url) => http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10))),
      );

      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        if (response.statusCode != 200) {
          AppLogger.warning(
              'Events: HTTP ${response.statusCode} for week $i',
              module: 'EventsService');
          continue;
        }
        final parsed = _parseWeekHtml(response.body, today);
        for (final event in parsed) {
          final key =
              '${event.date.toIso8601String()}|${event.title.toLowerCase().trim()}';
          if (seen.add(key)) allEvents.add(event);
        }
      }

      allEvents.sort((a, b) => a.date.compareTo(b.date));

      AppLogger.success(
          'Events: loaded ${allEvents.length} upcoming events',
          module: 'EventsService');

      _cachedEvents = allEvents;
      _cacheTimestamp = DateTime.now();
      return allEvents;
    } catch (e, st) {
      AppLogger.error('Events: fetch failed', error: e, stackTrace: st,
          module: 'EventsService');
      if (_cachedEvents != null) {
        AppLogger.debug('Events: returning stale cache', module: 'EventsService');
        return _cachedEvents!;
      }
      rethrow;
    }
  }

  void invalidateCache() {
    _cacheTimestamp = null;
  }

  // ── Internals ───────────────────────────────────────────────────────────────

  bool _isCacheValid() =>
      _cachedEvents != null &&
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheDuration;

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

  List<SchoolEvent> _parseWeekHtml(String html, DateTime today) {
    final events = <SchoolEvent>[];

    for (final match in _liPattern.allMatches(html)) {
      final li = match.group(1)!;

      // Extract date from href
      final hrefMatch = _hrefPattern.firstMatch(li);
      if (hrefMatch == null) continue;
      final year = int.parse(hrefMatch.group(1)!);
      final month = int.parse(hrefMatch.group(2)!);
      final day = int.parse(hrefMatch.group(3)!);
      final date = DateTime(year, month, day);

      // Skip events in the past
      if (date.isBefore(today)) continue;

      // Extract title from the <a title="..."> attribute
      final titleMatch = _titlePattern.firstMatch(li);
      if (titleMatch == null) continue;
      final title = _decodeHtmlEntities(titleMatch.group(1)!.trim());
      if (title.isEmpty) continue;

      // Extract optional start time (first time found in the li text)
      final timeMatch = _timePattern.firstMatch(li);
      final time = timeMatch?.group(1);

      events.add(SchoolEvent(date: date, time: time, title: title));
    }

    return events;
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

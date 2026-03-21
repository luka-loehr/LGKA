// Copyright Luka Löhr 2026

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../domain/event_model.dart';

/// Fetches and parses upcoming school events from the school website.
class EventsService {
  EventsService._();
  static final EventsService instance = EventsService._();

  static const Duration _cacheDuration = Duration(hours: 1);
  static const int _maxEvents = 20;

  List<SchoolEvent>? _cachedEvents;
  DateTime? _cacheTimestamp;

  static const Map<String, int> _germanMonths = {
    'januar': 1,
    'februar': 2,
    'märz': 3,
    'april': 4,
    'mai': 5,
    'juni': 6,
    'juli': 7,
    'august': 8,
    'september': 9,
    'oktober': 10,
    'november': 11,
    'dezember': 12,
  };

  /// Returns upcoming events. Uses in-memory cache if less than 1 hour old.
  Future<List<SchoolEvent>> fetchUpcomingEvents() async {
    // Return cache if fresh
    if (_cachedEvents != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedEvents!;
    }

    try {
      final now = DateTime.now();
      final year = now.year.toString();
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');

      final url =
          'https://lessing-gymnasium-karlsruhe.de/cm3/index.php/termine/year.listevents/$year/$month/$day/-?catids=';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final events = _parseEvents(response.body, now);

      _cachedEvents = events;
      _cacheTimestamp = DateTime.now();
      return events;
    } catch (_) {
      // On error, return cached data if available
      if (_cachedEvents != null) {
        return _cachedEvents!;
      }
      rethrow;
    }
  }

  List<SchoolEvent> _parseEvents(String htmlBody, DateTime now) {
    final document = html_parser.parse(htmlBody);

    final List<SchoolEvent> events = [];
    final Set<String> seen = {}; // for deduplication: "date|title"

    // The calendar page groups events under date headers.
    // Date headers are <a> tags with href containing "listevents" and
    // containing a child <div> or direct text like "16. März".
    // We look for the pattern: a container element that has both a date
    // header anchor and a subsequent <ul> of events.

    // Strategy: find all elements that look like date anchors (text matches
    // "D. Monatsname" pattern), then find the sibling/nearby <ul>.
    final dateHeaderRegex = RegExp(r'^(\d{1,2})\.\s+(\w+)$');
    final timeRegex = RegExp(r'(\d{1,2}:\d{2})\s+Uhr');

    // Walk all nodes looking for date header anchors
    // The structure observed: <div class="..."><a href="...listevents..."><div>16. März</div></a><ul>...</ul></div>
    // We use a broad search: find all <a> tags whose text matches a date pattern
    final allAnchors = document.querySelectorAll('a');

    for (final anchor in allAnchors) {
      final anchorText = anchor.text.trim();
      final dateMatch = dateHeaderRegex.firstMatch(anchorText);
      if (dateMatch == null) continue;

      final dayNum = int.tryParse(dateMatch.group(1)!);
      final monthName = dateMatch.group(2)!.toLowerCase();
      if (dayNum == null) continue;

      final monthNum = _germanMonths[monthName];
      if (monthNum == null) continue;

      // Determine the year: if month is earlier than current month,
      // it belongs to next year (wrapping at year end)
      int year = now.year;
      if (monthNum < now.month ||
          (monthNum == now.month && dayNum < now.day)) {
        year = now.year + 1;
      }

      final eventDate = DateTime(year, monthNum, dayNum);

      // Find the <ul> that is a sibling of this anchor or its parent
      // Try parent's next sibling first, then parent of parent
      Element? ulElement;

      // The anchor may be inside a wrapper div; look at the anchor's parent
      // and that parent's siblings
      final parent = anchor.parent;
      if (parent != null) {
        // Look for a <ul> as a sibling of the anchor within the same parent
        ulElement = _findNextSiblingUl(anchor);
        // Try siblings of the parent if not found as anchor sibling
        ulElement ??= _findNextSiblingUl(parent);
      }

      if (ulElement == null) continue;

      // Parse each <li> in the <ul>
      final listItems = ulElement.querySelectorAll('li');
      for (final li in listItems) {
        // Extract the title from the <a> tag inside the <li>
        final titleAnchor = li.querySelector('a');
        if (titleAnchor == null) continue;
        final title = titleAnchor.text.trim();
        if (title.isEmpty) continue;

        // Extract optional time from the raw text of the <li>
        // The time appears as plain text before the <a> tag
        String? time;
        final liText = li.text;
        final timeMatch = timeRegex.firstMatch(liText);
        if (timeMatch != null) {
          time = timeMatch.group(1);
        }

        // Deduplicate by (date, normalized title)
        final key = '${eventDate.toIso8601String()}|${title.toLowerCase()}';
        if (seen.contains(key)) continue;
        seen.add(key);

        events.add(SchoolEvent(
          date: eventDate,
          time: time,
          title: title,
        ));
      }
    }

    // Sort by date and limit to max events
    events.sort((a, b) => a.date.compareTo(b.date));
    if (events.length > _maxEvents) {
      return events.sublist(0, _maxEvents);
    }
    return events;
  }

  /// Finds the next sibling <ul> element after [element] within the same parent.
  Element? _findNextSiblingUl(Element element) {
    final parent = element.parent;
    if (parent == null) return null;

    bool found = false;
    for (final node in parent.children) {
      if (found && node.localName == 'ul') {
        return node;
      }
      if (node == element) {
        found = true;
      }
    }
    return null;
  }
}

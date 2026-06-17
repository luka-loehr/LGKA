import 'package:flutter_test/flutter_test.dart';
import 'package:lgka_flutter/features/events/domain/event_model.dart';
import 'package:lgka_flutter/features/schedule/domain/schedule_models.dart';
import 'package:lgka_flutter/features/news/domain/news_models.dart';

/// Round-trip tests for the JSON serialization that backs the persistent
/// disk cache. A schema mismatch here would silently break cold-start hydration.
void main() {
  test('SchoolEvent round-trips through JSON (with and without time)', () {
    final timed = SchoolEvent(
      date: DateTime(2026, 6, 17),
      time: '18:00',
      title: 'Schulkonzert',
    );
    final allDay = SchoolEvent(date: DateTime(2026, 7, 1), title: 'Sommerfest');

    final timedBack = SchoolEvent.fromJson(timed.toJson());
    expect(timedBack.date, timed.date);
    expect(timedBack.time, '18:00');
    expect(timedBack.title, 'Schulkonzert');

    final allDayBack = SchoolEvent.fromJson(allDay.toJson());
    expect(allDayBack.time, isNull);
    expect(allDayBack.title, 'Sommerfest');
  });

  test('ScheduleItem round-trips through JSON', () {
    const item = ScheduleItem(
      title: 'Klassen 5-10 (2. HJ)',
      url: '/cm3/../stundenplan/5-10_hj2.pdf',
      halbjahr: '2. Halbjahr',
      gradeLevel: 'Klassen 5-10',
      fullUrl: 'https://lessing-gymnasium-karlsruhe.de/stundenplan/5-10_hj2.pdf',
    );

    final back = ScheduleItem.fromJson(item.toJson());
    expect(back, item); // ScheduleItem has value equality
  });

  test('NewsEvent round-trips nested links/images/downloads + parsedDate', () {
    final event = NewsEvent(
      title: 'Neues von der Schule',
      author: 'Schulleitung',
      description: 'Beschreibung',
      htmlContent: '<p>Inhalt</p>',
      createdDate: '17.06.2026',
      parsedDate: DateTime(2026, 6, 17),
      views: 42,
      url: 'https://example.org/news/1',
      links: [NewsLink(text: 'mehr', url: 'https://example.org/x')],
      standaloneLinks: [NewsLink(text: 'PDF', url: 'https://example.org/y.pdf')],
      images: [NewsImage(url: 'https://example.org/i.jpg', alt: 'Bild')],
      downloads: [
        NewsDownload(
          title: 'Datei',
          url: 'https://example.org/f.pdf',
          fileType: 'document',
          size: '3.6 MB',
        ),
      ],
      tags: ['Allgemein'],
    );

    final back = NewsEvent.fromJson(event.toJson());
    expect(back.title, event.title);
    expect(back.author, event.author);
    expect(back.htmlContent, '<p>Inhalt</p>');
    expect(back.parsedDate, DateTime(2026, 6, 17));
    expect(back.views, 42);
    expect(back.links.single.url, 'https://example.org/x');
    expect(back.standaloneLinks!.single.text, 'PDF');
    expect(back.images.single.alt, 'Bild');
    expect(back.downloads.single.size, '3.6 MB');
    expect(back.tags, ['Allgemein']);
  });
}

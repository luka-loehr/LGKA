// Copyright Luka Löhr 2026

/// Represents a single school event scraped from the school website.
class SchoolEvent {
  final DateTime date;
  final String? time; // e.g. "18:00" or null for all-day events
  final String title;

  const SchoolEvent({
    required this.date,
    this.time,
    required this.title,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        if (time != null) 'time': time,
        'title': title,
      };

  factory SchoolEvent.fromJson(Map<String, dynamic> json) => SchoolEvent(
        date: DateTime.parse(json['date'] as String),
        time: json['time'] as String?,
        title: json['title'] as String,
      );
}

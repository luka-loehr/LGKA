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
}

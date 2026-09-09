// Copyright Luka Löhr 2026

/// Represents a schedule PDF with metadata
class ScheduleItem {
  final String title;
  final String url;
  final String halbjahr;
  final String gradeLevel;
  final String fullUrl;

  const ScheduleItem({
    required this.title,
    required this.url,
    required this.halbjahr,
    required this.gradeLevel,
    required this.fullUrl,
  });

  @override
  String toString() {
    return 'ScheduleItem(title: $title, halbjahr: $halbjahr, gradeLevel: $gradeLevel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleItem &&
        other.title == title &&
        other.url == url &&
        other.halbjahr == halbjahr &&
        other.gradeLevel == gradeLevel &&
        other.fullUrl == fullUrl;
  }

  @override
  int get hashCode {
    return Object.hash(title, url, halbjahr, gradeLevel, fullUrl);
  }
}

/// The `gradeLevel` values a [ScheduleItem] can carry.
///
/// The upper grades used to be published as a single combined PDF ([j11j12]);
/// since 2026/2027 the school publishes one PDF per Jahrgang ([j11], [j12]).
/// Both layouts are still supported so older halbjahr links keep working.
abstract final class GradeLevels {
  static const String grades5to10 = 'Klassen 5-10';
  static const String j11 = 'J11';
  static const String j12 = 'J12';
  static const String j11j12 = 'J11/J12';
  static const String unknown = 'Unbekannt';

  /// Whether [className] belongs to the upper grades (`j11`/`j12`).
  static bool isJahrgangClass(String? className) =>
      className != null && className.startsWith('j');

  /// Whether [gradeLevel] denotes an upper-grade PDF, combined or not.
  static bool isJahrgang(String gradeLevel) =>
      gradeLevel == j11 || gradeLevel == j12 || gradeLevel == j11j12;

  /// Grade levels whose PDF can contain [className]'s timetable, most specific
  /// first — the per-Jahrgang PDF is preferred over the combined one.
  static List<String> forClass(String className) {
    switch (className.toLowerCase()) {
      case 'j11':
        return const [j11, j11j12];
      case 'j12':
        return const [j12, j11j12];
      default:
        return const [grades5to10];
    }
  }

  /// The classes covered by one [gradeLevel] PDF of the upper grades.
  static List<String> jahrgangClassesIn(String gradeLevel) {
    switch (gradeLevel) {
      case j11:
        return const ['j11'];
      case j12:
        return const ['j12'];
      case j11j12:
        return const ['j11', 'j12'];
      default:
        return const [];
    }
  }

  /// Page of [className] inside its own PDF: a per-Jahrgang PDF holds a single
  /// timetable on page 1, the combined PDF holds j11 on page 2 and j12 on 3.
  static int jahrgangPage(String gradeLevel, String className) {
    if (gradeLevel != j11j12) return 1;
    return className == 'j11' ? 2 : 3;
  }
}

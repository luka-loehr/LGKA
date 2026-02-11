// Copyright Luka Löhr 2026

import 'dart:convert';

/// German weekdays
const List<String> germanWeekdays = [
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
];

/// Represents a single lesson in the schedule
class ScheduleLesson {
  /// Period/lesson number (1-11)
  final int period;
  /// Subject code (e.g., "D", "M", "E")
  final String subject;
  /// Teacher abbreviation (e.g., "Blm", "Hum")
  final String teacher;
  /// Room number (e.g., "109", "BKOG")
  final String room;
  /// Day index (0=Monday, 1=Tuesday, etc.)
  final int dayIndex;
  /// Day name
  String get dayName => germanWeekdays[dayIndex];
  /// Full lesson time info
  final LessonTime? timeInfo;

  const ScheduleLesson({
    required this.period,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.dayIndex,
    this.timeInfo,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'subject': subject,
      'teacher': teacher,
      'room': room,
      'dayIndex': dayIndex,
      'dayName': dayName,
      'timeInfo': timeInfo?.toJson(),
    };
  }

  /// Create from JSON
  factory ScheduleLesson.fromJson(Map<String, dynamic> json) {
    return ScheduleLesson(
      period: json['period'] as int,
      subject: json['subject'] as String,
      teacher: json['teacher'] as String,
      room: json['room'] as String,
      dayIndex: json['dayIndex'] as int,
      timeInfo: json['timeInfo'] != null
          ? LessonTime.fromJson(json['timeInfo'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() => 'ScheduleLesson(${toJson()})';
}

/// Lesson time information
class LessonTime {
  /// Start time (e.g., "08:00")
  final String startTime;
  /// End time (e.g., "08:45")
  final String endTime;
  /// Whether this is a break/pause
  final bool isBreak;

  const LessonTime({
    required this.startTime,
    required this.endTime,
    this.isBreak = false,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'isBreak': isBreak,
    };
  }

  /// Create from JSON
  factory LessonTime.fromJson(Map<String, dynamic> json) {
    return LessonTime(
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      isBreak: json['isBreak'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'LessonTime($startTime - $endTime)';
}

/// Schedule for a specific class
class ClassSchedule {
  /// Class name (e.g., "5a", "10b")
  final String className;
  /// All lessons for this class
  final List<ScheduleLesson> lessons;
  /// Teachers responsible for this class
  final List<String> classTeachers;

  const ClassSchedule({
    required this.className,
    required this.lessons,
    this.classTeachers = const [],
  });

  /// Get lessons for a specific day
  List<ScheduleLesson> getLessonsForDay(int dayIndex) {
    return lessons
        .where((l) => l.dayIndex == dayIndex)
        .toList()
      ..sort((a, b) => a.period.compareTo(b.period));
  }

  /// Get lessons for a specific period across all days
  List<ScheduleLesson> getLessonsForPeriod(int period) {
    return lessons
        .where((l) => l.period == period)
        .toList()
      ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
  }

  /// Get unique periods
  List<int> get uniquePeriods {
    final periods = lessons.map((l) => l.period).toSet().toList();
    periods.sort();
    return periods;
  }

  /// Get all lessons grouped by day
  Map<String, List<ScheduleLesson>> get lessonsByDay {
    final result = <String, List<ScheduleLesson>>{};
    for (final day in germanWeekdays) {
      final dayLessons = lessons.where((l) => l.dayName == day).toList()
        ..sort((a, b) => a.period.compareTo(b.period));
      if (dayLessons.isNotEmpty) {
        result[day] = dayLessons;
      }
    }
    return result;
  }

  /// Get all lessons grouped by period
  Map<int, List<ScheduleLesson>> get lessonsByPeriod {
    final result = <int, List<ScheduleLesson>>{};
    for (final period in uniquePeriods) {
      result[period] = getLessonsForPeriod(period);
    }
    return result;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'classTeachers': classTeachers,
      'lessons': lessons.map((l) => l.toJson()).toList(),
      'lessonsByDay': lessonsByDay.map(
        (key, value) => MapEntry(key, value.map((l) => l.toJson()).toList()),
      ),
      'lessonsByPeriod': lessonsByPeriod.map(
        (key, value) => MapEntry(key.toString(), value.map((l) => l.toJson()).toList()),
      ),
      'uniquePeriods': uniquePeriods,
    };
  }

  /// Create from JSON
  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      className: json['className'] as String,
      classTeachers: (json['classTeachers'] as List?)?.cast<String>() ?? [],
      lessons: (json['lessons'] as List)
          .map((l) => ScheduleLesson.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() => 'ClassSchedule($className, ${lessons.length} lessons)';
}

/// Complete schedule data for all classes
class SchoolSchedule {
  /// Map of class name to schedule
  final Map<String, ClassSchedule> classSchedules;
  /// School year
  final String schoolYear;
  /// Last updated
  final DateTime? lastUpdated;

  const SchoolSchedule({
    required this.classSchedules,
    this.schoolYear = '2025-2026',
    this.lastUpdated,
  });

  /// Get all class names
  List<String> get classNames {
    final names = classSchedules.keys.toList();
    names.sort(compareClasses);
    return names;
  }

  /// Get schedule for a specific class
  ClassSchedule? getScheduleForClass(String className) {
    return classSchedules[className];
  }

  /// Compare class names for sorting
  static int compareClasses(String a, String b) {
    final aMatch = RegExp(r'^(\d+|[A-Z]+)([a-z]*)$').firstMatch(a);
    final bMatch = RegExp(r'^(\d+|[A-Z]+)([a-z]*)$').firstMatch(b);
    
    if (aMatch == null || bMatch == null) return a.compareTo(b);
    
    final aNum = int.tryParse(aMatch.group(1) ?? '');
    final bNum = int.tryParse(bMatch.group(1) ?? '');
    final aLetter = aMatch.group(2) ?? '';
    final bLetter = bMatch.group(2) ?? '';
    
    if (aNum != null && bNum != null) {
      if (aNum != bNum) return aNum.compareTo(bNum);
      return aLetter.compareTo(bLetter);
    }
    
    if (aNum == null && bNum != null) return 1;
    if (aNum != null && bNum == null) return -1;
    
    return a.compareTo(b);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'schoolYear': schoolYear,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'classNames': classNames,
      'classSchedules': classSchedules.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  /// Convert to pretty printed JSON string
  String toJsonString({bool pretty = true}) {
    final encoder = pretty 
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return encoder.convert(toJson());
  }

  /// Create from JSON
  factory SchoolSchedule.fromJson(Map<String, dynamic> json) {
    return SchoolSchedule(
      schoolYear: json['schoolYear'] as String? ?? '2025-2026',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      classSchedules: (json['classSchedules'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, ClassSchedule.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }

  /// Empty schedule
  factory SchoolSchedule.empty() {
    return const SchoolSchedule(
      classSchedules: {},
    );
  }

  @override
  String toString() => 'SchoolSchedule($schoolYear, ${classNames.length} classes)';
}

/// Schedule with substitution overlay
class ScheduleWithSubstitutions {
  /// Base schedule
  final ClassSchedule schedule;
  /// Substitutions for this class (period -> list of substitutions)
  final Map<String, List<Map<String, dynamic>>> substitutions;

  const ScheduleWithSubstitutions({
    required this.schedule,
    this.substitutions = const {},
  });

  /// Check if there's a substitution for a specific period on a specific day
  bool hasSubstitution(int period, int dayIndex) {
    final key = '${dayIndex}_$period';
    return substitutions.containsKey(key) && substitutions[key]!.isNotEmpty;
  }

  /// Get substitutions for a specific period on a specific day
  List<Map<String, dynamic>>? getSubstitutions(int period, int dayIndex) {
    final key = '${dayIndex}_$period';
    return substitutions[key];
  }
}

// Copyright Luka Löhr 2026

import 'dart:io';
import 'dart:convert';

/// Type of substitution entry
enum SubstitutionType {
  /// Regular substitution (Vertretung)
  substitution,
  /// Cancellation (Entfall)
  cancellation,
  /// Room change (Raum-Vtr.)
  roomChange,
  /// Exchange/Tausch
  exchange,
  /// Relocation (Verlegung)
  relocation,
  /// Supervision (Betreuung)
  supervision,
  /// Special unit (Sonderein)
  specialUnit,
  /// Teacher observation (Lehrprobe)
  teacherObservation,
  /// Unknown type
  unknown,
}

extension SubstitutionTypeExtension on SubstitutionType {
  String get name {
    switch (this) {
      case SubstitutionType.substitution:
        return 'substitution';
      case SubstitutionType.cancellation:
        return 'cancellation';
      case SubstitutionType.roomChange:
        return 'roomChange';
      case SubstitutionType.exchange:
        return 'exchange';
      case SubstitutionType.relocation:
        return 'relocation';
      case SubstitutionType.supervision:
        return 'supervision';
      case SubstitutionType.specialUnit:
        return 'specialUnit';
      case SubstitutionType.teacherObservation:
        return 'teacherObservation';
      case SubstitutionType.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case SubstitutionType.substitution:
        return 'Vertretung';
      case SubstitutionType.cancellation:
        return 'Entfall';
      case SubstitutionType.roomChange:
        return 'Raumänderung';
      case SubstitutionType.exchange:
        return 'Tausch';
      case SubstitutionType.relocation:
        return 'Verlegung';
      case SubstitutionType.supervision:
        return 'Betreuung';
      case SubstitutionType.specialUnit:
        return 'Sondereinheit';
      case SubstitutionType.teacherObservation:
        return 'Lehrprobe';
      case SubstitutionType.unknown:
        return 'Sonstiges';
    }
  }

  int get colorValue {
    switch (this) {
      case SubstitutionType.cancellation:
        return 0xFFEF4444; // Red
      case SubstitutionType.roomChange:
        return 0xFF3B82F6; // Blue
      case SubstitutionType.exchange:
        return 0xFF10B981; // Green
      case SubstitutionType.relocation:
        return 0xFFF59E0B; // Amber
      case SubstitutionType.supervision:
        return 0xFF8B5CF6; // Purple
      case SubstitutionType.specialUnit:
        return 0xFFEC4899; // Pink
      case SubstitutionType.teacherObservation:
        return 0xFF06B6D4; // Cyan
      case SubstitutionType.substitution:
        return 0xFF6366F1; // Indigo
      case SubstitutionType.unknown:
        return 0xFF6B7280; // Gray
    }
  }

  static SubstitutionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'substitution':
      case 'vertretung':
        return SubstitutionType.substitution;
      case 'cancellation':
      case 'entfall':
        return SubstitutionType.cancellation;
      case 'roomchange':
      case 'room_change':
      case 'raum-vtr.':
      case 'raumänderung':
        return SubstitutionType.roomChange;
      case 'exchange':
      case 'tausch':
        return SubstitutionType.exchange;
      case 'relocation':
      case 'verlegung':
        return SubstitutionType.relocation;
      case 'supervision':
      case 'betreuung':
        return SubstitutionType.supervision;
      case 'specialunit':
      case 'special_unit':
      case 'sonderein':
      case 'sondereinheit':
        return SubstitutionType.specialUnit;
      case 'teacherobservation':
      case 'teacher_observation':
      case 'lehrprobe':
        return SubstitutionType.teacherObservation;
      default:
        return SubstitutionType.unknown;
    }
  }
}

/// Represents a single substitution entry for a specific class
class SubstitutionEntry {
  /// Type of substitution
  final SubstitutionType type;
  /// Period/lesson number (e.g., "1", "3-4")
  final String period;
  /// Class name (e.g., "5b", "8a")
  final String className;
  /// Subject (e.g., "D", "M", "Ph")
  final String subject;
  /// Room (e.g., "110", "PHHS")
  final String room;
  /// Substitute teacher (may be empty for cancellations)
  final String substituteTeacher;
  /// Original teacher (from parentheses)
  final String? originalTeacher;
  /// Original subject (from parentheses)
  final String? originalSubject;
  /// Original room (from parentheses)
  final String? originalRoom;
  /// Additional text/info
  final String? text;
  /// Full row text for reference
  final String rawText;

  const SubstitutionEntry({
    required this.type,
    required this.period,
    required this.className,
    required this.subject,
    required this.room,
    required this.substituteTeacher,
    this.originalTeacher,
    this.originalSubject,
    this.originalRoom,
    this.text,
    required this.rawText,
  });

  /// Get display label for the type
  String get typeLabel => type.label;

  /// Get color for the type (for UI)
  int get typeColor => type.colorValue;

  /// Whether this entry represents a cancellation
  bool get isCancellation => type == SubstitutionType.cancellation;

  /// Whether this entry has a room change
  bool get hasRoomChange => type == SubstitutionType.roomChange || originalRoom != null;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'typeLabel': typeLabel,
      'period': period,
      'className': className,
      'subject': subject,
      'room': room,
      'substituteTeacher': substituteTeacher,
      'originalTeacher': originalTeacher,
      'originalSubject': originalSubject,
      'originalRoom': originalRoom,
      'text': text,
      'isCancellation': isCancellation,
      'hasRoomChange': hasRoomChange,
    };
  }

  /// Create from JSON
  factory SubstitutionEntry.fromJson(Map<String, dynamic> json) {
    return SubstitutionEntry(
      type: SubstitutionTypeExtension.fromString(json['type'] as String),
      period: json['period'] as String,
      className: json['className'] as String,
      subject: json['subject'] as String,
      room: json['room'] as String,
      substituteTeacher: json['substituteTeacher'] as String,
      originalTeacher: json['originalTeacher'] as String?,
      originalSubject: json['originalSubject'] as String?,
      originalRoom: json['originalRoom'] as String?,
      text: json['text'] as String?,
      rawText: json['rawText'] ?? '',
    );
  }

  @override
  String toString() {
    return 'SubstitutionEntry(${toJson()})';
  }
}

/// Represents parsed substitution data for a day
class ParsedSubstitutionData {
  /// Date string (e.g., "11.02.2026")
  final String date;
  /// Weekday (e.g., "Mittwoch")
  final String weekday;
  /// Last updated timestamp
  final String? lastUpdated;
  /// List of all substitution entries
  final List<SubstitutionEntry> entries;
  /// List of absent teachers
  final List<String> absentTeachers;
  /// Duty/service info (Hofdienst)
  final String? dutyInfo;
  /// Blocked rooms
  final List<String> blockedRooms;

  const ParsedSubstitutionData({
    required this.date,
    required this.weekday,
    this.lastUpdated,
    required this.entries,
    this.absentTeachers = const [],
    this.dutyInfo,
    this.blockedRooms = const [],
  });

  /// Get all unique class names from entries
  List<String> get uniqueClasses {
    final classes = entries.map((e) => e.className).toSet().toList();
    classes.sort(_compareClasses);
    return classes;
  }

  /// Get entries for a specific class
  List<SubstitutionEntry> getEntriesForClass(String className) {
    return entries.where((e) => e.className == className).toList()
      ..sort((a, b) => _comparePeriods(a.period, b.period));
  }

  /// Check if there are any entries for a class
  bool hasEntriesForClass(String className) {
    return entries.any((e) => e.className == className);
  }

  /// Group entries by class
  Map<String, List<SubstitutionEntry>> get entriesByClass {
    final result = <String, List<SubstitutionEntry>>{};
    for (final className in uniqueClasses) {
      result[className] = getEntriesForClass(className);
    }
    return result;
  }

  /// Compare class names for sorting (e.g., "5a", "5b", "10a", "J11")
  static int _compareClasses(String a, String b) {
    // Extract numeric and alphabetic parts
    final aMatch = RegExp(r'(\d+|[A-Z]+)([a-z]?)').firstMatch(a);
    final bMatch = RegExp(r'(\d+|[A-Z]+)([a-z]?)').firstMatch(b);
    
    if (aMatch == null || bMatch == null) return a.compareTo(b);
    
    final aNum = int.tryParse(aMatch.group(1) ?? '');
    final bNum = int.tryParse(bMatch.group(1) ?? '');
    final aLetter = aMatch.group(2) ?? '';
    final bLetter = bMatch.group(2) ?? '';
    
    if (aNum != null && bNum != null) {
      if (aNum != bNum) return aNum.compareTo(bNum);
      return aLetter.compareTo(bLetter);
    }
    
    // Handle case like "J11" vs "5a"
    if (aNum == null && bNum != null) return 1;
    if (aNum != null && bNum == null) return -1;
    
    return a.compareTo(b);
  }

  /// Compare periods for sorting (e.g., "1", "3-4")
  static int _comparePeriods(String a, String b) {
    final aStart = int.tryParse(a.split('-').first.trim()) ?? 0;
    final bStart = int.tryParse(b.split('-').first.trim()) ?? 0;
    return aStart.compareTo(bStart);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'weekday': weekday,
      'lastUpdated': lastUpdated,
      'entries': entries.map((e) => e.toJson()).toList(),
      'entriesByClass': entriesByClass.map(
        (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
      ),
      'absentTeachers': absentTeachers,
      'dutyInfo': dutyInfo,
      'blockedRooms': blockedRooms,
      'uniqueClasses': uniqueClasses,
      'totalEntries': entries.length,
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
  factory ParsedSubstitutionData.fromJson(Map<String, dynamic> json) {
    return ParsedSubstitutionData(
      date: json['date'] as String,
      weekday: json['weekday'] as String,
      lastUpdated: json['lastUpdated'] as String?,
      entries: (json['entries'] as List)
          .map((e) => SubstitutionEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      absentTeachers: (json['absentTeachers'] as List?)?.cast<String>() ?? [],
      dutyInfo: json['dutyInfo'] as String?,
      blockedRooms: (json['blockedRooms'] as List?)?.cast<String>() ?? [],
    );
  }

  /// Empty data placeholder
  factory ParsedSubstitutionData.empty() {
    return const ParsedSubstitutionData(
      date: '',
      weekday: '',
      entries: [],
    );
  }

  /// Whether this data is valid (has entries)
  bool get isValid => entries.isNotEmpty && date.isNotEmpty;

  @override
  String toString() {
    return 'ParsedSubstitutionData(date: $date, weekday: $weekday, entries: ${entries.length})';
  }
}

/// Represents the state of a single substitution PDF (today or tomorrow)
class SubstitutionState {
  final bool isLoading;
  final bool hasData;
  final String? error;
  final String? weekday;
  final String? date;
  final String? lastUpdated;
  final File? file;
  final DateTime? downloadTimestamp;
  final ParsedSubstitutionData? parsedData;

  const SubstitutionState({
    this.isLoading = false,
    this.hasData = false,
    this.error,
    this.weekday,
    this.date,
    this.lastUpdated,
    this.file,
    this.downloadTimestamp,
    this.parsedData,
  });

  SubstitutionState copyWith({
    bool? isLoading,
    bool? hasData,
    String? error,
    String? weekday,
    String? date,
    String? lastUpdated,
    File? file,
    DateTime? downloadTimestamp,
    ParsedSubstitutionData? parsedData,
  }) {
    return SubstitutionState(
      isLoading: isLoading ?? this.isLoading,
      hasData: hasData ?? this.hasData,
      error: error,
      weekday: weekday,
      date: date,
      lastUpdated: lastUpdated,
      file: file,
      downloadTimestamp: downloadTimestamp ?? this.downloadTimestamp,
      parsedData: parsedData ?? this.parsedData,
    );
  }

  /// Returns true if this PDF represents a weekend/holiday (no data)
  bool get isWeekend => weekday == 'weekend';
  
  /// Returns true if this PDF can be displayed
  bool get canDisplay {
    final hasWeekday = (weekday != null && weekday!.isNotEmpty && weekday != 'weekend');
    final hasDateString = (date != null && date!.isNotEmpty);
    return hasData && hasWeekday && hasDateString && file != null;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'isLoading': isLoading,
      'hasData': hasData,
      'error': error,
      'weekday': weekday,
      'date': date,
      'lastUpdated': lastUpdated,
      'downloadTimestamp': downloadTimestamp?.toIso8601String(),
      'parsedData': parsedData?.toJson(),
    };
  }
}

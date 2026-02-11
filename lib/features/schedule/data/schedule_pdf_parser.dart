// Copyright Luka Löhr 2026

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../domain/schedule_models.dart';

/// Parser for schedule PDFs
class SchedulePdfParser {
  /// Standard lesson times for Lessing Gymnasium
  static const Map<int, LessonTime> standardLessonTimes = {
    1: LessonTime(startTime: '08:00', endTime: '08:45'),
    2: LessonTime(startTime: '08:55', endTime: '09:40'),
    3: LessonTime(startTime: '09:50', endTime: '10:35'),
    4: LessonTime(startTime: '10:55', endTime: '11:40'),
    5: LessonTime(startTime: '11:50', endTime: '12:35'),
    6: LessonTime(startTime: '12:45', endTime: '13:30'),
    7: LessonTime(startTime: '13:35', endTime: '14:20'),
    8: LessonTime(startTime: '14:25', endTime: '15:10'),
    9: LessonTime(startTime: '15:15', endTime: '16:00'),
    10: LessonTime(startTime: '16:05', endTime: '16:50'),
    11: LessonTime(startTime: '16:55', endTime: '17:40'),
  };

  /// Parse a schedule PDF and extract all class schedules
  static Future<SchoolSchedule> parseSchedulePdf(File file) async {
    return await compute(_parseInIsolate, await file.readAsBytes());
  }

  /// Parse PDF bytes in isolate
  static SchoolSchedule _parseInIsolate(List<int> bytes) {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      
      final classSchedules = <String, ClassSchedule>{};
      
      // Parse each page
      for (int pageNum = 0; pageNum < document.pages.count; pageNum++) {
        final text = extractor.extractText(
          startPageIndex: pageNum, 
          endPageIndex: pageNum,
        );
        
        final schedule = _parseClassPage(text);
        if (schedule != null) {
          classSchedules[schedule.className] = schedule;
        }
      }
      
      document.dispose();
      
      return SchoolSchedule(
        classSchedules: classSchedules,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Schedule PDF Parse Error: $e');
        print(stackTrace);
      }
      return SchoolSchedule.empty();
    }
  }

  /// Parse a single class page from extracted text
  static ClassSchedule? _parseClassPage(String text) {
    final lines = text.split('\n').map((l) => l.trim()).toList();
    
    // Find class name - look for pattern like "5a", "10b" after timestamp
    String? className;
    String? teachers;
    int classNameIndex = -1;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Look for timestamp pattern then class name
      if (line.contains(':') && line.contains('.')) {
        // Check if next line is class name
        if (i + 1 < lines.length) {
          final possibleClass = lines[i + 1];
          if (_isClassName(possibleClass)) {
            className = possibleClass;
            classNameIndex = i + 1;
            // Get teachers from line after class name
            if (i + 2 < lines.length && lines[i + 2].contains('/')) {
              teachers = lines[i + 2];
            }
            break;
          }
        }
      }
    }
    
    if (className == null || classNameIndex == -1) return null;
    
    // Find day headers
    final dayIndices = <String, int>{};
    final dayNames = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag'];
    
    for (int i = classNameIndex + 1; i < lines.length; i++) {
      final line = lines[i];
      if (dayNames.contains(line)) {
        dayIndices[line] = i;
        if (dayIndices.length == 5) break;
      }
    }
    
    if (dayIndices.length < 5) return null;
    
    // Sort days by their line index to determine column order
    final sortedDays = dayIndices.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final orderedDayNames = sortedDays.map((e) => e.key).toList();
    
    // Find period numbers (1-11)
    final periodIndices = <int, int>{};
    for (int i = classNameIndex + 6; i < lines.length; i++) {
      final line = lines[i];
      if (RegExp(r'^(\d|10|11)$').hasMatch(line)) {
        final period = int.parse(line);
        if (period >= 1 && period <= 11 && !periodIndices.containsKey(period)) {
          periodIndices[period] = i;
          if (periodIndices.length == 11) break;
        }
      }
    }
    
    if (periodIndices.isEmpty) return null;
    
    // Parse lessons
    final lessons = <ScheduleLesson>[];
    final classTeachers = teachers?.split('/').map((t) => t.trim()).toList() ?? [];
    
    // For each period, find lessons for each day
    for (final periodEntry in periodIndices.entries) {
      final periodNum = periodEntry.key;
      final periodLineIndex = periodEntry.value;
      
      // Find the next period line to determine the range
      final nextPeriodLine = periodIndices.entries
        .where((e) => e.key > periodNum)
        .map((e) => e.value)
        .fold<int>(lines.length, (min, val) => val < min ? val : min);
      
      // Get lines for this period
      final periodLines = lines.sublist(
        periodLineIndex + 1, 
        nextPeriodLine.clamp(periodLineIndex + 1, lines.length)
      );
      
      // Group lines by day based on position in the period
      // This is a simplified approach - we'll look for content and assign to days
      for (int dayIdx = 0; dayIdx < 5; dayIdx++) {
        final dayName = orderedDayNames[dayIdx];
        
        // Look for content in this period/day slot
        // Try to find subject, teacher, room
        String? subject;
        String? teacher;
        String? room;
        
        // Simple heuristic: look through period lines and try to find triplets
        for (int i = 0; i < periodLines.length - 2; i++) {
          final line1 = periodLines[i];
          final line2 = periodLines[i + 1];
          final line3 = periodLines[i + 2];
          
          // Skip if any line is a period number or day name
          if (RegExp(r'^(\d|10|11)$').hasMatch(line1)) continue;
          if (dayNames.contains(line1)) continue;
          
          // Check if this looks like a lesson (subject + teacher + room)
          if (_looksLikeSubject(line1) && 
              _looksLikeTeacher(line2) && 
              _looksLikeRoom(line3)) {
            subject = line1;
            teacher = line2;
            room = line3;
            break;
          }
        }
        
        if (subject != null && subject.isNotEmpty && subject != '.') {
          lessons.add(ScheduleLesson(
            period: periodNum,
            subject: subject,
            teacher: teacher ?? '',
            room: room ?? '',
            dayIndex: dayIdx,
            timeInfo: standardLessonTimes[periodNum],
          ));
        }
      }
    }
    
    return ClassSchedule(
      className: className,
      lessons: lessons,
      classTeachers: classTeachers,
    );
  }
  
  /// Check if string looks like a class name
  static bool _isClassName(String text) {
    return RegExp(r'^(\d+[a-z]+|[A-Z]\d+)$', caseSensitive: false).hasMatch(text);
  }
  
  /// Check if string looks like a subject
  static bool _looksLikeSubject(String text) {
    // Subjects are typically 1-4 chars, uppercase or mixed
    return text.isNotEmpty && 
           text.length <= 8 && 
           !text.contains('/') &&
           !RegExp(r'^\d+$').hasMatch(text);
  }
  
  /// Check if string looks like a teacher abbreviation
  static bool _looksLikeTeacher(String text) {
    // Teachers are typically 2-4 letters
    return text.isNotEmpty && 
           text.length <= 5 &&
           RegExp(r'^[A-Za-z.]+$').hasMatch(text);
  }
  
  /// Check if string looks like a room
  static bool _looksLikeRoom(String text) {
    // Rooms are numbers or room codes
    return text.isNotEmpty && 
           (RegExp(r'^\d+$').hasMatch(text) || 
            RegExp(r'^[A-Z]', caseSensitive: false).hasMatch(text));
  }

  /// Parse and export to JSON file
  static Future<String> parseAndExportToJson(
    File pdfFile, 
    String outputPath, {
    bool pretty = true,
  }) async {
    final schedule = await parseSchedulePdf(pdfFile);
    final file = File(outputPath);
    await file.writeAsString(schedule.toJsonString(pretty: pretty));
    return outputPath;
  }

  /// Get JSON map directly
  static Future<Map<String, dynamic>> parseToMap(File file) async {
    final schedule = await parseSchedulePdf(file);
    return schedule.toJson();
  }
}

/// Extension for JSON export
extension SchoolScheduleJson on SchoolSchedule {
  Future<void> saveToFile(String path, {bool pretty = true}) async {
    final file = File(path);
    await file.writeAsString(toJsonString(pretty: pretty));
  }
}

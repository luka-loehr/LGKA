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
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    
    // Find class name - look for pattern like "5a", "10b" after timestamp
    String? className;
    String? teachers;
    int headerEndIndex = -1;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Look for timestamp pattern then class name
      if (line.contains(':') && line.contains('.')) {
        // Check if next line is class name
        if (i + 1 < lines.length) {
          final possibleClass = lines[i + 1];
          if (_isClassName(possibleClass)) {
            className = possibleClass;
            headerEndIndex = i + 1;
            // Get teachers from line after class name
            if (i + 2 < lines.length && lines[i + 2].contains('/')) {
              teachers = lines[i + 2];
            }
            break;
          }
        }
      }
    }
    
    if (className == null || headerEndIndex == -1) return null;
    
    // Find day headers
    final dayNames = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag'];
    final dayIndices = <int>[];
    
    for (int i = headerEndIndex + 1; i < lines.length; i++) {
      final line = lines[i];
      // Match day names (Freitag might be prefixed with 'y' from PDF extraction)
      final cleanedLine = line.replaceAll(RegExp(r'^[a-z]'), '');
      if (dayNames.contains(cleanedLine)) {
        dayIndices.add(i);
        if (dayIndices.length == 5) break;
      }
    }
    
    if (dayIndices.length < 5) return null;
    
    // Find period numbers (1-11) - they come after day headers
    int periodStartIndex = -1;
    for (int i = dayIndices.last + 1; i < lines.length; i++) {
      if (lines[i] == '1') {
        // Verify it's a sequence
        bool isValid = true;
        for (int j = 1; j <= 10 && (i + j) < lines.length; j++) {
          if (lines[i + j] != (j + 1).toString()) {
            isValid = false;
            break;
          }
        }
        if (isValid) {
          periodStartIndex = i;
          break;
        }
      }
    }
    
    if (periodStartIndex == -1) return null;
    
    // Parse lessons by analyzing the data after period numbers
    final lessons = <ScheduleLesson>[];
    final classTeachers = teachers?.split('/').map((t) => t.trim()).toList() ?? [];
    
    // The data structure is: periods 1-11 listed, then subject/teacher/room triplets
    // We need to parse the grid properly
    
    // Get the data section (after period 11)
    final dataStartIndex = periodStartIndex + 11;
    if (dataStartIndex >= lines.length) return null;
    
    // Try to extract by looking at patterns in the data
    // Each period has 5 cells (one per day)
    // Each cell has: subject, teacher, room
    
    for (int periodNum = 1; periodNum <= 11; periodNum++) {
      // Find lessons for each day in this period
      for (int dayIndex = 0; dayIndex < 5; dayIndex++) {
        final lesson = _extractLessonForPeriodAndDay(
          lines, 
          dataStartIndex, 
          periodNum, 
          dayIndex,
          dayIndices,
        );
        
        if (lesson != null) {
          lessons.add(lesson);
        }
      }
    }
    
    return ClassSchedule(
      className: className,
      lessons: lessons,
      classTeachers: classTeachers,
    );
  }
  
  /// Extract a lesson for a specific period and day
  static ScheduleLesson? _extractLessonForPeriodAndDay(
    List<String> lines,
    int dataStartIndex,
    int period,
    int dayIndex,
    List<int> dayHeaderIndices,
  ) {
    // This is a simplified approach - we look for content in the data section
    // that's likely to be a lesson (subject + teacher + room pattern)
    
    // For now, return null as we need a more sophisticated parsing approach
    // The PDF extraction format makes it difficult to reliably extract table cells
    return null;
  }
  
  /// Check if string looks like a class name
  static bool _isClassName(String text) {
    return RegExp(r'^(\d+[a-e])$').hasMatch(text);
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

// Copyright Luka Löhr 2026

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../domain/schedule_models.dart';
import '../../substitution/domain/substitution_models.dart';
import 'schedule_pdf_parser.dart';

/// Service for managing school schedules
class ScheduleService {
  SchoolSchedule _schoolSchedule = SchoolSchedule.empty();
  List<SubstitutionEntry> _todaySubstitutions = [];
  List<SubstitutionEntry> _tomorrowSubstitutions = [];
  bool _isLoaded = false;

  /// Get all class names
  List<String> get classNames => _schoolSchedule.classNames;

  /// Check if schedule is loaded
  bool get isLoaded => _isLoaded;

  /// Get schedule for a specific class
  ClassSchedule? getScheduleForClass(String className) {
    return _schoolSchedule.getScheduleForClass(className);
  }

  /// Get substitutions for today
  List<SubstitutionEntry> getTodaySubstitutions(String className) {
    return _todaySubstitutions.where((s) => s.className == className).toList();
  }

  /// Get substitutions for tomorrow
  List<SubstitutionEntry> getTomorrowSubstitutions(String className) {
    return _tomorrowSubstitutions.where((s) => s.className == className).toList();
  }

  /// Get all substitutions for a class (both today and tomorrow)
  List<SubstitutionEntry> getAllSubstitutions(String className) {
    return [
      ...getTodaySubstitutions(className),
      ...getTomorrowSubstitutions(className),
    ];
  }

  /// Load schedule and substitutions from assets
  Future<void> loadFromAssets() async {
    try {
      // Load schedule data
      final scheduleJson = await rootBundle.loadString('assets/data/schedule_data.json');
      final scheduleData = jsonDecode(scheduleJson) as Map<String, dynamic>;
      _schoolSchedule = SchoolSchedule.fromJson(scheduleData);
      
      // Load substitution data
      try {
        final subJson = await rootBundle.loadString('assets/data/substitutions.json');
        final subData = jsonDecode(subJson) as Map<String, dynamic>;
        
        // Parse today's substitutions
        final todayData = subData['today'] as Map<String, dynamic>?;
        if (todayData != null) {
          final todaySubs = todayData['substitutions'] as List? ?? [];
          _todaySubstitutions = todaySubs.map((s) => _parseSubstitution(s)).toList();
        }
        
        // Parse tomorrow's substitutions
        final tomorrowData = subData['tomorrow'] as Map<String, dynamic>?;
        if (tomorrowData != null) {
          final tomorrowSubs = tomorrowData['substitutions'] as List? ?? [];
          _tomorrowSubstitutions = tomorrowSubs.map((s) => _parseSubstitution(s)).toList();
        }
      } catch (e) {
        // Substitution loading is optional
        _todaySubstitutions = [];
        _tomorrowSubstitutions = [];
      }
      
      _isLoaded = true;
    } catch (e) {
      _schoolSchedule = SchoolSchedule.empty();
      _todaySubstitutions = [];
      _tomorrowSubstitutions = [];
      _isLoaded = false;
    }
  }

  /// Parse substitution from JSON
  SubstitutionEntry _parseSubstitution(Map<String, dynamic> json) {
    return SubstitutionEntry(
      type: SubstitutionTypeExtension.fromString(json['type'] as String),
      period: json['period'] as String,
      className: json['className'] as String,
      subject: json['subject'] as String,
      room: json['room'] as String,
      substituteTeacher: json['teacher'] as String,
      originalTeacher: json['originalTeacher'] as String?,
      originalSubject: json['originalSubject'] as String?,
      originalRoom: json['originalRoom'] as String?,
      text: json['text'] as String?,
      rawText: json.toString(),
    );
  }

  /// Load schedule from PDF file
  Future<void> loadFromPdf(File file) async {
    _schoolSchedule = await SchedulePdfParser.parseSchedulePdf(file);
    _isLoaded = _schoolSchedule.classSchedules.isNotEmpty;
  }

  /// Export current schedule to JSON file
  Future<void> exportToFile(String path, {bool pretty = true}) async {
    final file = File(path);
    await file.writeAsString(_schoolSchedule.toJsonString(pretty: pretty));
  }
}

/// Singleton instance
final ScheduleService _scheduleService = ScheduleService();

/// Get schedule service instance
ScheduleService get scheduleService => _scheduleService;

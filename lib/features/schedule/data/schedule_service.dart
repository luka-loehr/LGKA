// Copyright Luka Löhr 2026

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../domain/schedule_models.dart';
import 'schedule_pdf_parser.dart';
import 'schedule_mock_data.dart';

/// Service for managing school schedules
class ScheduleService {
  SchoolSchedule _schoolSchedule = SchoolSchedule.empty();
  bool _isLoaded = false;

  /// Get all class names
  List<String> get classNames => _schoolSchedule.classNames;

  /// Check if schedule is loaded
  bool get isLoaded => _isLoaded;

  /// Get schedule for a specific class
  ClassSchedule? getScheduleForClass(String className) {
    return _schoolSchedule.getScheduleForClass(className);
  }

  /// Load mock data for testing
  void loadMockData() {
    _schoolSchedule = ScheduleMockData.getMockSchedule();
    _isLoaded = true;
  }

  /// Load schedule from asset bundle
  Future<void> loadFromAssets() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/schedule.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _schoolSchedule = SchoolSchedule.fromJson(json);
      _isLoaded = true;
    } catch (e) {
      // Fall back to mock data
      loadMockData();
    }
  }

  /// Load schedule from PDF file
  Future<void> loadFromPdf(File file) async {
    _schoolSchedule = await SchedulePdfParser.parseSchedulePdf(file);
    _isLoaded = _schoolSchedule.classSchedules.isNotEmpty;
  }

  /// Load schedule from JSON string
  Future<void> loadFromJsonString(String jsonString) async {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _schoolSchedule = SchoolSchedule.fromJson(json);
      _isLoaded = true;
    } catch (e) {
      // Fall back to mock data
      loadMockData();
    }
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

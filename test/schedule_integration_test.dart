// Comprehensive integration tests for schedule and substitutions
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgka_flutter/features/schedule/domain/schedule_models.dart';
import 'package:lgka_flutter/features/substitution/domain/substitution_models.dart';

void main() {
  group('Schedule Data Integration Tests', () {
    test('All class schedules exist and have valid structure', () async {
      final file = File('assets/data/schedule_data.json');
      expect(await file.exists(), true, reason: 'Schedule data file should exist');
      
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      // Verify structure
      expect(json.containsKey('schoolYear'), true);
      expect(json.containsKey('classSchedules'), true);
      
      final schedules = json['classSchedules'] as Map<String, dynamic>;
      
      // Should have all 23 classes
      expect(schedules.length, 23, reason: 'Should have 23 classes');
      
      // Expected classes
      final expectedClasses = [
        '5a', '5b', '5c',
        '6a', '6b', '6c',
        '7a', '7b', '7c', '7d',
        '8a', '8b', '8c', '8d',
        '9a', '9b', '9c', '9d',
        '10a', '10b', '10c', '10d', '10e',
      ];
      
      for (final className in expectedClasses) {
        expect(schedules.containsKey(className), true, 
          reason: 'Should have schedule for $className');
        
        final schedule = schedules[className] as Map<String, dynamic>;
        expect(schedule['className'], className);
        expect(schedule.containsKey('lessons'), true);
        expect(schedule.containsKey('classTeachers'), true);
        
        final lessons = schedule['lessons'] as List;
        expect(lessons.isNotEmpty, true, 
          reason: '$className should have lessons');
        
        // Verify each lesson has required fields
        for (final lesson in lessons) {
          expect(lesson['period'], isNotNull);
          expect(lesson['dayIndex'], isNotNull);
          expect(lesson['subject'], isNotNull);
        }
      }
      
      print('✓ All 23 classes validated');
      print('  Total lessons: ${schedules.values.fold<int>(0, (sum, s) => sum + (s['lessons'] as List).length)}');
    });
    
    test('Schedule can be parsed into SchoolSchedule model', () async {
      final file = File('assets/data/schedule_data.json');
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      final schoolSchedule = SchoolSchedule.fromJson(json);
      
      expect(schoolSchedule.classNames.length, 23);
      expect(schoolSchedule.schoolYear, '2025-2026');
      
      // Test 5a specifically
      final class5a = schoolSchedule.getScheduleForClass('5a');
      expect(class5a, isNotNull);
      expect(class5a!.className, '5a');
      expect(class5a.lessons.isNotEmpty, true);
      
      // Check day grouping works
      final mondayLessons = class5a.getLessonsForDay(0);
      expect(mondayLessons.isNotEmpty, true);
      
      print('✓ SchoolSchedule model works correctly');
      print('  5a has ${class5a.lessons.length} total lessons');
      print('  5a has ${mondayLessons.length} Monday lessons');
    });
    
    test('Each class has lessons for all 5 days', () async {
      final file = File('assets/data/schedule_data.json');
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final schoolSchedule = SchoolSchedule.fromJson(json);
      
      for (final className in schoolSchedule.classNames) {
        final schedule = schoolSchedule.getScheduleForClass(className)!;
        
        for (int day = 0; day < 5; day++) {
          final dayLessons = schedule.getLessonsForDay(day);
          expect(dayLessons.isNotEmpty, true, 
            reason: '$className should have lessons on day $day');
        }
      }
      
      print('✓ All classes have lessons for all 5 days');
    });
    
    test('Periods are within valid range (1-11)', () async {
      final file = File('assets/data/schedule_data.json');
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final schoolSchedule = SchoolSchedule.fromJson(json);
      
      for (final className in schoolSchedule.classNames) {
        final schedule = schoolSchedule.getScheduleForClass(className)!;
        
        for (final lesson in schedule.lessons) {
          expect(lesson.period, greaterThanOrEqualTo(1));
          expect(lesson.period, lessThanOrEqualTo(11));
        }
      }
      
      print('✓ All periods are within valid range (1-11)');
    });
  });
  
  group('Substitution Data Integration Tests', () {
    test('Substitution data exists and has valid structure', () async {
      final file = File('assets/data/substitutions.json');
      expect(await file.exists(), true, reason: 'Substitution data file should exist');
      
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      expect(json.containsKey('today'), true);
      expect(json.containsKey('tomorrow'), true);
      
      // Verify today
      final today = json['today'] as Map<String, dynamic>;
      expect(today.containsKey('date'), true);
      expect(today.containsKey('weekday'), true);
      expect(today.containsKey('substitutions'), true);
      expect(today.containsKey('absentTeachers'), true);
      
      // Verify tomorrow
      final tomorrow = json['tomorrow'] as Map<String, dynamic>;
      expect(tomorrow.containsKey('date'), true);
      expect(tomorrow.containsKey('weekday'), true);
      expect(tomorrow.containsKey('substitutions'), true);
      
      print('✓ Substitution data structure is valid');
      print('  Today: ${today['weekday']} with ${(today['substitutions'] as List).length} substitutions');
      print('  Tomorrow: ${tomorrow['weekday']} with ${(tomorrow['substitutions'] as List).length} substitutions');
    });
    
    test('Substitutions can be matched to schedule entries', () async {
      final scheduleFile = File('assets/data/schedule_data.json');
      final scheduleJson = jsonDecode(await scheduleFile.readAsString()) as Map<String, dynamic>;
      final schoolSchedule = SchoolSchedule.fromJson(scheduleJson);
      
      final subFile = File('assets/data/substitutions.json');
      final subJson = jsonDecode(await subFile.readAsString()) as Map<String, dynamic>;
      
      final todaySubs = subJson['today']['substitutions'] as List;
      
      // For each substitution, check if the class exists
      int matchedClasses = 0;
      int matchedPeriods = 0;
      
      for (final sub in todaySubs) {
        final className = sub['className'] as String;
        final period = sub['period'] as String;
        
        if (schoolSchedule.getScheduleForClass(className) != null) {
          matchedClasses++;
          
          // Check if there's a lesson at this period
          final schedule = schoolSchedule.getScheduleForClass(className)!;
          final periodNum = int.tryParse(period.split('-')[0]) ?? 0;
          
          final hasLesson = schedule.lessons.any((l) => l.period == periodNum);
          if (hasLesson) {
            matchedPeriods++;
          }
        }
      }
      
      print('✓ Substitution matching results:');
      print('  Total substitutions: ${todaySubs.length}');
      print('  Matched to existing classes: $matchedClasses');
      print('  Matched to existing periods: $matchedPeriods');
    });
  });
  
  group('End-to-End Integration Tests', () {
    test('Complete workflow: Load schedule and apply substitutions', () async {
      // Load schedule
      final scheduleFile = File('assets/data/schedule_data.json');
      final scheduleJson = jsonDecode(await scheduleFile.readAsString()) as Map<String, dynamic>;
      final schoolSchedule = SchoolSchedule.fromJson(scheduleJson);
      
      // Load substitutions
      final subFile = File('assets/data/substitutions.json');
      final subJson = jsonDecode(await subFile.readAsString()) as Map<String, dynamic>;
      final todaySubs = subJson['today']['substitutions'] as List;
      
      // Pick a class that has substitutions
      String? testClass;
      for (final sub in todaySubs) {
        final className = sub['className'] as String;
        if (schoolSchedule.getScheduleForClass(className) != null) {
          testClass = className;
          break;
        }
      }
      
      expect(testClass, isNotNull, reason: 'Should find a class with substitutions');
      
      final schedule = schoolSchedule.getScheduleForClass(testClass!)!;
      final classSubs = todaySubs.where((s) => s['className'] == testClass).toList();
      
      print('✓ End-to-end test for class $testClass:');
      print('  Total lessons: ${schedule.lessons.length}');
      print('  Substitutions: ${classSubs.length}');
      
      // Show the substitutions
      for (final sub in classSubs) {
        final period = sub['period'] as String;
        final type = sub['type'] as String;
        final subject = sub['subject'] as String;
        print('  - Period $period: $type - $subject');
      }
      
      // Verify we can find matching lessons
      for (final sub in classSubs) {
        final periodStr = sub['period'] as String;
        final period = int.tryParse(periodStr.split('-')[0]) ?? 0;
        
        final matchingLessons = schedule.lessons.where((l) => l.period == period).toList();
        expect(matchingLessons.isNotEmpty, true, 
          reason: 'Should find lesson for period $period');
      }
    });
    
    test('JSON export and re-import preserves all data', () async {
      // Load original
      final scheduleFile = File('assets/data/schedule_data.json');
      final originalJson = jsonDecode(await scheduleFile.readAsString()) as Map<String, dynamic>;
      final originalSchedule = SchoolSchedule.fromJson(originalJson);
      
      // Export to JSON string
      final exportedJson = originalSchedule.toJsonString();
      
      // Re-import
      final reimportedJson = jsonDecode(exportedJson) as Map<String, dynamic>;
      final reimportedSchedule = SchoolSchedule.fromJson(reimportedJson);
      
      // Verify data integrity
      expect(reimportedSchedule.classNames.length, originalSchedule.classNames.length);
      expect(reimportedSchedule.schoolYear, originalSchedule.schoolYear);
      
      for (final className in originalSchedule.classNames) {
        final origClass = originalSchedule.getScheduleForClass(className)!;
        final reimpClass = reimportedSchedule.getScheduleForClass(className)!;
        
        expect(reimpClass.lessons.length, origClass.lessons.length,
          reason: 'Class $className should have same number of lessons');
      }
      
      print('✓ JSON roundtrip preserves all data');
    });
  });
}

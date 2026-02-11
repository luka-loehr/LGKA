// Test to verify schedule PDF parser works correctly
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgka_flutter/features/schedule/data/schedule_pdf_parser.dart';
import 'package:lgka_flutter/features/schedule/domain/schedule_models.dart';

void main() {
  group('Schedule PDF Parser Tests', () {
    test('Parse Stundenpläne KL 5-10 2025-2026.pdf', () async {
      final file = File('Stundenpläne KL 5-10 2025-2026.pdf');
      expect(await file.exists(), true);
      
      final schedule = await SchedulePdfParser.parseSchedulePdf(file);
      
      print('\n${'='*60}');
      print('=== School Schedule ===');
      print('${'='*60}');
      print('Classes: ${schedule.classNames.join(', ')}');
      print('Total classes: ${schedule.classNames.length}');
      print('${'='*60}\n');
      
      // Print each class schedule
      for (final className in schedule.classNames.take(3)) {
        final classSchedule = schedule.getScheduleForClass(className);
        if (classSchedule != null) {
          print('\n--- Class $className ---');
          print('Teachers: ${classSchedule.classTeachers.join(', ')}');
          print('Lessons: ${classSchedule.lessons.length}');
          print('Periods: ${classSchedule.uniquePeriods.join(', ')}');
          
          // Print lessons by day
          for (final day in ['Montag', 'Dienstag', 'Mittwoch'].take(2)) {
            final dayLessons = classSchedule.lessonsByDay[day] ?? [];
            if (dayLessons.isNotEmpty) {
              print('  $day: ${dayLessons.length} lessons');
              for (final lesson in dayLessons.take(3)) {
                print('    ${lesson.period}. ${lesson.subject} (${lesson.teacher}) ${lesson.room}');
              }
            }
          }
        }
      }
      
      // Validate
      expect(schedule.classNames.isNotEmpty, true);
      expect(schedule.classSchedules.isNotEmpty, true);
    });
    
    test('Parse and generate JSON', () async {
      final file = File('Stundenpläne KL 5-10 2025-2026.pdf');
      final schedule = await SchedulePdfParser.parseSchedulePdf(file);
      
      print('\n${'='*60}');
      print('=== JSON OUTPUT (first class) ===');
      print('${'='*60}');
      
      if (schedule.classNames.isNotEmpty) {
        final firstClass = schedule.classNames.first;
        final classSchedule = schedule.getScheduleForClass(firstClass)!;
        print(classSchedule.toJson());
      }
      
      // Test full JSON export
      final json = schedule.toJson();
      expect(json.containsKey('classSchedules'), true);
      expect(json.containsKey('classNames'), true);
    });
    
    test('Export JSON to file', () async {
      final file = File('Stundenpläne KL 5-10 2025-2026.pdf');
      
      final tempDir = Directory.systemTemp;
      final outputPath = '${tempDir.path}/schedule_test.json';
      
      await SchedulePdfParser.parseAndExportToJson(file, outputPath);
      
      final outputFile = File(outputPath);
      expect(await outputFile.exists(), true);
      
      final content = await outputFile.readAsString();
      expect(content.isNotEmpty, true);
      expect(content.contains('classSchedules'), true);
      
      print('\nExported to: $outputPath');
      print('Size: ${await outputFile.length()} bytes');
      
      // Cleanup
      await outputFile.delete();
    });
    
    test('Class name sorting', () {
      final classes = ['5a', '5b', '10b', 'J11', '6c', '6a', '7b'];
      classes.sort(SchoolSchedule.compareClasses);
      
      print('\nSorted classes: ${classes.join(', ')}');
      
      // Test the sorting worked
      expect(classes.first, '5a');
      expect(classes.contains('10b'), true);
    });
  });
}

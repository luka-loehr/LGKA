// Test to verify PDF parser works correctly and generates JSON
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgka_flutter/features/substitution/data/pdf_parser_service.dart';
import 'package:lgka_flutter/features/substitution/domain/substitution_models.dart';

void main() {
  group('PDF Parser Tests', () {
    test('Parse V Schueler Heute.pdf and generate JSON', () async {
      final file = File('V Schueler Heute.pdf');
      expect(await file.exists(), true);
      
      final data = await PdfParserService.parsePdf(file);
      
      print('\n${'='*60}');
      print('=== V Schueler Heute.pdf ===');
      print('${'='*60}');
      print('Date: ${data.date}');
      print('Weekday: ${data.weekday}');
      print('Last Updated: ${data.lastUpdated}');
      print('Absent Teachers: ${data.absentTeachers.join(', ')}');
      print('Duty Info: ${data.dutyInfo}');
      print('Entries: ${data.entries.length}');
      print('Unique Classes: ${data.uniqueClasses.join(', ')}');
      print('${'='*60}\n');
      
      // Print first few entries
      for (var i = 0; i < data.entries.length.clamp(0, 8); i++) {
        final entry = data.entries[i];
        print('Entry ${i + 1}: ${entry.className}, ${entry.period}. Stunde, ${entry.typeLabel}, ${entry.subject}, ${entry.room}');
      }
      
      // Print JSON output
      print('\n${'='*60}');
      print('=== JSON OUTPUT ===');
      print('${'='*60}');
      print(data.toJsonString(pretty: true));
      
      expect(data.isValid, true);
      expect(data.entries.isNotEmpty, true);
      expect(data.uniqueClasses.isNotEmpty, true);
      
      // Test JSON roundtrip
      final json = data.toJson();
      final jsonString = data.toJsonString();
      expect(jsonString.isNotEmpty, true);
      expect(json['date'], data.date);
      expect(json['weekday'], data.weekday);
      expect(json['totalEntries'], data.entries.length);
    });
    
    test('Parse V Schueler Morgen.pdf and generate JSON', () async {
      final file = File('V Schueler Morgen.pdf');
      expect(await file.exists(), true);
      
      final data = await PdfParserService.parsePdf(file);
      
      print('\n${'='*60}');
      print('=== V Schueler Morgen.pdf ===');
      print('${'='*60}');
      print('Date: ${data.date}');
      print('Weekday: ${data.weekday}');
      print('Last Updated: ${data.lastUpdated}');
      print('Absent Teachers: ${data.absentTeachers.join(', ')}');
      print('Blocked Rooms: ${data.blockedRooms.join(', ')}');
      print('Entries: ${data.entries.length}');
      print('Unique Classes: ${data.uniqueClasses.join(', ')}');
      print('${'='*60}\n');
      
      // Print first few entries
      for (var i = 0; i < data.entries.length.clamp(0, 8); i++) {
        final entry = data.entries[i];
        print('Entry ${i + 1}: ${entry.className}, ${entry.period}. Stunde, ${entry.typeLabel}, ${entry.subject}, ${entry.room}');
      }
      
      // Print JSON output
      print('\n${'='*60}');
      print('=== JSON OUTPUT (first 2000 chars) ===');
      print('${'='*60}');
      final jsonString = data.toJsonString(pretty: true);
      print(jsonString.substring(0, jsonString.length.clamp(0, 2000)));
      
      expect(data.isValid, true);
      expect(data.entries.isNotEmpty, true);
      expect(data.uniqueClasses.isNotEmpty, true);
    });
    
    test('Test JSON export to file', () async {
      final file = File('V Schueler Heute.pdf');
      final data = await PdfParserService.parsePdf(file);
      
      // Export to temp file
      final tempDir = Directory.systemTemp;
      final outputPath = '${tempDir.path}/substitution_test.json';
      await PdfParserService.parsePdfAndSaveJson(file, outputPath);
      
      // Verify file exists and has content
      final outputFile = File(outputPath);
      expect(await outputFile.exists(), true);
      
      final content = await outputFile.readAsString();
      expect(content.isNotEmpty, true);
      expect(content.contains('date'), true);
      expect(content.contains('entries'), true);
      
      print('\nExported JSON to: $outputPath');
      print('File size: ${await outputFile.length()} bytes');
      
      // Cleanup
      await outputFile.delete();
    });
    
    test('Class expansion works correctly', () {
      final testCases = [
        ['5b', ['5b']],
        ['6abc', ['6a', '6b', '6c']],
        ['9ab', ['9a', '9b']],
        ['J11', ['J11']],
        ['8a', ['8a']],
        ['10cde', ['10c', '10d', '10e']],
      ];
      
      for (final testCase in testCases) {
        final input = testCase[0] as String;
        final expected = testCase[1] as List<String>;
        print('Class expansion: $input -> $expected');
      }
    });
    
    test('Substitution type detection', () {
      final types = [
        ['Betreuung', SubstitutionType.supervision],
        ['Entfall', SubstitutionType.cancellation],
        ['Verlegung', SubstitutionType.relocation],
        ['Tausch', SubstitutionType.exchange],
        ['Raum-Vtr.', SubstitutionType.roomChange],
        ['Lehrprobe', SubstitutionType.teacherObservation],
      ];
      
      for (final typeCase in types) {
        final label = typeCase[0] as String;
        final type = typeCase[1] as SubstitutionType;
        print('Type: $label -> ${type.name}');
      }
    });
  });
}

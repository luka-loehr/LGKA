// Debug test to understand schedule PDF structure
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  group('Schedule PDF Debug', () {
    test('Debug page structure', () async {
      final file = File('Stundenpläne KL 5-10 2025-2026.pdf');
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      
      // Get first page
      final text = extractor.extractText(startPageIndex: 0, endPageIndex: 0);
      document.dispose();
      
      print('\n=== RAW LINES ===');
      final lines = text.split('\n').map((l) => l.trim()).toList();
      for (int i = 0; i < lines.length.clamp(0, 60); i++) {
        print('$i: "${lines[i]}"');
      }
      
      // Find class name pattern
      print('\n=== LOOKING FOR CLASS NAME ===');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Test different patterns
        if (RegExp(r'^\d+[a-z]$', caseSensitive: false).hasMatch(line)) {
          print('Found pattern "5a" style at $i: "$line"');
        }
        if (RegExp(r'^[0-9]+[a-z]+$', caseSensitive: false).hasMatch(line)) {
          print('Found pattern digits+letters at $i: "$line"');
        }
      }
      
      // Find day headers
      print('\n=== DAY HEADERS ===');
      final dayNames = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag'];
      for (int i = 0; i < lines.length; i++) {
        if (dayNames.contains(lines[i])) {
          print('Day "${lines[i]}" at index $i');
        }
      }
      
      // Find period numbers
      print('\n=== PERIOD NUMBERS ===');
      for (int i = 0; i < lines.length; i++) {
        if (lines[i] == '1') {
          print('Period 1 at index $i, context: ${lines.sublist(i.clamp(0, i-2), (i+15).clamp(0, lines.length))}');
        }
      }
    });
  });
}

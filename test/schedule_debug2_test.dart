// Debug test to understand schedule PDF grid structure
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  group('Schedule PDF Grid Debug', () {
    test('Analyze grid structure', () async {
      final file = File('Stundenpläne KL 5-10 2025-2026.pdf');
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      
      final text = extractor.extractText(startPageIndex: 0, endPageIndex: 0);
      document.dispose();
      
      final lines = text.split('\n').map((l) => l.trim()).toList();
      
      // Find where the periods end (1-11)
      final periodStart = lines.indexOf('1');
      final periodEnd = lines.indexOf('11');
      
      print('Period 1 at index: $periodStart');
      print('Period 11 at index: $periodEnd');
      
      // The data starts after period 11
      final dataStart = periodEnd + 1;
      print('Data starts at index: $dataStart');
      
      // Print the next 80 lines which should be the schedule data
      print('\n=== SCHEDULE DATA (80 lines) ===');
      for (int i = dataStart; i < (dataStart + 80).clamp(0, lines.length); i++) {
        print('${i - dataStart}: ${lines[i]}');
      }
      
      // Try to understand the pattern
      // The schedule has 11 periods, 5 days = 55 cells
      // Each cell has: subject, teacher, room (3 items)
      // Total: 55 * 3 = 165 items (approximately)
      
      // But looking at the PDF, it might be organized differently
      // Let me check if data is by period or by day
      
      print('\n=== PATTERN ANALYSIS ===');
      print('Assuming 5 days x 11 periods = 55 slots');
      print('With 3 fields per slot (subject, teacher, room) = 165 lines');
      print('Actual data from index $dataStart to ${lines.length} = ${lines.length - dataStart} lines');
    });
  });
}

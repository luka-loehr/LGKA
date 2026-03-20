// Test to extract and verify real schedule PDF content
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  group('Real Schedule PDF Tests', () {
    test('Extract and analyze page 1 (5a) structure', () async {
      final file = File('Stundenpläne KL 5-10 2025-2026.pdf');
      expect(await file.exists(), true);
      
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      
      // Get page 1 (5a)
      final text = extractor.extractText(startPageIndex: 0, endPageIndex: 0);
      document.dispose();
      
      print('\n=== PAGE 1 (5a) FULL TEXT ===');
      print(text);
      
      // Verify structure
      expect(text.contains('5a'), true);
      expect(text.contains('Montag'), true);
      expect(text.contains('Dienstag'), true);
      expect(text.contains('Mittwoch'), true);
      expect(text.contains('Donnerstag'), true);
      expect(text.contains('Freitag'), true);
    });
    
    test('Extract all pages and count classes', () async {
      final file = File('Stundenpläne KL 5-10 2025-2026.pdf');
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      
      final classes = <String>[];
      
      for (int i = 0; i < document.pages.count; i++) {
        final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        final lines = text.split('\n').map((l) => l.trim()).toList();
        
        // Find class name (line after timestamp)
        for (int j = 0; j < lines.length; j++) {
          if (lines[j].contains(':') && lines[j].contains('.')) {
            // This looks like a timestamp, next line should be class
            if (j + 1 < lines.length) {
              final possibleClass = lines[j + 1];
              if (RegExp(r'^\d+[a-e]$').hasMatch(possibleClass)) {
                classes.add(possibleClass);
                print('Page ${i + 1}: Class $possibleClass');
                break;
              }
            }
          }
        }
      }
      
      document.dispose();
      
      print('\nTotal classes found: ${classes.length}');
      print('Classes: ${classes.join(', ')}');
      
      expect(classes.length, 23); // 5a-5c, 6a-6c, 7a-7d, 8a-8d, 9a-9d, 10a-10e
    });
    
    test('Parse table structure from page 1', () async {
      final file = File('Stundenpläne KL 5-10 2025-2026.pdf');
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      
      final text = extractor.extractText(startPageIndex: 0, endPageIndex: 0);
      document.dispose();
      
      final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      
      print('\n=== STRUCTURED LINES ===');
      for (int i = 0; i < lines.length; i++) {
        print('$i: "${lines[i]}"');
      }
      
      // Find period numbers
      final periodIndices = <int>[];
      for (int i = 0; i < lines.length; i++) {
        if (RegExp(r'^(\d|10|11)$').hasMatch(lines[i])) {
          periodIndices.add(i);
        }
      }
      
      print('\nPeriod indices: $periodIndices');
      expect(periodIndices.length >= 11, true); // Should have periods 1-11
    });
  });
}

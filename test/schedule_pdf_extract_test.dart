// Test to extract schedule PDF content
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  group('Schedule PDF Extraction', () {
    test('Extract text from Stundenpläne KL 5-10 2025-2026.pdf', () async {
      final file = File('Stundenpläne KL 5-10 2025-2026.pdf');
      expect(await file.exists(), true);
      
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      
      // Extract first few pages
      for (int pageNum = 0; pageNum < document.pages.count.clamp(0, 5); pageNum++) {
        final text = extractor.extractText(startPageIndex: pageNum, endPageIndex: pageNum);
        
        print('\n${'='*60}');
        print('=== Page ${pageNum + 1} ===');
        print('${'='*60}');
        print(text.substring(0, text.length.clamp(0, 3000)));
        print('...');
      }
      
      document.dispose();
    });
  });
}

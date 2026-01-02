import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import '../models/search_result.dart';
import '../../../../utils/app_logger.dart';

/// Service for searching text within PDF documents.
class PdfSearchService {
  /// Searches for a query string in the PDF file.
  /// Returns a list of [SearchResult] objects containing matches.
  static Future<List<SearchResult>> searchInPdf(
    File pdfFile,
    String query,
  ) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final bytes = await pdfFile.readAsBytes();
      final document = syncfusion.PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      final results = <SearchResult>[];

      for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        try {
          final textExtractor = syncfusion.PdfTextExtractor(document);
          final pageText = textExtractor.extractText(
            startPageIndex: pageIndex,
            endPageIndex: pageIndex,
          );

          if (pageText.toLowerCase().contains(query.toLowerCase())) {
            // Find all occurrences on this page
            final lowerText = pageText.toLowerCase();
            final lowerQuery = query.toLowerCase();
            int startIndex = 0;

            while (true) {
              final index = lowerText.indexOf(lowerQuery, startIndex);
              if (index == -1) break;

              // Get context around the match
              final contextStart = (index - 20).clamp(0, pageText.length);
              final contextEnd =
                  (index + query.length + 20).clamp(0, pageText.length);
              final context = pageText.substring(contextStart, contextEnd);

              results.add(SearchResult(
                pageNumber: pageIndex + 2, // +2 to fix the offset
                context: context,
                query: query,
                matchIndex: index - contextStart,
              ));

              startIndex = index + 1;
            }
          }
        } catch (e) {
          // Skip pages with extraction errors
          AppLogger.debug(
            'Error extracting text from page $pageIndex: $e',
            module: 'PdfSearchService',
          );
          continue;
        }
      }

      document.dispose();

      AppLogger.search('Search completed: ${results.length} results for "$query"');
      return results;
    } catch (e) {
      AppLogger.error('Error searching in PDF: $e', module: 'PdfSearchService');
      rethrow;
    }
  }

  /// Checks if a class/query exists in the PDF document.
  /// Returns true if the query is found, false otherwise.
  static Future<bool> checkQueryExistsInPdf(
    File pdfFile,
    String query,
  ) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = syncfusion.PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;

      final textExtractor = syncfusion.PdfTextExtractor(document);
      final allText = textExtractor.extractText(
        startPageIndex: 0,
        endPageIndex: pageCount - 1,
      );

      document.dispose();

      // Check if query exists in PDF (case-insensitive)
      return allText.toLowerCase().contains(query.toLowerCase());
    } catch (e) {
      AppLogger.debug(
        'Error checking query in PDF: $e',
        module: 'PdfSearchService',
      );
      // If validation fails, allow proceeding anyway (fail gracefully)
      return true;
    }
  }
}

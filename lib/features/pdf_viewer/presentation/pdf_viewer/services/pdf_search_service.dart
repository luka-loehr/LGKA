import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import '../models/search_result.dart';
import '../../../../../utils/app_logger.dart';

/// Data class for passing search parameters to isolate
class _SearchParams {
  final String pdfPath;
  final String query;

  _SearchParams(this.pdfPath, this.query);
}

/// Top-level function for searching in PDF in background isolate
Future<List<SearchResult>> _searchInPdfIsolate(_SearchParams params) async {
  try {
    final file = File(params.pdfPath);
    final bytes = await file.readAsBytes();
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

        if (pageText.toLowerCase().contains(params.query.toLowerCase())) {
          // Find all occurrences on this page
          final lowerText = pageText.toLowerCase();
          final lowerQuery = params.query.toLowerCase();
          int startIndex = 0;

          while (true) {
            final index = lowerText.indexOf(lowerQuery, startIndex);
            if (index == -1) break;

            // Get context around the match
            final contextStart = (index - 20).clamp(0, pageText.length);
            final contextEnd =
                (index + params.query.length + 20).clamp(0, pageText.length);
            final context = pageText.substring(contextStart, contextEnd);

            results.add(SearchResult(
              pageNumber: pageIndex + 2, // +2 to fix the offset
              context: context,
              query: params.query,
              matchIndex: index - contextStart,
            ));

            startIndex = index + 1;
          }
        }
      } catch (e) {
        // Skip pages with extraction errors
        continue;
      }
    }

    document.dispose();
    return results;
  } catch (e) {
    return [];
  }
}

/// Top-level function for checking if query exists in PDF in background isolate
Future<bool> _checkQueryExistsIsolate(_SearchParams params) async {
  try {
    final file = File(params.pdfPath);
    final bytes = await file.readAsBytes();
    final document = syncfusion.PdfDocument(inputBytes: bytes);
    final pageCount = document.pages.count;

    final textExtractor = syncfusion.PdfTextExtractor(document);
    final allText = textExtractor.extractText(
      startPageIndex: 0,
      endPageIndex: pageCount - 1,
    );

    document.dispose();

    // Check if query exists in PDF (case-insensitive)
    return allText.toLowerCase().contains(params.query.toLowerCase());
  } catch (e) {
    // If validation fails, allow proceeding anyway (fail gracefully)
    return true;
  }
}

/// Service for searching text within PDF documents.
class PdfSearchService {
  /// Searches for a query string in the PDF file.
  /// Returns a list of [SearchResult] objects containing matches.
  /// Runs in a background isolate to avoid blocking the UI.
  static Future<List<SearchResult>> searchInPdf(
    File pdfFile,
    String query,
  ) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      AppLogger.debug('Starting PDF search in background isolate for "$query"', module: 'PdfSearchService');
      
      // Run the heavy PDF search in a background isolate
      final results = await compute(
        _searchInPdfIsolate,
        _SearchParams(pdfFile.path, query.trim()),
      );

      AppLogger.search('Search completed: ${results.length} results for "$query"');
      return results;
    } catch (e) {
      AppLogger.error('Error searching in PDF: $e', module: 'PdfSearchService');
      rethrow;
    }
  }

  /// Checks if a class/query exists in the PDF document.
  /// Returns true if the query is found, false otherwise.
  /// Runs in a background isolate to avoid blocking the UI.
  static Future<bool> checkQueryExistsInPdf(
    File pdfFile,
    String query,
  ) async {
    try {
      AppLogger.debug('Checking query existence in background isolate for "$query"', module: 'PdfSearchService');
      
      // Run the heavy PDF validation in a background isolate
      final exists = await compute(
        _checkQueryExistsIsolate,
        _SearchParams(pdfFile.path, query.trim()),
      );

      return exists;
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

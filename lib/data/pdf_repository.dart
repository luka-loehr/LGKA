// Copyright Luka Löhr 2025

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Represents the state of a single PDF (today or tomorrow)
class PdfState {
  final bool isLoading;
  final bool hasData;
  final String? error;
  final String? weekday;
  final String? date;
  final String? lastUpdated;
  final File? file;

  const PdfState({
    this.isLoading = false,
    this.hasData = false,
    this.error,
    this.weekday,
    this.date,
    this.lastUpdated,
    this.file,
  });

  PdfState copyWith({
    bool? isLoading,
    bool? hasData,
    String? error,
    String? weekday,
    String? date,
    String? lastUpdated,
    File? file,
  }) {
    return PdfState(
      isLoading: isLoading ?? this.isLoading,
      hasData: hasData ?? this.hasData,
      error: error,
      weekday: weekday,
      date: date,
      lastUpdated: lastUpdated,
      file: file,
    );
  }

  /// Returns true if this PDF represents a weekend/holiday (no data)
  bool get isWeekend => weekday == 'weekend';
  
  /// Returns true if this PDF can be displayed
  bool get canDisplay => hasData && !isWeekend && file != null;
}

/// Repository for managing PDF substitution plans
class PdfRepository extends ChangeNotifier {
  static const String _username = 'vertretungsplan';
  static const String _password = 'ephraim';
  static const String _todayUrl = 'https://lessing-gymnasium-karlsruhe.de/stundenplan/schueler/v_schueler_heute.pdf';
  static const String _tomorrowUrl = 'https://lessing-gymnasium-karlsruhe.de/stundenplan/schueler/v_schueler_morgen.pdf';
  static const Duration _timeout = Duration(seconds: 10);

  PdfState _todayState = const PdfState();
  PdfState _tomorrowState = const PdfState();
  bool _isInitialized = false;

  PdfRepository(Ref ref);

  // Getters
  PdfState get todayState => _todayState;
  PdfState get tomorrowState => _tomorrowState;
  bool get isInitialized => _isInitialized;
  bool get hasAnyData => _todayState.hasData || _tomorrowState.hasData;
  bool get hasAnyError => _todayState.error != null || _tomorrowState.error != null;
  bool get isLoading => _todayState.isLoading || _tomorrowState.isLoading;

  /// Initialize the repository by loading both PDFs
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadBothPdfs();
    _isInitialized = true;
    notifyListeners();
  }

  /// Load both PDFs simultaneously
  Future<void> _loadBothPdfs() async {
    final futures = [
      _loadPdf(_todayUrl, true),
      _loadPdf(_tomorrowUrl, false),
    ];

    await Future.wait(futures);
  }

  /// Load a single PDF and update its state
  Future<void> _loadPdf(String url, bool isToday) async {
    final state = isToday ? _todayState : _tomorrowState;
    
    // Set loading state
    _updatePdfState(isToday, state.copyWith(isLoading: true, error: null));
    
    try {
      final file = await _downloadPdf(url);
      final metadata = await _extractMetadata(file);
      
      // Update state with success
      _updatePdfState(isToday, PdfState(
        isLoading: false,
        hasData: true,
        weekday: metadata['weekday'],
        date: metadata['date'],
        lastUpdated: metadata['lastUpdated'],
        file: file,
      ));
      
    } catch (e) {
      // Update state with error
      _updatePdfState(isToday, state.copyWith(
        isLoading: false,
        error: 'Verbindung fehlgeschlagen',
      ));
    }
  }

  /// Download PDF from URL with authentication
  Future<File> _downloadPdf(String url) async {
    final credentials = base64Encode(utf8.encode('$_username:$_password'));
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic $credentials',
        'User-Agent': 'LGKA-App-Luka-Loehr',
      },
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    // Save to temporary directory
    final cacheDir = await getTemporaryDirectory();
    final filename = url.contains('heute') ? 'today.pdf' : 'tomorrow.pdf';
    final file = File('${cacheDir.path}/$filename');
    
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  /// Extract metadata from PDF file
  Future<Map<String, String>> _extractMetadata(File file) async {
    return await compute(_extractPdfData, await file.readAsBytes());
  }

  /// Update the state of a specific PDF and notify listeners
  void _updatePdfState(bool isToday, PdfState newState) {
    if (isToday) {
      _todayState = newState;
    } else {
      _tomorrowState = newState;
    }
    notifyListeners();
  }

  /// Retry loading a specific PDF
  Future<void> retryPdf(bool isToday) async {
    final url = isToday ? _todayUrl : _tomorrowUrl;
    await _loadPdf(url, isToday);
  }

  /// Retry loading both PDFs
  Future<void> retryAll() async {
    await _loadBothPdfs();
  }

  /// Refresh all PDFs (force reload)
  Future<void> refresh() async {
    _isInitialized = false;
    await initialize();
  }

  /// Get the file for a specific PDF if available
  File? getPdfFile(bool isToday) {
    final state = isToday ? _todayState : _tomorrowState;
    return state.file;
  }

  /// Check if a PDF can be opened
  bool canOpenPdf(bool isToday) {
    final state = isToday ? _todayState : _tomorrowState;
    return state.canDisplay;
  }
}

/// Extract PDF data in background isolate
Map<String, String> _extractPdfData(List<int> bytes) {
  try {
    final document = PdfDocument(inputBytes: bytes);
    final textExtractor = PdfTextExtractor(document);
    final text = textExtractor.extractText(startPageIndex: 0, endPageIndex: 0);
    document.dispose();

    // Check if PDF is empty (weekend/holiday)
    if (text.trim().length < 50) {
      return {
        'weekday': 'weekend',
        'date': '',
        'lastUpdated': '',
      };
    }

    // Extract date and weekday from "23.6. / Montag" format
    final planPattern = RegExp(
      r'(\d{1,2}\.\d{1,2}\.)\s*\/\s*(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)',
      caseSensitive: false,
    );
    
    final planMatch = planPattern.firstMatch(text);
    String weekday = '';
    String date = '';
    
    if (planMatch != null) {
      final partialDate = planMatch.group(1)!;
      weekday = planMatch.group(2)!;

      // Extract year from the date context, not from anywhere in the text
      // Look for year in the same line or nearby context as the date
      final dateContextPattern = RegExp(r'(\d{1,2}\.\d{1,2}\.)\s*\/\s*(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag).*?(\d{4})', caseSensitive: false, dotAll: true);
      final dateContextMatch = dateContextPattern.firstMatch(text);
      
      if (dateContextMatch != null) {
        date = '$partialDate${dateContextMatch.group(3)}';
      } else {
        // If no year found in context, use current year
        final currentYear = DateTime.now().year;
        date = '$partialDate$currentYear';
      }

      // Normalize date format: ensure month has leading zero
      date = date.replaceAllMapped(
        RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})'),
        (match) {
          final day = match.group(1)!.padLeft(2, '0');
          final month = match.group(2)!.padLeft(2, '0');
          final year = match.group(3);
          return '$day.$month.$year';
        },
      );

      // Debug: Print the extracted date
      debugPrint('DEBUG: Extracted date: "$date" from partial: "$partialDate"');
      debugPrint('DEBUG: Full text for context: "${text.substring(0, text.length > 200 ? 200 : text.length)}"');
    } else {
      // Fallback patterns - look for complete date format first
      final completeDatePattern = RegExp(r'(\d{1,2}\.\d{1,2}\.\d{4})');
      final completeDateMatch = completeDatePattern.firstMatch(text);
      if (completeDateMatch != null) {
        date = completeDateMatch.group(1)!;
      } else {
        // If no complete date, try to find weekday and partial date separately
        final weekdayPattern = RegExp(r'(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)', caseSensitive: false);
        final weekdayMatch = weekdayPattern.firstMatch(text);
        weekday = weekdayMatch?.group(1) ?? '';
        
        // Look for partial date near the weekday
        final partialDatePattern = RegExp(r'(\d{1,2}\.\d{1,2}\.)');
        final partialDateMatch = partialDatePattern.firstMatch(text);
        if (partialDateMatch != null) {
          // Use current year for partial dates
          final currentYear = DateTime.now().year;
          date = '${partialDateMatch.group(1)}$currentYear';
        }
      }

      // Also normalize fallback date format
      if (date.isNotEmpty) {
        date = date.replaceAllMapped(
          RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})'),
          (match) {
            final day = match.group(1)!.padLeft(2, '0');
            final month = match.group(2)!.padLeft(2, '0');
            final year = match.group(3);
            return '$day.$month.$year';
          },
        );
      }

      // Debug: Print the fallback extracted date
      debugPrint('DEBUG: Fallback extracted date: "$date"');
      debugPrint('DEBUG: Fallback weekday: "$weekday"');
    }

    // Extract last updated timestamp
    final timestampPattern = RegExp(r'(\d{1,2}\.\d{1,2}\.\d{4}\s+\d{1,2}:\d{2})');
    final timestampMatch = timestampPattern.firstMatch(text);
    final lastUpdated = timestampMatch?.group(1) ?? '';

    return {
      'weekday': weekday,
      'date': date,
      'lastUpdated': lastUpdated,
    };
  } catch (e) {
    return {
      'weekday': '',
      'date': '',
      'lastUpdated': '',
    };
  }
} 
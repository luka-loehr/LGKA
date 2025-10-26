// Copyright Luka Löhr 2025

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../utils/app_info.dart';
import '../config/app_credentials.dart';

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
  bool get canDisplay {
    final hasWeekday = (weekday != null && weekday!.isNotEmpty && weekday != 'weekend');
    final hasDateString = (date != null && date!.isNotEmpty);
    return hasData && hasWeekday && hasDateString && file != null;
  }
}

/// Repository for managing PDF substitution plans
class PdfRepository extends ChangeNotifier {
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
        error: 'Serververbindung fehlgeschlagen',
      ));
    }
  }

  /// Download PDF from URL with authentication
  Future<File> _downloadPdf(String url) async {
    final credentials = base64Encode(utf8.encode('${AppCredentials.username}:${AppCredentials.password}'));
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic $credentials',
        'User-Agent': AppInfo.userAgent,
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
    String text = textExtractor.extractText(startPageIndex: 0, endPageIndex: 0);
    // Normalize text to improve regex robustness
    text = text
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '') // zero-width chars
        .replaceAll('\u00A0', ' ') // NBSP to space
        .replaceAll('\u202F', ' ') // narrow NBSP
        .replaceAll('\u2060', '') // word joiner
        .replaceAll('\u2044', '/') // fraction slash to normal slash
        .replaceAll('\u2215', '/') // division slash to normal slash
        // Normalize dash/hyphen variants to '-'
        .replaceAll('\u2010', '-') // hyphen
        .replaceAll('\u2011', '-') // non-breaking hyphen
        .replaceAll('\u2012', '-') // figure dash
        .replaceAll('\u2013', '-') // en dash
        .replaceAll('\u2212', '-') // minus
        .replaceAll(RegExp(r'\s+/\s+'), ' / ') // normalize around slash
        .replaceAll(RegExp(r'\s+'), ' ') // collapse whitespace
        .trim();
    document.dispose();

    // Check if PDF is empty (weekend/holiday)
    if (text.trim().length < 50) {
      return {
        'weekday': 'weekend',
        'date': '',
        'lastUpdated': '',
      };
    }

    // Prefer extracting from the header line: "Lessing-Klassen  19.9. / Freitag"
    String weekday = '';
    String date = '';
    String? detectedYearFromFooter;

    // Try to read academic footer date like "19.9.2025 (38)"
    final footerMatch = RegExp(r'\b(\d{1,2})\.(\d{1,2})\.((?:19|20)\d{2})\b\s*\(\d+\)')
        .firstMatch(text);
    if (footerMatch != null) {
      detectedYearFromFooter = footerMatch.group(3);
    }

    // Header pattern strictly scoped to the title line (robust against other dates on page)
    final headerPattern = RegExp(
      r'Lessing\S*Klassen\s+(\d{1,2}\.\d{1,2}\.)\s*\/\s*(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)\b',
      caseSensitive: false,
    );
    final headerMatch = headerPattern.firstMatch(text);
    if (headerMatch != null) {
      final partialDate = headerMatch.group(1)!;
      weekday = headerMatch.group(2)!;
      final year = detectedYearFromFooter ?? DateTime.now().year.toString();
      date = '$partialDate$year';
      // Also log the header line around the match for verification
      final lineStart = text.lastIndexOf('\n', headerMatch.start);
      final lineEnd = text.indexOf('\n', headerMatch.end);
    } else {
      // Fallback specifically on the header line if pattern failed due to stray characters
      final headerLineMatch = RegExp(r'Lessing\S*Klassen[^\n]+', caseSensitive: false)
          .firstMatch(text);
      if (headerLineMatch != null) {
        final headerLine = headerLineMatch.group(0)!;
        final partialDate = RegExp(r'(\d{1,2}\.\d{1,2}\.)').firstMatch(headerLine)?.group(1);
        final weekdayLoose = RegExp(
          r'(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)',
          caseSensitive: false,
        ).firstMatch(headerLine)?.group(1);
        if (partialDate != null && weekdayLoose != null) {
          weekday = weekdayLoose;
          final year = detectedYearFromFooter ?? DateTime.now().year.toString();
          date = '$partialDate$year';
        }
      }
    }

    // Pattern A: "Freitag, 19.09.2025" or "Freitag 19.09.2025"
    final patternA = RegExp(
      r'(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)[,\s]+(\d{1,2}\.\d{1,2}\.(?:\d{2}|\d{4}))',
      caseSensitive: false,
    );
    final matchA = patternA.firstMatch(text);

    // Pattern B: "19.9. / Freitag" possibly without year right there
    final patternB = RegExp(
      r'(\d{1,2}\.\d{1,2}\.)\s*\/\s*(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)',
      caseSensitive: false,
    );
    final matchB = patternB.firstMatch(text);

    if (date.isEmpty && matchA != null) {
      weekday = matchA.group(1)!;
      date = matchA.group(2)!;
      // Normalize 2-digit year to 4-digit by assuming 2000+
      date = date.replaceAllMapped(
        RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{2})$'),
        (m) => '${m.group(1)!.padLeft(2, '0')}.${m.group(2)!.padLeft(2, '0')}.20${m.group(3)}',
      );
    } else if (date.isEmpty && matchB != null) {
      final partialDate = matchB.group(1)!; // with trailing dot
      weekday = matchB.group(2)!;

      // Find a 4-digit year near this match to avoid picking up unrelated numbers
      final start = (matchB.start - 200).clamp(0, text.length);
      final end = (matchB.end + 200).clamp(0, text.length);
      final localContext = text.substring(start as int, end as int);
      // Prefer real years only (19xx or 20xx). This avoids picking up '7613' from ZIP '76135'.
      final yearInContext = RegExp(r'\b(19|20)\d{2}\b').firstMatch(localContext)?.group(0);

      // As a more reliable fallback, use the document timestamp year if present
      final tsYear = RegExp(r'\b\d{1,2}\.\d{1,2}\.(\d{4})\s+\d{1,2}:\d{2}\b')
          .firstMatch(text)
          ?.group(1);

      final year = (detectedYearFromFooter ?? yearInContext ?? tsYear) ?? DateTime.now().year.toString();
      date = '$partialDate$year';
    } else if (date.isEmpty) {
      // Fallback: try to find both independently, preferring weekday first
      final weekdayOnly = RegExp(r'(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)', caseSensitive: false)
          .firstMatch(text);
      if (weekdayOnly != null) {
        weekday = weekdayOnly.group(1)!;
        // Try to find a complete date near the weekday mention
        final start = (weekdayOnly.start - 200).clamp(0, text.length);
        final end = (weekdayOnly.end + 200).clamp(0, text.length);
        final localContext = text.substring(start as int, end as int);
        final dateNearby = RegExp(r'(\d{1,2})\.(\d{1,2})\.((?:19|20)\d{2})').firstMatch(localContext);
        if (dateNearby != null) {
          date = '${dateNearby.group(1)!.padLeft(2, '0')}.${dateNearby.group(2)!.padLeft(2, '0')}.${dateNearby.group(3)}';
        }
      }
      // As a last resort, look for any full date on the page
      if (date.isEmpty) {
        final anyDate = RegExp(r'(\d{1,2})\.(\d{1,2})\.(19|20)\d{2}')
            .firstMatch(text);
        if (anyDate != null) {
          date = '${anyDate.group(1)!.padLeft(2, '0')}.${anyDate.group(2)!.padLeft(2, '0')}.${anyDate.group(0)!.split('.').last}';
        }
      }
    }

    // Normalize date format if present
    if (date.isNotEmpty) {
      date = date.replaceAllMapped(
        RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$'),
        (m) => '${m.group(1)!.padLeft(2, '0')}.${m.group(2)!.padLeft(2, '0')}.${m.group(3)}',
      );
    }

    // Fallback: if weekday missing but date present, derive weekday from date
    if ((weekday.isEmpty || weekday == 'weekend') && date.isNotEmpty) {
      final m = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(date);
      if (m != null) {
        final day = int.parse(m.group(1)!);
        final month = int.parse(m.group(2)!);
        final year = int.parse(m.group(3)!);
        try {
          final dt = DateTime(year, month, day);
          const deWeekdays = {
            DateTime.monday: 'Montag',
            DateTime.tuesday: 'Dienstag',
            DateTime.wednesday: 'Mittwoch',
            DateTime.thursday: 'Donnerstag',
            DateTime.friday: 'Freitag',
            DateTime.saturday: 'Samstag',
            DateTime.sunday: 'Sonntag',
          };
          weekday = deWeekdays[dt.weekday] ?? '';
        } catch (_) {
          // ignore invalid dates
        }
      }
    }

    // Normalize weekday capitalization (first letter uppercase, rest lowercase)
    if (weekday.isNotEmpty && weekday != 'weekend') {
      final lower = weekday.toLowerCase();
      weekday = lower[0].toUpperCase() + lower.substring(1);
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

/// Debug helper to reuse the same parsing in tooling/tests
Map<String, String> debugExtractPdfDataFromBytes(List<int> bytes) {
  return _extractPdfData(bytes);
}
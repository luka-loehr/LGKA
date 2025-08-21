// Copyright Luka Löhr 2025


import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';


class PdfRepository extends ChangeNotifier {
  static const String _username = 'vertretungsplan';
  static const String _password = 'ephraim';
  static const String todayUrl = 'https://lessing-gymnasium-karlsruhe.de/stundenplan/schueler/v_schueler_heute.pdf';
  static const String tomorrowUrl = 'https://lessing-gymnasium-karlsruhe.de/stundenplan/schueler/v_schueler_morgen.pdf';
  
  // Keep legacy filenames for backwards compatibility during migration
  static const String todayFilename = 'today.pdf';
  static const String tomorrowFilename = 'tomorrow.pdf';

  // Private variables for storing data
  String _todayWeekday = '';
  String _tomorrowWeekday = '';
  String _todayLastUpdated = '';
  String _tomorrowLastUpdated = '';
  String _todayDate = '';
  String _tomorrowDate = '';
  bool _weekdaysLoaded = false;
  bool _isLoading = false;
  bool _showLoadingBar = false;
  String? _error;

  // Individual PDF states
  bool _todayLoading = false;
  bool _tomorrowLoading = false;
  String? _todayError;
  String? _tomorrowError;


  // Getters for accessing the data
  String get todayWeekday => _todayWeekday;
  String get tomorrowWeekday => _tomorrowWeekday;
  String get todayLastUpdated => _todayLastUpdated;
  String get tomorrowLastUpdated => _tomorrowLastUpdated;
  String get todayDate => _todayDate;
  String get tomorrowDate => _tomorrowDate;
  bool get weekdaysLoaded => _weekdaysLoaded;
  bool get isLoading => _isLoading;
  bool get showLoadingBar => _showLoadingBar;
  String? get error => _error;

  // Individual PDF getters
  bool get todayLoading => _todayLoading;
  bool get tomorrowLoading => _tomorrowLoading;
  String? get todayError => _todayError;
  String? get tomorrowError => _tomorrowError;

  // Derived state for UI logic
  bool get hasAnyData => _todayWeekday.isNotEmpty || _tomorrowWeekday.isNotEmpty;
  bool get shouldShowError => false; // Never show global error - just grey out buttons
  bool get hasTodayData => _todayWeekday.isNotEmpty;
  bool get hasTomorrowData => _tomorrowWeekday.isNotEmpty;

  
  // Dynamic filename getters based on weekdays
  String get todayPdfFilename => _todayWeekday.isNotEmpty ? '${_todayWeekday.toLowerCase()}.pdf' : todayFilename;
  String get tomorrowPdfFilename => _tomorrowWeekday.isNotEmpty ? '${_tomorrowWeekday.toLowerCase()}.pdf' : tomorrowFilename;



  /// Enhanced method to download PDF with weekday-based naming
  Future<File?> downloadPdfWithWeekdayName(String url, bool isToday, {bool forceReload = false}) async {
    try {
      // First, try to get the weekday-named file if we already have weekday info
      String targetFilename;
      if (isToday && _todayWeekday.isNotEmpty) {
        targetFilename = todayPdfFilename;
      } else if (!isToday && _tomorrowWeekday.isNotEmpty) {
        targetFilename = tomorrowPdfFilename;
      } else {
        // Use legacy names for initial download
        targetFilename = isToday ? todayFilename : tomorrowFilename;
      }

      final cacheDir = await getTemporaryDirectory();
      final file = File('${cacheDir.path}/$targetFilename');

      // Check if file exists and is not empty (unless force reload)
      if (!forceReload && file.existsSync() && file.lengthSync() > 0) {
        debugPrint('Using cached PDF file: $targetFilename');
        return file;
      }


      
      // Download with basic auth and timeout
      final credentials = base64Encode(utf8.encode('$_username:$_password'));
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Basic $credentials',
          'User-Agent': 'LGKA-Flutter-App/1.0',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint('Failed to download PDF: ${response.statusCode}');
        return null;
      }

      // Extract weekday info first before saving
      final tempBytes = response.bodyBytes;
      final result = await _extractPdfDataInIsolate(tempBytes);
      
      // Update weekday info
      if (isToday) {
        _todayWeekday = result['weekday'] ?? '';
        _todayLastUpdated = result['dateTime'] ?? '';
        _todayDate = result['date'] ?? '';
        debugPrint('Extracted for today - weekday: $_todayWeekday, dateTime: $_todayLastUpdated, date: $_todayDate');
      } else {
        _tomorrowWeekday = result['weekday'] ?? '';
        _tomorrowLastUpdated = result['dateTime'] ?? '';
        _tomorrowDate = result['date'] ?? '';
        debugPrint('Extracted for tomorrow - weekday: $_tomorrowWeekday, dateTime: $_tomorrowLastUpdated, date: $_tomorrowDate');
      }

      // Now determine the final filename based on extracted weekday
      final finalFilename = isToday ? todayPdfFilename : tomorrowPdfFilename;
      final finalFile = File('${cacheDir.path}/$finalFilename');

      // Save PDF with weekday-based filename
      await finalFile.writeAsBytes(tempBytes);
      debugPrint('Successfully downloaded and saved PDF as: $finalFilename');

      // Clean up any old legacy files
      if (finalFilename != targetFilename) {
        final oldFile = File('${cacheDir.path}/$targetFilename');
        if (await oldFile.exists()) {
          await oldFile.delete();
          debugPrint('Cleaned up old file: $targetFilename');
        }
      }



      _checkIfBothDaysLoaded();
      notifyListeners();

      return finalFile;
    } catch (e) {
      debugPrint('Error downloading PDF with weekday name: $e');
      return null;
    }
  }

  /// Extracts both weekday and datetime from PDF in background isolate
  Future<void> _extractMetadataFromPdf(File file, bool isToday) async {
    try {
      final bytes = await file.readAsBytes();
      final result = await _extractPdfDataInIsolate(bytes);

      if (isToday) {
        _todayWeekday = result['weekday'] ?? '';
        _todayLastUpdated = result['dateTime'] ?? '';
        _todayDate = result['date'] ?? '';
        debugPrint('Extracted for today - weekday: $_todayWeekday, dateTime: $_todayLastUpdated, date: $_todayDate');
      } else {
        _tomorrowWeekday = result['weekday'] ?? '';
        _tomorrowLastUpdated = result['dateTime'] ?? '';
        _tomorrowDate = result['date'] ?? '';
        debugPrint('Extracted for tomorrow - weekday: $_tomorrowWeekday, dateTime: $_tomorrowLastUpdated, date: $_tomorrowDate');
      }

      _checkIfBothDaysLoaded();
      notifyListeners();
    } catch (e) {
      debugPrint('Error extracting metadata from PDF: $e');
      if (isToday) {
        _todayWeekday = '';
        _todayLastUpdated = '';
        _todayDate = '';
      } else {
        _tomorrowWeekday = '';
        _tomorrowLastUpdated = '';
        _tomorrowDate = '';
      }
    }
  }

  /// Loads weekday information from cached PDFs (checks both legacy and weekday-named files)
  Future<void> loadWeekdaysFromCachedPdfs() async {
    // Try weekday-named files first, then fall back to legacy names
    File? todayFile = await getCachedPdf(todayPdfFilename);
    todayFile ??= await getCachedPdf(todayFilename);
    
    if (todayFile != null) {
      await _extractMetadataFromPdf(todayFile, true);
    }

    File? tomorrowFile = await getCachedPdf(tomorrowPdfFilename);
    tomorrowFile ??= await getCachedPdf(tomorrowFilename);
    
    if (tomorrowFile != null) {
      await _extractMetadataFromPdf(tomorrowFile, false);
    }

    _checkIfBothDaysLoaded();
  }

  /// Gets a cached PDF file if it exists
  Future<File?> getCachedPdf(String filename) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final file = File('${cacheDir.path}/$filename');
      return file.existsSync() ? file : null;
    } catch (e) {
      debugPrint('Error getting cached PDF: $e');
      return null;
    }
  }

  /// Gets cached PDF using weekday-based naming with fallback to legacy names
  Future<File?> getCachedPdfByDay(bool isToday) async {
    // Try weekday-named file first
    final weekdayFilename = isToday ? todayPdfFilename : tomorrowPdfFilename;
    File? file = await getCachedPdf(weekdayFilename);

    // Fall back to legacy name if weekday file doesn't exist
    if (file == null) {
      final legacyFilename = isToday ? todayFilename : tomorrowFilename;
      file = await getCachedPdf(legacyFilename);
    }

    return file;
  }

  /// Checks if both days are loaded and updates state
  void _checkIfBothDaysLoaded() {
    _weekdaysLoaded = _todayWeekday.isNotEmpty && _tomorrowWeekday.isNotEmpty;
  }



  
  /// Preload both PDFs from network
  Future<void> preloadPdfs({bool forceReload = false}) async {
    _isLoading = true;
    _showLoadingBar = true;
    _todayLoading = true;
    _tomorrowLoading = true;
    // Keep previous error visible during retry; clear only on success
    notifyListeners();

    debugPrint('🌐 [PdfRepository] Loading fresh PDFs from network');

    try {
      // Download PDFs individually to handle partial failures
      final todayResult = await downloadPdfWithWeekdayName(todayUrl, true, forceReload: forceReload).catchError((e) {
        debugPrint('❌ [PdfRepository] Today PDF failed: $e');
        _todayError = 'Server nicht erreichbar';
        return null;
      });

      final tomorrowResult = await downloadPdfWithWeekdayName(tomorrowUrl, false, forceReload: forceReload).catchError((e) {
        debugPrint('❌ [PdfRepository] Tomorrow PDF failed: $e');
        _tomorrowError = 'Server nicht erreichbar';
        return null;
      });

      // Handle individual results
      if (todayResult != null) {
        _todayError = null; // Clear today error on success
        debugPrint('✅ [PdfRepository] Today PDF downloaded successfully');
      }

      if (tomorrowResult != null) {
        _tomorrowError = null; // Clear tomorrow error on success
        debugPrint('✅ [PdfRepository] Tomorrow PDF downloaded successfully');
      }

      // Set global error only if both failed
      if (todayResult == null && tomorrowResult == null) {
        debugPrint('❌ [PdfRepository] Both PDFs failed to download');
        _error = 'Server nicht erreichbar';
      } else {
        _error = null; // Clear global error if at least one succeeded
        debugPrint('✅ [PdfRepository] At least one PDF downloaded successfully');
      }
    } catch (e) {
      debugPrint('❌ [PdfRepository] Error downloading PDFs: $e');
      _error = 'Server nicht erreichbar';
      _todayError = 'Server nicht erreichbar';
      _tomorrowError = 'Server nicht erreichbar';
    } finally {
      _isLoading = false;
      _showLoadingBar = false;
      _todayLoading = false;
      _tomorrowLoading = false;
      notifyListeners();
    }
  }

  /// Retry loading PDFs (for retry button)
  Future<void> retryLoadPdfs() async {
    await preloadPdfs(forceReload: true);
  }

  /// Retry loading only today's PDF
  Future<void> retryTodayPdf() async {
    _todayLoading = true;
    _todayError = null;
    notifyListeners();

    try {
      final result = await downloadPdfWithWeekdayName(todayUrl, true, forceReload: true);
      if (result != null) {
        _todayError = null;
        debugPrint('✅ [PdfRepository] Today PDF retry successful');
      } else {
        _todayError = 'Server nicht erreichbar';
        debugPrint('❌ [PdfRepository] Today PDF retry failed');
      }
    } catch (e) {
      _todayError = 'Server nicht erreichbar';
      debugPrint('❌ [PdfRepository] Today PDF retry error: $e');
    } finally {
      _todayLoading = false;
      notifyListeners();
    }
  }

  /// Retry loading only tomorrow's PDF
  Future<void> retryTomorrowPdf() async {
    _tomorrowLoading = true;
    _tomorrowError = null;
    notifyListeners();

    try {
      final result = await downloadPdfWithWeekdayName(tomorrowUrl, false, forceReload: true);
      if (result != null) {
        _tomorrowError = null;
        debugPrint('✅ [PdfRepository] Tomorrow PDF retry successful');
      } else {
        _tomorrowError = 'Server nicht erreichbar';
        debugPrint('❌ [PdfRepository] Tomorrow PDF retry failed');
      }
    } catch (e) {
      _tomorrowError = 'Server nicht erreichbar';
      debugPrint('❌ [PdfRepository] Tomorrow PDF retry error: $e');
    } finally {
      _tomorrowLoading = false;
      notifyListeners();
    }
  }
}

// Function to run PDF text extraction in isolate
Future<Map<String, String>> _extractPdfDataInIsolate(List<int> bytes) async {
  return await compute(_extractPdfData, bytes);
}

Map<String, String> _extractPdfData(List<int> bytes) {
  try {
    final document = PdfDocument(inputBytes: bytes);
    final textExtractor = PdfTextExtractor(document);
    final text = textExtractor.extractText(startPageIndex: 0, endPageIndex: 0);
    document.dispose();

    // DEBUG: Print the first 500 characters of the PDF text
    debugPrint('PDF Text Content (first 500 chars): ${text.length > 500 ? text.substring(0, 500) : text}');

    // Check if PDF is empty or has very little content (likely weekend/holiday)
    if (text.trim().length < 50) {
      debugPrint('PDF appears to be empty or minimal content (likely weekend/holiday)');
      return {'weekday': 'weekend', 'dateTime': '', 'date': ''};
    }

    // Extract "last updated" timestamp
    final dateTimePattern = RegExp(r'(\d{1,2}\.\d{1,2}\.\d{4}\s+\d{1,2}:\d{2})');
    final dateTimeMatch = dateTimePattern.firstMatch(text);
    final dateTime = dateTimeMatch?.group(1) ?? '';

    String weekday = '';
    String date = '';

    // New pattern to get the plan's date and weekday together from "23.6. / Montag"
    final planDateAndWeekdayPattern = RegExp(
        r'(\d{1,2}\.\d{1,2}\.)\s*\/\s*(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)',
        caseSensitive: false);
    final planMatch = planDateAndWeekdayPattern.firstMatch(text);
    
    if (planMatch != null) {
      final partialDate = planMatch.group(1)!; // "23.6."
      weekday = planMatch.group(2)!;

      // Extract year from the "last updated" timestamp since the plan date doesn't have it
      final yearPattern = RegExp(r'(\d{4})');
      final yearMatch = yearPattern.firstMatch(dateTime);
      if (yearMatch != null) {
        final year = yearMatch.group(0)!;
        date = '$partialDate$year'; // "23.6.2025"
      } else {
        date = partialDate; // Fallback to partial date if no year is found
      }
      
      debugPrint('Found weekday using main pattern: $weekday, date: $date');
    } else {
      // Fallback to old method if new pattern fails
      debugPrint('Main pattern failed, trying fallback pattern');
      final weekdayPattern = RegExp(r'(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)', caseSensitive: false);
      final weekdayMatch = weekdayPattern.firstMatch(text);
      weekday = weekdayMatch?.group(1) ?? '';

      final fallbackDatePattern = RegExp(r'(\d{1,2}\.\d{1,2}\.\d{4})');
      final fallbackDateMatch = fallbackDatePattern.firstMatch(text);
      date = fallbackDateMatch?.group(1) ?? '';
      
      debugPrint('Fallback pattern result - weekday: $weekday, date: $date');
    }

    return {'weekday': weekday, 'dateTime': dateTime, 'date': date};
  } catch (e) {
    debugPrint('Error extracting PDF data: $e');
    return {'weekday': '', 'dateTime': '', 'date': ''};
  }
} 
// Copyright Luka Löhr 2025

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  bool _hasSlowConnection = false;
  bool _showLoadingBar = false;

  // Getters for accessing the data
  String get todayWeekday => _todayWeekday;
  String get tomorrowWeekday => _tomorrowWeekday;
  String get todayLastUpdated => _todayLastUpdated;
  String get tomorrowLastUpdated => _tomorrowLastUpdated;
  String get todayDate => _todayDate;
  String get tomorrowDate => _tomorrowDate;
  bool get weekdaysLoaded => _weekdaysLoaded;
  bool get isLoading => _isLoading;
  bool get hasSlowConnection => _hasSlowConnection;
  bool get showLoadingBar => _showLoadingBar;
  
  // Dynamic filename getters based on weekdays
  String get todayPdfFilename => _todayWeekday.isNotEmpty ? '${_todayWeekday.toLowerCase()}.pdf' : todayFilename;
  String get tomorrowPdfFilename => _tomorrowWeekday.isNotEmpty ? '${_tomorrowWeekday.toLowerCase()}.pdf' : tomorrowFilename;

  /// Downloads a PDF from the given URL with HTTP Basic Auth
  Future<File?> downloadPdf(String url, String filename, {bool forceReload = false}) async {
    try {
      // Get cache directory
      final cacheDir = await getTemporaryDirectory();
      final file = File('${cacheDir.path}/$filename');

      // Check if file exists and is not empty (unless force reload)
      if (!forceReload && file.existsSync() && file.lengthSync() > 0) {
        debugPrint('Using cached PDF file: $filename');
        return file;
      }

      // Create HTTP request with Basic Auth
      final credentials = base64Encode(utf8.encode('$_username:$_password'));
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Basic $credentials',
          'User-Agent': 'LGKA-Flutter-App/1.0',
        },
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to download PDF: ${response.statusCode}');
        return null;
      }

      // Save PDF to file
      await file.writeAsBytes(response.bodyBytes);
      debugPrint('Successfully downloaded PDF: $filename');

      // Extract metadata after successful download
      final isToday = url == todayUrl;
      await _extractMetadataFromPdf(file, isToday);

      // If we now have weekday info, rename the file and save with weekday name
      final newFilename = isToday ? todayPdfFilename : tomorrowPdfFilename;
      if (newFilename != filename) {
        final newFile = File('${cacheDir.path}/$newFilename');
        // Copy to new filename and delete old one
        await file.copy(newFile.path);
        if (await file.exists()) {
          await file.delete();
        }
        debugPrint('Renamed PDF from $filename to $newFilename');
        return newFile;
      }

      // Update loaded state
      _checkIfBothDaysLoaded();

      return file;
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      return null;
    }
  }

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
      ).timeout(const Duration(seconds: 10));

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

  /// Check if device has internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  /// Preload both PDFs using weekday-based naming with network monitoring
  Future<void> preloadPdfs({bool forceReload = false}) async {
    _isLoading = true;
    _hasSlowConnection = false;
    _showLoadingBar = true;
    notifyListeners();

    // Always try to load from cache first to get weekdays
    await loadWeekdaysFromCachedPdfs();

    bool slowConnectionTimerTriggered = false;

    // Start a timer to detect slow connection after 3 seconds
    final slowConnectionTimer = Future.delayed(const Duration(seconds: 3), () {
      if (_isLoading && !slowConnectionTimerTriggered) {
        slowConnectionTimerTriggered = true;
        _hasSlowConnection = true;
        _showLoadingBar = false; // Hide loading bar, show notification instead
        notifyListeners();
        debugPrint('Slow connection detected after 3 seconds - replacing loading bar with notification');
      }
    });

    try {
      // Check connectivity first
      final hasConnection = await hasInternetConnection();
      debugPrint('Network connection available: $hasConnection');
      
      if (!hasConnection) {
        debugPrint('No internet connection detected - replacing loading bar with notification immediately');
        _hasSlowConnection = true;
        _showLoadingBar = false; // Hide loading bar immediately
        notifyListeners();
        return;
      }

      final results = await Future.wait([
        downloadPdfWithWeekdayName(todayUrl, true, forceReload: forceReload),
        downloadPdfWithWeekdayName(tomorrowUrl, false, forceReload: forceReload),
      ]);
      
      // Only clear slow connection notification if at least one PDF was successfully downloaded
      if (results[0] != null || results[1] != null) {
        _showLoadingBar = false;
        _hasSlowConnection = false;
        debugPrint('PDFs loaded successfully');
      } else {
        // Keep slow connection notification if no PDFs were downloaded
        _showLoadingBar = false;
        debugPrint('Failed to download PDFs, keeping slow connection notification');
      }
      
    } catch (e) {
      debugPrint('Error preloading PDFs: $e');
      _hasSlowConnection = true;
      _showLoadingBar = false; // Hide loading bar on error
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
      
      // We don't automatically clear the notification - it stays until successful download
      // or until the user takes an action that forces a new attempt
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
    } else {
      // Fallback to old method if new pattern fails
      final weekdayPattern = RegExp(r'(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)', caseSensitive: false);
      final weekdayMatch = weekdayPattern.firstMatch(text);
      weekday = weekdayMatch?.group(1) ?? '';

      final fallbackDatePattern = RegExp(r'(\d{1,2}\.\d{1,2}\.\d{4})');
      final fallbackDateMatch = fallbackDatePattern.firstMatch(text);
      date = fallbackDateMatch?.group(1) ?? '';
    }

    return {'weekday': weekday, 'dateTime': dateTime, 'date': date};
  } catch (e) {
    debugPrint('Error extracting PDF data: $e');
    return {'weekday': '', 'dateTime': '', 'date': ''};
  }
} 
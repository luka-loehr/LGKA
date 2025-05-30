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
  static const String todayFilename = 'today.pdf';
  static const String tomorrowFilename = 'tomorrow.pdf';

  String _todayWeekday = '';
  String _tomorrowWeekday = '';
  String _todayLastUpdated = '';
  String _tomorrowLastUpdated = '';
  bool _weekdaysLoaded = false;

  // Getters
  String get todayWeekday => _todayWeekday;
  String get tomorrowWeekday => _tomorrowWeekday;
  String get todayLastUpdated => _todayLastUpdated;
  String get tomorrowLastUpdated => _tomorrowLastUpdated;
  bool get weekdaysLoaded => _weekdaysLoaded;

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
      await _extractMetadataFromPdf(file, filename == todayFilename);

      // Update loaded state
      _checkIfBothDaysLoaded();

      return file;
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
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
        debugPrint('Extracted for today - weekday: $_todayWeekday, dateTime: $_todayLastUpdated');
      } else {
        _tomorrowWeekday = result['weekday'] ?? '';
        _tomorrowLastUpdated = result['dateTime'] ?? '';
        debugPrint('Extracted for tomorrow - weekday: $_tomorrowWeekday, dateTime: $_tomorrowLastUpdated');
      }

      _checkIfBothDaysLoaded();
      notifyListeners();
    } catch (e) {
      debugPrint('Error extracting metadata from PDF: $e');
      if (isToday) {
        _todayWeekday = '';
        _todayLastUpdated = '';
      } else {
        _tomorrowWeekday = '';
        _tomorrowLastUpdated = '';
      }
    }
  }

  /// Loads weekday information from cached PDFs
  Future<void> loadWeekdaysFromCachedPdfs() async {
    final todayFile = await getCachedPdf(todayFilename);
    if (todayFile != null) {
      await _extractMetadataFromPdf(todayFile, true);
    }

    final tomorrowFile = await getCachedPdf(tomorrowFilename);
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

  /// Checks if both days are loaded and updates state
  void _checkIfBothDaysLoaded() {
    _weekdaysLoaded = _todayWeekday.isNotEmpty && _tomorrowWeekday.isNotEmpty;
  }

  /// Preload both PDFs
  Future<void> preloadPdfs({bool forceReload = false}) async {
    await Future.wait([
      downloadPdf(todayUrl, todayFilename, forceReload: forceReload),
      downloadPdf(tomorrowUrl, tomorrowFilename, forceReload: forceReload),
    ]);
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

    // Extract weekday
    final weekdayPattern = RegExp(r'(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)', caseSensitive: false);
    final weekdayMatch = weekdayPattern.firstMatch(text);
    final weekday = weekdayMatch?.group(1) ?? '';

    // Extract date and time
    final dateTimePattern = RegExp(r'(\d{1,2}\.\d{1,2}\.\d{4}\s+\d{1,2}:\d{2})');
    final dateTimeMatch = dateTimePattern.firstMatch(text);
    final dateTime = dateTimeMatch?.group(1) ?? '';

    return {'weekday': weekday, 'dateTime': dateTime};
  } catch (e) {
    debugPrint('Error extracting PDF data: $e');
    return {'weekday': '', 'dateTime': ''};
  }
} 
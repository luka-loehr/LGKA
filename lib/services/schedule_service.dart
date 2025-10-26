// Copyright Luka Löhr 2025

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:path_provider/path_provider.dart';
import '../utils/app_logger.dart';
import '../utils/app_info.dart';
import '../config/app_credentials.dart';

/// Represents a schedule PDF with metadata
class ScheduleItem {
  final String title;
  final String url;
  final String halbjahr;
  final String gradeLevel;
  final String fullUrl;

  const   ScheduleItem({
    required this.title,
    required this.url,
    required this.halbjahr,
    required this.gradeLevel,
    required this.fullUrl,
  });

  @override
  String toString() {
    return 'ScheduleItem(title: $title, halbjahr: $halbjahr, gradeLevel: $gradeLevel)';
  }
}

/// Service for managing schedule PDFs through web scraping
class ScheduleService {
  static const String _baseUrl = 'https://lessing-gymnasium-karlsruhe.de';
  static const String _schedulePageUrl = '$_baseUrl/cm3/index.php/unterricht/stundenplan';
  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _availabilityCheckTimeout = Duration(seconds: 5); // Faster timeout for availability checks

  List<ScheduleItem>? _cachedSchedules;
  DateTime? _lastFetchTime;
  static const Duration _cacheValidity = Duration(minutes: 30);
  
  // Cache for availability checks
  Map<String, bool> _availabilityCache = {};
  DateTime? _lastAvailabilityCheck;
  static const Duration _availabilityCacheValidity = Duration(minutes: 15);

  /// Get all available schedules, using cache if valid
  Future<List<ScheduleItem>> getSchedules() async {
    // Check if cache is still valid
    if (_cachedSchedules != null && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _cacheValidity) {
        return _cachedSchedules!;
      }
    }

    // Fetch fresh data
    try {
      final schedules = await _scrapeSchedules();
      _cachedSchedules = schedules;
      _lastFetchTime = DateTime.now();
      return schedules;
    } catch (e) {
      // Return cached data if available, even if expired
      if (_cachedSchedules != null) {
        return _cachedSchedules!;
      }
      rethrow;
    }
  }

  /// Scrape the schedule page to extract PDF links
  Future<List<ScheduleItem>> _scrapeSchedules() async {
    final credentials = base64Encode(utf8.encode('${AppCredentials.username}:${AppCredentials.password}'));
    
          final response = await http.get(
        Uri.parse(_schedulePageUrl),
        headers: {
          'Authorization': 'Basic $credentials',
          'User-Agent': AppInfo.userAgent,
        },
      ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch schedule page: HTTP ${response.statusCode}');
    }

    // Check if response body is empty or too short to be valid HTML
    if (response.body.isEmpty || response.body.length < 100) {
      throw Exception('Server returned empty or invalid response');
    }

    return await compute(_parseScheduleHtml, response.body);
  }

  /// Check if a schedule PDF is available (HEAD request for faster checking)
  Future<bool> isScheduleAvailable(ScheduleItem schedule) async {
    // Check cache first
    final cacheKey = '${schedule.fullUrl}_${schedule.halbjahr}_${schedule.gradeLevel}';

    // Check if cache is still valid
    if (_availabilityCache.containsKey(cacheKey) && _lastAvailabilityCheck != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastAvailabilityCheck!);
      if (timeSinceLastCheck < _availabilityCacheValidity) {
        AppLogger.debug('Cache hit: ${schedule.title}', module: 'ScheduleService');
        return _availabilityCache[cacheKey]!;
      }
    }

    AppLogger.debug('Checking availability: ${schedule.title}', module: 'ScheduleService');

    try {
      final credentials = base64Encode(utf8.encode('${AppCredentials.username}:${AppCredentials.password}'));

      final response = await http.head(
        Uri.parse(schedule.fullUrl),
        headers: {
          'Authorization': 'Basic $credentials',
          'User-Agent': AppInfo.userAgent,
        },
      ).timeout(_availabilityCheckTimeout);

      // Cache the result
      final isAvailable = response.statusCode == 200;
      _availabilityCache[cacheKey] = isAvailable;
      _lastAvailabilityCheck = DateTime.now();

      AppLogger.debug('Availability check result: ${schedule.title} = ${isAvailable ? 'available' : 'not available'}', module: 'ScheduleService');
      return isAvailable;
    } catch (e) {
      // If there's any error (timeout, network issue, etc.), assume not available
      _availabilityCache[cacheKey] = false;
      _lastAvailabilityCheck = DateTime.now();
      AppLogger.debug('Availability check failed: ${schedule.title}', module: 'ScheduleService');
      return false;
    }
  }

  /// Download a specific schedule PDF
  Future<File?> downloadSchedule(ScheduleItem schedule) async {
    try {
      AppLogger.schedule('Starting download: ${schedule.title} (${schedule.halbjahr}, ${schedule.gradeLevel})');
      final credentials = base64Encode(utf8.encode('$_username:$_password'));

      AppLogger.debug('Making HTTP request for PDF', module: 'ScheduleService');
      final response = await http.get(
        Uri.parse(schedule.fullUrl),
        headers: {
          'Authorization': 'Basic $credentials',
          'User-Agent': AppInfo.userAgent,
        },
      ).timeout(_timeout);

      if (response.statusCode == 404) {
        AppLogger.warning('PDF not available (404): ${schedule.title}', module: 'ScheduleService');
        return null;
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }

      final cacheDir = await getTemporaryDirectory();
      final sanitizedGradeLevel = schedule.gradeLevel.replaceAll('/', '_');
      final sanitizedHalbjahr = schedule.halbjahr.replaceAll('.', '_');
      final filename = '${sanitizedGradeLevel}_$sanitizedHalbjahr.pdf';
      final file = File('${cacheDir.path}/$filename');

      AppLogger.debug('Saving PDF: ${response.bodyBytes.length} bytes', module: 'ScheduleService');
      await file.writeAsBytes(response.bodyBytes);
      AppLogger.success('PDF downloaded successfully: ${schedule.title} (${(response.bodyBytes.length / 1024).toStringAsFixed(1)}KB)', module: 'ScheduleService');
      
      // Validate PDF content
      if (response.bodyBytes.length < 1000) {
        AppLogger.warning('PDF too small, deleting', module: 'ScheduleService');
        await file.delete();
        return null;
      }
      
      final responseText = String.fromCharCodes(response.bodyBytes.take(100));
      if (responseText.contains('<html') || responseText.contains('<!DOCTYPE') || responseText.contains('error')) {
        AppLogger.warning('Server returned HTML instead of PDF', module: 'ScheduleService');
        await file.delete();
        return null;
      }
      
      try {
        final pdfBytes = await file.readAsBytes();
        if (pdfBytes.isNotEmpty && !_isValidPdfContent(pdfBytes)) {
          AppLogger.warning('Invalid PDF content', module: 'ScheduleService');
          await file.delete();
          return null;
        }
      } catch (e) {
        AppLogger.error('Error validating PDF', module: 'ScheduleService', error: e);
        await file.delete();
        return null;
      }
      
      return file;
    } catch (e) {
      AppLogger.error('Failed to download schedule', module: 'ScheduleService', error: e);
      rethrow;
    }
  }

  /// Clear the cache to force fresh data on next request
  void clearCache() {
    _cachedSchedules = null;
    _lastFetchTime = null;
    _availabilityCache.clear();
    _lastAvailabilityCheck = null;
  }
  
  /// Check if PDF content appears to be valid
  bool _isValidPdfContent(List<int> bytes) {
    if (bytes.length < 8) return false;
    
    // Check for PDF header signature (%PDF-)
    final header = String.fromCharCodes(bytes.take(8));
    if (!header.startsWith('%PDF-')) {
      return false;
    }
    
    // Check for PDF trailer (basic validation)
    final trailer = String.fromCharCodes(bytes.skip(bytes.length - 100).take(100));
    if (!trailer.contains('trailer') && !trailer.contains('startxref')) {
      return false;
    }
    
    return true;
  }
}

/// Parse HTML to extract schedule information
List<ScheduleItem> _parseScheduleHtml(String htmlContent) {
  final document = html.parse(htmlContent);
  final schedules = <ScheduleItem>[];

  try {
    // Find the module containing schedule links
    final module = document.querySelector('#mod-custom213');
    if (module == null) {
      throw Exception('Serververbindung fehlgeschlagen');
    }

    // Find all links in the module
    final links = module.querySelectorAll('a[href*="stundenplan"]');
    
    for (final link in links) {
      final href = link.attributes['href'];
      final title = link.attributes['title'] ?? link.text.trim();
      
      if (href != null && title.isNotEmpty) {
        // Convert relative URL to absolute
        String fullUrl = href;
        if (href.startsWith('/cm3/../')) {
          fullUrl = href.replaceFirst('/cm3/../', 'https://lessing-gymnasium-karlsruhe.de/');
        } else if (href.startsWith('/')) {
          fullUrl = 'https://lessing-gymnasium-karlsruhe.de$href';
        }

        final halbjahr = _extractHalbjahr(title);
        final gradeLevel = _extractGradeLevel(title);

        AppLogger.debug('Parsed schedule: $title ($halbjahr, $gradeLevel)', module: 'ScheduleService');

        schedules.add(ScheduleItem(
          title: title,
          url: href,
          halbjahr: halbjahr,
          gradeLevel: gradeLevel,
          fullUrl: fullUrl,
        ));
      }
    }

    if (schedules.isEmpty) {
      throw Exception('Serververbindung fehlgeschlagen');
    }

    return schedules;
  } catch (e) {
    // Convert any parsing error to generic server connection error
    throw Exception('Serververbindung fehlgeschlagen');
  }
}

/// Extract halbjahr information from title
String _extractHalbjahr(String title) {
  if (title.contains('1.HJ')) return '1. Halbjahr';
  if (title.contains('2.HJ')) return '2. Halbjahr';
  return 'Unbekannt';
}

/// Extract grade level information from title
String _extractGradeLevel(String title) {
  if (title.contains('5-10')) return 'Klassen 5-10';
  if (title.contains('J11/12')) return 'J11/J12';
  if (title.contains('11-12')) return 'J11/J12'; // Fallback for different formats
  return 'Unbekannt';
} 
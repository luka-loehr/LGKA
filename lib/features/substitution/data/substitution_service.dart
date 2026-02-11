// Copyright Luka Löhr 2026

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../domain/substitution_models.dart';
import 'pdf_parser_service.dart';
import '../../../../utils/app_info.dart';
import '../../../../utils/retry_util.dart';
import '../../../../utils/app_logger.dart';
import '../../../../config/app_credentials.dart';
import '../../../../services/cache_service.dart';

/// Service for managing substitution plan PDFs
class SubstitutionService {
  static const String _todayUrl = 'https://lessing-gymnasium-karlsruhe.de/stundenplan/schueler/v_schueler_heute.pdf';
  static const String _tomorrowUrl = 'https://lessing-gymnasium-karlsruhe.de/stundenplan/schueler/v_schueler_morgen.pdf';
  static const Duration _timeout = Duration(seconds: 10);
  
  final _cacheService = CacheService();

  SubstitutionState _todayState = const SubstitutionState();
  SubstitutionState _tomorrowState = const SubstitutionState();
  bool _isInitialized = false;
  DateTime? _lastFetchTime;
  bool _isRefreshing = false;

  // Getters
  SubstitutionState get todayState => _todayState;
  SubstitutionState get tomorrowState => _tomorrowState;
  bool get isInitialized => _isInitialized;
  bool get hasAnyData => _todayState.hasData || _tomorrowState.hasData;
  bool get hasAnyError => _todayState.error != null || _tomorrowState.error != null;
  bool get isLoading => _todayState.isLoading || _tomorrowState.isLoading;
  DateTime? get lastFetchTime => _lastFetchTime;
  bool get isCacheValid => _isCacheValid;

  bool get _isCacheValid {
    return _cacheService.isCacheValid(CacheKey.substitutions, lastFetchTime: _lastFetchTime);
  }

  /// Initialize the service by loading both PDFs
  Future<void> initialize() async {
    // Already initialized - check if refresh is needed
    if (_isInitialized) {
      // If cache is invalid and we have data, refresh immediately
      if (hasAnyData && !_isCacheValid) {
        AppLogger.info('Cache invalid on access - refreshing substitutions immediately', module: 'SubstitutionService');
        await refreshInBackground();
      }
      return;
    }

    await _loadBothPdfs();
    _isInitialized = true;
    _lastFetchTime = DateTime.now();
    _cacheService.updateCacheTimestamp(CacheKey.substitutions, _lastFetchTime);
    
    final loadedCount = (todayState.canDisplay ? 1 : 0) + (tomorrowState.canDisplay ? 1 : 0);
    AppLogger.debug('Substitution plan initialization complete: $loadedCount PDF(s) loaded', module: 'SubstitutionService');
  }

  /// Load both PDFs simultaneously
  Future<void> _loadBothPdfs({bool silent = false}) async {
    final results = await Future.wait<bool>([
      _loadPdf(_todayUrl, true, silent: silent),
      _loadPdf(_tomorrowUrl, false, silent: silent),
    ]);

    if (results.any((success) => success)) {
      _lastFetchTime = DateTime.now();
      _cacheService.updateCacheTimestamp(CacheKey.substitutions, _lastFetchTime);
    }
  }

  /// Load a single PDF and update its state
  Future<bool> _loadPdf(String url, bool isToday, {bool silent = false}) async {
    final previousState = isToday ? _todayState : _tomorrowState;
    final dayLabel = isToday ? 'today' : 'tomorrow';

    // Check if PDF is already cached and cache is still valid
    final cacheDir = await getTemporaryDirectory();
    final filename = isToday ? 'today.pdf' : 'tomorrow.pdf';
    final cachedFile = File('${cacheDir.path}/$filename');
    
    // Only use cached file if cache is valid
    if (await cachedFile.exists() && _isCacheValid) {
      final fileSize = await cachedFile.length();
      if (fileSize > 1000) {
        AppLogger.debug('Cache hit: Substitution plan - $dayLabel', module: 'SubstitutionService');
        try {
          final metadata = await _extractMetadata(cachedFile);
          final parsedData = await PdfParserService.parsePdf(cachedFile);
          final existingState = isToday ? _todayState : _tomorrowState;
          _updatePdfState(isToday, SubstitutionState(
            isLoading: false,
            hasData: true,
            weekday: metadata['weekday'],
            date: metadata['date'],
            lastUpdated: metadata['lastUpdated'],
            file: cachedFile,
            downloadTimestamp: existingState.downloadTimestamp ?? DateTime.now(),
            parsedData: parsedData.isValid ? parsedData : null,
          ));
          return true;
        } catch (e) {
          AppLogger.debug('Failed to extract metadata from cached file, re-downloading', module: 'SubstitutionService');
        }
      }
    }

    // Set loading state
    if (!silent) {
      _updatePdfState(isToday, previousState.copyWith(isLoading: true, error: null));
    }

    try {
      final file = await _downloadPdf(url);
      final metadata = await _extractMetadata(file);
      final parsedData = await PdfParserService.parsePdf(file);

      // Update state with success
      final downloadTime = DateTime.now();
      _updatePdfState(isToday, SubstitutionState(
        isLoading: false,
        hasData: true,
        weekday: metadata['weekday'],
        date: metadata['date'],
        lastUpdated: metadata['lastUpdated'],
        file: file,
        downloadTimestamp: downloadTime,
        parsedData: parsedData.isValid ? parsedData : null,
      ));

      AppLogger.debug('Substitution plan loaded: $dayLabel (${metadata['weekday']})', module: 'SubstitutionService');
      return true;
    } catch (e) {
      if (!silent) {
        _updatePdfState(isToday, previousState.copyWith(
          isLoading: false,
          error: 'Serververbindung fehlgeschlagen',
        ));
      } else {
        _updatePdfState(isToday, previousState);
      }
      return false;
    }
  }

  /// Download PDF from URL with authentication
  Future<File> _downloadPdf(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw Exception('Invalid URL format: $url');
    }
    
    return RetryUtil.retry<File>(
      operation: () async {
        final credentials = base64Encode(utf8.encode('${AppCredentials.username}:${AppCredentials.password}'));
        
        final response = await http.get(
          uri,
          headers: {
            'Authorization': 'Basic $credentials',
            'User-Agent': AppInfo.userAgent,
          },
        ).timeout(_timeout);

        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }

        final cacheDir = await getTemporaryDirectory();
        final filename = url.contains('heute') ? 'today.pdf' : 'tomorrow.pdf';
        final file = File('${cacheDir.path}/$filename');
        
        await file.writeAsBytes(response.bodyBytes);
        return file;
      },
      maxRetries: 2,
      operationName: 'SubstitutionService',
      shouldRetry: RetryUtil.isRetryableError,
    );
  }

  /// Extract metadata from PDF file
  Future<Map<String, String>> _extractMetadata(File file) async {
    return await compute(_extractPdfData, await file.readAsBytes());
  }

  /// Update the state of a specific PDF
  void _updatePdfState(bool isToday, SubstitutionState newState) {
    if (isToday) {
      _todayState = newState;
    } else {
      _tomorrowState = newState;
    }
  }

  /// Retry loading a specific PDF
  Future<void> retryPdf(bool isToday) async {
    final url = isToday ? _todayUrl : _tomorrowUrl;
    await _loadPdf(url, isToday);
  }

  /// Set loading state for both PDFs
  void setLoadingState(bool isLoading) {
    _todayState = _todayState.copyWith(isLoading: isLoading, error: null);
    _tomorrowState = _tomorrowState.copyWith(isLoading: isLoading, error: null);
  }

  /// Set loading state for a specific PDF
  void setLoadingStateForPdf(bool isToday, bool isLoading) {
    if (isToday) {
      _todayState = _todayState.copyWith(isLoading: isLoading, error: null);
    } else {
      _tomorrowState = _tomorrowState.copyWith(isLoading: isLoading, error: null);
    }
  }

  /// Retry loading both PDFs
  Future<void> retryAll() async {
    await _loadBothPdfs();
  }

  /// Refresh all PDFs (force reload)
  Future<void> refresh() async {
    await _loadBothPdfs();
    _isInitialized = true;
    _lastFetchTime = DateTime.now();
    _cacheService.updateCacheTimestamp(CacheKey.substitutions, _lastFetchTime);
  }

  /// Get the file for a specific PDF if available
  File? getPdfFile(bool isToday) {
    final state = isToday ? _todayState : _tomorrowState;
    return state.file;
  }

  /// Get parsed data for a specific PDF
  ParsedSubstitutionData? getParsedData(bool isToday) {
    final state = isToday ? _todayState : _tomorrowState;
    return state.parsedData;
  }

  /// Check if a PDF can be opened
  bool canOpenPdf(bool isToday) {
    final state = isToday ? _todayState : _tomorrowState;
    return state.canDisplay;
  }

  /// Trigger a silent background refresh when cache is stale
  Future<void> refreshInBackground() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    AppLogger.info('Starting background refresh: Substitution plans', module: 'SubstitutionService');
    
    final previousTodayState = _todayState;
    final previousTomorrowState = _tomorrowState;
    
    _todayState = _todayState.copyWith(isLoading: true, error: null);
    _tomorrowState = _tomorrowState.copyWith(isLoading: true, error: null);
    
    try {
      await _loadBothPdfs(silent: true).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Refresh timeout after 15 seconds', const Duration(seconds: 15));
        },
      );
      AppLogger.success('Background refresh complete: Substitution plans', module: 'SubstitutionService');
    } catch (e) {
      AppLogger.error('Background refresh failed: Substitution plans', module: 'SubstitutionService', error: e);
      
      if (!_isCacheValid) {
        AppLogger.info('Refresh failed with invalid cache - clearing cached data', module: 'SubstitutionService');
        _todayState = const SubstitutionState(
          isLoading: false,
          hasData: false,
          error: 'Serververbindung fehlgeschlagen',
        );
        _tomorrowState = const SubstitutionState(
          isLoading: false,
          hasData: false,
          error: 'Serververbindung fehlgeschlagen',
        );
      } else {
        _todayState = previousTodayState.copyWith(isLoading: false);
        _tomorrowState = previousTomorrowState.copyWith(isLoading: false);
      }
    } finally {
      _isRefreshing = false;
    }
  }
}

/// Extract PDF data in background isolate
Map<String, String> _extractPdfData(List<int> bytes) {
  try {
    final document = PdfDocument(inputBytes: bytes);
    final textExtractor = PdfTextExtractor(document);
    String text = textExtractor.extractText(startPageIndex: 0, endPageIndex: 0);
    text = _normalizeText(text);
    document.dispose();

    if (text.trim().length < 50) {
      return {
        'weekday': 'weekend',
        'date': '',
        'lastUpdated': '',
      };
    }

    String weekday = '';
    String date = '';
    String? detectedYearFromFooter;

    final footerMatch = RegExp(r'\b(\d{1,2})\.(\d{1,2})\.((?:19|20)\d{2})\s*\(\d+\)')
        .firstMatch(text);
    if (footerMatch != null) {
      detectedYearFromFooter = footerMatch.group(3);
    }

    final headerPattern = RegExp(
      r'Lessing\S*Klassen\s+(\d{1,2}\.\d{1,2}\.)\s*\/\s*(Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)',
      caseSensitive: false,
    );
    final headerMatch = headerPattern.firstMatch(text);
    if (headerMatch != null) {
      final partialDate = headerMatch.group(1);
      final weekdayGroup = headerMatch.group(2);
      if (partialDate != null && weekdayGroup != null) {
        weekday = weekdayGroup;
        final year = detectedYearFromFooter ?? DateTime.now().year.toString();
        date = '$partialDate$year';
      }
    }

    if (date.isNotEmpty) {
      date = date.replaceAllMapped(
        RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$'),
        (m) {
          final g1 = m.group(1);
          final g2 = m.group(2);
          final g3 = m.group(3);
          if (g1 != null && g2 != null && g3 != null) {
            return '${g1.padLeft(2, '0')}.${g2.padLeft(2, '0')}.$g3';
          }
          return date;
        },
      );
    }

    if ((weekday.isEmpty || weekday == 'weekend') && date.isNotEmpty) {
      final m = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(date);
      if (m != null) {
        final dayGroup = m.group(1);
        final monthGroup = m.group(2);
        final yearGroup = m.group(3);
        
        if (dayGroup != null && monthGroup != null && yearGroup != null) {
          try {
            final day = int.tryParse(dayGroup) ?? 1;
            final month = int.tryParse(monthGroup) ?? 1;
            final year = int.tryParse(yearGroup) ?? DateTime.now().year;
            
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 1900 && year <= 2100) {
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
            }
          } catch (_) {}
        }
      }
    }

    if (weekday.isNotEmpty && weekday != 'weekend') {
      try {
        final lower = weekday.toLowerCase();
        if (lower.isNotEmpty) {
          weekday = lower[0].toUpperCase() + (lower.length > 1 ? lower.substring(1) : '');
        }
      } catch (_) {}
    }

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

/// Normalize text
String _normalizeText(String text) {
  return text
      .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
      .replaceAll('\u00A0', ' ')
      .replaceAll('\u202F', ' ')
      .replaceAll('\u2060', '')
      .replaceAll('\u2044', '/')
      .replaceAll('\u2215', '/')
      .replaceAll('\u2010', '-')
      .replaceAll('\u2011', '-')
      .replaceAll('\u2012', '-')
      .replaceAll('\u2013', '-')
      .replaceAll('\u2212', '-')
      .replaceAll(RegExp(r'\s+/\s+'), ' / ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Timeout exception class
class TimeoutException implements Exception {
  final String message;
  final Duration duration;
  
  TimeoutException(this.message, this.duration);
  
  @override
  String toString() => 'TimeoutException: $message';
}

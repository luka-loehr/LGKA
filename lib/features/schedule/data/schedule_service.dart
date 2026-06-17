// Copyright Luka Löhr 2026

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html;
import 'package:path_provider/path_provider.dart';
import '../domain/schedule_models.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/parser_guard.dart';
import '../../../../utils/retry_util.dart';
import '../../../../services/cache_service.dart';
import '../../../../services/disk_cache.dart';
import '../../../../services/authed_http_client.dart';

/// Service for managing schedule PDFs through web scraping
class ScheduleService {
  static const String _baseUrl = 'https://lessing-gymnasium-karlsruhe.de';
  static const String _schedulePageUrl =
      '$_baseUrl/cm3/index.php/unterricht/stundenplan';
  // Unified 10 second timeout across all schedule-related requests
  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _availabilityCheckTimeout = Duration(seconds: 10);

  final _cacheService = CacheService();

  List<ScheduleItem>? _cachedSchedules;
  DateTime? _lastFetchTime;

  // Cache for availability checks
  final Map<String, bool> _availabilityCache = {};
  DateTime? _lastAvailabilityCheck;
  bool _isRefreshing = false;
  final _shapeTracker = ParserChangeTracker();

  List<ScheduleItem>? get cachedSchedules => _cachedSchedules;
  DateTime? get lastFetchTime => _lastFetchTime;
  bool get hasValidCache {
    if (_cachedSchedules == null || _lastFetchTime == null) {
      return false;
    }
    return _cacheService.isCacheValid(
      CacheKey.schedules,
      lastFetchTime: _lastFetchTime,
    );
  }

  /// Get all available schedules, using cache if valid
  Future<List<ScheduleItem>> getSchedules({bool forceRefresh = false}) async {
    // Prime the in-memory cache from disk on first access after a cold start,
    // so the schedule list is reused instead of re-scraped on every app open.
    if (!forceRefresh && _cachedSchedules == null) await hydrateFromDisk();
    if (!forceRefresh && _cachedSchedules != null) {
      if (hasValidCache) {
        return _cachedSchedules!;
      }

      _refreshCacheInBackground();
      return _cachedSchedules!;
    }

    try {
      final schedules = await _scrapeSchedules();
      _storeSchedules(schedules);
      return schedules;
    } catch (e) {
      if (_cachedSchedules != null) {
        return _cachedSchedules!;
      }
      rethrow;
    }
  }

  /// Stores freshly-scraped schedules in memory, records the fetch time
  /// (persisted via CacheService), and persists the list to disk so a cold
  /// start can reuse it without re-scraping.
  void _storeSchedules(List<ScheduleItem> schedules) {
    _cachedSchedules = schedules;
    _lastFetchTime = DateTime.now();
    _cacheService.updateCacheTimestamp(CacheKey.schedules, _lastFetchTime);
    unawaited(DiskCache.instance.write(
      _cacheBlob,
      jsonEncode(schedules.map((s) => s.toJson()).toList()),
    ));
  }

  static const String _cacheBlob = 'schedules';

  /// Loads last-persisted schedules from disk into the in-memory cache so the
  /// app shows them instantly on a cold start instead of re-scraping. The
  /// freshness timestamp is restored from the persisted CacheService value.
  Future<void> hydrateFromDisk() async {
    if (_cachedSchedules != null) return;
    final raw = await DiskCache.instance.read(_cacheBlob);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _cachedSchedules = list.map(ScheduleItem.fromJson).toList();
      _lastFetchTime = _cacheService.getLastFetchTime(CacheKey.schedules);
      AppLogger.debug('Schedules: hydrated ${_cachedSchedules!.length} from disk',
          module: 'ScheduleService');
    } catch (e) {
      AppLogger.debug('Schedules: disk hydrate failed: $e',
          module: 'ScheduleService');
    }
  }

  void _refreshCacheInBackground() {
    if (_isRefreshing) return;

    _isRefreshing = true;
    _scrapeSchedules()
        .then(_storeSchedules)
        .catchError((_) {
          // Ignore background refresh errors
        })
        .whenComplete(() {
          _isRefreshing = false;
        });
  }

  Future<void> refreshInBackground() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    AppLogger.info(
      'Starting background refresh: Schedules',
      module: 'ScheduleService',
    );
    final wasCacheValid = hasValidCache;

    try {
      final schedules = await _scrapeSchedules();
      _storeSchedules(schedules);
      AppLogger.success(
        'Background refresh complete: Schedules',
        module: 'ScheduleService',
      );
    } catch (e) {
      AppLogger.error(
        'Background refresh failed: Schedules',
        module: 'ScheduleService',
        error: e,
      );

      // If cache was invalid (app was backgrounded), clear cached data
      if (!wasCacheValid) {
        AppLogger.info(
          'Refresh failed with invalid cache - clearing cached schedules',
          module: 'ScheduleService',
        );
        _cachedSchedules = null;
        _lastFetchTime = null;
      }
      // If cache was valid, keep existing data (silent failure)
    } finally {
      _isRefreshing = false;
    }
  }

  /// Scrape the schedule page to extract PDF links
  Future<List<ScheduleItem>> _scrapeSchedules() async {
    return RetryUtil.retry<List<ScheduleItem>>(
      operation: () async {
        final response = await AuthedHttpClient.get(
          Uri.parse(_schedulePageUrl),
          timeout: _timeout,
        );

        if (response.statusCode != 200) {
          throw Exception(
            'Failed to fetch schedule page: HTTP ${response.statusCode}',
          );
        }

        // Check if response body is empty or too short to be valid HTML
        if (response.body.isEmpty || response.body.length < 100) {
          throw Exception('Server returned empty or invalid response');
        }

        // Parse once, in a background isolate. The isolate also returns the
        // link/module counts used for shape-change detection, so the HTML is
        // no longer parsed a second time on the UI thread.
        final parsed = await compute(_parseScheduleHtml, response.body);

        ParserGuard.requireMin(
          parser: 'Schedule parser',
          field: 'stundenplan links',
          actual: parsed.fallbackLinks,
          min: 1,
        );

        final fingerprint = ParserGuard.buildFingerprint({
          'primaryLinks': parsed.primaryLinks,
          'fallbackLinks': parsed.fallbackLinks,
          'hasModule': parsed.hasModule ? 1 : 0,
        });

        if (_shapeTracker.didShapeChange(
          key: 'schedule:list',
          fingerprint: fingerprint,
        )) {
          AppLogger.warning(
            'Schedule page structure changed: $fingerprint',
            module: 'ScheduleService',
          );
        }

        return parsed.schedules;
      },
      maxRetries: 2,
      operationName: 'ScheduleService',
      shouldRetry: RetryUtil.isRetryableError,
    );
  }

  /// Check if a schedule PDF is available (HEAD request for faster checking)
  Future<bool> isScheduleAvailable(ScheduleItem schedule) async {
    // Check cache first
    final cacheKey =
        '${schedule.fullUrl}_${schedule.halbjahr}_${schedule.gradeLevel}';

    // Check if cache is still valid
    if (_availabilityCache.containsKey(cacheKey) &&
        _lastAvailabilityCheck != null) {
      if (_cacheService.isCacheValid(
        CacheKey.scheduleAvailability,
        lastFetchTime: _lastAvailabilityCheck,
      )) {
        AppLogger.debug(
          'Cache hit: ${schedule.title}',
          module: 'ScheduleService',
        );
        return _availabilityCache[cacheKey]!;
      }
    }

    AppLogger.debug(
      'Checking availability: ${schedule.title}',
      module: 'ScheduleService',
    );

    try {
      // Validate URL before making request
      final uri = Uri.tryParse(schedule.fullUrl);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        AppLogger.warning(
          'Invalid URL format: ${schedule.fullUrl}',
          module: 'ScheduleService',
        );
        _availabilityCache[cacheKey] = false;
        _lastAvailabilityCheck = DateTime.now();
        _cacheService.updateCacheTimestamp(
          CacheKey.scheduleAvailability,
          _lastAvailabilityCheck,
        );
        return false;
      }

      final isAvailable = await RetryUtil.retry<bool>(
        operation: () async {
          final response = await AuthedHttpClient.head(
            uri,
            timeout: _availabilityCheckTimeout,
          );

          return response.statusCode == 200;
        },
        maxRetries: 2,
        operationName: 'ScheduleService',
        shouldRetry: RetryUtil.isRetryableError,
      );

      // Cache the result
      _availabilityCache[cacheKey] = isAvailable;
      _lastAvailabilityCheck = DateTime.now();
      _cacheService.updateCacheTimestamp(
        CacheKey.scheduleAvailability,
        _lastAvailabilityCheck,
      );

      AppLogger.debug(
        'Availability check result: ${schedule.title} = ${isAvailable ? 'available' : 'not available'}',
        module: 'ScheduleService',
      );
      return isAvailable;
    } catch (e) {
      // If there's any error (timeout, network issue, etc.), assume not available
      _availabilityCache[cacheKey] = false;
      _lastAvailabilityCheck = DateTime.now();
      _cacheService.updateCacheTimestamp(
        CacheKey.scheduleAvailability,
        _lastAvailabilityCheck,
      );
      AppLogger.debug(
        'Availability check failed: ${schedule.title}',
        module: 'ScheduleService',
      );
      return false;
    }
  }

  /// Download a specific schedule PDF
  Future<File?> downloadSchedule(ScheduleItem schedule) async {
    try {
      // Check if PDF is already cached
      final cacheDir = await getTemporaryDirectory();
      final sanitizedGradeLevel = schedule.gradeLevel.replaceAll('/', '_');
      final sanitizedHalbjahr = schedule.halbjahr.replaceAll('.', '_');
      final filename = '${sanitizedGradeLevel}_$sanitizedHalbjahr.pdf';
      final cachedFile = File('${cacheDir.path}/$filename');

      if (await cachedFile.exists()) {
        // Validate cached file size (must be > 1000 bytes)
        final fileSize = await cachedFile.length();
        if (fileSize > 1000) {
          AppLogger.debug(
            'Using cached schedule PDF: ${schedule.title}',
            module: 'ScheduleService',
          );
          return cachedFile;
        } else {
          // Invalid cached file, delete it
          await cachedFile.delete();
        }
      }

      AppLogger.schedule(
        'Starting download: ${schedule.title} (${schedule.halbjahr}, ${schedule.gradeLevel})',
      );

      // Validate URL before making request
      final uri = Uri.tryParse(schedule.fullUrl);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        AppLogger.error(
          'Invalid URL format: ${schedule.fullUrl}',
          module: 'ScheduleService',
        );
        throw Exception('Invalid URL format');
      }

      return RetryUtil.retry<File?>(
        operation: () async {
          AppLogger.debug(
            'Making HTTP request for PDF',
            module: 'ScheduleService',
          );
          final response = await AuthedHttpClient.get(uri, timeout: _timeout);

          if (response.statusCode == 404) {
            AppLogger.warning(
              'PDF not available (404): ${schedule.title}',
              module: 'ScheduleService',
            );
            return null;
          }

          if (response.statusCode != 200) {
            throw Exception(
              'Failed to download PDF: HTTP ${response.statusCode}',
            );
          }

          final file =
              cachedFile; // Use the cachedFile we already determined above

          AppLogger.debug(
            'Saving PDF: ${response.bodyBytes.length} bytes',
            module: 'ScheduleService',
          );
          await file.writeAsBytes(response.bodyBytes);
          AppLogger.success(
            'PDF downloaded successfully: ${schedule.title} (${(response.bodyBytes.length / 1024).toStringAsFixed(1)}KB)',
            module: 'ScheduleService',
          );

          // Validate PDF content
          if (response.bodyBytes.length < 1000) {
            AppLogger.warning(
              'PDF too small, deleting',
              module: 'ScheduleService',
            );
            await file.delete();
            return null;
          }

          final responseText = String.fromCharCodes(
            response.bodyBytes.take(100),
          );
          if (responseText.contains('<html') ||
              responseText.contains('<!DOCTYPE') ||
              responseText.contains('error')) {
            AppLogger.warning(
              'Server returned HTML instead of PDF',
              module: 'ScheduleService',
            );
            await file.delete();
            return null;
          }

          try {
            final pdfBytes = await file.readAsBytes();
            if (pdfBytes.isNotEmpty && !_isValidPdfContent(pdfBytes)) {
              AppLogger.warning(
                'Invalid PDF content',
                module: 'ScheduleService',
              );
              await file.delete();
              return null;
            }
          } catch (e) {
            AppLogger.error(
              'Error validating PDF',
              module: 'ScheduleService',
              error: e,
            );
            await file.delete();
            return null;
          }

          return file;
        },
        maxRetries: 2,
        operationName: 'ScheduleService',
        shouldRetry: RetryUtil.isRetryableError,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to download schedule',
        module: 'ScheduleService',
        error: e,
      );
      rethrow;
    }
  }

  /// Clear the cache to force fresh data on next request
  void clearCache() {
    _cachedSchedules = null;
    _lastFetchTime = null;
    _availabilityCache.clear();
    _lastAvailabilityCheck = null;
    _isRefreshing = false;
    unawaited(DiskCache.instance.delete(_cacheBlob));
  }

  /// Check if PDF content appears to be valid
  bool _isValidPdfContent(List<int> bytes) {
    if (bytes.length < 8) return false;

    try {
      // Check for PDF header signature (%PDF-)
      final header = String.fromCharCodes(bytes.take(8));
      if (!header.startsWith('%PDF-')) {
        return false;
      }

      // Check for PDF trailer (basic validation) - only if bytes are long enough
      if (bytes.length >= 100) {
        final trailerStart = bytes.length - 100;
        final trailer = String.fromCharCodes(
          bytes.skip(trailerStart).take(100),
        );
        if (!trailer.contains('trailer') && !trailer.contains('startxref')) {
          return false;
        }
      } else {
        // For small PDFs, just check header is valid
        // Some very small PDFs might not have trailer in last 100 bytes
      }

      return true;
    } catch (e) {
      // If any string conversion fails, PDF is invalid
      return false;
    }
  }
}

/// Parse HTML to extract schedule information (runs in a background isolate).
_ScheduleScrapeResult _parseScheduleHtml(String htmlContent) {
  final document = html.parse(htmlContent);
  final schedules = <ScheduleItem>[];

  try {
    // Find the module containing schedule links
    final module = document.querySelector('#mod-custom213');
    // Counts for shape-change detection, computed here so the UI thread no
    // longer re-parses the same HTML just to build the fingerprint.
    final primaryLinks =
        document.querySelectorAll('#mod-custom213 a[href*="stundenplan"]').length;
    final fallbackLinks =
        document.querySelectorAll('a[href*="stundenplan"]').length;
    final links = (module ?? document).querySelectorAll(
      'a[href*="stundenplan"]',
    );
    if (module == null && links.isNotEmpty) {
      AppLogger.warning(
        'Schedule parser fallback activated: #mod-custom213 missing',
        module: 'ScheduleService',
      );
    }
    final seenUrls = <String>{}; // Deduplicate by fullUrl

    for (final link in links) {
      final href = link.attributes['href'];
      // Use link text first (it's correct), fallback to title attribute
      final linkText = link.text.trim();
      final title = linkText.isNotEmpty
          ? linkText
          : (link.attributes['title'] ?? '');

      if (href != null && title.isNotEmpty) {
        // Convert relative URL to absolute with validation
        String fullUrl = href;
        try {
          if (href.startsWith('/cm3/../')) {
            fullUrl = href.replaceFirst(
              '/cm3/../',
              'https://lessing-gymnasium-karlsruhe.de/',
            );
          } else if (href.startsWith('/')) {
            fullUrl = 'https://lessing-gymnasium-karlsruhe.de$href';
          }

          // Validate URL format before using
          final uri = Uri.tryParse(fullUrl);
          if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
            AppLogger.warning(
              'Invalid URL format: $fullUrl',
              module: 'ScheduleService',
            );
            continue; // Skip this invalid URL
          }
        } catch (e) {
          AppLogger.warning(
            'Error processing URL: $href - $e',
            module: 'ScheduleService',
          );
          continue; // Skip this URL if processing fails
        }

        // Deduplicate by fullUrl
        if (seenUrls.contains(fullUrl)) {
          AppLogger.debug(
            'Skipping duplicate schedule: $fullUrl',
            module: 'ScheduleService',
          );
          continue;
        }
        seenUrls.add(fullUrl);

        // Extract halbjahr from href URL (most reliable - contains hj1 or hj2)
        final halbjahr = href.contains('hj2')
            ? '2. Halbjahr'
            : href.contains('hj1')
            ? '1. Halbjahr'
            : _extractHalbjahr(title); // Fallback to title parsing

        // Extract grade level from title (link text is correct)
        final gradeLevel = _extractGradeLevel(title);

        AppLogger.debug(
          'Parsed schedule: $title ($halbjahr, $gradeLevel)',
          module: 'ScheduleService',
        );

        schedules.add(
          ScheduleItem(
            title: title,
            url: href,
            halbjahr: halbjahr,
            gradeLevel: gradeLevel,
            fullUrl: fullUrl,
          ),
        );
      }
    }

    ParserGuard.requireMin(
      parser: 'Schedule parser',
      field: 'parsed schedule entries',
      actual: schedules.length,
      min: 1,
    );

    return _ScheduleScrapeResult(
      schedules: schedules,
      primaryLinks: primaryLinks,
      fallbackLinks: fallbackLinks,
      hasModule: module != null,
    );
  } catch (e) {
    // Convert any parsing error to generic server connection error
    throw Exception('Serververbindung fehlgeschlagen');
  }
}

/// Result of parsing the schedule listing page in a background isolate: the
/// parsed schedules plus the link/module counts used for shape tracking.
class _ScheduleScrapeResult {
  const _ScheduleScrapeResult({
    required this.schedules,
    required this.primaryLinks,
    required this.fallbackLinks,
    required this.hasModule,
  });

  final List<ScheduleItem> schedules;
  final int primaryLinks;
  final int fallbackLinks;
  final bool hasModule;
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
  if (title.contains('11-12')) {
    return 'J11/J12'; // Fallback for different formats
  }
  return 'Unbekannt';
}

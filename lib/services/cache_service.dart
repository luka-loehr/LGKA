// Copyright Luka Löhr 2026

import 'package:shared_preferences/shared_preferences.dart';

/// Cache keys for different data types
enum CacheKey {
  substitutions,
  schedules,
  scheduleAvailability,
  news,
  weather,
  events,
}

/// Centralized cache service for managing cache validity across all services
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  /// Cache validity durations for each data type.
  static const Map<CacheKey, Duration> _cacheValidityDurations = {
    CacheKey.substitutions: Duration(minutes: 1),
    // Schedules (semester timetable PDFs) refresh at most hourly — they
    // survive across app launches via the persisted timestamp below, so the
    // schedule is no longer re-scraped on every app open.
    CacheKey.schedules: Duration(hours: 1),
    CacheKey.scheduleAvailability: Duration(minutes: 15),
    CacheKey.news: Duration(hours: 1),
    CacheKey.weather: Duration(hours: 1),
    CacheKey.events: Duration(hours: 1),
  };

  /// Map to store last fetch time for each cache key
  final Map<CacheKey, DateTime?> _lastFetchTimes = {};

  /// SharedPreferences instance used to persist fetch timestamps across launches.
  /// Null until [init] is called (e.g. in unit tests), in which case the service
  /// degrades gracefully to in-memory-only behaviour.
  SharedPreferences? _prefs;

  static const String _tsKeyPrefix = 'cache_ts_';

  /// Timestamp when app was last backgrounded (null if never backgrounded in this session)
  DateTime? _lastBackgroundTime;

  /// Hydrate persisted fetch timestamps from disk. Call once at startup before
  /// any data preload so cold-start cache validity reflects the last real fetch.
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    for (final key in CacheKey.values) {
      final millis = prefs.getInt('$_tsKeyPrefix${key.name}');
      if (millis != null) {
        _lastFetchTimes[key] = DateTime.fromMillisecondsSinceEpoch(millis);
      }
    }
  }

  /// Get the cache validity duration for a specific cache key
  Duration getCacheValidity(CacheKey key) {
    return _cacheValidityDurations[key] ?? const Duration(minutes: 5);
  }

  /// Mark that the app was backgrounded
  void markAppBackgrounded() {
    _lastBackgroundTime = DateTime.now();
  }

  /// Keys whose cache is invalidated when the app is backgrounded.
  /// Schedules use a pure 24 h time-based window and are NOT in this set.
  static const Set<CacheKey> _backgroundInvalidatedKeys = {
    CacheKey.substitutions,
    CacheKey.weather,
  };

  /// Keys that use a time-based validity window (even while the app is open).
  static const Set<CacheKey> _timeBasedRefreshKeys = {
    CacheKey.substitutions,
    CacheKey.weather,
    CacheKey.schedules, // 24 h window
    CacheKey.news,      // 1 h window
    CacheKey.events,    // 1 h window
  };

  /// Check if cache is valid for a given key.
  bool isCacheValid(CacheKey key, {DateTime? lastFetchTime}) {
    final fetchTime = lastFetchTime ?? _lastFetchTimes[key];
    if (fetchTime == null) return false;

    // Background-invalidated keys: cache is stale if last fetch pre-dates backgrounding.
    if (_backgroundInvalidatedKeys.contains(key) && _lastBackgroundTime != null) {
      if (fetchTime.isBefore(_lastBackgroundTime!)) return false;
    }

    // Time-based keys: check elapsed time against validity window.
    if (_timeBasedRefreshKeys.contains(key)) {
      final elapsed = DateTime.now().difference(fetchTime);
      return elapsed < getCacheValidity(key);
    }

    // Everything else (scheduleAvailability): valid while app is open.
    return true;
  }

  /// Update the last fetch time for a cache key (persisted across launches).
  void updateCacheTimestamp(CacheKey key, DateTime? timestamp) {
    final ts = timestamp ?? DateTime.now();
    _lastFetchTimes[key] = ts;
    _prefs?.setInt('$_tsKeyPrefix${key.name}', ts.millisecondsSinceEpoch);
  }

  /// Get the last fetch time for a cache key
  DateTime? getLastFetchTime(CacheKey key) {
    return _lastFetchTimes[key];
  }

  /// Get the timestamp when app was last backgrounded (null if never backgrounded)
  DateTime? getLastBackgroundTime() {
    return _lastBackgroundTime;
  }

  /// Clear cache timestamp for a specific key
  void clearCache(CacheKey key) {
    _lastFetchTimes[key] = null;
    _prefs?.remove('$_tsKeyPrefix${key.name}');
  }

  /// Clear all cache timestamps
  void clearAllCaches() {
    _lastFetchTimes.clear();
    for (final key in CacheKey.values) {
      _prefs?.remove('$_tsKeyPrefix${key.name}');
    }
  }

  /// Mark app as backgrounded (clears cache validity)
  void onAppBackgrounded() {
    markAppBackgrounded();
  }

  /// Check if cache is expired (opposite of isCacheValid)
  bool isCacheExpired(CacheKey key, {DateTime? lastFetchTime}) {
    return !isCacheValid(key, lastFetchTime: lastFetchTime);
  }
}

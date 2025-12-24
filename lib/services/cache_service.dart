// Copyright Luka Löhr 2025

import 'dart:async';

/// Cache keys for different data types
enum CacheKey {
  substitutions,
  schedules,
  scheduleAvailability,
  news,
  weather,
}

/// Centralized cache service for managing cache validity across all services
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  /// Cache validity durations for each cache type (kept for backward compatibility, but not used)
  static const Map<CacheKey, Duration> _cacheValidityDurations = {
    CacheKey.substitutions: Duration(minutes: 2),
    CacheKey.schedules: Duration(minutes: 5),
    CacheKey.scheduleAvailability: Duration(minutes: 15),
    CacheKey.news: Duration(minutes: 5),
    CacheKey.weather: Duration(minutes: 5),
  };

  /// Map to store last fetch time for each cache key
  final Map<CacheKey, DateTime?> _lastFetchTimes = {};
  
  /// Timestamp when app was last backgrounded (null if never backgrounded in this session)
  DateTime? _lastBackgroundTime;

  /// Get the cache validity duration for a specific cache key
  Duration getCacheValidity(CacheKey key) {
    return _cacheValidityDurations[key] ?? const Duration(minutes: 5);
  }

  /// Mark that the app was backgrounded
  void markAppBackgrounded() {
    _lastBackgroundTime = DateTime.now();
  }

  /// Cache keys that should refresh periodically while app is open (time-based)
  static const Set<CacheKey> _timeBasedRefreshKeys = {
    CacheKey.substitutions,
    CacheKey.weather,
  };

  /// Check if cache is valid for a given key
  /// Cache is valid if:
  /// 1. There is a fetch time
  /// 2. App was not backgrounded since the last fetch (or was never backgrounded)
  /// 3. For substitutions and weather: if app is open, data is still within validity duration (time-based refresh)
  /// 4. For schedules and news: always valid while app is open (only invalidate when backgrounded)
  bool isCacheValid(CacheKey key, {DateTime? lastFetchTime}) {
    final fetchTime = lastFetchTime ?? _lastFetchTimes[key];
    if (fetchTime == null) return false;

    // If app was backgrounded, cache is invalid (must refetch when returning)
    if (_lastBackgroundTime != null) {
      // Cache is valid only if last fetch happened after the app was backgrounded
      // (i.e., data was fetched after returning to foreground)
      return fetchTime.isAfter(_lastBackgroundTime!);
    }

    // App is still open
    // Only substitutions and weather use time-based expiration while app is open
    if (_timeBasedRefreshKeys.contains(key)) {
      final validityDuration = getCacheValidity(key);
      final elapsed = DateTime.now().difference(fetchTime);
      return elapsed < validityDuration;
    }

    // For schedules, news, and scheduleAvailability: always valid while app is open
    // (only invalidate when app is backgrounded)
    return true;
  }

  /// Update the last fetch time for a cache key
  void updateCacheTimestamp(CacheKey key, DateTime? timestamp) {
    _lastFetchTimes[key] = timestamp ?? DateTime.now();
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
  }

  /// Clear all cache timestamps
  void clearAllCaches() {
    _lastFetchTimes.clear();
  }

  /// Mark app as backgrounded (clears cache validity)
  void onAppBackgrounded() {
    markAppBackgrounded();
  }

  /// Check if cache is expired (opposite of isCacheValid)
  bool isCacheExpired(CacheKey key, {DateTime? lastFetchTime}) {
    return !isCacheValid(key, lastFetchTime: lastFetchTime);
  }

  /// Get time until cache expires (returns Duration.zero if already expired)
  Duration getTimeUntilExpiry(CacheKey key, {DateTime? lastFetchTime}) {
    final fetchTime = lastFetchTime ?? _lastFetchTimes[key];
    if (fetchTime == null) return Duration.zero;

    final validityDuration = getCacheValidity(key);
    final elapsed = DateTime.now().difference(fetchTime);
    final remaining = validityDuration - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }
}

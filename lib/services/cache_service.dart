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

  /// Cache validity durations for each cache type
  static const Map<CacheKey, Duration> _cacheValidityDurations = {
    CacheKey.substitutions: Duration(minutes: 2),
    CacheKey.schedules: Duration(minutes: 5),
    CacheKey.scheduleAvailability: Duration(minutes: 15),
    CacheKey.news: Duration(minutes: 5),
    CacheKey.weather: Duration(minutes: 5),
  };

  /// Map to store last fetch time for each cache key
  final Map<CacheKey, DateTime?> _lastFetchTimes = {};

  /// Get the cache validity duration for a specific cache key
  Duration getCacheValidity(CacheKey key) {
    return _cacheValidityDurations[key] ?? const Duration(minutes: 5);
  }

  /// Check if cache is valid for a given key
  bool isCacheValid(CacheKey key, {DateTime? lastFetchTime}) {
    final fetchTime = lastFetchTime ?? _lastFetchTimes[key];
    if (fetchTime == null) return false;

    final validityDuration = getCacheValidity(key);
    return DateTime.now().difference(fetchTime) < validityDuration;
  }

  /// Update the last fetch time for a cache key
  void updateCacheTimestamp(CacheKey key, DateTime? timestamp) {
    _lastFetchTimes[key] = timestamp ?? DateTime.now();
  }

  /// Get the last fetch time for a cache key
  DateTime? getLastFetchTime(CacheKey key) {
    return _lastFetchTimes[key];
  }

  /// Clear cache timestamp for a specific key
  void clearCache(CacheKey key) {
    _lastFetchTimes[key] = null;
  }

  /// Clear all cache timestamps
  void clearAllCaches() {
    _lastFetchTimes.clear();
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

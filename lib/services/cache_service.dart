// Copyright Luka Löhr 2026

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

  /// Cache validity durations for each data type.
  static const Map<CacheKey, Duration> _cacheValidityDurations = {
    CacheKey.substitutions: Duration(minutes: 1),
    CacheKey.schedules: Duration(hours: 24),
    CacheKey.scheduleAvailability: Duration(minutes: 15),
    CacheKey.news: Duration(minutes: 5),
    CacheKey.weather: Duration(minutes: 1),
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

  /// Keys whose cache is invalidated when the app is backgrounded.
  /// Schedules use a pure 24 h time-based window and are NOT in this set.
  static const Set<CacheKey> _backgroundInvalidatedKeys = {
    CacheKey.substitutions,
    CacheKey.weather,
    CacheKey.news,
  };

  /// Keys that use a time-based validity window (even while the app is open).
  static const Set<CacheKey> _timeBasedRefreshKeys = {
    CacheKey.substitutions,
    CacheKey.weather,
    CacheKey.schedules, // 24 h window — never invalidated by backgrounding
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

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lgka_flutter/services/cache_service.dart';

/// Verifies the cold-start persistence behaviour that stops data (e.g. the
/// schedule) from being re-loaded on every app open: fetch timestamps survive
/// a process restart via SharedPreferences.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CacheService().clearAllCaches();
  });

  test('hydrates a persisted timestamp on init so cache stays valid across launches', () async {
    final twentyMinAgo = DateTime.now().subtract(const Duration(minutes: 20));
    SharedPreferences.setMockInitialValues({
      'cache_ts_news': twentyMinAgo.millisecondsSinceEpoch,
    });
    final prefs = await SharedPreferences.getInstance();

    await CacheService().init(prefs);

    // News TTL is 1h; a 20-min-old persisted timestamp must still be valid
    // after a simulated cold start (no in-memory state, only the persisted one).
    expect(CacheService().isCacheValid(CacheKey.news), isTrue);
    expect(CacheService().getLastFetchTime(CacheKey.news), isNotNull);
  });

  test('expired persisted timestamp is treated as stale on init', () async {
    final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
    SharedPreferences.setMockInitialValues({
      'cache_ts_news': twoHoursAgo.millisecondsSinceEpoch,
    });
    final prefs = await SharedPreferences.getInstance();

    await CacheService().init(prefs);

    expect(CacheService().isCacheValid(CacheKey.news), isFalse);
  });

  test('updateCacheTimestamp writes through to SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await CacheService().init(prefs);

    final now = DateTime.now();
    CacheService().updateCacheTimestamp(CacheKey.schedules, now);

    expect(prefs.getInt('cache_ts_schedules'), now.millisecondsSinceEpoch);
  });

  test('clearCache removes the persisted timestamp', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await CacheService().init(prefs);

    CacheService().updateCacheTimestamp(CacheKey.weather, DateTime.now());
    expect(prefs.getInt('cache_ts_weather'), isNotNull);

    CacheService().clearCache(CacheKey.weather);
    expect(prefs.getInt('cache_ts_weather'), isNull);
  });
}

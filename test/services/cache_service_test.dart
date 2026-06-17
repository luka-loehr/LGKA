import 'package:flutter_test/flutter_test.dart';
import 'package:lgka_flutter/services/cache_service.dart';

void main() {
  late CacheService cacheService;

  setUp(() {
    cacheService = CacheService();
    cacheService.clearAllCaches();
  });

  test('returns false when cache has no fetch timestamp', () {
    expect(cacheService.isCacheValid(CacheKey.news), isFalse);
    expect(cacheService.isCacheExpired(CacheKey.news), isTrue);
  });

  test('treats news cache as valid within one-hour window', () {
    final freshTime = DateTime.now().subtract(const Duration(minutes: 20));

    expect(
      cacheService.isCacheValid(CacheKey.news, lastFetchTime: freshTime),
      isTrue,
    );
  });

  test('invalidates substitutions cache after app background if fetched before', () {
    final staleTime = DateTime.now().subtract(const Duration(minutes: 2));

    cacheService.updateCacheTimestamp(CacheKey.substitutions, staleTime);
    cacheService.markAppBackgrounded();

    expect(cacheService.isCacheValid(CacheKey.substitutions), isFalse);
  });

  test('keeps schedule availability valid while app stays open', () {
    final oldTime = DateTime.now().subtract(const Duration(days: 3));

    expect(
      cacheService.isCacheValid(CacheKey.scheduleAvailability, lastFetchTime: oldTime),
      isTrue,
    );
  });
}

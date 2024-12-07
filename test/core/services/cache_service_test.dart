import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yogicast/core/services/cache_service.dart';
import 'package:yogicast/config/app_config.dart';
import '../../helpers/test_helper.dart';

void main() {
  group('CacheService', () {
    late CacheService cacheService;
    late SharedPreferences preferences;

    setUp(() async {
      await setupTestEnvironment();
      preferences = await SharedPreferences.getInstance();
      cacheService = CacheService(preferences);
    });

    test('initially returns empty list', () async {
      final podcasts = await cacheService.getCachedPodcasts();
      expect(podcasts, isEmpty);
    });

    test('can cache and retrieve a podcast', () async {
      final podcast = createTestPodcast();
      await cacheService.cachePodcast(podcast);

      final cachedPodcasts = await cacheService.getCachedPodcasts();
      expect(cachedPodcasts.length, equals(1));
      expect(cachedPodcasts.first.id, equals(podcast.id));
    });

    test('updates existing podcast', () async {
      final podcast = createTestPodcast();
      await cacheService.cachePodcast(podcast);

      final updatedPodcast = podcast.copyWith(
        title: 'Updated Title',
        lastModified: DateTime.now(),
      );
      await cacheService.cachePodcast(updatedPodcast);

      final cachedPodcasts = await cacheService.getCachedPodcasts();
      expect(cachedPodcasts.length, equals(1));
      expect(cachedPodcasts.first.title, equals('Updated Title'));
    });

    test('removes expired podcasts', () async {
      final expiredDate = DateTime.now().subtract(
        AppConfig.cacheDuration + const Duration(days: 1),
      );
      
      final expiredPodcast = createTestPodcast(
        id: 'expired',
        createdAt: expiredDate,
        lastModified: expiredDate,
      );
      
      final validPodcast = createTestPodcast(id: 'valid');

      await cacheService.cachePodcast(expiredPodcast);
      await cacheService.cachePodcast(validPodcast);

      final cachedPodcasts = await cacheService.getCachedPodcasts();
      expect(cachedPodcasts.length, equals(1));
      expect(cachedPodcasts.first.id, equals(validPodcast.id));
    });

    test('enforces cache size limit', () async {
      // Create a large podcast that will exceed cache size
      final largePodcast = createTestPodcast(
        segments: List.generate(100, (index) => createTestSegment(
          id: 'segment-$index',
          content: List.generate(1000, (i) => 'a').join(), // 1KB content
        )),
      );

      await cacheService.cachePodcast(largePodcast);
      
      // Add another podcast
      final newPodcast = createTestPodcast(id: 'new');
      await cacheService.cachePodcast(newPodcast);

      final cachedPodcasts = await cacheService.getCachedPodcasts();
      
      // Verify the new podcast is cached
      expect(
        cachedPodcasts.any((p) => p.id == 'new'),
        isTrue,
      );
      
      // Verify total size is within limit
      final totalSize = cachedPodcasts
          .map((p) => p.toJson().toString().length)
          .reduce((a, b) => a + b);
      expect(totalSize, lessThanOrEqualTo(AppConfig.maxCacheSize));
    });

    test('clear cache removes all podcasts', () async {
      await cacheService.cachePodcast(createTestPodcast(id: '1'));
      await cacheService.cachePodcast(createTestPodcast(id: '2'));

      await cacheService.clearCache();

      final cachedPodcasts = await cacheService.getCachedPodcasts();
      expect(cachedPodcasts, isEmpty);
    });

    test('sorts podcasts by last modified date', () async {
      final now = DateTime.now();
      
      final oldest = createTestPodcast(
        id: 'oldest',
        lastModified: now.subtract(const Duration(days: 2)),
      );
      
      final middle = createTestPodcast(
        id: 'middle',
        lastModified: now.subtract(const Duration(days: 1)),
      );
      
      final newest = createTestPodcast(
        id: 'newest',
        lastModified: now,
      );

      // Add in random order
      await cacheService.cachePodcast(middle);
      await cacheService.cachePodcast(oldest);
      await cacheService.cachePodcast(newest);

      final cachedPodcasts = await cacheService.getCachedPodcasts();
      
      // Verify order
      expect(cachedPodcasts[0].id, equals(newest.id));
      expect(cachedPodcasts[1].id, equals(middle.id));
      expect(cachedPodcasts[2].id, equals(oldest.id));
    });

    test('handles invalid cache data gracefully', () async {
      // Manually insert invalid JSON
      await preferences.setString('podcasts', 'invalid json');

      final cachedPodcasts = await cacheService.getCachedPodcasts();
      expect(cachedPodcasts, isEmpty);
    });

    test('handles null lastModified date', () async {
      final podcast = createTestPodcast(lastModified: null);
      await cacheService.cachePodcast(podcast);

      final cachedPodcasts = await cacheService.getCachedPodcasts();
      expect(cachedPodcasts.length, equals(1));
      expect(cachedPodcasts.first.lastModified, isNull);
    });
  });
}

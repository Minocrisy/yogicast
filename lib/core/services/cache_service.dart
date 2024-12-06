import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yogicast/config/app_config.dart';
import 'package:yogicast/core/models/podcast.dart';

class CacheService {
  static const String _podcastsKey = 'podcasts';
  static const String _lastCleanupKey = 'last_cache_cleanup';
  
  final SharedPreferences _prefs;

  CacheService(this._prefs);

  Future<void> cachePodcast(Podcast podcast) async {
    try {
      final podcasts = await getCachedPodcasts();
      
      // Update existing or add new
      final index = podcasts.indexWhere((p) => p.id == podcast.id);
      if (index != -1) {
        podcasts[index] = podcast;
      } else {
        podcasts.add(podcast);
      }

      // Sort by last modified/created date
      podcasts.sort((a, b) => 
        (b.lastModified ?? b.createdAt).compareTo(a.lastModified ?? a.createdAt)
      );

      // Enforce cache size limit
      while (_calculateCacheSize(podcasts) > AppConfig.maxCacheSize) {
        podcasts.removeLast();
      }

      // Save updated cache
      await _prefs.setString(_podcastsKey, jsonEncode(
        podcasts.map((p) => p.toJson()).toList(),
      ));

      // Perform cache cleanup if needed
      await _performCacheCleanupIfNeeded();
    } catch (e) {
      throw Exception('Failed to cache podcast: $e');
    }
  }

  Future<List<Podcast>> getCachedPodcasts() async {
    try {
      final jsonString = _prefs.getString(_podcastsKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
        .map((json) => Podcast.fromJson(json as Map<String, dynamic>))
        .where((podcast) => _isWithinCacheDuration(podcast))
        .toList();
    } catch (e) {
      throw Exception('Failed to get cached podcasts: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      await _prefs.remove(_podcastsKey);
      await _prefs.remove(_lastCleanupKey);
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }

  bool _isWithinCacheDuration(Podcast podcast) {
    final now = DateTime.now();
    final lastModified = podcast.lastModified ?? podcast.createdAt;
    return now.difference(lastModified) <= AppConfig.cacheDuration;
  }

  int _calculateCacheSize(List<Podcast> podcasts) {
    final jsonString = jsonEncode(podcasts.map((p) => p.toJson()).toList());
    return jsonString.length;
  }

  Future<void> _performCacheCleanupIfNeeded() async {
    try {
      final lastCleanup = DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt(_lastCleanupKey) ?? 0
      );
      
      final now = DateTime.now();
      if (now.difference(lastCleanup) > const Duration(days: 1)) {
        final podcasts = await getCachedPodcasts();
        
        // Remove expired podcasts
        podcasts.removeWhere((podcast) => !_isWithinCacheDuration(podcast));
        
        // Save updated cache
        await _prefs.setString(_podcastsKey, jsonEncode(
          podcasts.map((p) => p.toJson()).toList(),
        ));
        
        // Update last cleanup time
        await _prefs.setInt(_lastCleanupKey, now.millisecondsSinceEpoch);
      }
    } catch (e) {
      // Log error but don't throw since this is a background operation
      debugPrint('Cache cleanup failed: $e');
    }
  }
}

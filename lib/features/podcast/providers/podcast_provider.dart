import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:yogicast/core/models/podcast.dart';
import 'package:yogicast/core/services/groq_service.dart';
import 'package:yogicast/core/services/replicate_service.dart';
import 'package:yogicast/core/services/cache_service.dart';

class PodcastProvider extends ChangeNotifier {
  final GroqService _groqService;
  final ReplicateService _replicateService;
  final CacheService _cacheService;
  final List<Podcast> _podcasts = [];
  Podcast? _currentPodcast;

  PodcastProvider(
    this._groqService,
    this._replicateService,
    this._cacheService,
  );

  List<Podcast> get podcasts => List.unmodifiable(_podcasts);
  Podcast? get currentPodcast => _currentPodcast;

  Future<void> initialize() async {
    if (_podcasts.isEmpty) {
      final cachedPodcasts = await _cacheService.getCachedPodcasts();
      _podcasts.addAll(cachedPodcasts);
      notifyListeners();
    }
  }

  Future<void> createPodcast(Podcast podcast) async {
    try {
      _podcasts.add(podcast);
      _currentPodcast = podcast;
      await _cacheService.cachePodcast(podcast);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating podcast: $e');
      rethrow;
    }
  }

  Future<void> updatePodcast(Podcast podcast) async {
    try {
      final index = _podcasts.indexWhere((p) => p.id == podcast.id);
      if (index != -1) {
        _podcasts[index] = podcast;
        if (_currentPodcast?.id == podcast.id) {
          _currentPodcast = podcast;
        }
        await _cacheService.cachePodcast(podcast);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating podcast: $e');
      rethrow;
    }
  }

  Future<void> generatePodcastContent(Podcast podcast) async {
    try {
      // Update status to generating
      var updatedPodcast = podcast.copyWith(
        status: PodcastStatus.generating,
        lastModified: DateTime.now(),
      );
      await updatePodcast(updatedPodcast);

      // Generate main script
      final mainScript = await _groqService.generatePodcastScript(
        title: podcast.title,
        description: podcast.description,
        content: podcast.segments.first.content,
      );

      // Generate individual segments
      final segmentScripts = await _groqService.generateSegmentScripts(
        mainScript: mainScript,
        numberOfSegments: 3,
      );

      // Create new segments with generated content
      final newSegments = await Future.wait(
        segmentScripts.map((script) async {
          final description = await _groqService.generateSegmentDescription(script);
          return PodcastSegment(
            id: const Uuid().v4(),
            content: script,
            status: SegmentStatus.pending,
          );
        }),
      );

      // Update podcast with new segments
      updatedPodcast = updatedPodcast.copyWith(
        segments: newSegments,
        lastModified: DateTime.now(),
      );
      await updatePodcast(updatedPodcast);

      // Generate audio for each segment
      await generateAudio(updatedPodcast);

      // Generate visuals for each segment
      await generateVisuals(updatedPodcast);

      // Generate videos for each segment
      await generateVideos(updatedPodcast);
    } catch (e) {
      debugPrint('Error generating podcast content: $e');
      final errorPodcast = podcast.copyWith(
        status: PodcastStatus.error,
        lastModified: DateTime.now(),
      );
      await updatePodcast(errorPodcast);
      rethrow;
    }
  }

  Future<void> generateAudio(Podcast podcast) async {
    try {
      var updatedPodcast = podcast.copyWith(
        status: PodcastStatus.generating,
        lastModified: DateTime.now(),
      );
      await updatePodcast(updatedPodcast);

      // Update segments to show audio generation status
      var segments = podcast.segments.map((segment) => 
        segment.copyWith(status: SegmentStatus.generatingAudio)
      ).toList();
      
      updatedPodcast = updatedPodcast.copyWith(
        segments: segments,
        lastModified: DateTime.now(),
      );
      await updatePodcast(updatedPodcast);

      // Generate audio for each segment
      final audioUrls = await _replicateService.generateSegmentAudio(
        segments.map((s) => s.content).toList(),
      );

      // Update segments with audio paths
      segments = List.generate(segments.length, (index) {
        final segment = segments[index];
        final audioUrl = audioUrls[index];
        
        return segment.copyWith(
          audioPath: audioUrl,
          status: audioUrl.isEmpty ? SegmentStatus.error : SegmentStatus.complete,
        );
      });

      // Update podcast with new segments
      updatedPodcast = updatedPodcast.copyWith(
        segments: segments,
        status: segments.any((s) => s.status == SegmentStatus.error) 
          ? PodcastStatus.error 
          : PodcastStatus.ready,
        lastModified: DateTime.now(),
      );
      await updatePodcast(updatedPodcast);
    } catch (e) {
      debugPrint('Error generating audio: $e');
      final errorPodcast = podcast.copyWith(
        status: PodcastStatus.error,
        lastModified: DateTime.now(),
      );
      await updatePodcast(errorPodcast);
      rethrow;
    }
  }

  Future<void> generateVisuals(Podcast podcast) async {
    try {
      var updatedPodcast = podcast.copyWith(
        status: PodcastStatus.generating,
        lastModified: DateTime.now(),
      );
      await updatePodcast(updatedPodcast);

      // Update segments to show visual generation status
      var segments = podcast.segments.map((segment) =>
        segment.copyWith(status: SegmentStatus.generatingVisual)
      ).toList();
      
      updatedPodcast = updatedPodcast.copyWith(
        segments: segments,
        lastModified: DateTime.now(),
      );
      await updatePodcast(updatedPodcast);

      // Generate thumbnail for the podcast
      final thumbnailUrl = await _replicateService.generatePodcastThumbnail(
        title: podcast.title,
        description: podcast.description,
      );

      // Generate visuals for each segment
      final visualUrls = await _replicateService.generateSegmentVisuals(
        segments.map((s) => s.content).toList(),
      );

      // Update segments with visual paths
      segments = List.generate(segments.length, (index) {
        final segment = segments[index];
        final visualUrl = visualUrls[index];
        
        return segment.copyWith(
          visualPath: visualUrl,
          status: visualUrl.isEmpty ? SegmentStatus.error : SegmentStatus.complete,
        );
      });

      // Update podcast with new segments and status
      updatedPodcast = updatedPodcast.copyWith(
        segments: segments,
        status: segments.any((s) => s.status == SegmentStatus.error)
          ? PodcastStatus.error
          : PodcastStatus.ready,
        lastModified: DateTime.now(),
      );
      await updatePodcast(updatedPodcast);
    } catch (e) {
      debugPrint('Error generating visuals: $e');
      final errorPodcast = podcast.copyWith(
        status: PodcastStatus.error,
        lastModified: DateTime.now(),
      );
      await updatePodcast(errorPodcast);
      rethrow;
    }
  }

  Future<void> generateVideos(Podcast podcast) async {
    try {
      var updatedPodcast = podcast.copyWith(
        status: PodcastStatus.generating,
        lastModified: DateTime.now(),
      );
      await updatePodcast(updatedPodcast);

      // Update segments to show video generation status
      var segments = podcast.segments.map((segment) =>
        segment.copyWith(status: SegmentStatus.generatingVideo)
      ).toList();
      
      updatedPodcast = updatedPodcast.copyWith(
        segments: segments,
        lastModified: DateTime.now(),
      );
      await updatePodcast(updatedPodcast);

      // Generate videos for each segment
      final validImageUrls = segments
          .map((s) => s.visualPath)
          .where((url) => url != null)
          .map((url) => url!)
          .toList();

      final videoUrls = await _replicateService.generateSegmentVideos(
        segments.map((s) => s.content).toList(),
        imageUrls: validImageUrls,
      );

      // Update segments with video paths
      segments = List.generate(segments.length, (index) {
        final segment = segments[index];
        final videoUrl = videoUrls[index];
        
        return segment.copyWith(
          videoPath: videoUrl,
          status: videoUrl.isEmpty ? SegmentStatus.error : SegmentStatus.complete,
        );
      });

      // Update podcast with new segments and status
      updatedPodcast = updatedPodcast.copyWith(
        segments: segments,
        status: segments.any((s) => s.status == SegmentStatus.error)
          ? PodcastStatus.error
          : PodcastStatus.ready,
        lastModified: DateTime.now(),
      );
      await updatePodcast(updatedPodcast);
    } catch (e) {
      debugPrint('Error generating videos: $e');
      final errorPodcast = podcast.copyWith(
        status: PodcastStatus.error,
        lastModified: DateTime.now(),
      );
      await updatePodcast(errorPodcast);
      rethrow;
    }
  }
}

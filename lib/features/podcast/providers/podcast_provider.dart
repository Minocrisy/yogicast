import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:yogicast/core/models/podcast.dart';
import 'package:yogicast/core/services/groq_service.dart';
import 'package:yogicast/core/services/replicate_service.dart';

class PodcastProvider extends ChangeNotifier {
  final GroqService _groqService;
  final ReplicateService _replicateService;
  final List<Podcast> _podcasts = [];
  Podcast? _currentPodcast;

  PodcastProvider(this._groqService, this._replicateService);

  List<Podcast> get podcasts => List.unmodifiable(_podcasts);
  Podcast? get currentPodcast => _currentPodcast;

  Future<void> createPodcast(Podcast podcast) async {
    try {
      _podcasts.add(podcast);
      _currentPodcast = podcast;
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating podcast: $e');
      rethrow;
    }
  }

  Future<void> generatePodcastContent(Podcast podcast) async {
    try {
      // Update status to generating
      var updatedPodcast = podcast.copyWith(
        status: PodcastStatus.generating,
      );
      _updatePodcast(updatedPodcast);

      // Generate main script
      final mainScript = await _groqService.generatePodcastScript(
        title: podcast.title,
        description: podcast.description,
        content: podcast.segments.first.content,
      );

      // Generate individual segments
      final segmentScripts = await _groqService.generateSegmentScripts(
        mainScript: mainScript,
        numberOfSegments: 3, // We can make this configurable later
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
      );
      _updatePodcast(updatedPodcast);

      // Generate visuals for each segment
      await generateVisuals(updatedPodcast);
    } catch (e) {
      debugPrint('Error generating podcast content: $e');
      final errorPodcast = podcast.copyWith(
        status: PodcastStatus.error,
      );
      _updatePodcast(errorPodcast);
      rethrow;
    }
  }

  Future<void> generateVisuals(Podcast podcast) async {
    try {
      var updatedPodcast = podcast.copyWith(
        status: PodcastStatus.generating,
      );
      _updatePodcast(updatedPodcast);

      // Generate thumbnail for the podcast
      final thumbnailUrl = await _replicateService.generatePodcastThumbnail(
        title: podcast.title,
        description: podcast.description,
      );

      // Generate visuals for each segment
      final updatedSegments = await Future.wait(
        podcast.segments.map((segment) async {
          try {
            final visualUrl = await _replicateService.generateSegmentVisual(
              content: segment.content,
              description: segment.content.length > 200 
                  ? '${segment.content.substring(0, 200)}...' 
                  : segment.content,
            );

            return segment.copyWith(
              visualPath: visualUrl,
              status: SegmentStatus.complete,
            );
          } catch (e) {
            debugPrint('Error generating visual for segment ${segment.id}: $e');
            return segment.copyWith(
              status: SegmentStatus.error,
            );
          }
        }),
      );

      // Update podcast with new segments and status
      updatedPodcast = updatedPodcast.copyWith(
        segments: updatedSegments,
        status: PodcastStatus.ready,
      );
      _updatePodcast(updatedPodcast);
    } catch (e) {
      debugPrint('Error generating visuals: $e');
      final errorPodcast = podcast.copyWith(
        status: PodcastStatus.error,
      );
      _updatePodcast(errorPodcast);
      rethrow;
    }
  }

  void _updatePodcast(Podcast podcast) {
    final index = _podcasts.indexWhere((p) => p.id == podcast.id);
    if (index != -1) {
      _podcasts[index] = podcast;
      if (_currentPodcast?.id == podcast.id) {
        _currentPodcast = podcast;
      }
      notifyListeners();
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:yogicast/core/models/podcast.dart';
import 'package:yogicast/core/services/groq_service.dart';
import 'package:yogicast/core/services/replicate_service.dart';
import 'package:yogicast/core/services/cache_service.dart';
import 'package:yogicast/features/podcast/providers/podcast_provider.dart';

// Generate mock classes
@GenerateNiceMocks([
  MockSpec<GroqService>(),
  MockSpec<ReplicateService>(),
  MockSpec<CacheService>(),
])
import 'podcast_provider_test.mocks.dart';

void main() {
  group('PodcastProvider', () {
    late PodcastProvider provider;
    late MockGroqService mockGroqService;
    late MockReplicateService mockReplicateService;
    late MockCacheService mockCacheService;

    setUp(() {
      mockGroqService = MockGroqService();
      mockReplicateService = MockReplicateService();
      mockCacheService = MockCacheService();
      provider = PodcastProvider(
        mockGroqService,
        mockReplicateService,
        mockCacheService,
      );
    });

    Podcast createTestPodcast({String? id}) {
      return Podcast(
        id: id ?? 'test-id',
        title: 'Test Podcast',
        description: 'Test Description',
        segments: [
          PodcastSegment(
            id: 'segment-1',
            content: 'Initial content',
            status: SegmentStatus.pending,
          ),
        ],
        createdAt: DateTime.now(),
      );
    }

    test('initialize loads cached podcasts', () async {
      final cachedPodcasts = [createTestPodcast()];
      when(mockCacheService.getCachedPodcasts())
          .thenAnswer((_) async => cachedPodcasts);

      await provider.initialize();

      expect(provider.podcasts, equals(cachedPodcasts));
      verify(mockCacheService.getCachedPodcasts()).called(1);
    });

    test('createPodcast adds podcast and caches it', () async {
      final podcast = createTestPodcast();
      
      await provider.createPodcast(podcast);

      expect(provider.podcasts, contains(podcast));
      expect(provider.currentPodcast, equals(podcast));
      verify(mockCacheService.cachePodcast(podcast)).called(1);
    });

    test('generatePodcastContent follows correct generation flow', () async {
      final podcast = createTestPodcast();
      const mainScript = 'Generated main script';
      final segmentScripts = ['Segment 1', 'Segment 2'];
      const segmentDescription = 'Segment description';
      const audioUrl = 'audio/url.mp3';
      const visualUrl = 'image/url.jpg';

      // Mock Groq service responses
      when(mockGroqService.generatePodcastScript(
        title: anyNamed('title'),
        description: anyNamed('description'),
        content: anyNamed('content'),
      )).thenAnswer((_) async => mainScript);

      when(mockGroqService.generateSegmentScripts(
        mainScript: anyNamed('mainScript'),
        numberOfSegments: anyNamed('numberOfSegments'),
      )).thenAnswer((_) async => segmentScripts);

      when(mockGroqService.generateSegmentDescription(any))
          .thenAnswer((_) async => segmentDescription);

      // Mock Replicate service responses
      when(mockReplicateService.generateSegmentAudio(any))
          .thenAnswer((_) async => [audioUrl]);

      when(mockReplicateService.generatePodcastThumbnail(
        title: anyNamed('title'),
        description: anyNamed('description'),
      )).thenAnswer((_) async => visualUrl);

      when(mockReplicateService.generateSegmentVisuals(any))
          .thenAnswer((_) async => [visualUrl]);

      // Execute generation
      await provider.generatePodcastContent(podcast);

      // Verify the generation flow
      verify(mockGroqService.generatePodcastScript(
        title: podcast.title,
        description: podcast.description,
        content: podcast.segments.first.content,
      )).called(1);

      verify(mockGroqService.generateSegmentScripts(
        mainScript: mainScript,
        numberOfSegments: 3,
      )).called(1);

      verify(mockGroqService.generateSegmentDescription(any))
          .called(segmentScripts.length);

      verify(mockReplicateService.generateSegmentAudio(any)).called(1);
      verify(mockReplicateService.generateSegmentVisuals(any)).called(1);

      // Verify podcast status updates
      final updatedPodcast = provider.podcasts.first;
      expect(updatedPodcast.status, equals(PodcastStatus.ready));
      expect(updatedPodcast.segments.length, greaterThan(0));
      
      for (final segment in updatedPodcast.segments) {
        expect(segment.status, equals(SegmentStatus.complete));
        expect(segment.audioPath, isNotNull);
        expect(segment.visualPath, isNotNull);
      }
    });

    test('generatePodcastContent handles errors', () async {
      final podcast = createTestPodcast();

      when(mockGroqService.generatePodcastScript(
        title: anyNamed('title'),
        description: anyNamed('description'),
        content: anyNamed('content'),
      )).thenThrow(Exception('API Error'));

      await expectLater(
        () => provider.generatePodcastContent(podcast),
        throwsException,
      );

      final updatedPodcast = provider.podcasts.first;
      expect(updatedPodcast.status, equals(PodcastStatus.error));
    });

    test('currentPodcast updates when podcast is modified', () async {
      final podcast = createTestPodcast();
      await provider.createPodcast(podcast);

      expect(provider.currentPodcast, equals(podcast));

      final updatedPodcast = podcast.copyWith(
        title: 'Updated Title',
        status: PodcastStatus.generating,
      );

      // Simulate an update through generation
      when(mockGroqService.generatePodcastScript(
        title: anyNamed('title'),
        description: anyNamed('description'),
        content: anyNamed('content'),
      )).thenThrow(Exception()); // Force an error to stop generation

      try {
        await provider.generatePodcastContent(podcast);
      } catch (_) {}

      expect(provider.currentPodcast?.status, equals(PodcastStatus.error));
    });
  });
}

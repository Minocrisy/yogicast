import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:yogicast/core/models/podcast.dart';
import 'package:yogicast/core/services/share_service.dart';
import 'package:yogicast/features/podcast/providers/podcast_provider.dart';
import 'package:yogicast/features/podcast/screens/podcast_details_screen.dart';
import 'package:yogicast/features/settings/providers/settings_provider.dart';
import 'package:yogicast/shared/widgets/audio_player.dart';
import '../../../helpers/test_helper.dart';

class MockPodcastProvider extends Mock implements PodcastProvider {
  @override
  Future<void> updatePodcast(Podcast podcast) => super.noSuchMethod(
        Invocation.method(#updatePodcast, [podcast]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );

  @override
  Future<void> generatePodcastContent(Podcast podcast) => super.noSuchMethod(
        Invocation.method(#generatePodcastContent, [podcast]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      );
}

class MockSettingsProvider extends Mock implements SettingsProvider {
  @override
  bool get autoPlay => true;
}

class MockShareService extends Mock implements ShareService {}

class MockVideoPlayerController extends Mock implements VideoPlayerController {
  @override
  Future<void> initialize() async {}
  
  @override
  Future<void> dispose() async {}
}

void main() {
  group('PodcastDetailsScreen', () {
    late MockPodcastProvider podcastProvider;
    late MockSettingsProvider settingsProvider;
    late Podcast testPodcast;

    setUp(() async {
      await setupTestEnvironment();
      podcastProvider = MockPodcastProvider();
      settingsProvider = MockSettingsProvider();

      testPodcast = createTestPodcast(
        segments: [
          PodcastSegment(
            id: 'segment-1',
            content: 'Test content 1',
            audioPath: 'audio/test1.mp3',
            visualPath: 'images/test1.jpg',
            videoPath: 'videos/test1.mp4',
            status: SegmentStatus.complete,
          ),
          PodcastSegment(
            id: 'segment-2',
            content: 'Test content 2',
            status: SegmentStatus.pending,
          ),
        ],
      );
    });

    Future<void> pumpScreen(WidgetTester tester, Podcast podcast) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PodcastProvider>.value(
              value: podcastProvider,
            ),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider,
            ),
          ],
          child: MaterialApp(
            home: PodcastDetailsScreen(podcast: podcast),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('displays podcast title and description', (tester) async {
      await pumpScreen(tester, testPodcast);

      expect(find.text(testPodcast.title), findsOneWidget);
      expect(find.text(testPodcast.description), findsOneWidget);
    });

    testWidgets('displays segment list', (tester) async {
      await pumpScreen(tester, testPodcast);

      expect(find.text('Segment 1'), findsOneWidget);
      expect(find.text('Segment 2'), findsOneWidget);
      expect(find.text(testPodcast.segments[0].content), findsOneWidget);
      expect(find.text(testPodcast.segments[1].content), findsOneWidget);
    });

    testWidgets('shows media format toggle for segments with content', (tester) async {
      await pumpScreen(tester, testPodcast);

      // First segment has both visual and video content
      expect(find.byIcon(Icons.video_library), findsOneWidget);
      
      // Tap to toggle format
      await tester.tap(find.byIcon(Icons.video_library));
      await tester.pumpAndSettle();

      verify(podcastProvider.updatePodcast(testPodcast)).called(1);
    });

    testWidgets('shows generation controls for draft podcast', (tester) async {
      final draftPodcast = testPodcast.copyWith(status: PodcastStatus.draft);
      await pumpScreen(tester, draftPodcast);

      expect(find.text('Start Generation'), findsOneWidget);
      
      await tester.tap(find.text('Start Generation'));
      await tester.pumpAndSettle();

      verify(podcastProvider.generatePodcastContent(draftPodcast)).called(1);
    });

    testWidgets('shows share button for ready podcast', (tester) async {
      final readyPodcast = testPodcast.copyWith(status: PodcastStatus.ready);
      await pumpScreen(tester, readyPodcast);

      expect(find.byIcon(Icons.share), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      expect(find.text('Share Summary'), findsOneWidget);
      expect(find.text('Export as JSON'), findsOneWidget);
    });

    testWidgets('handles segment completion with auto-play', (tester) async {
      await pumpScreen(tester, testPodcast);

      // Find and tap play button for first segment
      await tester.tap(find.byIcon(Icons.play_arrow).first);
      await tester.pumpAndSettle();

      // Verify audio player is shown
      expect(find.byType(AudioPlayerWidget), findsOneWidget);
    });

    testWidgets('shows loading indicator during generation', (tester) async {
      final draftPodcast = testPodcast.copyWith(status: PodcastStatus.draft);
      
      // Mock long-running generation
      when(podcastProvider.generatePodcastContent(draftPodcast))
          .thenAnswer((_) => Future.delayed(const Duration(seconds: 1)));
      
      await pumpScreen(tester, draftPodcast);
      
      // Start generation
      await tester.tap(find.text('Start Generation'));
      await tester.pump();

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Starting podcast generation...'), findsOneWidget);
    });

    testWidgets('shows error state on generation failure', (tester) async {
      final draftPodcast = testPodcast.copyWith(status: PodcastStatus.draft);
      
      when(podcastProvider.generatePodcastContent(draftPodcast))
          .thenThrow(Exception('Generation failed'));
      
      await pumpScreen(tester, draftPodcast);
      await tester.tap(find.text('Start Generation'));
      await tester.pumpAndSettle();

      expect(find.text('Error generating podcast: Exception: Generation failed'), findsOneWidget);
    });
  });
}

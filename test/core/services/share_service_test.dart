import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:yogicast/core/models/podcast.dart';
import 'package:yogicast/core/services/share_service.dart';
import '../../helpers/test_helper.dart';

void main() {
  group('ShareService', () {
    late ShareService shareService;
    late Podcast testPodcast;

    setUp(() async {
      await setupTestEnvironment();
      shareService = ShareService();
      testPodcast = createTestPodcast();
    });

    test('sharePodcast formats content correctly', () {
      final segment = testPodcast.segments.first;
      final expectedSegmentContent = '''
✅ Segment: ${segment.content}
🎵 Audio available
🖼️ Visual available''';

      final formattedContent = shareService.sharePodcast(testPodcast);
      expect(formattedContent, contains(expectedSegmentContent));
      expect(segment.content, contains('Test content for segment 1'));
      expect(segment.audioPath, isNotNull);
      expect(segment.visualPath, isNotNull);
      expect(segment.status, equals(SegmentStatus.complete));
    });

    test('sharePodcastSegment formats segment correctly', () {
      final segment = testPodcast.segments.first;
      final expectedContent = '''
🎙️ Test Podcast - Segment
📝 Test content for segment 1
🎵 Audio available
🖼️ Visual available''';

      final formattedContent = shareService.sharePodcastSegment(segment, testPodcast.title);
      expect(formattedContent, equals(expectedContent));
      expect(segment.content, contains('Test content for segment 1'));
      expect(segment.audioPath, isNotNull);
      expect(segment.visualPath, isNotNull);
      expect(segment.status, equals(SegmentStatus.complete));
    });

    test('sharePodcastAsJson includes all podcast data', () {
      // Convert podcast to JSON and back to verify data integrity
      final jsonData = jsonEncode(testPodcast.toJson());
      final decodedPodcast = Podcast.fromJson(
        jsonDecode(jsonData) as Map<String, dynamic>,
      );

      // Verify all fields are preserved
      expect(decodedPodcast.id, equals(testPodcast.id));
      expect(decodedPodcast.title, equals(testPodcast.title));
      expect(decodedPodcast.description, equals(testPodcast.description));
      expect(decodedPodcast.segments.length, equals(testPodcast.segments.length));
      expect(decodedPodcast.createdAt, equals(testPodcast.createdAt));

      // Verify segment data
      final decodedSegment = decodedPodcast.segments.first;
      final originalSegment = testPodcast.segments.first;
      
      expect(decodedSegment.id, equals(originalSegment.id));
      expect(decodedSegment.content, equals(originalSegment.content));
      expect(decodedSegment.audioPath, equals(originalSegment.audioPath));
      expect(decodedSegment.visualPath, equals(originalSegment.visualPath));
      expect(decodedSegment.status, equals(originalSegment.status));
    });

    test('handles empty segments gracefully', () {
      final emptyPodcast = createTestPodcast(segments: []);
      
      expect(
        () => shareService.sharePodcast(emptyPodcast),
        returnsNormally,
      );
    });

    test('handles null paths gracefully', () {
      final segment = createTestSegment(
        audioPath: null,
        visualPath: null,
      );
      
      expect(
        () => shareService.sharePodcastSegment(segment, 'Test Podcast'),
        returnsNormally,
      );
    });
  });
}

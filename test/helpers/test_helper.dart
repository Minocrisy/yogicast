import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yogicast/core/models/podcast.dart';

Future<void> setupTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
}

Podcast createTestPodcast({
  String? id,
  String? title,
  String? description,
  List<PodcastSegment>? segments,
  DateTime? createdAt,
  DateTime? lastModified,
  PodcastStatus? status,
}) {
  return Podcast(
    id: id ?? 'test-id',
    title: title ?? 'Test Podcast',
    description: description ?? 'Test Description',
    segments: segments ?? [
      PodcastSegment(
        id: 'segment-1',
        content: 'Test content for segment 1',
        audioPath: 'audio/path/1.mp3',
        visualPath: 'images/path/1.jpg',
        status: SegmentStatus.complete,
      ),
      PodcastSegment(
        id: 'segment-2',
        content: 'Test content for segment 2',
        status: SegmentStatus.pending,
      ),
    ],
    createdAt: createdAt ?? DateTime(2024),
    lastModified: lastModified,
    status: status ?? PodcastStatus.draft,
  );
}

PodcastSegment createTestSegment({
  String? id,
  String? content,
  String? audioPath,
  String? visualPath,
  SegmentStatus? status,
}) {
  return PodcastSegment(
    id: id ?? 'test-segment',
    content: content ?? 'Test segment content',
    audioPath: audioPath,
    visualPath: visualPath,
    status: status ?? SegmentStatus.pending,
  );
}

extension PumpApp on WidgetTester {
  Future<void> pumpTestApp(Widget widget) {
    return pumpWidget(
      MaterialApp(
        home: widget,
      ),
    );
  }
}

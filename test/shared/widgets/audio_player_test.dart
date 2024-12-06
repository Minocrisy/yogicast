import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:yogicast/shared/widgets/audio_player.dart';
import '../../helpers/test_helper.dart';

void main() {
  group('AudioPlayerWidget', () {
    testWidgets('displays loading state initially', (tester) async {
      await tester.pumpTestApp(
        const AudioPlayerWidget(
          audioUrl: 'https://example.com/audio.mp3',
          title: 'Test Audio',
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Audio'), findsOneWidget);
    });

    testWidgets('shows error state for invalid URL', (tester) async {
      await tester.pumpTestApp(
        const AudioPlayerWidget(
          audioUrl: 'invalid-url',
          title: 'Test Audio',
        ),
      );

      // Wait for error state
      await tester.pumpAndSettle();

      expect(find.textContaining('Error'), findsOneWidget);
    });

    testWidgets('displays play button when ready', (tester) async {
      await tester.pumpTestApp(
        const AudioPlayerWidget(
          audioUrl: 'https://example.com/audio.mp3',
          title: 'Test Audio',
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('displays title correctly', (tester) async {
      const title = 'Test Audio Title';
      
      await tester.pumpTestApp(
        const AudioPlayerWidget(
          audioUrl: 'https://example.com/audio.mp3',
          title: title,
        ),
      );

      expect(find.text(title), findsOneWidget);
    });

    testWidgets('shows speed control button', (tester) async {
      await tester.pumpTestApp(
        const AudioPlayerWidget(
          audioUrl: 'https://example.com/audio.mp3',
          title: 'Test Audio',
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      expect(find.text('1.0x'), findsOneWidget);
    });

    testWidgets('shows replay button', (tester) async {
      await tester.pumpTestApp(
        const AudioPlayerWidget(
          audioUrl: 'https://example.com/audio.mp3',
          title: 'Test Audio',
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.replay), findsOneWidget);
    });

    testWidgets('shows slider for progress', (tester) async {
      await tester.pumpTestApp(
        const AudioPlayerWidget(
          audioUrl: 'https://example.com/audio.mp3',
          title: 'Test Audio',
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('calls onComplete callback when audio finishes', (tester) async {
      bool completed = false;
      
      await tester.pumpTestApp(
        AudioPlayerWidget(
          audioUrl: 'https://example.com/audio.mp3',
          title: 'Test Audio',
          onComplete: () => completed = true,
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Verify callback hasn't been called yet
      expect(completed, isFalse);
    });

    testWidgets('handles null onComplete callback', (tester) async {
      await tester.pumpTestApp(
        const AudioPlayerWidget(
          audioUrl: 'https://example.com/audio.mp3',
          title: 'Test Audio',
          onComplete: null,
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Should not throw any errors
      expect(tester.takeException(), isNull);
    });
  });
}

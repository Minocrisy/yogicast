import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:yogicast/core/models/podcast.dart';

class ShareService {
  Future<void> sharePodcast(Podcast podcast) async {
    try {
      final segments = podcast.segments.map((segment) {
        final status = segment.status == SegmentStatus.complete ? '✅' : '⏳';
        return '''
$status Segment: ${segment.content.substring(0, min(100, segment.content.length))}...
${segment.audioPath != null ? '🎵 Audio available' : ''}
${segment.visualPath != null ? '🖼️ Visual available' : ''}
''';
      }).join('\n');

      final text = '''
🎙️ ${podcast.title}

📝 ${podcast.description}

Segments:
$segments

Created with YOGICAST
''';

      await Share.share(text, subject: podcast.title);
    } catch (e) {
      throw Exception('Failed to share podcast: $e');
    }
  }

  Future<void> sharePodcastSegment(PodcastSegment segment, String podcastTitle) async {
    try {
      final text = '''
🎙️ $podcastTitle - Segment

📝 ${segment.content}

${segment.audioPath != null ? '🎵 Audio available' : ''}
${segment.visualPath != null ? '🖼️ Visual available' : ''}

Created with YOGICAST
''';

      await Share.share(text, subject: 'Podcast Segment');
    } catch (e) {
      throw Exception('Failed to share segment: $e');
    }
  }

  Future<void> sharePodcastAsJson(Podcast podcast) async {
    try {
      final jsonData = jsonEncode(podcast.toJson());
      final text = '''
YOGICAST Podcast Export

Title: ${podcast.title}
Created: ${podcast.createdAt}
Last Modified: ${podcast.lastModified ?? 'N/A'}

Data:
$jsonData
''';

      await Share.share(text, subject: '${podcast.title} - Export');
    } catch (e) {
      throw Exception('Failed to export podcast: $e');
    }
  }
}

int min(int a, int b) => a < b ? a : b;

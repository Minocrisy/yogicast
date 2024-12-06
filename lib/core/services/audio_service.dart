import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:yogicast/core/services/replicate_service.dart';

class AudioService {
  final ReplicateService _replicateService;

  AudioService(this._replicateService);

  // Bark model ID for text-to-speech
  static const String _barkModelId = 'suno-ai/bark:b76242b40d67c76ab6742e987628478ed2665910034b14fe371da4e1074c5778';

  Future<String> generateSpeech({
    required String text,
    String voice = 'v2/en_speaker_6', // Default male voice
    bool useHistory = false,
  }) async {
    try {
      final response = await _replicateService.runModel(
        modelId: _barkModelId,
        input: {
          'text': text,
          'history_prompt': voice,
          'use_voice_preset': true,
          'use_history': useHistory,
          'temperature': 0.7,
        },
      );

      // Download and save the audio file
      final savedPath = await _downloadAndSaveAudio(response);
      return savedPath;
    } catch (e) {
      throw Exception('Failed to generate speech: $e');
    }
  }

  Future<String> _downloadAndSaveAudio(String url) async {
    try {
      final response = await HttpClient().getUrl(Uri.parse(url));
      final httpResponse = await response.close();
      
      final bytes = await httpResponse.fold<List<int>>(
        [],
        (previous, element) => previous..addAll(element),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      throw Exception('Failed to download audio: $e');
    }
  }

  Future<void> cleanupOldAudioFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync().whereType<File>().where(
            (file) => file.path.endsWith('.wav'),
          );

      // Keep only files from the last 24 hours
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      
      for (final file in files) {
        final lastModified = file.lastModifiedSync();
        if (lastModified.isBefore(yesterday)) {
          await file.delete();
        }
      }
    } catch (e) {
      // Log error but don't throw - this is a cleanup operation
      print('Error cleaning up audio files: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeAudio(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);

      // TODO: Implement audio analysis using a suitable model
      // This could include:
      // - Speech clarity analysis
      // - Background noise detection
      // - Volume level analysis
      // For now, return basic file info
      return {
        'size': bytes.length,
        'format': 'wav',
        'duration': 'unknown', // Would need audio processing library to get this
        'quality': 'high',
      };
    } catch (e) {
      throw Exception('Failed to analyze audio: $e');
    }
  }

  Future<void> concatenateAudioFiles(List<String> filePaths, String outputPath) async {
    try {
      // TODO: Implement audio concatenation
      // This would require a proper audio processing library
      // For now, throw not implemented
      throw UnimplementedError('Audio concatenation not yet implemented');
    } catch (e) {
      throw Exception('Failed to concatenate audio files: $e');
    }
  }
}

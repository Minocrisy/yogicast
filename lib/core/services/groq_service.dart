import 'package:yogicast/core/services/api_service.dart';

class GroqService {
  final GroqApiService _apiService;

  GroqService(this._apiService);

  Future<String> generatePodcastScript({
    required String title,
    required String description,
    required String content,
  }) async {
    const prompt = '''
You are an expert podcast script writer. Create an engaging podcast script based on the following:
Title: {title}
Description: {description}
Content: {content}

The script should include:
1. An engaging introduction
2. Clear segment transitions
3. Natural dialogue between hosts
4. Relevant discussion points
5. A concise conclusion

Format the script with clear speaker indicators and timing markers.
''';

    try {
      final response = await _apiService.generateText(
        prompt: prompt
            .replaceAll('{title}', title)
            .replaceAll('{description}', description)
            .replaceAll('{content}', content),
        options: {
          'temperature': 0.7,
          'max_tokens': 4000,
          'top_p': 0.9,
        },
      );

      final generatedText = response['choices'][0]['message']['content'] as String;
      return generatedText;
    } catch (e) {
      throw Exception('Failed to generate podcast script: $e');
    }
  }

  Future<List<String>> generateSegmentScripts({
    required String mainScript,
    required int numberOfSegments,
  }) async {
    const segmentPrompt = '''
Break down the following podcast script into {segments} natural segments.
Each segment should be self-contained but flow naturally into the next.
Maintain the dialogue format and speaking parts.

Script:
{script}

Return each segment as a complete mini-conversation.
''';

    try {
      final response = await _apiService.generateText(
        prompt: segmentPrompt
            .replaceAll('{segments}', numberOfSegments.toString())
            .replaceAll('{script}', mainScript),
        options: {
          'temperature': 0.7,
          'max_tokens': 4000,
          'top_p': 0.9,
        },
      );

      final generatedText = response['choices'][0]['message']['content'] as String;
      
      // Split the text into segments based on segment markers
      // This is a simple implementation - might need refinement based on actual output
      final segments = generatedText
          .split(RegExp(r'Segment \d+:', caseSensitive: false))
          .where((segment) => segment.trim().isNotEmpty)
          .map((segment) => segment.trim())
          .toList();

      return segments;
    } catch (e) {
      throw Exception('Failed to generate segment scripts: $e');
    }
  }

  Future<String> generateSegmentDescription(String segmentContent) async {
    const descriptionPrompt = '''
Create a brief, engaging description for the following podcast segment.
The description should capture the main topics and tone of the conversation.

Segment Content:
{content}

Provide a concise, one-paragraph description that would interest potential listeners.
''';

    try {
      final response = await _apiService.generateText(
        prompt: descriptionPrompt.replaceAll('{content}', segmentContent),
        options: {
          'temperature': 0.7,
          'max_tokens': 200,
          'top_p': 0.9,
        },
      );

      return response['choices'][0]['message']['content'] as String;
    } catch (e) {
      throw Exception('Failed to generate segment description: $e');
    }
  }
}

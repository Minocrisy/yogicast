import 'package:yogicast/core/services/api_service.dart';
import 'package:yogicast/config/app_config.dart';

class ReplicateService {
  final ReplicateApiService _apiService;

  ReplicateService(this._apiService);

  Future<String> generateImage({
    required String prompt,
    int width = 768,
    int height = 768,
  }) async {
    try {
      // Using Stable Diffusion model
      const model = 'stability-ai/sdxl:39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b';
      
      final response = await _apiService.createPrediction(
        model: model,
        input: {
          'prompt': prompt,
          'width': width,
          'height': height,
          'num_outputs': 1,
          'scheduler': 'K_EULER',
          'num_inference_steps': 50,
          'guidance_scale': 7.5,
        },
      );

      // Get the prediction ID
      final predictionId = response['id'] as String;

      // Poll for the result
      while (true) {
        await Future.delayed(const Duration(seconds: 2));
        final status = await _apiService.getPrediction(predictionId);
        
        if (status['status'] == 'succeeded') {
          final outputs = status['output'] as List;
          if (outputs.isEmpty) {
            throw Exception('No image was generated');
          }
          return outputs.first as String;
        } else if (status['status'] == 'failed') {
          throw Exception('Image generation failed: ${status['error']}');
        }
      }
    } catch (e) {
      throw Exception('Failed to generate image: $e');
    }
  }

  Future<String> generateVideo({
    required String prompt,
    String? imageUrl,
    int duration = 4,
    int fps = 24,
  }) async {
    try {
      // Using Hunyuan Video model
      const model = 'alibaba-pai/hunyuan-video:7a236f267ccd03d2e516a5c55d99b06d0e67b0f9c78aec8b8594e1fa4c3b6ad3';
      
      final input = {
        'prompt': prompt,
        'duration': duration,
        'fps': fps,
        'guidance_scale': 7.5,
        'num_inference_steps': 50,
      };

      if (imageUrl != null) {
        input['image'] = imageUrl;
      }

      final response = await _apiService.createPrediction(
        model: model,
        input: input,
      );

      final predictionId = response['id'] as String;

      while (true) {
        await Future.delayed(const Duration(seconds: 2));
        final status = await _apiService.getPrediction(predictionId);
        
        if (status['status'] == 'succeeded') {
          final outputs = status['output'] as List;
          if (outputs.isEmpty) {
            throw Exception('No video was generated');
          }
          return outputs.first as String;
        } else if (status['status'] == 'failed') {
          throw Exception('Video generation failed: ${status['error']}');
        }
      }
    } catch (e) {
      throw Exception('Failed to generate video: $e');
    }
  }

  Future<String> generateAudio({
    required String text,
    String? voiceId,
    double? speed,
  }) async {
    try {
      // Using Coqui TTS model
      const model = 'cjwbw/coqui-tts:d6ef0e2e6ef7c7f42d5a9a7557399cb53c180a0a1a49ef90be48112d0f0c1ce1';
      
      final response = await _apiService.createPrediction(
        model: model,
        input: {
          'text': text,
          'speaker_id': voiceId ?? 'default',
          'speed': speed ?? 1.0,
          'sample_rate': AppConfig.defaultSampleRate,
          'channels': AppConfig.defaultChannels,
        },
      );

      final predictionId = response['id'] as String;

      while (true) {
        await Future.delayed(const Duration(seconds: 2));
        final status = await _apiService.getPrediction(predictionId);
        
        if (status['status'] == 'succeeded') {
          final outputs = status['output'] as List;
          if (outputs.isEmpty) {
            throw Exception('No audio was generated');
          }
          return outputs.first as String;
        } else if (status['status'] == 'failed') {
          throw Exception('Audio generation failed: ${status['error']}');
        }
      }
    } catch (e) {
      throw Exception('Failed to generate audio: $e');
    }
  }

  Future<String> generatePodcastThumbnail({
    required String title,
    required String description,
  }) async {
    final prompt = '''
Create a visually striking podcast thumbnail for a podcast titled "$title".
The image should be modern, professional, and capture the essence of: $description.
Make it eye-catching and suitable for podcast platforms.
Include visual elements that suggest audio or conversation.
Use vibrant colors and clear composition.
''';

    return generateImage(
      prompt: prompt,
      width: 1400,
      height: 1400,
    );
  }

  Future<String> generateSegmentVisual({
    required String content,
    required String description,
  }) async {
    final prompt = '''
Create a compelling visual representation for a podcast segment.
The segment discusses: $description
The image should be engaging and relevant to the topic.
Make it suitable for social media sharing and video platforms.
Include subtle elements that suggest audio or podcast content.
Use a style that's both professional and creative.
''';

    return generateImage(
      prompt: prompt,
      width: 1920,
      height: 1080,
    );
  }

  Future<String> generateSegmentVideo({
    required String content,
    required String description,
    String? imageUrl,
  }) async {
    final prompt = '''
Create an engaging video for a podcast segment about: $description
The video should be dynamic and visually interesting.
Include subtle motion and transitions.
Maintain a professional and polished look.
''';

    return generateVideo(
      prompt: prompt,
      imageUrl: imageUrl,
      duration: 10, // 10 seconds per segment
      fps: 24,
    );
  }

  Future<List<String>> generateSegmentVisuals(List<String> segmentContents) async {
    final List<String> visualUrls = [];

    for (final content in segmentContents) {
      try {
        final description = content.length > 200 
            ? '${content.substring(0, 200)}...' 
            : content;
            
        final visualUrl = await generateSegmentVisual(
          content: content,
          description: description,
        );
        
        visualUrls.add(visualUrl);
      } catch (e) {
        // If one visual fails, continue with the others but add an empty string
        visualUrls.add(''); // Empty string indicates failed generation
      }
    }

    return visualUrls;
  }

  Future<List<String>> generateSegmentVideos(List<String> segmentContents, {List<String>? imageUrls}) async {
    final List<String> videoUrls = [];

    for (var i = 0; i < segmentContents.length; i++) {
      try {
        final content = segmentContents[i];
        final description = content.length > 200 
            ? '${content.substring(0, 200)}...' 
            : content;
            
        final videoUrl = await generateSegmentVideo(
          content: content,
          description: description,
          imageUrl: imageUrls?[i],
        );
        
        videoUrls.add(videoUrl);
      } catch (e) {
        // If one video fails, continue with the others but add an empty string
        videoUrls.add(''); // Empty string indicates failed generation
      }
    }

    return videoUrls;
  }

  Future<List<String>> generateSegmentAudio(List<String> segments) async {
    final List<String> audioUrls = [];

    for (final segment in segments) {
      try {
        final audioUrl = await generateAudio(text: segment);
        audioUrls.add(audioUrl);
      } catch (e) {
        // If one audio fails, continue with others but add empty string
        audioUrls.add('');
      }
    }

    return audioUrls;
  }
}

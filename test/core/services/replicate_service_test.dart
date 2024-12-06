import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:yogicast/core/services/api_service.dart';
import 'package:yogicast/core/services/replicate_service.dart';

@GenerateNiceMocks([MockSpec<ReplicateApiService>()])
import 'replicate_service_test.mocks.dart';

void main() {
  group('ReplicateService', () {
    late ReplicateService service;
    late MockReplicateApiService mockApi;

    setUp(() {
      mockApi = MockReplicateApiService();
      service = ReplicateService(mockApi);
    });

    test('generateVideo creates prediction and polls for result', () async {
      const predictionId = 'test-prediction-id';
      const videoUrl = 'https://example.com/video.mp4';
      const prompt = 'Test prompt';

      // Mock create prediction response
      when(mockApi.createPrediction(
        model: anyNamed('model'),
        input: anyNamed('input'),
      )).thenAnswer((_) async => {'id': predictionId});

      // Mock poll responses
      var callCount = 0;
      when(mockApi.getPrediction(predictionId)).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          return Future.value({'status': 'processing'});
        }
        return Future.value({
          'status': 'succeeded',
          'output': [videoUrl],
        });
      });

      final result = await service.generateVideo(prompt: prompt);

      expect(result, equals(videoUrl));

      // Verify API calls
      final createCall = verify(mockApi.createPrediction(
        model: captureAnyNamed('model'),
        input: captureAnyNamed('input'),
      ));
      createCall.called(1);

      final captured = createCall.captured;
      expect(captured[1]['prompt'], equals(prompt));
      expect(captured[1]['duration'], equals(4));
      expect(captured[1]['fps'], equals(24));

      verify(mockApi.getPrediction(predictionId)).called(2);
    });

    test('generateVideo with image creates prediction with image input', () async {
      const predictionId = 'test-prediction-id';
      const videoUrl = 'https://example.com/video.mp4';
      const prompt = 'Test prompt';
      const imageUrl = 'https://example.com/image.jpg';

      when(mockApi.createPrediction(
        model: anyNamed('model'),
        input: anyNamed('input'),
      )).thenAnswer((_) async => {'id': predictionId});

      when(mockApi.getPrediction(predictionId))
          .thenAnswer((_) async => {
                'status': 'succeeded',
                'output': [videoUrl],
              });

      final result = await service.generateVideo(
        prompt: prompt,
        imageUrl: imageUrl,
      );

      expect(result, equals(videoUrl));

      final createCall = verify(mockApi.createPrediction(
        model: captureAnyNamed('model'),
        input: captureAnyNamed('input'),
      ));
      createCall.called(1);

      final captured = createCall.captured;
      expect(captured[1]['prompt'], equals(prompt));
      expect(captured[1]['image'], equals(imageUrl));
    });

    test('generateSegmentVideo formats prompt correctly', () async {
      const predictionId = 'test-prediction-id';
      const videoUrl = 'https://example.com/video.mp4';
      const content = 'Test content';
      const description = 'Test description';

      when(mockApi.createPrediction(
        model: anyNamed('model'),
        input: anyNamed('input'),
      )).thenAnswer((_) async => {'id': predictionId});

      when(mockApi.getPrediction(predictionId))
          .thenAnswer((_) async => {
                'status': 'succeeded',
                'output': [videoUrl],
              });

      final result = await service.generateSegmentVideo(
        content: content,
        description: description,
      );

      expect(result, equals(videoUrl));

      final createCall = verify(mockApi.createPrediction(
        model: captureAnyNamed('model'),
        input: captureAnyNamed('input'),
      ));
      createCall.called(1);

      final captured = createCall.captured;
      expect(captured[1]['prompt'], contains(description));
      expect(captured[1]['duration'], equals(10));
      expect(captured[1]['fps'], equals(24));
    });

    test('generateSegmentVideos handles multiple segments', () async {
      const segments = ['Segment 1', 'Segment 2'];
      const videoUrls = [
        'https://example.com/video1.mp4',
        'https://example.com/video2.mp4'
      ];

      var callCount = 0;
      when(mockApi.createPrediction(
        model: anyNamed('model'),
        input: anyNamed('input'),
      )).thenAnswer((_) async => {'id': 'test-id-${callCount++}'});

      when(mockApi.getPrediction(any)).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        final index = int.parse(id.split('-').last);
        return {
          'status': 'succeeded',
          'output': [videoUrls[index]],
        };
      });

      final results = await service.generateSegmentVideos(segments);

      expect(results, equals(videoUrls));
      verify(mockApi.createPrediction(
        model: anyNamed('model'),
        input: anyNamed('input'),
      )).called(segments.length);
    });

    test('generateVideo handles failure gracefully', () async {
      when(mockApi.createPrediction(
        model: anyNamed('model'),
        input: anyNamed('input'),
      )).thenThrow(Exception('API Error'));

      expect(
        () => service.generateVideo(prompt: 'Test'),
        throwsException,
      );
    });

    test('generateVideo handles empty output', () async {
      const predictionId = 'test-prediction-id';

      when(mockApi.createPrediction(
        model: anyNamed('model'),
        input: anyNamed('input'),
      )).thenAnswer((_) async => {'id': predictionId});

      when(mockApi.getPrediction(predictionId))
          .thenAnswer((_) async => {
                'status': 'succeeded',
                'output': [],
              });

      expect(
        () => service.generateVideo(prompt: 'Test'),
        throwsException,
      );
    });
  });
}

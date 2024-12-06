import 'package:dio/dio.dart';
import 'package:yogicast/config/app_config.dart';
import 'package:yogicast/config/env.dart';

abstract class ApiService {
  final Dio _dio;
  
  ApiService(String baseUrl, String apiKey) : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Authorization': 'Bearer $apiKey',
    },
  ));

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return TimeoutException();
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 500;
          final message = error.response?.data?['message'] ?? 'Unknown error occurred';
          
          if (statusCode == 401) {
            return AuthenticationException();
          }
          
          return ApiException(statusCode, message);
        default:
          return NetworkException();
      }
    }
    return UnknownException();
  }
}

class ReplicateApiService extends ApiService {
  ReplicateApiService() : super(
    AppConfig.replicateApiBaseUrl,
    Env.replicateApiKey,
  );

  Future<Map<String, dynamic>> createPrediction({
    required String model,
    required Map<String, dynamic> input,
  }) async {
    final response = await post('/predictions', data: {
      'version': model,
      'input': input,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getPrediction(String id) async {
    final response = await get('/predictions/$id');
    return response.data;
  }
}

class GroqApiService extends ApiService {
  GroqApiService() : super(
    AppConfig.groqApiBaseUrl,
    Env.groqApiKey,
  );

  Future<Map<String, dynamic>> generateText({
    required String prompt,
    Map<String, dynamic>? options,
  }) async {
    final response = await post('/chat/completions', data: {
      'model': 'mixtral-8x7b-32768',
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      ...?options,
    });
    return response.data;
  }
}

// Exceptions
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException: [$statusCode] $message';
}

class AuthenticationException implements Exception {
  @override
  String toString() => 'AuthenticationException: Invalid or missing API key';
}

class NetworkException implements Exception {
  @override
  String toString() => 'NetworkException: Unable to connect to the server';
}

class TimeoutException implements Exception {
  @override
  String toString() => 'TimeoutException: The request timed out';
}

class UnknownException implements Exception {
  @override
  String toString() => 'UnknownException: An unknown error occurred';
}

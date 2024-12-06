import 'dart:io' show Platform;

class Env {
  static String get groqApiKey => Platform.environment['GROQ_API_KEY'] ?? '';
  static String get replicateApiKey => Platform.environment['REPLICATE_API_KEY'] ?? '';

  static bool get hasRequiredKeys => groqApiKey.isNotEmpty && replicateApiKey.isNotEmpty;

  static void validateEnv() {
    if (!hasRequiredKeys) {
      throw Exception('''
Missing required environment variables.
Please ensure the following environment variables are set:
- GROQ_API_KEY
- REPLICATE_API_KEY
''');
    }
  }
}

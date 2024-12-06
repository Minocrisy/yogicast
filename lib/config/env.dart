import 'dart:io' show Platform, File;

class Env {
  static String get groqApiKey => _getEnvVar('GROQ_API_KEY');
  static String get replicateApiKey => _getEnvVar('REPLICATE_API_KEY');

  static bool get hasRequiredKeys => groqApiKey.isNotEmpty && replicateApiKey.isNotEmpty;

  static String _getEnvVar(String key) {
    // First try to get from environment variables
    if (Platform.environment.containsKey(key)) {
      return Platform.environment[key] ?? '';
    }

    // If not found, try to read from .env file
    try {
      final envFile = File('.env');
      if (envFile.existsSync()) {
        final lines = envFile.readAsLinesSync();
        for (final line in lines) {
          if (line.startsWith('$key=')) {
            return line.split('=')[1].trim();
          }
        }
      }
    } catch (e) {
      print('Error reading .env file: $e');
    }

    return '';
  }

  static void validateEnv() {
    if (!hasRequiredKeys) {
      throw Exception('''
Missing required environment variables.
Please ensure the following environment variables are set:
- GROQ_API_KEY
- REPLICATE_API_KEY

Current values:
GROQ_API_KEY: ${groqApiKey.isEmpty ? 'not set' : 'set'}
REPLICATE_API_KEY: ${replicateApiKey.isEmpty ? 'not set' : 'set'}
''');
    }
  }
}

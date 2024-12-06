class AppConfig {
  static const String appName = 'YOGICAST';
  
  // API Endpoints
  static const String replicateApiBaseUrl = 'https://api.replicate.com/v1';
  static const String groqApiBaseUrl = 'https://api.groq.com/v1';
  
  // Feature Flags
  static const bool enableVisualGeneration = true;
  static const bool enableAudioGeneration = true;
  
  // Cache Configuration
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration cacheDuration = Duration(days: 7);
  
  // Audio Configuration
  static const int defaultSampleRate = 44100;
  static const int defaultChannels = 2;
  
  // Visual Generation Configuration
  static const int defaultImageWidth = 1024;
  static const int defaultImageHeight = 1024;
  
  // Podcast Configuration
  static const int maxPodcastDuration = 3600; // 1 hour in seconds
  static const int defaultSegmentDuration = 300; // 5 minutes in seconds
}

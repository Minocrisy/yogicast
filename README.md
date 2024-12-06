# YOGICAST

An AI-powered podcast creation platform built with Flutter, featuring automated visual elements and audio generation.

## Features

- 🎙️ AI-Powered Podcast Creation using Groq API
- 🖼️ Visual Element Generation using Replicate API
- 🎵 Audio Generation with Coqui TTS
- 🎨 Modern Material Design UI
- 📊 Real-time Generation Progress Tracking
- 🔄 Automatic Content Caching
- 🌓 Theme Customization
- 🎯 Smart Settings Management
- 📤 Multi-format Sharing Options

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- API Keys:
  - Groq API Key
  - Replicate API Key

### Installation

1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Set up API keys in the settings screen
4. Run the app: `flutter run`

## Architecture

The app follows a clean architecture pattern with the following components:

### Services
- `ApiService`: Base HTTP client implementation
- `GroqService`: AI text generation
- `ReplicateService`: Visual and audio generation
- `CacheService`: Local data persistence
- `ShareService`: Content sharing

### State Management
- Provider-based architecture
- Separate providers for podcasts and settings
- Reactive UI updates

### Features
- Podcast Creation
- Audio Playback
- Settings Management
- Content Sharing
- Cache Management

## Testing

Run tests with: `flutter test`

### Test Coverage
- Unit Tests: Services and providers
- Widget Tests: UI components
- Integration Tests: Feature workflows

### Key Test Areas
- Data persistence
- API integration
- UI interactions
- Error handling
- State management

## Directory Structure

```
lib/
├── config/           # App configuration
├── core/
│   ├── models/      # Data models
│   └── services/    # Core services
├── features/
│   ├── podcast/     # Podcast feature
│   └── settings/    # Settings feature
└── shared/          # Shared components
    ├── constants/
    └── widgets/

test/
├── core/            # Core tests
├── features/        # Feature tests
└── helpers/         # Test utilities
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yogicast/config/app_config.dart';
import 'package:yogicast/core/models/podcast.dart';
import 'package:yogicast/core/services/groq_service.dart';
import 'package:yogicast/core/services/replicate_service.dart';
import 'package:yogicast/core/services/cache_service.dart';
import 'package:yogicast/features/podcast/providers/podcast_provider.dart';
import 'package:yogicast/features/podcast/screens/create_podcast_screen.dart';
import 'package:yogicast/features/podcast/screens/podcast_details_screen.dart';
import 'package:yogicast/features/settings/providers/settings_provider.dart';
import 'package:yogicast/features/settings/screens/settings_screen.dart';
import 'package:yogicast/shared/constants/app_theme.dart';
import 'package:yogicast/core/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize settings and validate environment
  final settings = SettingsProvider(prefs);
  if (!settings.hasRequiredKeys) {
    // Show settings screen on first launch or when API keys are missing
    runApp(
      MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: Provider.value(
          value: settings,
          child: const SettingsScreen(),
        ),
      ),
    );
    return;
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<ReplicateApiService>(
          create: (_) => ReplicateApiService(),
        ),
        Provider<GroqApiService>(
          create: (_) => GroqApiService(),
        ),
        Provider<GroqService>(
          create: (context) => GroqService(context.read<GroqApiService>()),
        ),
        Provider<ReplicateService>(
          create: (context) => ReplicateService(context.read<ReplicateApiService>()),
        ),
        Provider<CacheService>(
          create: (_) => CacheService(prefs),
        ),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(
          create: (context) => PodcastProvider(
            context.read<GroqService>(),
            context.read<ReplicateService>(),
            context.read<CacheService>(),
          )..initialize(),
        ),
      ],
      child: const YogicastApp(),
    ),
  );
}

class YogicastApp extends StatelessWidget {
  const YogicastApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: switch (settings.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateToCreatePodcast(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePodcastScreen(),
      ),
    );
  }

  void _navigateToPodcastDetails(BuildContext context, podcast) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PodcastDetailsScreen(podcast: podcast),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final podcastProvider = context.watch<PodcastProvider>();
    final settings = context.watch<SettingsProvider>();
    
    if (!settings.hasRequiredKeys) {
      return const SettingsScreen();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mic,
                size: 64,
                color: Color(0xFF6750A4),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to ${AppConfig.appName}',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Create AI-powered podcasts with visual elements',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _navigateToCreatePodcast(context),
                icon: const Icon(Icons.add),
                label: const Text('Create New Podcast'),
              ),
              if (podcastProvider.podcasts.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'Recent Podcasts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: podcastProvider.podcasts.length,
                    itemBuilder: (context, index) {
                      final podcast = podcastProvider.podcasts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(podcast.title),
                          subtitle: Text(podcast.description),
                          trailing: _buildPodcastStatus(podcast.status),
                          onTap: () => _navigateToPodcastDetails(context, podcast),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToSettings(context),
        child: const Icon(Icons.settings),
      ),
    );
  }

  Widget _buildPodcastStatus(PodcastStatus status) {
    late final IconData icon;
    late final Color color;

    switch (status) {
      case PodcastStatus.draft:
        icon = Icons.edit;
        color = Colors.grey;
      case PodcastStatus.generating:
        icon = Icons.autorenew;
        color = Colors.blue;
      case PodcastStatus.ready:
        icon = Icons.check_circle;
        color = Colors.green;
      case PodcastStatus.error:
        icon = Icons.error;
        color = Colors.red;
    }

    return Icon(icon, color: color);
  }
}

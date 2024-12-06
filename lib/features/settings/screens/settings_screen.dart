import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yogicast/features/settings/providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _groqApiKeyController = TextEditingController();
  final _replicateApiKeyController = TextEditingController();
  bool _obscureGroqKey = true;
  bool _obscureReplicateKey = true;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _groqApiKeyController.text = settings.groqApiKey;
    _replicateApiKeyController.text = settings.replicateApiKey;
  }

  @override
  void dispose() {
    _groqApiKeyController.dispose();
    _replicateApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Settings'),
                  content: const Text(
                    'Are you sure you want to reset all settings to default? '
                    'This will remove your API keys and preferences.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<SettingsProvider>().clearSettings();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Settings reset to default'),
                          ),
                        );
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Configuration',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _groqApiKeyController,
                      decoration: InputDecoration(
                        labelText: 'Groq API Key',
                        hintText: 'Enter your Groq API key',
                        errorText: settings.groqApiKey.isEmpty
                            ? 'API key is required'
                            : null,
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _obscureGroqKey
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureGroqKey = !_obscureGroqKey;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () {
                                settings.setGroqApiKey(_groqApiKeyController.text);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Groq API key saved'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      obscureText: _obscureGroqKey,
                      onSubmitted: (value) {
                        settings.setGroqApiKey(value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Groq API key saved'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _replicateApiKeyController,
                      decoration: InputDecoration(
                        labelText: 'Replicate API Key',
                        hintText: 'Enter your Replicate API key',
                        errorText: settings.replicateApiKey.isEmpty
                            ? 'API key is required'
                            : null,
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _obscureReplicateKey
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureReplicateKey = !_obscureReplicateKey;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () {
                                settings.setReplicateApiKey(
                                  _replicateApiKeyController.text,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Replicate API key saved'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      obscureText: _obscureReplicateKey,
                      onSubmitted: (value) {
                        settings.setReplicateApiKey(value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Replicate API key saved'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferences',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: settings.themeMode,
                      decoration: const InputDecoration(
                        labelText: 'Theme Mode',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'system',
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: 'light',
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: 'dark',
                          child: Text('Dark'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          settings.setThemeMode(value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Auto-play Next Segment'),
                      subtitle: const Text(
                        'Automatically play the next segment when current one ends',
                      ),
                      value: settings.autoPlay,
                      onChanged: (value) {
                        settings.setAutoPlay(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

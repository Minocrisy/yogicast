import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yogicast/core/models/podcast.dart';
import 'package:yogicast/features/podcast/providers/podcast_provider.dart';
import 'package:uuid/uuid.dart';

class CreatePodcastScreen extends StatefulWidget {
  const CreatePodcastScreen({super.key});

  @override
  State<CreatePodcastScreen> createState() => _CreatePodcastScreenState();
}

class _CreatePodcastScreenState extends State<CreatePodcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  bool _enableVideo = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _createPodcast() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final podcast = Podcast(
          id: const Uuid().v4(),
          title: _titleController.text,
          description: _descriptionController.text,
          segments: [
            PodcastSegment(
              id: const Uuid().v4(),
              content: _contentController.text,
              preferredFormat: _enableVideo ? MediaFormat.video : MediaFormat.image,
            ),
          ],
          createdAt: DateTime.now(),
        );

        await context.read<PodcastProvider>().createPodcast(podcast);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Podcast created successfully!'),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating podcast: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Podcast'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Podcast Title',
                  hintText: 'Enter a title for your podcast',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter a description that will guide visual generation',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Enter descriptive content that can be visualized',
                  border: OutlineInputBorder(),
                  helperText: 'Include vivid descriptions for better visual generation',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter content';
                  }
                  if (value.length < 50) {
                    return 'Please enter at least 50 characters for better results';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enable Video Generation'),
                subtitle: const Text(
                  'Generate video content instead of static images',
                ),
                value: _enableVideo,
                onChanged: (value) {
                  setState(() {
                    _enableVideo = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _createPodcast,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.create),
                label: Text(_isLoading ? 'Creating...' : 'Create Podcast'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_enableVideo) ...[
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tips for Better Video Generation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('• Use descriptive language about scenes and actions'),
                        Text('• Include details about movement and transitions'),
                        Text('• Describe visual elements like colors and lighting'),
                        Text('• Keep descriptions focused and coherent'),
                        Text('• Avoid abstract or non-visual concepts'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

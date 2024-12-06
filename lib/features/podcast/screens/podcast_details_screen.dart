import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yogicast/core/models/podcast.dart';
import 'package:yogicast/core/services/share_service.dart';
import 'package:yogicast/features/podcast/providers/podcast_provider.dart';
import 'package:yogicast/features/settings/providers/settings_provider.dart';
import 'package:yogicast/shared/widgets/loading_overlay.dart';
import 'package:yogicast/shared/widgets/audio_player.dart';

class PodcastDetailsScreen extends StatefulWidget {
  final Podcast podcast;

  const PodcastDetailsScreen({
    super.key,
    required this.podcast,
  });

  @override
  State<PodcastDetailsScreen> createState() => _PodcastDetailsScreenState();
}

class _PodcastDetailsScreenState extends State<PodcastDetailsScreen> {
  bool _isGenerating = false;
  String _generationStage = '';
  String _generationMessage = '';
  int? _currentPlayingIndex;
  final _shareService = ShareService();

  void _handleSegmentComplete(BuildContext context, int currentIndex) {
    final settings = context.read<SettingsProvider>();
    if (settings.autoPlay && currentIndex < widget.podcast.segments.length - 1) {
      setState(() {
        _currentPlayingIndex = currentIndex + 1;
      });
    } else {
      setState(() {
        _currentPlayingIndex = null;
      });
    }
  }

  Future<void> _handleShare() async {
    try {
      await showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Summary'),
                onTap: () async {
                  Navigator.pop(context);
                  await _shareService.sharePodcast(widget.podcast);
                },
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Export as JSON'),
                onTap: () async {
                  Navigator.pop(context);
                  await _shareService.sharePodcastAsJson(widget.podcast);
                },
              ),
              if (widget.podcast.segments.length == 1)
                ListTile(
                  leading: const Icon(Icons.segment),
                  title: const Text('Share Segment'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _shareService.sharePodcastSegment(
                      widget.podcast.segments.first,
                      widget.podcast.title,
                    );
                  },
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing podcast: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusIndicator(PodcastStatus status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case PodcastStatus.draft:
        color = Colors.grey;
        icon = Icons.edit;
        text = 'Draft';
      case PodcastStatus.generating:
        color = Colors.blue;
        icon = Icons.autorenew;
        text = 'Generating';
      case PodcastStatus.ready:
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Ready';
      case PodcastStatus.error:
        color = Colors.red;
        icon = Icons.error;
        text = 'Error';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }

  Widget _buildSegmentList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.podcast.segments.length,
      itemBuilder: (context, index) {
        final segment = widget.podcast.segments[index];
        final isPlaying = _currentPlayingIndex == index;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text('Segment ${index + 1}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (segment.status == SegmentStatus.complete)
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => _shareService.sharePodcastSegment(
                          segment,
                          widget.podcast.title,
                        ),
                      ),
                    _buildSegmentStatus(segment.status),
                  ],
                ),
              ),
              if (segment.visualPath != null && segment.visualPath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      segment.visualPath!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  segment.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (segment.audioPath != null && segment.audioPath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isPlaying
                        ? AudioPlayerWidget(
                            key: ValueKey(segment.id),
                            audioUrl: segment.audioPath!,
                            title: 'Segment ${index + 1} Audio',
                            onComplete: () => _handleSegmentComplete(context, index),
                          )
                        : OutlinedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play Audio'),
                            onPressed: () {
                              setState(() {
                                _currentPlayingIndex = index;
                              });
                            },
                          ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegmentStatus(SegmentStatus status) {
    Color color;
    IconData icon;
    String tooltip;

    switch (status) {
      case SegmentStatus.pending:
        color = Colors.grey;
        icon = Icons.hourglass_empty;
        tooltip = 'Pending';
      case SegmentStatus.generatingAudio:
        color = Colors.orange;
        icon = Icons.music_note;
        tooltip = 'Generating Audio';
      case SegmentStatus.generatingVisual:
        color = Colors.purple;
        icon = Icons.image;
        tooltip = 'Generating Visual';
      case SegmentStatus.complete:
        color = Colors.green;
        icon = Icons.check_circle;
        tooltip = 'Complete';
      case SegmentStatus.error:
        color = Colors.red;
        icon = Icons.error;
        tooltip = 'Error';
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color),
    );
  }

  Future<void> _startGeneration() async {
    setState(() {
      _isGenerating = true;
      _generationStage = 'Initializing';
      _generationMessage = 'Starting podcast generation...';
    });

    try {
      final provider = context.read<PodcastProvider>();

      setState(() {
        _generationStage = 'Content Generation';
        _generationMessage = 'Generating podcast script and segments...';
      });

      await provider.generatePodcastContent(widget.podcast);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Podcast generation completed!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating podcast: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isGenerating,
      message: _generationMessage,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Podcast Details'),
          actions: [
            if (widget.podcast.status == PodcastStatus.ready)
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _handleShare,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.podcast.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  _buildStatusIndicator(widget.podcast.status),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.podcast.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              if (_isGenerating)
                GenerationProgress(
                  stage: _generationStage,
                  message: _generationMessage,
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Segments',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (widget.podcast.segments.isNotEmpty &&
                      widget.podcast.status == PodcastStatus.ready)
                    TextButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play All'),
                      onPressed: () {
                        setState(() {
                          _currentPlayingIndex = 0;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSegmentList(),
              const SizedBox(height: 24),
              if (widget.podcast.status == PodcastStatus.draft)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _startGeneration,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Generation'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final String title;

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    required this.title,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer.setFilePath(widget.audioPath);
      _duration = _audioPlayer.duration ?? Duration.zero;

      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _audioPlayer.playerStateStream.listen((playerState) {
        if (mounted) {
          setState(() {
            _isPlaying = playerState.playing;
          });
        }
      });
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    if (_isPlaying) {
                      _audioPlayer.pause();
                    } else {
                      _audioPlayer.play();
                    }
                  },
                ),
                Expanded(
                  child: Slider(
                    value: _position.inSeconds.toDouble(),
                    min: 0,
                    max: _duration.inSeconds.toDouble(),
                    onChanged: (value) {
                      _audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
                Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.speed, size: 20),
                    const SizedBox(width: 8),
                    DropdownButton<double>(
                      value: _playbackSpeed,
                      items: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
                          .map((speed) => DropdownMenuItem(
                                value: speed,
                                child: Text('${speed}x'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _playbackSpeed = value;
                            _audioPlayer.setSpeed(value);
                          });
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      onPressed: () {
                        _audioPlayer.seek(
                          _position - const Duration(seconds: 10),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_30),
                      onPressed: () {
                        _audioPlayer.seek(
                          _position + const Duration(seconds: 30),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

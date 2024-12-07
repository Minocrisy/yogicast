import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'podcast.g.dart';

@JsonSerializable()
class Podcast extends Equatable {
  final String id;
  final String title;
  final String description;
  final List<PodcastSegment> segments;
  final DateTime createdAt;
  final DateTime? lastModified;
  final PodcastStatus status;
  final String? thumbnailUrl;

  const Podcast({
    required this.id,
    required this.title,
    required this.description,
    required this.segments,
    required this.createdAt,
    this.lastModified,
    this.status = PodcastStatus.draft,
    this.thumbnailUrl,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) => _$PodcastFromJson(json);
  Map<String, dynamic> toJson() => _$PodcastToJson(this);

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    segments,
    createdAt,
    lastModified,
    status,
    thumbnailUrl,
  ];

  Podcast copyWith({
    String? title,
    String? description,
    List<PodcastSegment>? segments,
    DateTime? lastModified,
    PodcastStatus? status,
    String? thumbnailUrl,
  }) {
    return Podcast(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      segments: segments ?? this.segments,
      createdAt: createdAt,
      lastModified: lastModified ?? this.lastModified,
      status: status ?? this.status,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}

@JsonSerializable()
class PodcastSegment extends Equatable {
  final String id;
  final String content;
  final String? description;
  final String? audioPath;
  final String? visualPath;
  final String? videoPath;
  final SegmentStatus status;
  final MediaFormat preferredFormat;

  const PodcastSegment({
    required this.id,
    required this.content,
    this.description,
    this.audioPath,
    this.visualPath,
    this.videoPath,
    this.status = SegmentStatus.pending,
    this.preferredFormat = MediaFormat.image,
  });

  factory PodcastSegment.fromJson(Map<String, dynamic> json) =>
      _$PodcastSegmentFromJson(json);
  Map<String, dynamic> toJson() => _$PodcastSegmentToJson(this);

  @override
  List<Object?> get props => [
    id,
    content,
    description,
    audioPath,
    visualPath,
    videoPath,
    status,
    preferredFormat,
  ];

  PodcastSegment copyWith({
    String? content,
    String? description,
    String? audioPath,
    String? visualPath,
    String? videoPath,
    SegmentStatus? status,
    MediaFormat? preferredFormat,
  }) {
    return PodcastSegment(
      id: id,
      content: content ?? this.content,
      description: description ?? this.description,
      audioPath: audioPath ?? this.audioPath,
      visualPath: visualPath ?? this.visualPath,
      videoPath: videoPath ?? this.videoPath,
      status: status ?? this.status,
      preferredFormat: preferredFormat ?? this.preferredFormat,
    );
  }

  bool get hasVisualContent => visualPath != null || videoPath != null;
  String? get activeVisualPath => preferredFormat == MediaFormat.video ? videoPath : visualPath;
}

enum PodcastStatus {
  draft,
  generating,
  ready,
  error,
}

enum SegmentStatus {
  pending,
  generatingAudio,
  generatingVisual,
  generatingVideo,
  complete,
  error,
}

enum MediaFormat {
  image,
  video,
}

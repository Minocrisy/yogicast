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

  const Podcast({
    required this.id,
    required this.title,
    required this.description,
    required this.segments,
    required this.createdAt,
    this.lastModified,
    this.status = PodcastStatus.draft,
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
  ];

  Podcast copyWith({
    String? title,
    String? description,
    List<PodcastSegment>? segments,
    DateTime? lastModified,
    PodcastStatus? status,
  }) {
    return Podcast(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      segments: segments ?? this.segments,
      createdAt: createdAt,
      lastModified: lastModified ?? this.lastModified,
      status: status ?? this.status,
    );
  }
}

@JsonSerializable()
class PodcastSegment extends Equatable {
  final String id;
  final String content;
  final String? audioPath;
  final String? visualPath;
  final SegmentStatus status;

  const PodcastSegment({
    required this.id,
    required this.content,
    this.audioPath,
    this.visualPath,
    this.status = SegmentStatus.pending,
  });

  factory PodcastSegment.fromJson(Map<String, dynamic> json) =>
      _$PodcastSegmentFromJson(json);
  Map<String, dynamic> toJson() => _$PodcastSegmentToJson(this);

  @override
  List<Object?> get props => [
    id,
    content,
    audioPath,
    visualPath,
    status,
  ];

  PodcastSegment copyWith({
    String? content,
    String? audioPath,
    String? visualPath,
    SegmentStatus? status,
  }) {
    return PodcastSegment(
      id: id,
      content: content ?? this.content,
      audioPath: audioPath ?? this.audioPath,
      visualPath: visualPath ?? this.visualPath,
      status: status ?? this.status,
    );
  }
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
  complete,
  error,
}

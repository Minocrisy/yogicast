// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'podcast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Podcast _$PodcastFromJson(Map<String, dynamic> json) => Podcast(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      segments: (json['segments'] as List<dynamic>)
          .map((e) => PodcastSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] == null
          ? null
          : DateTime.parse(json['lastModified'] as String),
      status: $enumDecodeNullable(_$PodcastStatusEnumMap, json['status']) ??
          PodcastStatus.draft,
    );

Map<String, dynamic> _$PodcastToJson(Podcast instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'segments': instance.segments,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastModified': instance.lastModified?.toIso8601String(),
      'status': _$PodcastStatusEnumMap[instance.status]!,
    };

const _$PodcastStatusEnumMap = {
  PodcastStatus.draft: 'draft',
  PodcastStatus.generating: 'generating',
  PodcastStatus.ready: 'ready',
  PodcastStatus.error: 'error',
};

PodcastSegment _$PodcastSegmentFromJson(Map<String, dynamic> json) =>
    PodcastSegment(
      id: json['id'] as String,
      content: json['content'] as String,
      audioPath: json['audioPath'] as String?,
      visualPath: json['visualPath'] as String?,
      videoPath: json['videoPath'] as String?,
      status: $enumDecodeNullable(_$SegmentStatusEnumMap, json['status']) ??
          SegmentStatus.pending,
      preferredFormat:
          $enumDecodeNullable(_$MediaFormatEnumMap, json['preferredFormat']) ??
              MediaFormat.image,
    );

Map<String, dynamic> _$PodcastSegmentToJson(PodcastSegment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'audioPath': instance.audioPath,
      'visualPath': instance.visualPath,
      'videoPath': instance.videoPath,
      'status': _$SegmentStatusEnumMap[instance.status]!,
      'preferredFormat': _$MediaFormatEnumMap[instance.preferredFormat]!,
    };

const _$SegmentStatusEnumMap = {
  SegmentStatus.pending: 'pending',
  SegmentStatus.generatingAudio: 'generatingAudio',
  SegmentStatus.generatingVisual: 'generatingVisual',
  SegmentStatus.generatingVideo: 'generatingVideo',
  SegmentStatus.complete: 'complete',
  SegmentStatus.error: 'error',
};

const _$MediaFormatEnumMap = {
  MediaFormat.image: 'image',
  MediaFormat.video: 'video',
};

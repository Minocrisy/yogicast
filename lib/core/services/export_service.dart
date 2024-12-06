import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:yogicast/core/models/podcast.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

class ExportService {
  Future<String> exportPodcast(Podcast podcast) async {
    try {
      final exportDir = await _createExportDirectory(podcast);
      
      // Create metadata file
      await _createMetadataFile(podcast, exportDir);
      
      // Create transcript
      await _createTranscript(podcast, exportDir);
      
      // Copy audio and visual files
      await _copyMediaFiles(podcast, exportDir);
      
      // Create ZIP archive
      final zipPath = await _createZipArchive(exportDir, podcast.title);
      
      // Cleanup temporary directory
      await exportDir.delete(recursive: true);
      
      return zipPath;
    } catch (e) {
      throw Exception('Failed to export podcast: $e');
    }
  }

  Future<Directory> _createExportDirectory(Podcast podcast) async {
    final baseDir = await getTemporaryDirectory();
    final exportDir = Directory('${baseDir.path}/export_${podcast.id}');
    
    if (await exportDir.exists()) {
      await exportDir.delete(recursive: true);
    }
    
    await exportDir.create(recursive: true);
    return exportDir;
  }

  Future<void> _createMetadataFile(Podcast podcast, Directory exportDir) async {
    final metadata = {
      'id': podcast.id,
      'title': podcast.title,
      'description': podcast.description,
      'createdAt': podcast.createdAt.toIso8601String(),
      'lastModified': podcast.lastModified?.toIso8601String(),
      'segments': podcast.segments.map((segment) => {
        'id': segment.id,
        'content': segment.content,
        'audioPath': segment.audioPath,
        'visualPath': segment.visualPath,
        'status': segment.status.toString(),
      }).toList(),
    };

    final metadataFile = File('${exportDir.path}/metadata.json');
    await metadataFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(metadata),
    );
  }

  Future<void> _createTranscript(Podcast podcast, Directory exportDir) async {
    final transcriptBuffer = StringBuffer();
    transcriptBuffer.writeln('# ${podcast.title}\n');
    transcriptBuffer.writeln(podcast.description);
    transcriptBuffer.writeln('\n---\n');

    for (var i = 0; i < podcast.segments.length; i++) {
      final segment = podcast.segments[i];
      transcriptBuffer.writeln('## Segment ${i + 1}\n');
      transcriptBuffer.writeln(segment.content);
      transcriptBuffer.writeln('\n---\n');
    }

    final transcriptFile = File('${exportDir.path}/transcript.md');
    await transcriptFile.writeAsString(transcriptBuffer.toString());
  }

  Future<void> _copyMediaFiles(Podcast podcast, Directory exportDir) async {
    final audioDir = Directory('${exportDir.path}/audio');
    final visualDir = Directory('${exportDir.path}/visuals');
    
    await audioDir.create();
    await visualDir.create();

    for (var i = 0; i < podcast.segments.length; i++) {
      final segment = podcast.segments[i];
      
      // Copy audio file
      if (segment.audioPath != null && segment.audioPath!.isNotEmpty) {
        final audioFile = File(segment.audioPath!);
        if (await audioFile.exists()) {
          final newAudioPath = '${audioDir.path}/segment_${i + 1}.wav';
          await audioFile.copy(newAudioPath);
        }
      }

      // Download and save visual file
      if (segment.visualPath != null && segment.visualPath!.isNotEmpty) {
        try {
          final response = await HttpClient().getUrl(Uri.parse(segment.visualPath!));
          final httpResponse = await response.close();
          final bytes = await httpResponse.fold<List<int>>(
            [],
            (previous, element) => previous..addAll(element),
          );
          
          final visualFile = File('${visualDir.path}/segment_${i + 1}.jpg');
          await visualFile.writeAsBytes(bytes);
        } catch (e) {
          print('Failed to download visual for segment ${i + 1}: $e');
        }
      }
    }
  }

  Future<String> _createZipArchive(Directory sourceDir, String podcastTitle) async {
    final outputDir = await getApplicationDocumentsDirectory();
    final zipPath = '${outputDir.path}/${_sanitizeFileName(podcastTitle)}.zip';
    
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    
    // Add all files recursively
    await for (final file in sourceDir.list(recursive: true)) {
      if (file is File) {
        final relativePath = file.path.substring(sourceDir.path.length + 1);
        encoder.addFile(file, relativePath);
      }
    }
    
    encoder.close();
    return zipPath;
  }

  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}

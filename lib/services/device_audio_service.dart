import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song_model.dart';

class DeviceAudioService {
  static final DeviceAudioService _instance = DeviceAudioService._internal();
  factory DeviceAudioService() => _instance;
  DeviceAudioService._internal();

  // Scan device folders for audio files
  Future<List<SongModel>> scanDeviceAudioFiles() async {
    final List<SongModel> deviceSongs = [];
    final Set<String> foundPaths = {};

    final List<String> candidateDirs = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Audio',
      '/storage/emulated/0/Podcasts',
    ];

    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) candidateDirs.add(extDir.path);
    } catch (_) {}

    for (final dirPath in candidateDirs) {
      try {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          await for (final entity in dir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              final path = entity.path;
              final lower = path.toLowerCase();
              if (lower.endsWith('.mp3') ||
                  lower.endsWith('.m4a') ||
                  lower.endsWith('.wav') ||
                  lower.endsWith('.flac') ||
                  lower.endsWith('.aac')) {
                if (!foundPaths.contains(path)) {
                  foundPaths.add(path);
                  final fileName = entity.uri.pathSegments.last;
                  final title = fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').replaceAll('_', ' ');

                  deviceSongs.add(SongModel(
                    id: 'device_${path.hashCode.abs()}',
                    title: title,
                    artist: 'Phone Storage',
                    album: 'Device Audio',
                    duration: const Duration(minutes: 3), // default estimate
                    thumbnailUrl: '',
                    localFilePath: path,
                    isDownloaded: true,
                  ));
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error scanning $dirPath: $e');
      }
    }

    return deviceSongs;
  }
}

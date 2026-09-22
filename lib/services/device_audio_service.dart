import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song_model.dart';

class DeviceAudioService {
  static final DeviceAudioService _instance = DeviceAudioService._internal();
  factory DeviceAudioService() => _instance;
  DeviceAudioService._internal();

  static const MethodChannel _nativeChannel = MethodChannel('com.abhishekpal.abhisuno/native');

  /// Scan device for audio files using Android MediaStore (Android 11+ Scoped Storage compliant)
  /// with graceful directory scanning fallback.
  Future<List<SongModel>> scanDeviceAudioFiles() async {
    final List<SongModel> deviceSongs = [];
    final Set<String> foundPaths = {};

    // 1. Primary: Native MediaStore query (Fast, Scoped Storage compliant, extracts real metadata)
    try {
      final List<dynamic>? rawTracks = await _nativeChannel.invokeMethod<List<dynamic>>('getDeviceAudioTracks');
      if (rawTracks != null && rawTracks.isNotEmpty) {
        for (final item in rawTracks) {
          if (item is Map) {
            final path = item['path']?.toString() ?? '';
            if (path.isNotEmpty && !foundPaths.contains(path)) {
              foundPaths.add(path);
              final id = item['id']?.toString() ?? 'device_${path.hashCode.abs()}';
              final title = item['title']?.toString() ?? 'Unknown Track';
              final artist = item['artist']?.toString() ?? 'Phone Storage';
              final album = item['album']?.toString() ?? 'Device Audio';
              final durationMs = (item['durationMs'] as num?)?.toInt() ?? 180000;

              deviceSongs.add(SongModel(
                id: id,
                title: title,
                artist: artist,
                album: album,
                duration: Duration(milliseconds: durationMs > 0 ? durationMs : 180000),
                thumbnailUrl: '',
                localFilePath: path,
                isDownloaded: true,
              ));
            }
          }
        }
        if (deviceSongs.isNotEmpty) {
          return deviceSongs;
        }
      }
    } catch (e) {
      debugPrint('MediaStore native scan failed, falling back to directory scan: $e');
    }

    // 2. Secondary fallback: Traditional filesystem scan
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
          await for (final entity in dir.list(recursive: true, followLinks: false).handleError((_) {})) {
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
                    duration: const Duration(minutes: 3),
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

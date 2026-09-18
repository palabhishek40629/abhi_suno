import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import 'music_service.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 45),
  ));
  final MusicService _musicService = MusicService();
  static const String _storageKey = 'abhi_suno_offline_songs';

  final Map<String, double> _downloadProgress = {};
  Map<String, double> get downloadProgress => _downloadProgress;

  Future<Directory> _getAppPrivateDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final privateVault = Directory('${appDocDir.path}/abhi_suno_vault');
    if (!await privateVault.exists()) {
      await privateVault.create(recursive: true);
    }
    return privateVault;
  }

  Future<bool> downloadSong(
    SongModel song, {
    Function(double progress)? onProgress,
  }) async {
    try {
      // 1. Resolve direct audio stream url (from cache or fast parallel lookup)
      String? streamUrl = song.streamUrl;
      if (streamUrl == null || streamUrl.isEmpty) {
        streamUrl = await _musicService.getAudioStreamUrl(song.id);
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        return false;
      }

      // 2. Prepare destination path inside app private vault
      final vaultDir = await _getAppPrivateDirectory();
      final cleanId = song.id.replaceAll(RegExp(r'[^\w]+'), '_');
      final safeName = cleanId.isEmpty ? 'song_${song.title.hashCode.abs()}' : cleanId;
      final filePath = '${vaultDir.path}/$safeName.m4a';

      _downloadProgress[song.id] = 0.0;
      if (onProgress != null) onProgress(0.0);

      final downloadOptions = Options(
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
          'Referer': 'https://www.youtube.com/',
        },
      );

      try {
        await _dio.download(
          streamUrl,
          filePath,
          options: downloadOptions,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              final progress = received / total;
              _downloadProgress[song.id] = progress;
              if (onProgress != null) onProgress(progress);
            }
          },
        );
      } catch (firstErr) {
        // Fallback retry
        final fallbackUrl = await _musicService.getFallbackAudioStreamUrl(song.id);
        if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
          await _dio.download(
            fallbackUrl,
            filePath,
            options: downloadOptions,
            onReceiveProgress: (received, total) {
              if (total > 0) {
                final progress = received / total;
                _downloadProgress[song.id] = progress;
                if (onProgress != null) onProgress(progress);
              }
            },
          );
        } else {
          rethrow;
        }
      }

      _downloadProgress.remove(song.id);

      song.localFilePath = filePath;
      song.isDownloaded = true;

      await _saveOfflineTrack(song);
      return true;
    } catch (e) {
      _downloadProgress.remove(song.id);
      return false;
    }
  }

  Future<bool> isSongDownloaded(String songId) async {
    final downloaded = await getDownloadedSongs();
    return downloaded.any((s) => s.id == songId && File(s.localFilePath ?? '').existsSync());
  }

  Future<List<SongModel>> getDownloadedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encoded = prefs.getString(_storageKey);
      if (encoded == null || encoded.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(encoded);
      final List<SongModel> songs = [];

      for (final item in jsonList) {
        final song = SongModel.fromJson(item as Map<String, dynamic>);
        if (song.localFilePath != null && File(song.localFilePath!).existsSync()) {
          songs.add(song);
        }
      }
      return songs;
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveOfflineTrack(SongModel song) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentSongs = await getDownloadedSongs();

      currentSongs.removeWhere((s) => s.id == song.id);
      currentSongs.insert(0, song);

      final encoded = json.encode(currentSongs.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  Future<void> deleteDownloadedSong(String songId) async {
    try {
      final songs = await getDownloadedSongs();
      final toRemove = songs.where((s) => s.id == songId).toList();

      for (final song in toRemove) {
        if (song.localFilePath != null) {
          final file = File(song.localFilePath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      songs.removeWhere((s) => s.id == songId);
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(songs.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  // Get total offline cache storage size in MB
  Future<double> getVaultSizeInMB() async {
    try {
      final vaultDir = await _getAppPrivateDirectory();
      if (!await vaultDir.exists()) return 0.0;

      int totalBytes = 0;
      await for (final entity in vaultDir.list(recursive: true)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
      return totalBytes / (1024 * 1024);
    } catch (_) {
      return 0.0;
    }
  }

  // Clear cache memory
  Future<void> clearVaultCache() async {
    try {
      final vaultDir = await _getAppPrivateDirectory();
      if (await vaultDir.exists()) {
        await for (final entity in vaultDir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}

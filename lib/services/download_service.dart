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

  final Dio _dio = Dio();
  final MusicService _musicService = MusicService();
  static const String _storageKey = 'abhi_suno_offline_songs';

  // Map to track active download percentages (0.0 to 1.0)
  final Map<String, double> _downloadProgress = {};
  Map<String, double> get downloadProgress => _downloadProgress;

  // Get in-app sandboxed private directory for offline music
  Future<Directory> _getAppPrivateDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final privateVault = Directory('${appDocDir.path}/abhi_suno_vault');
    if (!await privateVault.exists()) {
      await privateVault.create(recursive: true);
    }
    return privateVault;
  }

  // Download song inside app's private sandbox
  Future<bool> downloadSong(
    SongModel song, {
    Function(double progress)? onProgress,
  }) async {
    try {
      // 1. Resolve direct audio stream url
      String? streamUrl = song.streamUrl;
      if (streamUrl == null || streamUrl.isEmpty) {
        streamUrl = await _musicService.getAudioStreamUrl(song.id);
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        return false;
      }

      // 2. Prepare destination path inside app's private storage
      final vaultDir = await _getAppPrivateDirectory();
      // Clean filename for safety
      final safeName = song.id.replaceAll(RegExp(r'[^\w\s]+'), '');
      final filePath = '${vaultDir.path}/$safeName.m4a';

      _downloadProgress[song.id] = 0.0;
      if (onProgress != null) onProgress(0.0);

      // 3. Download using Dio with stream progress
      await _dio.download(
        streamUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _downloadProgress[song.id] = progress;
            if (onProgress != null) onProgress(progress);
          }
        },
      );

      _downloadProgress.remove(song.id);

      // 4. Update track model with local sandboxed path
      song.localFilePath = filePath;
      song.isDownloaded = true;

      // 5. Save to persistent offline database
      await _saveOfflineTrack(song);

      return true;
    } catch (e) {
      _downloadProgress.remove(song.id);
      return false;
    }
  }

  // Check if song is downloaded inside app
  Future<bool> isSongDownloaded(String songId) async {
    final downloaded = await getDownloadedSongs();
    return downloaded.any((s) => s.id == songId && File(s.localFilePath ?? '').existsSync());
  }

  // Get list of all in-app downloaded songs (100% offline)
  Future<List<SongModel>> getDownloadedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encoded = prefs.getString(_storageKey);
      if (encoded == null || encoded.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(encoded);
      final List<SongModel> songs = [];

      for (final item in jsonList) {
        final song = SongModel.fromJson(item as Map<String, dynamic>);
        // Verify that file actually exists in private app storage
        if (song.localFilePath != null && File(song.localFilePath!).existsSync()) {
          songs.add(song);
        }
      }
      return songs;
    } catch (e) {
      return [];
    }
  }

  // Save or update offline track in local storage
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

  // Delete downloaded song from app vault
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
}

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import 'cache_manager.dart';
import 'audio_providers/unified_audio_repository.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 45),
  ));
  final CacheManager _cacheManager = CacheManager();
  final UnifiedAudioRepository _audioRepo = UnifiedAudioRepository();
  static const String _storageKey = 'abhi_suno_offline_songs';

  final Map<String, double> _downloadProgress = {};
  Map<String, double> get downloadProgress => _downloadProgress;

  Future<bool> downloadSong(
    SongModel song, {
    Function(double progress)? onProgress,
  }) async {
    try {
      // 1. Check if already permanently downloaded
      final permDir = await _cacheManager.permanentDir;
      final cleanId = song.id.replaceAll(RegExp(r'[^\w]+'), '_');
      final safeName = cleanId.isEmpty ? 'song_${DateTime.now().millisecondsSinceEpoch}' : cleanId;
      final filePath = '${permDir.path}/$safeName.m4a';

      final existingFile = File(filePath);
      if (existingFile.existsSync() && existingFile.lengthSync() > 1024) {
        song.localFilePath = filePath;
        song.isDownloaded = true;
        await _saveOfflineTrack(song);
        if (onProgress != null) onProgress(1.0);
        return true;
      }

      // 2. Check if already present in temporary cache tiers to avoid redundant network download
      final cachedFile = await _cacheManager.getCachedSongFile(song.id);
      if (cachedFile != null && await cachedFile.exists() && await cachedFile.length() > 50000) {
        try {
          await cachedFile.copy(filePath);
          song.localFilePath = filePath;
          song.isDownloaded = true;
          await _saveOfflineTrack(song);
          if (onProgress != null) onProgress(1.0);
          return true;
        } catch (_) {}
      }

      // 3. Resolve direct stream URL via UnifiedAudioRepository (JioSaavn 320 kbps Akamai CDN)
      String? streamUrl = song.streamUrl;
      if (streamUrl == null || streamUrl.isEmpty) {
        streamUrl = await _audioRepo.resolveAudioStreamUrl(song.id, quality: '320kbps');
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        return false;
      }

      _downloadProgress[song.id] = 0.0;
      if (onProgress != null) onProgress(0.0);

      final downloadOptions = Options(
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        },
      );

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

  Future<double> getPermanentStorageSizeInMB() async {
    return await _cacheManager.getPermanentDownloadsSizeMB();
  }

  Future<double> getTemporaryCacheSizeInMB() async {
    return await _cacheManager.getTemporaryCacheSizeMB();
  }

  Future<void> clearTemporaryCache() async {
    await _cacheManager.clearTemporaryCache();
  }
}

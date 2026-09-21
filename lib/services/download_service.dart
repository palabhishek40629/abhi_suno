import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import 'cache_manager.dart';
import 'audio_providers/unified_audio_repository.dart';
import 'music_service.dart';

class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal() {
    _loadInitialDownloads();
  }

  static const MethodChannel _nativeChannel = MethodChannel('com.abhishekpal.abhisuno/native');
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 45),
  ));
  final CacheManager _cacheManager = CacheManager();
  final UnifiedAudioRepository _audioRepo = UnifiedAudioRepository();
  static const String _storageKey = 'abhi_suno_offline_songs';

  final List<SongModel> _downloadedSongs = [];
  List<SongModel> get downloadedSongs => List.unmodifiable(_downloadedSongs);

  final Map<String, double> _downloadProgress = {};
  Map<String, double> get downloadProgress => Map.unmodifiable(_downloadProgress);

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> _loadInitialDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encoded = prefs.getString(_storageKey);
      if (encoded != null && encoded.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(encoded);
        _downloadedSongs.clear();

        for (final item in jsonList) {
          final song = SongModel.fromJson(item as Map<String, dynamic>);
          if (song.localFilePath != null && File(song.localFilePath!).existsSync()) {
            song.isDownloaded = true;
            _downloadedSongs.add(song);
          }
        }
      }
    } catch (_) {}
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> downloadSong(
    SongModel song, {
    Function(double progress)? onProgress,
  }) async {
    try {
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

      final prefs = await SharedPreferences.getInstance();
      final audioQuality = prefs.getString('audio_download_quality_pref') ?? '160kbps';
      final thumbQuality = prefs.getString('thumbnail_download_quality_pref') ?? '200px';

      // Check temporary cache tiers to avoid redundant download
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

      // Resolve stream URL with selected quality
      String? streamUrl = song.streamUrl;
      if (streamUrl == null || streamUrl.isEmpty) {
        streamUrl = await _audioRepo.resolveAudioStreamUrl(song.id, quality: audioQuality);
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        return false;
      }

      _downloadProgress[song.id] = 0.0;
      notifyListeners();
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
            notifyListeners();
            if (onProgress != null) onProgress(progress);
          }
        },
      );

      _downloadProgress.remove(song.id);

      song.localFilePath = filePath;
      song.isDownloaded = true;

      // Download thumbnail in 200px crisp quality (never degraded 50x50)
      final thumbPath = '${permDir.path}/$safeName.jpg';
      try {
        if (song.thumbnailUrl.isNotEmpty) {
          String thumbDownloadUrl = song.thumbnailUrl;
          if (thumbQuality == 'high') {
            thumbDownloadUrl = thumbDownloadUrl.replaceAll('150x150', '500x500');
          } else {
            // Default crisp ~200px thumbnail (150x150 or 250x250)
            thumbDownloadUrl = thumbDownloadUrl
                .replaceAll('500x500', '250x250')
                .replaceAll('50x50', '250x250');
          }
          await _dio.download(thumbDownloadUrl, thumbPath);
          if (File(thumbPath).existsSync() && File(thumbPath).lengthSync() > 100) {
            song.localThumbnailPath = thumbPath;
          }
        }
      } catch (_) {}

      // Download lyrics for 100% offline reading
      final lyricsPath = '${permDir.path}/$safeName.lrc';
      try {
        final lyrics = await MusicService().fetchLyrics(song.title, song.artist, songId: song.id);
        if (lyrics.isNotEmpty && !lyrics.contains('गीत के बोल उपलब्ध नहीं हैं')) {
          final lrcFile = File(lyricsPath);
          await lrcFile.writeAsString(lyrics);
          song.localLyricsPath = lyricsPath;
          song.lyrics = lyrics;
        }
      } catch (_) {}

      await _saveOfflineTrack(song);
      return true;
    } catch (e) {
      _downloadProgress.remove(song.id);
      notifyListeners();
      return false;
    }
  }

  bool isSongDownloaded(String songId) {
    return _downloadedSongs.any((s) => s.id == songId && File(s.localFilePath ?? '').existsSync());
  }

  Future<List<SongModel>> getDownloadedSongs() async {
    if (!_isInitialized) {
      await _loadInitialDownloads();
    }
    return List.unmodifiable(_downloadedSongs);
  }

  Future<void> _saveOfflineTrack(SongModel song) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _downloadedSongs.removeWhere((s) => s.id == song.id);
      _downloadedSongs.insert(0, song);

      final encoded = json.encode(_downloadedSongs.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, encoded);

      // Reactively notify listeners immediately so Downloads UI updates with zero delay!
      notifyListeners();
    } catch (_) {}
  }

  Future<void> deleteDownloadedSong(String songId) async {
    try {
      final toRemove = _downloadedSongs.where((s) => s.id == songId).toList();

      for (final song in toRemove) {
        if (song.localFilePath != null) {
          final file = File(song.localFilePath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        if (song.localThumbnailPath != null) {
          final thumb = File(song.localThumbnailPath!);
          if (await thumb.exists()) {
            await thumb.delete();
          }
        }
        if (song.localLyricsPath != null) {
          final lrc = File(song.localLyricsPath!);
          if (await lrc.exists()) {
            await lrc.delete();
          }
        }
      }

      _downloadedSongs.removeWhere((s) => s.id == songId);
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(_downloadedSongs.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, encoded);

      notifyListeners();
    } catch (_) {}
  }

  /// Export downloaded song outside the app into public Music folder
  Future<String?> exportSongToPublic(SongModel song) async {
    try {
      if (song.localFilePath == null || !File(song.localFilePath!).existsSync()) {
        return null;
      }

      final cleanName = '${song.title} - ${song.artist}'.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_') + '.m4a';
      final String? exportedPath = await _nativeChannel.invokeMethod<String>('exportAudio', {
        'srcPath': song.localFilePath,
        'fileName': cleanName,
      });

      return exportedPath;
    } catch (_) {
      return null;
    }
  }

  /// Share audio file via native Android Sharesheet
  Future<void> shareAudioFile(SongModel song) async {
    try {
      if (song.localFilePath != null && File(song.localFilePath!).existsSync()) {
        await _nativeChannel.invokeMethod('shareAudio', {
          'srcPath': song.localFilePath,
          'title': 'Share ${song.title}',
        });
      } else {
        await _nativeChannel.invokeMethod('shareText', {
          'text': 'Listen to "${song.title}" by ${song.artist} on Abhi Suno!',
          'title': 'Share Song',
        });
      }
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
    notifyListeners();
  }
}

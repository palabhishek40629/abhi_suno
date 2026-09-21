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

  final List<SongModel> _downloadQueue = [];
  List<SongModel> get downloadQueue => List.unmodifiable(_downloadQueue);

  SongModel? _currentlyDownloadingSong;
  SongModel? get currentlyDownloadingSong => _currentlyDownloadingSong;
  int get queueCount => _downloadQueue.length + (_currentlyDownloadingSong != null ? 1 : 0);

  bool _isWorkerRunning = false;
  final Map<String, Completer<bool>> _taskCompleters = {};
  final Map<String, Function(double)?> _taskProgressCallbacks = {};

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

  bool isSongInQueue(String songId) {
    return _currentlyDownloadingSong?.id == songId || _downloadQueue.any((s) => s.id == songId);
  }

  /// Sequential Single Track Download Entrypoint
  Future<bool> downloadSong(
    SongModel song, {
    Function(double progress)? onProgress,
  }) async {
    if (isSongDownloaded(song.id)) {
      if (onProgress != null) onProgress(1.0);
      return true;
    }

    if (isSongInQueue(song.id)) {
      if (onProgress != null) {
        _taskProgressCallbacks[song.id] = onProgress;
      }
      return _taskCompleters[song.id]?.future ?? Future.value(true);
    }

    final completer = Completer<bool>();
    _taskCompleters[song.id] = completer;
    if (onProgress != null) {
      _taskProgressCallbacks[song.id] = onProgress;
    }

    _downloadQueue.add(song);
    notifyListeners();

    _startSequentialWorker();
    return completer.future;
  }

  /// Enqueue Batch of Songs (e.g. Playlist "Download All") Sequentially
  Future<void> downloadSongsSequentially(List<SongModel> songs) async {
    for (final song in songs) {
      if (!isSongDownloaded(song.id) && !isSongInQueue(song.id)) {
        final completer = Completer<bool>();
        _taskCompleters[song.id] = completer;
        _downloadQueue.add(song);
      }
    }
    notifyListeners();
    _startSequentialWorker();
  }

  /// Single-Worker Sequential Processor (Strictly One Song At A Time)
  Future<void> _startSequentialWorker() async {
    if (_isWorkerRunning) return;
    _isWorkerRunning = true;

    while (_downloadQueue.isNotEmpty) {
      final song = _downloadQueue.removeAt(0);
      _currentlyDownloadingSong = song;
      notifyListeners();

      bool success = false;
      try {
        success = await _executeSingleDownload(song);
      } catch (_) {
        success = false;
      }

      final completer = _taskCompleters.remove(song.id);
      if (completer != null && !completer.isCompleted) {
        completer.complete(success);
      }
      _taskProgressCallbacks.remove(song.id);
      _downloadProgress.remove(song.id);

      _currentlyDownloadingSong = null;
      notifyListeners();
    }

    _isWorkerRunning = false;
    try {
      _nativeChannel.invokeMethod('dismissDownloadNotification');
    } catch (_) {}
    notifyListeners();
  }

  /// Internal Worker Method to download Audio + High-Res Banner + Synced Lyrics
  Future<bool> _executeSingleDownload(SongModel song) async {
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
        _taskProgressCallbacks[song.id]?.call(1.0);
        return true;
      }

      final prefs = await SharedPreferences.getInstance();
      final audioQuality = prefs.getString('audio_download_quality_pref') ?? '320kbps';
      final thumbQuality = prefs.getString('thumbnail_download_quality_pref') ?? '200px';

      // 1. Check temporary cache tiers to avoid redundant download
      final cachedFile = await _cacheManager.getCachedSongFile(song.id);
      if (cachedFile != null && await cachedFile.exists() && await cachedFile.length() > 50000) {
        try {
          await cachedFile.copy(filePath);
          song.localFilePath = filePath;
          song.isDownloaded = true;
          await _saveOfflineTrack(song);
          _taskProgressCallbacks[song.id]?.call(1.0);
          return true;
        } catch (_) {}
      }

      // 2. Resolve stream URL with 100% JioSaavn Primary
      String? streamUrl = song.streamUrl;
      if (streamUrl == null || streamUrl.isEmpty) {
        final query = '${song.title} ${song.artist}'.trim();
        streamUrl = await _audioRepo.resolveAudioStreamUrl(song.id, query: query, quality: audioQuality);
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        return false;
      }

      _downloadProgress[song.id] = 0.0;
      notifyListeners();
      _taskProgressCallbacks[song.id]?.call(0.0);

      final downloadOptions = Options(
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept': '*/*',
          'Connection': 'keep-alive',
        },
      );

      // 3. Download Audio Stream Sequentially
      await _dio.download(
        streamUrl,
        filePath,
        options: downloadOptions,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            _downloadProgress[song.id] = progress;
            notifyListeners();
            _taskProgressCallbacks[song.id]?.call(progress);
            try {
              final remaining = _downloadQueue.length;
              final statusTitle = remaining > 0 ? '${song.title} (+$remaining in queue)' : song.title;
              _nativeChannel.invokeMethod('updateDownloadNotification', {
                'title': statusTitle,
                'progress': (progress * 100).toInt(),
                'isDone': false,
              });
            } catch (_) {}
          }
        },
      );

      final audioFile = File(filePath);
      if (!audioFile.existsSync() || audioFile.lengthSync() < 50000) {
        try { if (audioFile.existsSync()) audioFile.deleteSync(); } catch (_) {}
        return false;
      }

      try {
        _nativeChannel.invokeMethod('updateDownloadNotification', {
          'title': song.title,
          'progress': 100,
          'isDone': true,
        });
      } catch (_) {}

      song.localFilePath = filePath;
      song.isDownloaded = true;

      // 4. Download High-Res / Crisp Artwork Banner (.jpg)
      final thumbPath = '${permDir.path}/$safeName.jpg';
      try {
        if (song.thumbnailUrl.isNotEmpty) {
          String thumbDownloadUrl = song.thumbnailUrl;
          if (thumbQuality == 'high') {
            thumbDownloadUrl = thumbDownloadUrl.replaceAll('150x150', '500x500');
          } else {
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

      // 5. Download Synced Timestamps Lyrics (.lrc)
      final lyricsPath = '${permDir.path}/$safeName.lrc';
      try {
        final lyrics = await MusicService().fetchLyrics(song.title, song.artist, songId: song.id);
        if (lyrics.isNotEmpty && !lyrics.contains('गीत के बोल उपलब्ध नहीं हैं') && !lyrics.contains('Lyrics not available')) {
          final lrcFile = File(lyricsPath);
          await lrcFile.writeAsString(lyrics);
          song.localLyricsPath = lyricsPath;
          song.lyrics = lyrics;
        }
      } catch (_) {}

      await _saveOfflineTrack(song);
      return true;
    } catch (e) {
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

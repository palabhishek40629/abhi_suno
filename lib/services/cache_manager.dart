import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum CacheTier {
  current,
  prefetch,
  recent,
  permanent,
}

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  Directory? _baseCacheDir;
  Directory? _currentDir;
  Directory? _prefetchDir;
  Directory? _recentDir;
  Directory? _permanentDir;

  Future<void> init() async {
    if (_baseCacheDir != null) return;
    final appDocDir = await getApplicationDocumentsDirectory();
    _baseCacheDir = Directory('${appDocDir.path}/abhi_suno_cache');

    _currentDir = Directory('${_baseCacheDir!.path}/CURRENT');
    _prefetchDir = Directory('${_baseCacheDir!.path}/PREFETCH');
    _recentDir = Directory('${_baseCacheDir!.path}/RECENT');
    _permanentDir = Directory('${appDocDir.path}/abhi_suno_vault/PERMANENT');

    await _currentDir!.create(recursive: true);
    await _prefetchDir!.create(recursive: true);
    await _recentDir!.create(recursive: true);
    await _permanentDir!.create(recursive: true);
  }

  Future<Directory> get currentDir async {
    await init();
    return _currentDir!;
  }

  Future<Directory> get prefetchDir async {
    await init();
    return _prefetchDir!;
  }

  Future<Directory> get recentDir async {
    await init();
    return _recentDir!;
  }

  Future<Directory> get permanentDir async {
    await init();
    return _permanentDir!;
  }

  /// Get cached file if it exists in any tier
  Future<File?> getCachedSongFile(String songId) async {
    await init();
    final cleanId = _cleanId(songId);

    // 1. Check PERMANENT (Offline downloads)
    final permFile = File('${_permanentDir!.path}/$cleanId.m4a');
    if (await permFile.exists() && await permFile.length() > 1024) return permFile;

    // 2. Check CURRENT
    final curFile = File('${_currentDir!.path}/$cleanId.m4a');
    if (await curFile.exists() && await curFile.length() > 1024) return curFile;

    // 3. Check PREFETCH
    final prefFile = File('${_prefetchDir!.path}/$cleanId.m4a');
    if (await prefFile.exists() && await prefFile.length() > 1024) return prefFile;

    // 4. Check RECENT
    final recFile = File('${_recentDir!.path}/$cleanId.m4a');
    if (await recFile.exists() && await recFile.length() > 1024) return recFile;

    return null;
  }

  /// Promote prefetched file to current
  Future<File?> promotePrefetchToCurrent(String songId) async {
    await init();
    final cleanId = _cleanId(songId);
    final prefFile = File('${_prefetchDir!.path}/$cleanId.m4a');
    if (await prefFile.exists()) {
      final dest = File('${_currentDir!.path}/$cleanId.m4a');
      try {
        await prefFile.rename(dest.path);
        return dest;
      } catch (_) {
        return prefFile;
      }
    }
    return null;
  }

  /// Demote current to recent
  Future<void> demoteCurrentToRecent(String songId) async {
    await init();
    final cleanId = _cleanId(songId);
    final curFile = File('${_currentDir!.path}/$cleanId.m4a');
    if (await curFile.exists()) {
      final dest = File('${_recentDir!.path}/$cleanId.m4a');
      try {
        await curFile.rename(dest.path);
      } catch (_) {}
    }
    await _enforceRecentLRULimit();
  }

  /// Keep only the most recent 10 tracks in RECENT tier
  Future<void> _enforceRecentLRULimit() async {
    try {
      await init();
      final entities = _recentDir!.listSync().whereType<File>().toList();
      if (entities.length > 10) {
        entities.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
        for (int i = 0; i < entities.length - 10; i++) {
          try {
            await entities[i].delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Total temporary cache size in MB (CURRENT + PREFETCH + RECENT)
  Future<double> getTemporaryCacheSizeMB() async {
    await init();
    int bytes = 0;
    bytes += await _calcDirSize(_currentDir!);
    bytes += await _calcDirSize(_prefetchDir!);
    bytes += await _calcDirSize(_recentDir!);
    return bytes / (1024 * 1024);
  }

  /// Total permanent offline downloads size in MB
  Future<double> getPermanentDownloadsSizeMB() async {
    await init();
    final bytes = await _calcDirSize(_permanentDir!);
    return bytes / (1024 * 1024);
  }

  Future<int> _calcDirSize(Directory dir) async {
    if (!await dir.exists()) return 0;
    int total = 0;
    try {
      await for (final file in dir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          total += await file.length();
        }
      }
    } catch (_) {}
    return total;
  }

  /// Clear ONLY temporary cache tiers (CURRENT, PREFETCH, RECENT). NEVER touches PERMANENT.
  Future<void> clearTemporaryCache() async {
    await init();
    await _clearDirContents(_currentDir!);
    await _clearDirContents(_prefetchDir!);
    await _clearDirContents(_recentDir!);
  }

  Future<void> _clearDirContents(Directory dir) async {
    if (!await dir.exists()) return;
    try {
      await for (final entity in dir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    } catch (_) {}
  }

  String _cleanId(String id) {
    final clean = id.replaceAll(RegExp(r'[^\w]+'), '_');
    return clean.isEmpty ? 'track_' : clean;
  }
}

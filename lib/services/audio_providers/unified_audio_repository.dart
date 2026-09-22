import 'dart:async';
import 'audio_provider_adapter.dart';
import 'jiosaavn_adapter.dart';

class UnifiedAudioRepository {
  static final UnifiedAudioRepository _instance = UnifiedAudioRepository._internal();
  factory UnifiedAudioRepository() => _instance;
  UnifiedAudioRepository._internal();

  final JioSaavnAdapter _primaryJioSaavn = JioSaavnAdapter();

  // In-memory stream cache
  final Map<String, String> _streamCache = {};

  // Request deduplication map
  final Map<String, Future<String?>> _inFlightRequests = {};

  Future<String?> resolveAudioStreamUrl(String trackId, {String? query, String quality = '320kbps'}) async {
    // 1. Check if trackId is already a direct http/https stream URL
    if (trackId.startsWith('http://') || trackId.startsWith('https://')) {
      return trackId;
    }

    // 2. Check in-memory stream cache
    if (_streamCache.containsKey(trackId)) {
      return _streamCache[trackId];
    }

    final cacheLookupKey = query != null && query.isNotEmpty ? '${trackId}_$query' : trackId;
    if (_streamCache.containsKey(cacheLookupKey)) {
      return _streamCache[cacheLookupKey];
    }

    // 3. Request deduplication
    if (_inFlightRequests.containsKey(cacheLookupKey)) {
      return await _inFlightRequests[cacheLookupKey];
    }

    // 4. Initiate resolution and record in flight
    final future = _executeResolution(trackId, query: query, quality: quality);
    _inFlightRequests[cacheLookupKey] = future;

    try {
      final result = await future;
      if (result != null && result.isNotEmpty) {
        _streamCache[trackId] = result;
        _streamCache[cacheLookupKey] = result;
      }
      return result;
    } finally {
      _inFlightRequests.remove(cacheLookupKey);
    }
  }

  Future<String?> _executeResolution(String trackId, {String? query, String quality = '320kbps'}) async {
    // 1. 100% Primary: JioSaavn Akamai CDN by Track PID
    try {
      final saavnUrl = await _primaryJioSaavn.resolveAudioStreamUrl(trackId, quality: quality);
      if (saavnUrl != null && saavnUrl.isNotEmpty) {
        return saavnUrl;
      }
    } catch (_) {}

    // 2. JioSaavn Match by Song Title / Full Query (<100ms response)
    if (query != null && query.trim().isNotEmpty) {
      try {
        final cleanQ = query.replaceAll(RegExp(r'\(.*?\)'), '').replaceAll(RegExp(r'\[.*?\]'), '').trim();
        final matches = await _primaryJioSaavn.searchSongs(cleanQ, limit: 3);
        if (matches.isNotEmpty) {
          for (final match in matches) {
            if (match.streamUrl != null && match.streamUrl!.isNotEmpty) {
              return match.streamUrl;
            }
            if (match.id.isNotEmpty) {
              final resolved = await _primaryJioSaavn.resolveAudioStreamUrl(match.id, quality: quality);
              if (resolved != null && resolved.isNotEmpty) {
                return resolved;
              }
            }
          }
        }
      } catch (_) {}

      // 3. Fallback: Search by song title alone (strips secondary artist names)
      try {
        final titleOnly = query.split('-').first.split('|').first.replaceAll(RegExp(r'\(.*?\)'), '').trim();
        if (titleOnly.isNotEmpty && titleOnly != query.trim()) {
          final titleMatches = await _primaryJioSaavn.searchSongs(titleOnly, limit: 3);
          if (titleMatches.isNotEmpty) {
            for (final match in titleMatches) {
              if (match.streamUrl != null && match.streamUrl!.isNotEmpty) {
                return match.streamUrl;
              }
              if (match.id.isNotEmpty) {
                final resolved = await _primaryJioSaavn.resolveAudioStreamUrl(match.id, quality: quality);
                if (resolved != null && resolved.isNotEmpty) {
                  return resolved;
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  void cacheStreamUrl(String trackId, String url) {
    if (trackId.isNotEmpty && url.isNotEmpty) {
      _streamCache[trackId] = url;
    }
  }

  bool hasCachedStream(String trackId) => _streamCache.containsKey(trackId);

  void clearStreamCache() {
    _streamCache.clear();
  }
}

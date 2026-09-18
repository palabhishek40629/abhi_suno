import 'dart:async';
import 'audio_provider_adapter.dart';
import 'jiosaavn_adapter.dart';
import 'youtube_explode_adapter.dart';

class UnifiedAudioRepository {
  static final UnifiedAudioRepository _instance = UnifiedAudioRepository._internal();
  factory UnifiedAudioRepository() => _instance;
  UnifiedAudioRepository._internal();

  final JioSaavnAdapter _primaryJioSaavn = JioSaavnAdapter();
  final YouTubeExplodeAdapter _secondaryYouTube = YouTubeExplodeAdapter();

  // In-memory stream cache
  final Map<String, String> _streamCache = {};

  // Request deduplication map
  final Map<String, Future<String?>> _inFlightRequests = {};

  Future<String?> resolveAudioStreamUrl(String trackId, {String quality = '320kbps'}) async {
    // 1. Check in-memory stream cache
    if (_streamCache.containsKey(trackId)) {
      return _streamCache[trackId];
    }

    // 2. Request deduplication
    if (_inFlightRequests.containsKey(trackId)) {
      return await _inFlightRequests[trackId];
    }

    // 3. Initiate resolution and record in flight
    final future = _executeResolution(trackId, quality: quality);
    _inFlightRequests[trackId] = future;

    try {
      final result = await future;
      if (result != null && result.isNotEmpty) {
        _streamCache[trackId] = result;
      }
      return result;
    } finally {
      _inFlightRequests.remove(trackId);
    }
  }

  Future<String?> _executeResolution(String trackId, {String quality = '320kbps'}) async {
    // Check if ID is a YouTube 11-char ID
    final isYouTubeId = RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trackId);

    if (isYouTubeId) {
      try {
        final ytUrl = await _secondaryYouTube.resolveAudioStreamUrl(trackId);
        if (ytUrl != null && ytUrl.isNotEmpty) return ytUrl;
      } catch (_) {}
    }

    // Primary resolution via JioSaavn Akamai CDN
    try {
      final saavnUrl = await _primaryJioSaavn.resolveAudioStreamUrl(trackId, quality: quality);
      if (saavnUrl != null && saavnUrl.isNotEmpty) {
        return saavnUrl;
      }
    } catch (_) {}

    // Fallback resolution via YouTube Explode if not tried yet
    if (!isYouTubeId) {
      try {
        final ytFallback = await _secondaryYouTube.resolveAudioStreamUrl(trackId);
        if (ytFallback != null && ytFallback.isNotEmpty) {
          return ytFallback;
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

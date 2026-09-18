import 'dart:async';
import 'audio_provider_adapter.dart';
import 'youtube_explode_adapter.dart';
import 'piped_invidious_adapter.dart';

class UnifiedAudioRepository {
  static final UnifiedAudioRepository _instance = UnifiedAudioRepository._internal();
  factory UnifiedAudioRepository() => _instance;
  UnifiedAudioRepository._internal();

  final YouTubeExplodeAdapter _primaryAdapter = YouTubeExplodeAdapter();
  final PipedInvidiousAdapter _fallbackAdapter = PipedInvidiousAdapter();

  // In-memory stream cache
  final Map<String, String> _streamCache = {};

  // Request deduplication map: prevents duplicate concurrent requests for the same track
  final Map<String, Future<String?>> _inFlightRequests = {};

  // Resolve audio stream URL with caching, deduplication, and parallel race
  Future<String?> resolveAudioStreamUrl(String trackId) async {
    // 1. Check in-memory stream cache
    if (_streamCache.containsKey(trackId)) {
      return _streamCache[trackId];
    }

    // 2. Request deduplication: if request is already in-flight, await existing Future
    if (_inFlightRequests.containsKey(trackId)) {
      return await _inFlightRequests[trackId];
    }

    // 3. Initiate resolution and record in flight
    final future = _executeResolution(trackId);
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

  Future<String?> _executeResolution(String trackId) async {
    // Parallel race between primary adapter and fallback adapter
    final primaryFuture = _primaryAdapter.resolveAudioStreamUrl(trackId).then<String>((url) {
      if (url != null && url.isNotEmpty) return url;
      throw Exception('primary null');
    });

    final fallbackFuture = _fallbackAdapter.resolveAudioStreamUrl(trackId).then<String>((url) {
      if (url != null && url.isNotEmpty) return url;
      throw Exception('fallback null');
    });

    try {
      final String resolvedUrl = await Future.any<String>([
        primaryFuture,
        fallbackFuture,
      ]).timeout(const Duration(seconds: 4));

      if (resolvedUrl.isNotEmpty) {
        return resolvedUrl;
      }
    } catch (_) {
      // If race failed, attempt sequential fallback
      try {
        final fallback = await _primaryAdapter.resolveAudioStreamUrl(trackId) ??
            await _fallbackAdapter.resolveAudioStreamUrl(trackId);
        if (fallback != null && fallback.isNotEmpty) {
          return fallback;
        }
      } catch (_) {}
    }

    return null;
  }

  void cacheStreamUrl(String trackId, String url) {
    _streamCache[trackId] = url;
  }

  bool hasCachedStream(String trackId) => _streamCache.containsKey(trackId);
}

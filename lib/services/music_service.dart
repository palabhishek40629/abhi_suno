import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';
import 'audio_providers/jiosaavn_adapter.dart';
import 'audio_providers/unified_audio_repository.dart';
import 'language_service.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final JioSaavnAdapter _saavnAdapter = JioSaavnAdapter();
  final UnifiedAudioRepository _audioRepo = UnifiedAudioRepository();

  // In-Memory Fast Cache to make home & category scrolling instant
  final Map<String, List<SongModel>> _queryCache = {};
  final Map<String, String> _lyricsCache = {};

  /// Search music catalog using 100% JioSaavn CDN direct open-source API with in-memory caching
  Future<List<SongModel>> searchSongs(String query, {bool forceRefresh = false}) async {
    final cleanQuery = query.trim().isEmpty ? 'Top Hindi Songs Bollywood' : query.trim();
    final cacheKey = cleanQuery.toLowerCase();

    if (!forceRefresh && _queryCache.containsKey(cacheKey) && _queryCache[cacheKey]!.isNotEmpty) {
      return _queryCache[cacheKey]!;
    }

    // 1. Primary fast search on JioSaavn (<120ms)
    try {
      final saavnResults = await _saavnAdapter.searchSongs(cleanQuery, limit: 35);
      if (saavnResults.isNotEmpty) {
        for (final song in saavnResults) {
          if (song.streamUrl != null && song.streamUrl!.isNotEmpty) {
            _audioRepo.cacheStreamUrl(song.id, song.streamUrl!);
          }
        }
        _queryCache[cacheKey] = saavnResults;
        return saavnResults;
      }
    } catch (_) {}

    // 2. Secondary fallback: Cleaned query (removes brackets, feat, video, etc.)
    final stripped = _cleanTitle(cleanQuery);
    if (stripped.isNotEmpty && stripped.toLowerCase() != cleanQuery.toLowerCase()) {
      try {
        final strippedResults = await _saavnAdapter.searchSongs(stripped, limit: 35);
        if (strippedResults.isNotEmpty) {
          for (final song in strippedResults) {
            if (song.streamUrl != null && song.streamUrl!.isNotEmpty) {
              _audioRepo.cacheStreamUrl(song.id, song.streamUrl!);
            }
          }
          _queryCache[cacheKey] = strippedResults;
          return strippedResults;
        }
      } catch (_) {}
    }

    // 3. Tertiary fallback: First keyword or primary title token
    final primaryKeyword = cleanQuery.split(' ').first.trim();
    if (primaryKeyword.length >= 3 && primaryKeyword.toLowerCase() != cleanQuery.toLowerCase()) {
      try {
        final keywordResults = await _saavnAdapter.searchSongs(primaryKeyword, limit: 25);
        if (keywordResults.isNotEmpty) {
          _queryCache[cacheKey] = keywordResults;
          return keywordResults;
        }
      } catch (_) {}
    }

    return [];
  }

  /// Multi-Source Lyrics Engine (Prioritizes Millisecond Synced LRC, with JioSaavn & Plaintext Fallbacks)
  Future<String> fetchLyrics(String title, String artist, {String? songId}) async {
    final cacheKey = '$title-$artist'.toLowerCase();
    if (_lyricsCache.containsKey(cacheKey)) {
      return _lyricsCache[cacheKey]!;
    }

    final cleanT = _cleanTitle(title);
    final cleanA = artist
        .replaceAll(RegExp(r'(VEVO|Official|Topic|Music|Zee Music|T-Series)', caseSensitive: false), '')
        .split(',')
        .first
        .trim();

    String? plainLyricsFallback;

    // 1. First Priority: LRCLIB Search with Clean Title + Artist (Instant Millisecond Synced Lyrics)
    try {
      final searchUrl = Uri.parse(
        'https://lrclib.net/api/search?q=${Uri.encodeComponent("$cleanT $cleanA")}',
      );
      final res = await http.get(
        searchUrl,
        headers: {'User-Agent': 'AbhiSuno/4.4.1 (palabhishek40629@gmail.com)'},
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(res.body);
        for (final item in list) {
          if (item['syncedLyrics'] != null && item['syncedLyrics'].toString().trim().isNotEmpty) {
            final lyrics = item['syncedLyrics'].toString();
            _lyricsCache[cacheKey] = lyrics;
            return lyrics;
          }
          if (plainLyricsFallback == null && item['plainLyrics'] != null && item['plainLyrics'].toString().trim().isNotEmpty) {
            plainLyricsFallback = item['plainLyrics'].toString();
          }
        }
      }
    } catch (_) {}

    // 2. Second Priority: LRCLIB Search with Clean Title Alone (Captures Indian Chartbusters Regardless of Artist Variations)
    try {
      if (cleanT.isNotEmpty && cleanT != title) {
        final titleOnlyUrl = Uri.parse(
          'https://lrclib.net/api/search?q=${Uri.encodeComponent(cleanT)}',
        );
        final res = await http.get(
          titleOnlyUrl,
          headers: {'User-Agent': 'AbhiSuno/4.4.1 (palabhishek40629@gmail.com)'},
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          final List<dynamic> list = json.decode(res.body);
          for (final item in list) {
            if (item['syncedLyrics'] != null && item['syncedLyrics'].toString().trim().isNotEmpty) {
              final lyrics = item['syncedLyrics'].toString();
              _lyricsCache[cacheKey] = lyrics;
              return lyrics;
            }
            if (plainLyricsFallback == null && item['plainLyrics'] != null && item['plainLyrics'].toString().trim().isNotEmpty) {
              plainLyricsFallback = item['plainLyrics'].toString();
            }
          }
        }
      }
    } catch (_) {}

    // 3. Third Priority: LRCLIB Exact Match Endpoint
    try {
      final exactUrl = Uri.parse(
        'https://lrclib.net/api/get?track_name=${Uri.encodeComponent(cleanT)}&artist_name=${Uri.encodeComponent(cleanA)}',
      );
      final res = await http.get(
        exactUrl,
        headers: {'User-Agent': 'AbhiSuno/4.4.1 (palabhishek40629@gmail.com)'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['syncedLyrics'] != null && data['syncedLyrics'].toString().trim().isNotEmpty) {
          final lyrics = data['syncedLyrics'].toString();
          _lyricsCache[cacheKey] = lyrics;
          return lyrics;
        }
        if (plainLyricsFallback == null && data['plainLyrics'] != null && data['plainLyrics'].toString().trim().isNotEmpty) {
          plainLyricsFallback = data['plainLyrics'].toString();
        }
      }
    } catch (_) {}

    // 4. Fourth Priority: Direct Official JioSaavn Lyrics (Plaintext)
    if (songId != null && songId.isNotEmpty) {
      try {
        final saavnLyrics = await _saavnAdapter.fetchLyrics(songId);
        if (saavnLyrics != null && saavnLyrics.trim().isNotEmpty) {
          _lyricsCache[cacheKey] = saavnLyrics;
          return saavnLyrics;
        }
      } catch (_) {}
    }

    // 5. Use cached LRCLIB plaintext if available
    if (plainLyricsFallback != null && plainLyricsFallback.trim().isNotEmpty) {
      _lyricsCache[cacheKey] = plainLyricsFallback;
      return plainLyricsFallback;
    }

    // 6. Lyrics.ovh Public Fallback API
    try {
      if (cleanA.isNotEmpty && cleanT.isNotEmpty) {
        final ovhUrl = Uri.parse(
          'https://api.lyrics.ovh/v1/${Uri.encodeComponent(cleanA)}/${Uri.encodeComponent(cleanT)}',
        );
        final res = await http.get(ovhUrl).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (data['lyrics'] != null && data['lyrics'].toString().trim().isNotEmpty) {
            final lyrics = data['lyrics'].toString().trim();
            _lyricsCache[cacheKey] = lyrics;
            return lyrics;
          }
        }
      }
    } catch (_) {}

    // 7. Graceful Fallback
    final isHindi = LanguageService().isHindi;
    final fallback = isHindi
        ? 'गीत के बोल उपलब्ध नहीं हैं।\n\nअभी सुनो - शुद्ध भारतीय संगीत प्लेयर'
        : 'Lyrics not available for this song.\n\nAbhi Suno - Ad-Free Music Player';
    _lyricsCache[cacheKey] = fallback;
    return fallback;
  }

  Future<void> preloadStreamUrl(String songId) async {
    try {
      await _audioRepo.resolveAudioStreamUrl(songId, quality: '320kbps');
    } catch (_) {}
  }

  Future<List<SongModel>> getTrendingHindi() => searchSongs('Trending Hindi Songs Top 50 Chartbusters');
  Future<List<SongModel>> getBollywoodRomantic() => searchSongs('Bollywood Romantic Superhit Love Songs Arijit');
  Future<List<SongModel>> getRetroClassics() => searchSongs('Kishore Kumar Lata Mangeshkar 90s Evergreen Retro');
  Future<List<SongModel>> getPunjabiHits() => searchSongs('Punjabi Superhit Songs Karan Aujla Sidhu');
  Future<List<SongModel>> getHindiLofi() => searchSongs('Hindi Lo-Fi Slowed Reverb Aesthetic Chill');

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
        .replaceAll(RegExp(r'["\-_|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<List<String>> getAutocompleteSuggestions(String query) async {
    return await _saavnAdapter.getAutocompleteSuggestions(query);
  }

  Future<List<JioSaavnPlaylist>> searchPlaylists(String query) async {
    return await _saavnAdapter.searchPlaylists(query);
  }

  Future<List<SongModel>> getPlaylistSongs(String playlistId) async {
    return await _saavnAdapter.getPlaylistSongs(playlistId);
  }
}


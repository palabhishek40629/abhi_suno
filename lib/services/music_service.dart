import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song_model.dart';
import 'audio_providers/jiosaavn_adapter.dart';
import 'audio_providers/unified_audio_repository.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final YoutubeExplode _yt = YoutubeExplode();
  final JioSaavnAdapter _saavnAdapter = JioSaavnAdapter();
  final UnifiedAudioRepository _audioRepo = UnifiedAudioRepository();

  // In-Memory Fast Cache to make home & category scrolling instant
  final Map<String, List<SongModel>> _queryCache = {};
  final Map<String, String> _lyricsCache = {};

  /// Search music catalog using JioSaavn CDN primary with in-memory caching
  Future<List<SongModel>> searchSongs(String query, {bool forceRefresh = false}) async {
    final cleanQuery = query.trim().isEmpty ? 'Top Hindi Songs Bollywood' : query.trim();
    final cacheKey = cleanQuery.toLowerCase();

    if (!forceRefresh && _queryCache.containsKey(cacheKey) && _queryCache[cacheKey]!.isNotEmpty) {
      return _queryCache[cacheKey]!;
    }

    // 1. Primary fast search on JioSaavn (<150ms)
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

    // 2. Secondary fallback search on YouTube Explode
    try {
      final searchResults = await _yt.search.search(cleanQuery);
      final List<SongModel> songs = [];

      for (final video in searchResults) {
        if (video.duration != null && video.duration!.inMinutes > 15) continue;

        final cleanTitle = _cleanTitle(video.title);
        final song = SongModel(
          id: video.id.value,
          title: cleanTitle,
          artist: video.author,
          album: 'Single',
          duration: video.duration ?? const Duration(minutes: 3),
          thumbnailUrl: video.thumbnails.highResUrl.isNotEmpty
              ? video.thumbnails.highResUrl
              : video.thumbnails.standardResUrl,
        );
        songs.add(song);
        if (songs.length >= 25) break;
      }

      if (songs.isNotEmpty) {
        _queryCache[cacheKey] = songs;
        return songs;
      }
    } catch (_) {}

    return [];
  }

  /// Multi-Source Lyrics Engine (LRCLIB Search + JioSaavn API + Synced LRC Timestamps)
  Future<String> fetchLyrics(String title, String artist) async {
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

    // 1. LRCLIB Fuzzy Search endpoint (works on Indian tracks with synced LRC lines)
    try {
      final searchUrl = Uri.parse(
        'https://lrclib.net/api/search?q=\${Uri.encodeComponent("\$cleanT \$cleanA")}',
      );
      final res = await http.get(
        searchUrl,
        headers: {'User-Agent': 'AbhiSuno/3.5.0 (palabhishek40629@gmail.com)'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(res.body);
        for (final item in list) {
          if (item['syncedLyrics'] != null && item['syncedLyrics'].toString().trim().isNotEmpty) {
            final lyrics = item['syncedLyrics'].toString();
            _lyricsCache[cacheKey] = lyrics;
            return lyrics;
          }
          if (item['plainLyrics'] != null && item['plainLyrics'].toString().trim().isNotEmpty) {
            final lyrics = item['plainLyrics'].toString();
            _lyricsCache[cacheKey] = lyrics;
            return lyrics;
          }
        }
      }
    } catch (_) {}

    // 2. LRCLIB Exact Get endpoint
    try {
      final exactUrl = Uri.parse(
        'https://lrclib.net/api/get?track_name=\${Uri.encodeComponent(cleanT)}&artist_name=\${Uri.encodeComponent(cleanA)}',
      );
      final res = await http.get(
        exactUrl,
        headers: {'User-Agent': 'AbhiSuno/3.5.0 (palabhishek40629@gmail.com)'},
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['syncedLyrics'] != null && data['syncedLyrics'].toString().trim().isNotEmpty) {
          final lyrics = data['syncedLyrics'].toString();
          _lyricsCache[cacheKey] = lyrics;
          return lyrics;
        }
        if (data['plainLyrics'] != null && data['plainLyrics'].toString().trim().isNotEmpty) {
          final lyrics = data['plainLyrics'].toString();
          _lyricsCache[cacheKey] = lyrics;
          return lyrics;
        }
      }
    } catch (_) {}

    // 3. Fallback lyrics
    const fallback = 'गीत के बोल उपलब्ध नहीं हैं।\n\nअभी सुनो - शुद्ध भारतीय संगीत प्लेयर';
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

  Future<List<SongModel>> importYouTubePlaylist(String playlistUrl) async {
    try {
      final playlist = await _yt.playlists.get(playlistUrl);
      final List<SongModel> songs = [];
      await for (final video in _yt.playlists.getVideos(playlist.id)) {
        songs.add(
          SongModel(
            id: video.id.value,
            title: _cleanTitle(video.title),
            artist: video.author,
            album: playlist.title,
            duration: video.duration ?? const Duration(minutes: 3),
            thumbnailUrl: video.thumbnails.highResUrl.isNotEmpty
                ? video.thumbnails.highResUrl
                : video.thumbnails.standardResUrl,
          ),
        );
        if (songs.length >= 100) break;
      }
      return songs;
    } catch (_) {
      return [];
    }
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*?(\\bofficial|video|audio|lyric|song|4k|hd|remix).*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[.*?(\\bofficial|video|audio|lyric|song|4k|hd|remix).*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\|.*\$'), '')
        .trim();
  }

  void dispose() {
    _yt.close();
  }
}

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

  final JioSaavnAdapter _saavnAdapter = JioSaavnAdapter();
  final YoutubeExplode _yt = YoutubeExplode();
  final UnifiedAudioRepository _audioRepo = UnifiedAudioRepository();

  /// Search music catalog using JioSaavn CDN primary with YouTube Explode fallback
  Future<List<SongModel>> searchSongs(String query) async {
    final cleanQuery = query.trim().isEmpty ? 'Top Hindi Songs Bollywood' : query.trim();

    // 1. Primary fast search on JioSaavn
    try {
      final saavnResults = await _saavnAdapter.searchSongs(cleanQuery, limit: 30);
      if (saavnResults.isNotEmpty) {
        // Cache resolved stream URLs in repository
        for (final song in saavnResults) {
          if (song.streamUrl != null && song.streamUrl!.isNotEmpty) {
            _audioRepo.cacheStreamUrl(song.id, song.streamUrl!);
          }
        }
        return saavnResults;
      }
    } catch (_) {}

    // 2. Secondary fallback search on YouTube Explode
    try {
      final searchResults = await _yt.search.search(cleanQuery);
      final List<SongModel> songs = [];

      for (final video in searchResults) {
        if (video.duration != null && video.duration!.inMinutes > 15) {
          continue;
        }

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

      // Pre-warm cache for the first 2 songs in background
      if (songs.isNotEmpty) {
        preloadStreamUrl(songs[0].id);
        if (songs.length > 1) preloadStreamUrl(songs[1].id);
      }

      return songs;
    } catch (_) {
      return [];
    }
  }

  void preloadStreamUrl(String trackId) {
    if (_audioRepo.hasCachedStream(trackId)) return;
    _audioRepo.resolveAudioStreamUrl(trackId);
  }

  // Curated category feeds powered by JioSaavn CDN
  Future<List<SongModel>> getTrendingHindi() => _saavnAdapter.getTrendingHindi();
  Future<List<SongModel>> getBollywoodRomantic() => _saavnAdapter.getBollywoodRomantic();
  Future<List<SongModel>> getRetroClassics() => _saavnAdapter.getRetroClassics();
  Future<List<SongModel>> getPunjabiHits() => _saavnAdapter.getPunjabiHits();
  Future<List<SongModel>> getHindiLofi() => _saavnAdapter.getHindiLofi();
  Future<List<SongModel>> getBhaktiSongs() => _saavnAdapter.getBhaktiSongs();
  Future<List<SongModel>> getWorkoutSongs() => _saavnAdapter.getWorkoutSongs();
  Future<List<SongModel>> getPartySongs() => _saavnAdapter.getPartySongs();
  Future<List<SongModel>> getGhazals() => _saavnAdapter.getGhazals();

  Future<String?> getAudioStreamUrl(String trackId) async {
    return await _audioRepo.resolveAudioStreamUrl(trackId);
  }

  Future<List<SongModel>> importYouTubePlaylist(String urlOrId) async {
    try {
      final playlistId = _extractPlaylistId(urlOrId);
      if (playlistId.isEmpty) return [];

      final playlist = await _yt.playlists.get(playlistId);
      final List<SongModel> songs = [];

      await for (final video in _yt.playlists.getVideos(playlist.id)) {
        songs.add(SongModel(
          id: video.id.value,
          title: _cleanTitle(video.title),
          artist: video.author,
          album: playlist.title,
          duration: video.duration ?? const Duration(minutes: 3),
          thumbnailUrl: video.thumbnails.highResUrl.isNotEmpty
              ? video.thumbnails.highResUrl
              : video.thumbnails.standardResUrl,
        ));
        if (songs.length >= 50) break;
      }

      return songs;
    } catch (_) {
      return [];
    }
  }

  String _extractPlaylistId(String url) {
    if (!url.contains('http')) return url.trim();
    final uri = Uri.tryParse(url);
    if (uri != null && uri.queryParameters.containsKey('list')) {
      return uri.queryParameters['list']!;
    }
    return '';
  }

  /// Fetch crystal-clear synced/plain lyrics from LRCLIB
  Future<String> fetchLyrics(String title, String artist) async {
    try {
      final cleanT = _cleanTitle(title);
      final cleanA = artist
          .replaceAll(RegExp(r'(VEVO|Official|Topic|Music|Zee Music|T-Series)', caseSensitive: false), '')
          .split(',')
          .first
          .trim();

      final url = Uri.parse(
        'https://lrclib.net/api/get?track_name=${Uri.encodeComponent(cleanT)}&artist_name=${Uri.encodeComponent(cleanA)}',
      );
      final res = await http.get(
        url,
        headers: {'User-Agent': 'AbhiSuno/3.2.0 (palabhishek40629@gmail.com)'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['syncedLyrics'] != null && data['syncedLyrics'].toString().trim().isNotEmpty) {
          return data['syncedLyrics'].toString();
        }
        if (data['plainLyrics'] != null && data['plainLyrics'].toString().trim().isNotEmpty) {
          return data['plainLyrics'].toString();
        }
      }
    } catch (_) {}

    return 'गीत के बोल उपलब्ध नहीं हैं।\n\nअभी सुनो - शुद्ध संगीत प्लेयर';
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*?(\bofficial|video|audio|lyric|song|4k|hd|remix).*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[.*?(\bofficial|video|audio|lyric|song|4k|hd|remix).*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\|.*$'), '')
        .trim();
  }

  void dispose() {
    _yt.close();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song_model.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final YoutubeExplode _yt = YoutubeExplode();
  final Map<String, String> _streamCache = {};

  // Search songs with query - pure audio focus
  Future<List<SongModel>> searchSongs(String query) async {
    try {
      final searchResults = await _yt.search.search(
        query.trim().isEmpty ? 'Top Hindi Songs Bollywood' : query.trim(),
      );

      final List<SongModel> songs = [];
      for (final video in searchResults) {
        if (video.duration != null && video.duration!.inMinutes > 15) {
          continue;
        }

        songs.add(SongModel(
          id: video.id.value,
          title: _cleanTitle(video.title),
          artist: video.author,
          album: 'Single',
          duration: video.duration ?? const Duration(minutes: 3),
          thumbnailUrl: video.thumbnails.highResUrl.isNotEmpty
              ? video.thumbnails.highResUrl
              : video.thumbnails.standardResUrl,
        ));

        if (songs.length >= 25) break;
      }

      // Pre-warm cache for the first 2 songs in background
      if (songs.isNotEmpty) {
        preloadStreamUrl(songs[0].id);
        if (songs.length > 1) preloadStreamUrl(songs[1].id);
      }

      return songs;
    } catch (e) {
      return [];
    }
  }

  // Pre-load stream URL into cache for instantaneous playback
  void preloadStreamUrl(String videoId) {
    if (_streamCache.containsKey(videoId)) return;
    getAudioStreamUrl(videoId);
  }

  // Curated category playlists
  Future<List<SongModel>> getTrendingHindi() => searchSongs('Trending Hindi Songs Bollywood Official');
  Future<List<SongModel>> getBollywoodRomantic() => searchSongs('Best Bollywood Romantic Songs Arijit Singh');
  Future<List<SongModel>> getRetroClassics() => searchSongs('Old Hindi Retro Classics Kishore Kumar Lata Mangeshkar');
  Future<List<SongModel>> getPunjabiHits() => searchSongs('Top Punjabi Songs Sidhu Moosewala Diljit Dosanjh Karan Aujla');
  Future<List<SongModel>> getHindiLofi() => searchSongs('Hindi Lofi Chill Songs Bollywood Slowed Reverb');
  Future<List<SongModel>> getBhaktiSongs() => searchSongs('Best Hindi Bhakti Songs Bhajan Devotional');
  Future<List<SongModel>> getWorkoutSongs() => searchSongs('High Energy Gym Workout Bollywood Hindi Songs');
  Future<List<SongModel>> getPartySongs() => searchSongs('Bollywood Dance Party Mashup Songs');
  Future<List<SongModel>> getGhazals() => searchSongs('Best Jagjit Singh Mehdi Hassan Ghazals');

  // Ultra-Fast Stream Resolver with Cache & Parallel Race
  Future<String?> getAudioStreamUrl(String videoId) async {
    // 1. Check in-memory stream cache
    if (_streamCache.containsKey(videoId)) {
      return _streamCache[videoId];
    }

    // 2. Launch YouTube Explode and Piped in parallel race
    final ytExplodeFuture = _getYtExplodeStream(videoId);
    final fallbackFuture = getFallbackAudioStreamUrl(videoId);

    try {
      // Race: whichever finishes first with a valid URL wins
      final String resolvedUrl = await Future.any<String>([
        ytExplodeFuture.then((url) => (url != null && url.isNotEmpty) ? url : Future<String>.error('yt null')),
        fallbackFuture.then((url) => (url != null && url.isNotEmpty) ? url : Future<String>.error('fallback null')),
      ]).timeout(const Duration(seconds: 4));

      if (resolvedUrl.isNotEmpty) {
        _streamCache[videoId] = resolvedUrl;
        return resolvedUrl;
      }
    } catch (_) {
      // If race timed out or had errors, fallback to sequential check
      final fallback = await ytExplodeFuture ?? await fallbackFuture;
      if (fallback != null && fallback.isNotEmpty) {
        _streamCache[videoId] = fallback;
        return fallback;
      }
    }

    return null;
  }

  Future<String?> _getYtExplodeStream(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [
          YoutubeApiClient.ios,
          YoutubeApiClient.tv,
          YoutubeApiClient.androidVr,
          YoutubeApiClient.safari,
        ],
      );

      final audioStreams = manifest.audioOnly;
      if (audioStreams.isNotEmpty) {
        final bestAudio = audioStreams.withHighestBitrate();
        return bestAudio.url.toString();
      }
    } catch (_) {}
    return null;
  }

  // Fallback stream resolver using open-source Piped and Invidious APIs
  Future<String?> getFallbackAudioStreamUrl(String videoId) async {
    final pipedInstances = [
      'https://pipedapi.kavin.rocks',
      'https://api.piped.private.coffee',
      'https://piped-api.garudalinux.org',
    ];

    for (final host in pipedInstances) {
      try {
        final res = await http.get(
          Uri.parse('System.Management.Automation.Internal.Host.InternalHost/streams/'),
          headers: {'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X)'},
        ).timeout(const Duration(milliseconds: 2500));

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final audioList = data['audioStreams'] as List<dynamic>? ?? [];
          if (audioList.isNotEmpty) {
            final url = audioList[0]['url'] as String?;
            if (url != null && url.isNotEmpty) {
              return url;
            }
          }
        }
      } catch (_) {}
    }

    // Invidious Mirrors
    final invidiousMirrors = [
      'https://invidious.nerdvpn.de',
      'https://inv.nadeko.net',
      'https://invidious.f5.si',
    ];

    for (final host in invidiousMirrors) {
      try {
        final res = await http.get(
          Uri.parse('System.Management.Automation.Internal.Host.InternalHost/api/v1/videos/'),
          headers: {'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X)'},
        ).timeout(const Duration(milliseconds: 2500));

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final formats = data['adaptiveFormats'] as List<dynamic>? ?? [];
          final audioList = formats.where((f) => (f['type'] ?? '').toString().contains('audio')).toList();
          if (audioList.isNotEmpty) {
            final url = audioList[0]['url'] as String?;
            if (url != null && url.isNotEmpty) return url;
          }
        }
      } catch (_) {}
    }

    return null;
  }

  // Import public YouTube playlist by link or ID
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

  // Fetch real-time lyrics
  Future<String> fetchLyrics(String title, String artist) async {
    try {
      final cleanT = _cleanTitle(title);
      final cleanA = artist.replaceAll(RegExp(r'(VEVO|Official|Topic|Music)', caseSensitive: false), '').trim();

      final url = Uri.parse('https://lrclib.net/api/get?track_name=&artist_name=');
      final res = await http.get(url).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['syncedLyrics'] != null && data['syncedLyrics'].toString().isNotEmpty) {
          return data['syncedLyrics'];
        }
        if (data['plainLyrics'] != null && data['plainLyrics'].toString().isNotEmpty) {
          return data['plainLyrics'];
        }
      }
    } catch (_) {}

    return 'गीत के बोल उपलब्ध नहीं हैं।\n\n\n\n\nअभी सुनो - शुद्ध संगीत प्लेयर';
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*?(official|video|audio|lyric|song|4k|hd|remix).*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[.*?(official|video|audio|lyric|song|4k|hd|remix).*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\|.*$'), '')
        .trim();
  }

  void dispose() {
    _yt.close();
  }
}

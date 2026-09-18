import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song_model.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final YoutubeExplode _yt = YoutubeExplode();

  // Search songs with query - pure audio focus
  Future<List<SongModel>> searchSongs(String query) async {
    try {
      final searchResults = await _yt.search.search(
        query.trim().isEmpty ? 'Top Hindi Songs Bollywood' : '$query audio',
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
      return songs;
    } catch (e) {
      return [];
    }
  }

  // Curated Hindi categories
  Future<List<SongModel>> getTrendingHindi() => searchSongs('Trending Hindi Songs Bollywood Official');
  Future<List<SongModel>> getBollywoodRomantic() => searchSongs('Best Bollywood Romantic Songs Arijit Singh');
  Future<List<SongModel>> getRetroClassics() => searchSongs('Old Hindi Retro Classics Kishore Kumar Lata Mangeshkar');
  Future<List<SongModel>> getPunjabiHits() => searchSongs('Top Punjabi Songs Sidhu Moosewala Diljit Dosanjh Karan Aujla');
  Future<List<SongModel>> getHindiLofi() => searchSongs('Hindi Lofi Chill Songs Bollywood Slowed Reverb');

  // Direct high-quality pure audio stream resolver using iOS, Music & TV clients (bypasses bot blocks & 403)
  Future<String?> getAudioStreamUrl(String videoId) async {
    // Strategy 1: YouTube Explode with specialized clients
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

    // Strategy 2: Fallback to Piped & Invidious mirrors
    return await getFallbackAudioStreamUrl(videoId);
  }

  // Fallback stream resolver using open-source Piped and Invidious APIs
  Future<String?> getFallbackAudioStreamUrl(String videoId) async {
    // Piped APIs (fastest, unthrottled audio stream links)
    final pipedInstances = [
      'https://pipedapi.kavin.rocks',
      'https://api.piped.private.coffee',
      'https://piped-api.garudalinux.org',
      'https://pipedapi.tokhmi.xyz',
    ];

    for (final host in pipedInstances) {
      try {
        final res = await http.get(
          Uri.parse('$host/streams/$videoId'),
          headers: {'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X)'},
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final audioList = data['audioStreams'] as List<dynamic>? ?? [];
          if (audioList.isNotEmpty) {
            final url = audioList[0]['url'] as String?;
            if (url != null && url.isNotEmpty) return url;
          }
        }
      } catch (_) {}
    }

    // Invidious Mirrors
    final invidiousMirrors = [
      'https://invidious.nerdvpn.de',
      'https://inv.nadeko.net',
      'https://yt.chocolatemoo53.com',
      'https://invidious.f5.si',
    ];

    for (final host in invidiousMirrors) {
      try {
        final res = await http.get(
          Uri.parse('$host/api/v1/videos/$videoId'),
          headers: {'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X)'},
        ).timeout(const Duration(seconds: 4));

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

      final url = Uri.parse('https://lrclib.net/api/get?track_name=${Uri.encodeComponent(cleanT)}&artist_name=${Uri.encodeComponent(cleanA)}');
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

    return "Bol / Lyrics available nahi hain.\n\n$title\n$artist\n\nAbhi Suno Pure Audio Player";
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*?(official|video|audio|lyric|song|4k|hd).*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[.*?(official|video|audio|lyric|song|4k|hd).*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\|.*$'), '')
        .trim();
  }

  void dispose() {
    _yt.close();
  }
}

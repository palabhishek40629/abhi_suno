import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song_model.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final YoutubeExplode _yt = YoutubeExplode();

  // Search songs with query
  Future<List<SongModel>> searchSongs(String query) async {
    try {
      final searchResults = await _yt.search.search(
        query.trim().isEmpty ? 'Top Hindi Songs Bollywood' : '$query audio',
      );

      final List<SongModel> songs = [];
      for (final video in searchResults) {
        // Filter out very long videos (> 15 mins) to keep only songs
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
      // In case of error or offline, return empty list safely
      return [];
    }
  }

  // Curated Hindi categories
  Future<List<SongModel>> getTrendingHindi() async {
    return searchSongs('Trending Hindi Songs Bollywood Official');
  }

  Future<List<SongModel>> getBollywoodRomantic() async {
    return searchSongs('Best Bollywood Romantic Songs Arijit Singh');
  }

  Future<List<SongModel>> getRetroClassics() async {
    return searchSongs('Old Hindi Retro Classics Kishore Kumar Lata Mangeshkar');
  }

  Future<List<SongModel>> getPunjabiHits() async {
    return searchSongs('Top Punjabi Songs Sidhu Moosewala Diljit Dosanjh Karan Aujla');
  }

  Future<List<SongModel>> getHindiLofi() async {
    return searchSongs('Hindi Lofi Chill Songs Bollywood Slowed Reverb');
  }

  // Get direct high quality audio stream URL (128kbps - 160kbps opus/m4a)
  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isNotEmpty) {
        // Choose the highest bitrate audio stream
        final bestAudio = audioStreams.withHighestBitrate();
        return bestAudio.url.toString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Fetch real-time synchronized or plain lyrics using LrcLib API
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
    } catch (_) {
      // Fallback
    }

    return "Bol / Lyrics available nahi hain.\n\n$title\n$artist\n\nAbhi Suno par gaane ka anand lein!";
  }

  // Clean YouTube video title from clutter like "(Official Video)", "[Lyrical]"
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

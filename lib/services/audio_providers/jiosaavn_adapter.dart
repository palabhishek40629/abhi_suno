import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/song_model.dart';
import '../des_helper.dart';
import 'audio_provider_adapter.dart';

class JioSaavnAdapter implements AudioProviderAdapter {
  static final JioSaavnAdapter _instance = JioSaavnAdapter._internal();
  factory JioSaavnAdapter() => _instance;
  JioSaavnAdapter._internal();

  @override
  String get providerName => 'JioSaavn Direct Akamai CDN';

  static const String _baseUrl = 'https://www.jiosaavn.com/api.php';
  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'en-US,en;q=0.9,hi;q=0.8',
  };

  /// Search JioSaavn catalog and decrypt Akamai CDN stream URLs in memory
  Future<List<SongModel>> searchSongs(String query, {int limit = 30}) async {
    try {
      final cleanQuery = query.trim().isEmpty ? 'Top Hindi Songs Bollywood' : query.trim();
      final uri = Uri.parse(
        '$_baseUrl?__call=search.getResults&_format=json&_marker=0&cc=in&n=$limit&p=1&q=${Uri.encodeComponent(cleanQuery)}',
      );

      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return [];

      final List<SongModel> songs = [];
      for (final item in results) {
        if (item is! Map<String, dynamic>) continue;

        final songId = (item['id'] ?? '').toString();
        if (songId.isEmpty) continue;

        final title = _decodeHtmlEntities((item['song'] ?? item['title'] ?? 'Unknown').toString());
        final artist = _decodeHtmlEntities(
          (item['primary_artists'] ?? item['singers'] ?? item['music'] ?? 'Various Artists').toString(),
        );
        final album = _decodeHtmlEntities((item['album'] ?? 'Abhi Suno Music').toString());

        final durationSeconds = int.tryParse((item['duration'] ?? '180').toString()) ?? 180;
        final rawImg = (item['image'] ?? '').toString();
        final hdImage = rawImg.replaceAll('150x150', '500x500').replaceAll('http://', 'https://');

        // Pre-decrypt media stream URL directly for instant <0.1s startup
        String? directStreamUrl;
        final encUrl = (item['encrypted_media_url'] ?? '').toString();
        if (encUrl.isNotEmpty) {
          directStreamUrl = DesHelper.decryptJioSaavnUrl(encUrl, quality: '320kbps');
        }

        songs.add(
          SongModel(
            id: songId,
            title: title,
            artist: artist,
            album: album,
            duration: Duration(seconds: durationSeconds),
            thumbnailUrl: hdImage,
            streamUrl: directStreamUrl,
          ),
        );
      }

      return songs;
    } catch (_) {
      return [];
    }
  }

  /// Resolve audio stream URL by song PID
  @override
  Future<String?> resolveAudioStreamUrl(String trackId, {String quality = '320kbps'}) async {
    try {
      if (trackId.isEmpty) return null;

      final uri = Uri.parse(
        '$_baseUrl?__call=song.getDetails&cc=in&_marker=0&_format=json&pids=${Uri.encodeComponent(trackId)}',
      );

      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data is Map<String, dynamic> && data.containsKey(trackId)) {
        final songData = data[trackId] as Map<String, dynamic>?;
        final encUrl = (songData?['encrypted_media_url'] ?? '').toString();
        if (encUrl.isNotEmpty) {
          return DesHelper.decryptJioSaavnUrl(encUrl, quality: quality);
        }
      }
    } catch (_) {}
    return null;
  }

  // Curated category feeds
  Future<List<SongModel>> getTrendingHindi() => searchSongs('Trending Hindi Songs Bollywood Official');
  Future<List<SongModel>> getBollywoodRomantic() => searchSongs('Best Bollywood Romantic Songs Arijit Singh');
  Future<List<SongModel>> getRetroClassics() => searchSongs('Old Hindi Retro Classics Kishore Kumar Lata Mangeshkar');
  Future<List<SongModel>> getPunjabiHits() => searchSongs('Top Punjabi Hits Sidhu Moosewala Diljit Dosanjh Karan Aujla');
  Future<List<SongModel>> getHindiLofi() => searchSongs('Hindi Lofi Chill Songs Slowed Reverb');
  Future<List<SongModel>> getBhaktiSongs() => searchSongs('Best Hindi Bhakti Songs Bhajan Devotional Aarti');
  Future<List<SongModel>> getWorkoutSongs() => searchSongs('High Energy Gym Workout Bollywood Songs');
  Future<List<SongModel>> getPartySongs() => searchSongs('Bollywood Dance Party Mashup Songs');
  Future<List<SongModel>> getGhazals() => searchSongs('Best Jagjit Singh Mehdi Hassan Ghazals');

  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&copy;', '©')
        .trim();
  }
}

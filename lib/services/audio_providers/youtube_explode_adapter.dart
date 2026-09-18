import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'audio_provider_adapter.dart';

class YouTubeExplodeAdapter implements AudioProviderAdapter {
  final YoutubeExplode _yt;

  YouTubeExplodeAdapter([YoutubeExplode? yt]) : _yt = yt ?? YoutubeExplode();

  @override
  String get providerName => 'YouTubeExplode';

  @override
  Future<String?> resolveAudioStreamUrl(String trackId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(
        trackId,
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
}

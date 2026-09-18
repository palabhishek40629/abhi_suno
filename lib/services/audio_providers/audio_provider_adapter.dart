abstract class AudioProviderAdapter {
  String get providerName;
  Future<String?> resolveAudioStreamUrl(String trackId);
}

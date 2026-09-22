import 'dart:convert';
import 'package:http/http.dart' as http;
import 'audio_provider_adapter.dart';

class PipedInvidiousAdapter implements AudioProviderAdapter {
  @override
  String get providerName => 'PipedInvidiousMirror';

  final List<String> _pipedInstances = [
    'https://pipedapi.kavin.rocks',
    'https://api.piped.private.coffee',
    'https://piped-api.garudalinux.org',
  ];

  final List<String> _invidiousMirrors = [
    'https://invidious.nerdvpn.de',
    'https://inv.nadeko.net',
    'https://invidious.f5.si',
  ];

  @override
  Future<String?> resolveAudioStreamUrl(String trackId) async {
    // 1. Try Piped instances
    for (final host in _pipedInstances) {
      try {
        final res = await http.get(
          Uri.parse('$host/streams/$trackId'),
          headers: {'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X)'},
        ).timeout(const Duration(milliseconds: 2500));

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

    // 2. Try Invidious instances
    for (final host in _invidiousMirrors) {
      try {
        final res = await http.get(
          Uri.parse('$host/api/v1/videos/$trackId'),
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
}

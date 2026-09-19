import 'package:flutter/services.dart';

class ShareHelper {
  static const MethodChannel _channel = MethodChannel('com.abhishekpal.abhisuno/share');

  static Future<void> shareSong({
    required String title,
    required String artist,
    String? streamUrl,
    String? permaUrl,
  }) async {
    try {
      final playableLink = (permaUrl != null && permaUrl.trim().isNotEmpty)
          ? permaUrl.trim()
          : 'https://www.jiosaavn.com/search/${Uri.encodeComponent('$title $artist')}';

      final text = '🎵 Listen to "$title" by $artist on Abhi Suno!\n\n'
          '🔗 Song Link: $playableLink\n\n'
          'Experience pure high-speed lossless music streaming without ads.\n'
          '📲 Download Abhi Suno App: https://github.com/palabhishek40629/abhi_suno\n'
          'Created by Abhishek Pal';
      await _channel.invokeMethod('shareText', {
        'text': text,
        'title': 'Share Song - $title',
      });
    } catch (_) {}
  }

  static Future<void> shareCustomText({
    required String text,
    required String title,
  }) async {
    try {
      await _channel.invokeMethod('shareText', {
        'text': text,
        'title': title,
      });
    } catch (_) {}
  }
}


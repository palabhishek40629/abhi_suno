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
      final saavnLink = (permaUrl != null && permaUrl.trim().isNotEmpty)
          ? permaUrl.trim()
          : 'https://www.jiosaavn.com/search/${Uri.encodeComponent('$title $artist')}';
      final universalPlayLink = 'https://music.youtube.com/search?q=${Uri.encodeComponent('$title $artist')}';
      final deepLink = 'abhisuno://play?title=${Uri.encodeComponent(title)}&artist=${Uri.encodeComponent(artist)}';

      final text = '🎧 सुनिए "$title" by $artist on Abhi Suno!\n\n'
          '▶️ वेब पर तुरंत बजाएं (Instant Web Play):\n$universalPlayLink\n\n'
          '🔗 JioSaavn लिंक:\n$saavnLink\n\n'
          '🚀 Abhi Suno ऐप में खोलें (Deep Link):\n$deepLink\n\n'
          '✨ बिना किसी विज्ञापन और रुकावट के 320kbps लॉसलेस म्यूज़िक!\n'
          '📲 Abhi Suno ऐप डाउनलोड करें: https://github.com/palabhishek40629/abhi_suno/releases\n'
          'Dev: Abhishek Pal';

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


import 'package:flutter/services.dart';
import 'language_service.dart';

class ShareHelper {
  static const MethodChannel _channel = MethodChannel('com.abhishekpal.abhisuno/share');

  static Future<void> shareSong({
    required String title,
    required String artist,
    String? streamUrl,
    String? permaUrl,
  }) async {
    try {
      final isHindi = LanguageService().isHindi;
      final saavnLink = (permaUrl != null && permaUrl.trim().isNotEmpty)
          ? permaUrl.trim()
          : 'https://www.jiosaavn.com/search/${Uri.encodeComponent('$title $artist')}';
      final universalPlayLink = 'https://music.youtube.com/search?q=${Uri.encodeComponent('$title $artist')}';
      final deepLink = 'abhisuno://play?title=${Uri.encodeComponent(title)}&artist=${Uri.encodeComponent(artist)}';

      final text = isHindi
          ? '🎧 सुनिए "$title" by $artist on Abhi Suno!\n\n'
              '▶️ वेब पर तुरंत बजाएं (Instant Web Play):\n$universalPlayLink\n\n'
              '🔗 JioSaavn लिंक:\n$saavnLink\n\n'
              '🚀 Abhi Suno ऐप में खोलें (Deep Link):\n$deepLink\n\n'
              '✨ बिना किसी विज्ञापन और रुकावट के 320kbps लॉसलेस म्यूज़िक!\n'
              '📲 Abhi Suno ऐप डाउनलोड करें: https://github.com/palabhishek40629/abhi_suno/releases\n'
              'Dev: Abhishek Pal'
          : '🎧 Listen to "$title" by $artist on Abhi Suno!\n\n'
              '▶️ Instant Web Play:\n$universalPlayLink\n\n'
              '🔗 JioSaavn Link:\n$saavnLink\n\n'
              '🚀 Open in Abhi Suno App:\n$deepLink\n\n'
              '✨ 100% Ad-Free 320kbps Lossless Music Streaming & Downloads!\n'
              '📲 Download Abhi Suno: https://github.com/palabhishek40629/abhi_suno/releases\n'
              'Developer: Abhishek Pal';

      await _channel.invokeMethod('shareText', {
        'text': text,
        'title': isHindi ? 'गाना शेयर करें - $title' : 'Share Song - $title',
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

  static Future<void> shareApp() async {
    try {
      final isHindi = LanguageService().isHindi;
      final text = isHindi
          ? '🎧 Abhi Suno — 100% फ्री और बिना किसी विज्ञापन वाला म्यूज़िक ऐप!\n\n'
              '✨ 320kbps अल्ट्रा HD साउंड, अनलिमिटेड डाउनलोड्स, लिरिक्स और पार्टी रूम!\n'
              '📲 अभी डाउनलोड करें: https://github.com/palabhishek40629/abhi_suno/releases\n\n'
              'निर्माता: Abhishek Pal (Computer Science & Engineering Student)'
          : '🎧 Abhi Suno — 100% Free & Ad-Free Music App!\n\n'
              '✨ 320kbps Ultra HD Sound, Unlimited Downloads, Lyrics & Party Room!\n'
              '📲 Download now: https://github.com/palabhishek40629/abhi_suno/releases\n\n'
              'Developer: Abhishek Pal (Computer Science & Engineering Student)';

      await _channel.invokeMethod('shareText', {
        'text': text,
        'title': isHindi ? 'Abhi Suno ऐप शेयर करें' : 'Share Abhi Suno App',
      });
    } catch (_) {}
  }
}

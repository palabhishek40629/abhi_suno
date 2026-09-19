import 'package:flutter/services.dart';

class ShareHelper {
  static const MethodChannel _channel = MethodChannel('com.abhishekpal.abhisuno/share');

  static Future<void> shareSong({
    required String title,
    required String artist,
    String? streamUrl,
  }) async {
    try {
      final text = 'Listen to "$title" by $artist on Abhi Suno!\n\nExperience pure high-speed music streaming without ads.\nApp created by Abhishek Pal.';
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


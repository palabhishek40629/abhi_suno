import 'dart:convert';
import 'package:dart_des/dart_des.dart';

class DesHelper {
  static const String _jioSaavnKey = '38346591';

  static String? decryptJioSaavnUrl(String encryptedMediaUrl, {String quality = '320kbps'}) {
    try {
      final trimmed = encryptedMediaUrl.trim();
      if (trimmed.isEmpty) return null;

      final keyBytes = _jioSaavnKey.codeUnits;
      final encryptedBytes = base64.decode(trimmed);

      final des = DES(
        key: keyBytes,
        mode: DESMode.ECB,
        paddingType: DESPaddingType.PKCS5,
      );

      final decryptedBytes = des.decrypt(encryptedBytes);
      String decryptedString = utf8.decode(decryptedBytes, allowMalformed: true).trim();

      // Clean non-printable characters if any remain
      decryptedString = decryptedString.replaceAll(RegExp(r'[^\x20-\x7E]'), '');

      if (!decryptedString.startsWith('http')) {
        return null;
      }

      // Select target bitrate suffix
      final String targetSuffix;
      if (quality.contains('96')) {
        targetSuffix = '_96.mp4';
      } else if (quality.contains('160')) {
        targetSuffix = '_160.mp4';
      } else {
        targetSuffix = '_320.mp4';
      }

      if (decryptedString.contains('_96.mp4') && targetSuffix != '_96.mp4') {
        decryptedString = decryptedString.replaceAll('_96.mp4', targetSuffix);
      } else if (decryptedString.contains('_160.mp4') && targetSuffix != '_160.mp4') {
        decryptedString = decryptedString.replaceAll('_160.mp4', targetSuffix);
      } else if (decryptedString.contains('_320.mp4') && targetSuffix != '_320.mp4') {
        decryptedString = decryptedString.replaceAll('_320.mp4', targetSuffix);
      }

      if (decryptedString.startsWith('http://')) {
        decryptedString = decryptedString.replaceFirst('http://', 'https://');
      }

      return decryptedString;
    } catch (_) {
      return null;
    }
  }
}

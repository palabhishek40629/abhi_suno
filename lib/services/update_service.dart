import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String apkDownloadUrl;
  final int assetSize;
  final bool hasUpdate;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.assetSize,
    required this.hasUpdate,
  });
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const String currentVersion = '3.1.0';
  static const String _repoOwner = 'palabhishek40629';
  static const String _repoName = 'abhi_suno';

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final url = Uri.parse('https://api.github.com/repos///releases/latest');
      final res = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'AbhiSuno-Android-App',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final tagName = (data['tag_name'] ?? '').toString();
        final releaseNotes = (data['body'] ?? 'Performance improvements and bug fixes.').toString();
        final assets = data['assets'] as List<dynamic>? ?? [];

        String apkUrl = '';
        int apkSize = 0;
        for (final asset in assets) {
          final name = (asset['name'] ?? '').toString();
          if (name.endsWith('.apk')) {
            apkUrl = (asset['browser_download_url'] ?? '').toString();
            apkSize = (asset['size'] ?? 0) as int;
            break;
          }
        }

        final cleanLatest = tagName.replaceAll('v', '').trim();
        final hasUpdate = _isNewerVersion(cleanLatest, currentVersion);

        return UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: cleanLatest.isEmpty ? currentVersion : cleanLatest,
          releaseNotes: releaseNotes,
          apkDownloadUrl: apkUrl,
          assetSize: apkSize,
          hasUpdate: hasUpdate,
        );
      }
    } catch (_) {}

    return null;
  }

  bool _isNewerVersion(String latest, String current) {
    if (latest.isEmpty) return false;
    try {
      final lParts = latest.split('-')[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final cParts = current.split('-')[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final l = i < lParts.length ? lParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }
}

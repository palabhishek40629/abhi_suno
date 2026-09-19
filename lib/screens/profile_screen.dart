import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/download_service.dart';
import '../services/language_service.dart';
import '../services/music_service.dart';
import '../services/playlist_service.dart';
import '../services/theme_service.dart';
import '../services/update_service.dart';
import '../utils/app_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();
  final DownloadService _downloadService = DownloadService();
  final MusicService _musicService = MusicService();
  final PlaylistService _playlistService = PlaylistService();
  final UpdateService _updateService = UpdateService();

  static const MethodChannel _nativeChannel = MethodChannel('com.abhishekpal.abhisuno/native');

  String? _profileImagePath;
  String _installedVersion = AppConstants.appVersion;
  String _audioQuality = '320kbps';
  double _tempCacheMB = 0.0;
  double _permStorageMB = 0.0;
  double _deviceTotalGB = 0.0;
  double _deviceFreeGB = 0.0;

  bool _isCheckingUpdate = false;
  UpdateInfo? _updateInfo;
  String _updateStatusMessage = '';

  final TextEditingController _urlController = TextEditingController();
  bool _isProcessingUrl = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('user_custom_profile_image');
    final quality = prefs.getString('audio_quality_pref') ?? '320kbps';
    final tempSize = await _downloadService.getTemporaryCacheSizeInMB();
    final permSize = await _downloadService.getPermanentStorageSizeInMB();
    final version = await _updateService.getInstalledVersion();

    // Load device storage from native StatFs
    try {
      final Map<dynamic, dynamic>? storageMap =
          await _nativeChannel.invokeMethod<Map<dynamic, dynamic>>('getStorageInfo');
      if (storageMap != null) {
        final totalB = (storageMap['totalBytes'] as num?)?.toDouble() ?? 0.0;
        final freeB = (storageMap['freeBytes'] as num?)?.toDouble() ?? 0.0;
        _deviceTotalGB = totalB / (1024 * 1024 * 1024);
        _deviceFreeGB = freeB / (1024 * 1024 * 1024);
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _profileImagePath = savedPath;
        _audioQuality = quality;
        _tempCacheMB = tempSize;
        _permStorageMB = permSize;
        _installedVersion = version;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final String? path = await _nativeChannel.invokeMethod<String>('pickProfileImage');
      if (path != null && path.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_custom_profile_image', path);
        if (mounted) setState(() => _profileImagePath = path);
      }
    } catch (_) {}
  }

  Future<void> _saveAudioQuality(String quality) async {
    setState(() => _audioQuality = quality);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audio_quality_pref', quality);
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateStatusMessage = _lang.t('checking_updates');
    });

    final info = await _updateService.checkForUpdate();
    if (mounted) {
      setState(() {
        _isCheckingUpdate = false;
        _updateInfo = info;
        if (info == null) {
          _updateStatusMessage = _lang.isHindi
              ? 'अपडेट जांच विफल रही। इंटरनेट कनेक्शन जांचें।'
              : 'Failed to check updates. Check internet connection.';
        } else if (info.hasUpdate) {
          _updateStatusMessage = '${_lang.t('update_available')} (v${info.latestVersion})';
        } else {
          _updateStatusMessage = _lang.t('up_to_date');
        }
      });
    }
  }

  void _downloadAndInstallApk() {
    if (_updateInfo == null || _updateInfo!.apkDownloadUrl.isEmpty) return;

    final apkUrl = _updateInfo!.apkDownloadUrl;
    final cancelToken = CancelToken();
    final progressNotifier = ValueNotifier<Map<String, dynamic>>({
      'received': 0,
      'total': _updateInfo!.assetSize > 0 ? _updateInfo!.assetSize : 1,
      'percent': 0.0,
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return ValueListenableBuilder<Map<String, dynamic>>(
          valueListenable: progressNotifier,
          builder: (context, data, _) {
            final received = data['received'] as int;
            final total = data['total'] as int;
            final percent = (data['percent'] as double).clamp(0.0, 1.0);

            return AlertDialog(
              backgroundColor: const Color(0xFF161616),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.system_update_rounded, color: Color(0xFF00E676)),
                  const SizedBox(width: 8),
                  Text(
                    _lang.isHindi ? 'अपडेट डाउनलोड हो रहा है' : 'Downloading Update',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent > 0 ? percent : null,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(received / (1024 * 1024)).toStringAsFixed(1)} MB / ${(total / (1024 * 1024)).toStringAsFixed(1)} MB',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${(percent * 100).toInt()}%',
                        style: const TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    cancelToken.cancel();
                    Navigator.of(dialogCtx).pop();
                  },
                  child: Text(
                    _lang.t('cancel'),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    _updateService.downloadUpdateApk(
      apkUrl,
      cancelToken: cancelToken,
      onProgress: (received, total, percent) {
        progressNotifier.value = {
          'received': received,
          'total': total > 0 ? total : _updateInfo!.assetSize,
          'percent': percent,
        };
      },
    ).then((apkPath) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (apkPath != null && apkPath.isNotEmpty) {
        _updateService.installApk(apkPath);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_lang.isHindi ? 'डाउनलोड विफल रहा' : 'Download failed'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    });
  }

  Future<void> _shareApp() async {
    try {
      const shareChannel = MethodChannel('com.abhishekpal.abhisuno/share');
      await shareChannel.invokeMethod('shareText', {
        'text': _lang.t('share_app_text'),
        'title': _lang.t('share_app'),
      });
    } catch (_) {}
  }

  Future<void> _clearTemporaryCache() async {
    await _downloadService.clearTemporaryCache();
    await _loadProfileData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lang.t('cache_cleared')),
          backgroundColor: const Color(0xFF05D9E8),
        ),
      );
    }
  }

  Future<void> _confirmDeleteAllDownloads() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _lang.t('delete_all_downloads'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          _lang.t('delete_all_warning'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_lang.t('cancel'), style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_lang.t('delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final songs = List.from(_downloadService.downloadedSongs);
      for (final s in songs) {
        await _downloadService.deleteDownloadedSong(s.id);
      }
      await _loadProfileData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_lang.isHindi ? 'सभी डाउनलोड हटा दिए गए' : 'All downloads deleted'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _lang.t('language_title'),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: LanguageService.supportedLanguages.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, i) {
                    final lang = LanguageService.supportedLanguages[i];
                    final isSelected = _lang.currentCode == lang.code;

                    return ListTile(
                      title: Text(lang.nativeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(lang.englishName, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676))
                          : null,
                      onTap: () {
                        _lang.setLanguageCode(lang.code);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleMediaUrlAction(bool isAudio) async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isProcessingUrl = true);
    try {
      final songs = await _musicService.importYouTubePlaylist(url);
      if (songs.isNotEmpty) {
        if (isAudio) {
          final pName = songs.first.album.isNotEmpty ? songs.first.album : 'Imported URL Audio';
          await _playlistService.createPlaylist(pName);
          for (final s in songs) {
            await _playlistService.addSongToPlaylist(pName, s);
          }
          if (mounted) {
            _urlController.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${songs.length} ' + (_lang.isHindi ? 'गाने सफलतापूर्वक जोड़े गए!' : 'songs imported successfully!')),
                backgroundColor: const Color(0xFF00E676),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_lang.isHindi ? 'वीडियो डाउनलोड शुरू किया गया' : 'Video download initiated'),
                backgroundColor: const Color(0xFF00E676),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_lang.isHindi ? 'URL से गाने नहीं मिले' : 'No media found for URL'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_lang.isHindi ? 'URL प्रोसेस करने में त्रुटि' : 'Error processing URL'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingUrl = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_theme, _lang]),
      builder: (context, _) {
        final textColor = _theme.textColor;
        final subtextColor = _theme.subtextColor;
        final cardColor = _theme.cardBg;
        final primaryColor = _theme.primaryColor;

        return Scaffold(
          backgroundColor: _theme.scaffoldBg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _lang.t('profile'),
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          body: Container(
            decoration: _theme.backgroundDecoration,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                // SECTION 1: Profile Avatar & Name
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.35),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _profileImagePath != null && File(_profileImagePath!).existsSync()
                              ? Image.file(File(_profileImagePath!), fit: BoxFit.cover)
                              : Image.asset(AppConstants.logoAsset, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    AppConstants.developerName,
                    style: TextStyle(color: textColor, fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Text(
                    AppConstants.developerRole,
                    style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION 2: About Application (with Neon Headphone Logo)
                _buildSectionHeader(_lang.t('about_developer'), textColor),
                const SizedBox(height: 8),
                _buildCard(
                  cardColor: cardColor,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          AppConstants.logoAsset,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.appName,
                              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Version $_installedVersion',
                              style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _lang.t('developer_bio'),
                              style: TextStyle(color: subtextColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 3: Language Selection (21+ Languages)
                _buildSectionHeader(_lang.t('language_title'), textColor),
                const SizedBox(height: 8),
                _buildCard(
                  cardColor: cardColor,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.translate_rounded, color: Color(0xFF00E676)),
                    title: Text(_lang.isHindi ? 'भाषा चुनें' : 'Select Language', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      LanguageService.supportedLanguages.firstWhere((l) => l.code == _lang.currentCode, orElse: () => LanguageService.supportedLanguages.first).nativeName,
                      style: TextStyle(color: primaryColor, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                    onTap: _showLanguagePicker,
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 4: GitHub In-App Updates
                _buildSectionHeader(_lang.t('github_updates_title'), textColor),
                const SizedBox(height: 8),
                _buildCard(
                  cardColor: cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_lang.t('current_version'), style: TextStyle(color: subtextColor, fontSize: 11)),
                              Text('v$_installedVersion', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (_updateInfo != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_lang.t('latest_version'), style: TextStyle(color: subtextColor, fontSize: 11)),
                                Text('v${_updateInfo!.latestVersion}', style: TextStyle(color: _updateInfo!.hasUpdate ? const Color(0xFF00E676) : primaryColor, fontSize: 15, fontWeight: FontWeight.bold)),
                              ],
                            ),
                        ],
                      ),
                      if (_updateStatusMessage.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_updateStatusMessage, style: TextStyle(color: _updateInfo?.hasUpdate == true ? const Color(0xFF00E676) : subtextColor, fontSize: 12)),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _updateInfo?.hasUpdate == true ? const Color(0xFF00E676) : primaryColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isCheckingUpdate
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : Icon(_updateInfo?.hasUpdate == true ? Icons.system_update_rounded : Icons.sync_rounded, size: 18),
                          label: Text(
                            _isCheckingUpdate ? _lang.t('checking_updates') : (_updateInfo?.hasUpdate == true ? _lang.t('update_now') : _lang.t('check_updates')),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: _isCheckingUpdate
                              ? null
                              : (_updateInfo?.hasUpdate == true ? _downloadAndInstallApk : _checkForUpdates),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 5: Theme Selection (Default, Dark, Light, Transparent)
                _buildSectionHeader(_lang.t('theme_title'), textColor),
                const SizedBox(height: 8),
                _buildCard(
                  cardColor: cardColor,
                  child: Column(
                    children: [
                      RadioListTile<AppThemeMode>(
                        value: AppThemeMode.dark,
                        groupValue: _theme.currentTheme,
                        activeColor: primaryColor,
                        title: Text(_lang.t('theme_dark'), style: TextStyle(color: textColor, fontSize: 13)),
                        onChanged: (val) => _theme.setTheme(val!),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      RadioListTile<AppThemeMode>(
                        value: AppThemeMode.light,
                        groupValue: _theme.currentTheme,
                        activeColor: primaryColor,
                        title: Text(_lang.t('theme_light'), style: TextStyle(color: textColor, fontSize: 13)),
                        onChanged: (val) => _theme.setTheme(val!),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      RadioListTile<AppThemeMode>(
                        value: AppThemeMode.transparent,
                        groupValue: _theme.currentTheme,
                        activeColor: primaryColor,
                        title: Text(_lang.t('theme_transparent'), style: TextStyle(color: textColor, fontSize: 13)),
                        onChanged: (val) => _theme.setTheme(val!),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 6: Download Quality Settings
                _buildSectionHeader(_lang.t('audio_quality_title'), textColor),
                const SizedBox(height: 8),
                _buildCard(
                  cardColor: cardColor,
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: '320kbps',
                        groupValue: _audioQuality,
                        activeColor: primaryColor,
                        title: Text(_lang.t('quality_high'), style: TextStyle(color: textColor, fontSize: 13)),
                        onChanged: (val) => _saveAudioQuality(val!),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      RadioListTile<String>(
                        value: '160kbps',
                        groupValue: _audioQuality,
                        activeColor: primaryColor,
                        title: Text(_lang.t('quality_medium'), style: TextStyle(color: textColor, fontSize: 13)),
                        onChanged: (val) => _saveAudioQuality(val!),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      RadioListTile<String>(
                        value: '96kbps',
                        groupValue: _audioQuality,
                        activeColor: primaryColor,
                        title: Text(_lang.t('quality_low'), style: TextStyle(color: textColor, fontSize: 13)),
                        onChanged: (val) => _saveAudioQuality(val!),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 7: Playlist URL Import / Download (Audio & Video)
                _buildSectionHeader(_lang.t('youtube_sync_title'), textColor),
                const SizedBox(height: 8),
                _buildCard(
                  cardColor: cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_lang.t('youtube_sync_desc'), style: TextStyle(color: subtextColor, fontSize: 11)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _urlController,
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: _lang.t('yt_link_hint'),
                          hintStyle: TextStyle(color: subtextColor.withOpacity(0.5), fontSize: 12),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
                              onPressed: _isProcessingUrl ? null : () => _handleMediaUrlAction(true),
                              child: Text(_lang.t('download_audio'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(side: BorderSide(color: primaryColor), foregroundColor: primaryColor),
                              onPressed: _isProcessingUrl ? null : () => _handleMediaUrlAction(false),
                              child: Text(_lang.t('download_video'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 8: Storage Management
                _buildSectionHeader(_lang.t('cache_clear_title'), textColor),
                const SizedBox(height: 8),
                _buildCard(
                  cardColor: cardColor,
                  child: Column(
                    children: [
                      if (_deviceTotalGB > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_lang.t('total_storage'), style: TextStyle(color: subtextColor, fontSize: 12)),
                            Text('${_deviceTotalGB.toStringAsFixed(1)} GB', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_lang.t('available_storage'), style: TextStyle(color: subtextColor, fontSize: 12)),
                            Text('${_deviceFreeGB.toStringAsFixed(1)} GB', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_lang.t('temporary_cache'), style: TextStyle(color: subtextColor, fontSize: 12)),
                          Text('${_tempCacheMB.toStringAsFixed(1)} MB', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_lang.t('permanent_downloads'), style: TextStyle(color: subtextColor, fontSize: 12)),
                          Text('${_permStorageMB.toStringAsFixed(1)} MB', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                              onPressed: _clearTemporaryCache,
                              child: Text(_lang.t('clear_cache_btn'), style: TextStyle(color: textColor, fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: _confirmDeleteAllDownloads,
                              child: Text(_lang.t('delete_all_downloads'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 9: Share Application
                _buildSectionHeader(_lang.t('share_app'), textColor),
                const SizedBox(height: 8),
                _buildCard(
                  cardColor: cardColor,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.share_rounded, color: Color(0xFF05D9E8)),
                    title: Text(_lang.t('share_app'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    subtitle: Text(_lang.t('share_app_desc'), style: TextStyle(color: subtextColor, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                    onTap: _shareApp,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.3),
    );
  }

  Widget _buildCard({required Color cardColor, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

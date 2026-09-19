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
import '../services/user_service.dart';
import '../utils/app_constants.dart';
import '../widgets/equalizer_sheet.dart';
import '../widgets/tactile_3d_wrapper.dart';
import '../widgets/party_room_card.dart';
import '../services/audio_handler.dart';
import 'about_screen.dart';
import 'language_screen.dart';
import 'edit_profile_screen.dart';
import 'app_settings_screen.dart';
import 'theme_selection_screen.dart';
import 'download_settings_screen.dart';
import 'storage_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AbhiAudioHandler? audioHandler;

  const ProfileScreen({Key? key, this.audioHandler}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();
  final UserService _user = UserService();
  final DownloadService _downloadService = DownloadService();
  final MusicService _musicService = MusicService();
  final PlaylistService _playlistService = PlaylistService();
  final UpdateService _updateService = UpdateService();

  static const MethodChannel _nativeChannel = MethodChannel('com.abhishekpal.abhisuno/native');

  String? _profileImagePath;
  String _userName = 'Abhishek Pal';
  String _installedVersion = AppConstants.appVersion;
  String _audioQuality = '320kbps';
  String _thumbQuality = 'low';
  bool _djCrossfade = true;
  int _crossfadeSeconds = 4;
  bool _replayGain = true;
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
    _user.init();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('user_custom_profile_image');
    final savedName = prefs.getString('user_custom_profile_name') ?? 'Abhishek Pal';
    final quality = prefs.getString('audio_download_quality_pref') ?? prefs.getString('audio_quality_pref') ?? '320kbps';
    final thumbQ = prefs.getString('thumbnail_download_quality_pref') ?? 'low';
    final crossfade = prefs.getBool('audio_crossfade_enabled') ?? true;
    final crossSecs = prefs.getInt('audio_crossfade_seconds') ?? 4;
    final rg = prefs.getBool('audio_loudness_normalizer') ?? true;

    final tempSize = await _downloadService.getTemporaryCacheSizeInMB();
    final permSize = await _downloadService.getPermanentStorageSizeInMB();
    final version = await _updateService.getInstalledVersion();

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
        _userName = savedName;
        _audioQuality = quality;
        _thumbQuality = thumbQ;
        _djCrossfade = crossfade;
        _crossfadeSeconds = crossSecs;
        _replayGain = rg;
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

  Future<void> _showEditNameDialog() async {
    final controller = TextEditingController(text: _userName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181818),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.edit_rounded, color: Color(0xFF00E5FF), size: 22),
            const SizedBox(width: 8),
            Text(
              _lang.isHindi ? 'अपना नाम बदलें' : 'Edit Your Name',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: _lang.isHindi ? 'नाम दर्ज करें' : 'Enter name',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_lang.t('cancel'), style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(
              _lang.isHindi ? 'सहेजें' : 'Save',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_custom_profile_name', newName);
      if (mounted) setState(() => _userName = newName);
    }
  }

  Future<void> _saveAudioQuality(String quality) async {
    setState(() => _audioQuality = quality);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audio_quality_pref', quality);
    await prefs.setString('audio_download_quality_pref', quality);
  }

  Future<void> _saveThumbnailQuality(String quality) async {
    setState(() => _thumbQuality = quality);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('thumbnail_download_quality_pref', quality);
  }

  Future<void> _toggleCrossfade(bool val) async {
    setState(() => _djCrossfade = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_crossfade_enabled', val);
    widget.audioHandler?.setCrossfade(val, _crossfadeSeconds);
  }

  Future<void> _setCrossfadeSeconds(int secs) async {
    setState(() => _crossfadeSeconds = secs);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('audio_crossfade_seconds', secs);
    widget.audioHandler?.setCrossfade(_djCrossfade, secs);
  }

  Future<void> _toggleReplayGain(bool val) async {
    setState(() => _replayGain = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_loudness_normalizer', val);
    widget.audioHandler?.setLoudnessNormalizer(val);
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00E676),
              duration: const Duration(seconds: 3),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lang.isHindi
                          ? 'आपका ऐप पहले से ही नवीनतम वर्ज़न (v' + _installedVersion + ') पर है! कोई नया अपडेट उपलब्ध नहीं है।'
                          : 'Your app is already on the latest version (v' + _installedVersion + ')!',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_theme, _lang, _user]),
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  child: Tactile3DWrapper(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      );
                    },
                    scaleElevation: 1.08,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFFFF2A6D)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            _lang.isHindi ? 'एडिट प्रोफ़ाइल' : 'Edit Profile',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Container(
            decoration: _theme.backgroundDecoration,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [

                // SECTION 1: Profile Avatar (clean without pencil icon)
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      );
                    },
                    child: Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFFFF2A6D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.35),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3.5),
                      child: ClipOval(
                        child: _user.profileImagePath != null && File(_user.profileImagePath!).existsSync()
                            ? Image.file(File(_user.profileImagePath!), fit: BoxFit.cover)
                            : Image.asset(AppConstants.logoAsset, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // User Name (clean without pencil icon)
                Center(
                  child: Text(
                    _user.userName,
                    style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                // User Bio / Tagline (clean without pencil icon)
                Center(
                  child: Text(
                    _user.userBio,
                    style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),

                // ================================================================
                // EXPANDABLE ACCORDION SECTION 1: 🎧 Audio & DJ Engine
                // ================================================================
                _buildAccordionCard(
                  title: _lang.isHindi ? 'ऑडियो एवं डीजे इंजन' : 'Audio & DJ Engine',
                  subtitle: _lang.isHindi ? 'क्रॉसफ़ेड, वॉल्यूम नॉर्मलाइज़र और इक्वलाइज़र' : 'Crossfade, volume normalizer & EQ',
                  icon: Icons.graphic_eq_rounded,
                  accentColor: const Color(0xFF00E5FF),
                  children: [
                    // DJ Crossfade Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.shuffle_rounded, color: Color(0xFF00E5FF)),
                      title: Text(
                        _lang.isHindi ? 'स्मार्ट डीजे क्रॉसफ़ेड' : 'Smart DJ Crossfade',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        _lang.isHindi ? 'गानों के बीच बिना सन्नाटा स्मूथ मिक्सिंग' : 'Seamless 0ms silence mixing between songs',
                        style: TextStyle(color: subtextColor, fontSize: 12),
                      ),
                      value: _djCrossfade,
                      activeColor: const Color(0xFF00E5FF),
                      onChanged: _toggleCrossfade,
                    ),
                    if (_djCrossfade) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            Text(
                              _lang.isHindi ? 'क्रॉसफ़ेड अवधि:' : 'Duration:',
                              style: TextStyle(color: subtextColor, fontSize: 12),
                            ),
                            const Spacer(),
                            Text(
                              '$_crossfadeSeconds s',
                              style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Slider(
                        value: _crossfadeSeconds.toDouble(),
                        min: 2,
                        max: 8,
                        divisions: 6,
                        activeColor: const Color(0xFF00E5FF),
                        inactiveColor: Colors.white12,
                        onChanged: (val) => _setCrossfadeSeconds(val.toInt()),
                      ),
                    ],
                    const Divider(color: Colors.white10),
                    // Volume Normalization Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.volume_up_rounded, color: Color(0xFFFF2A6D)),
                      title: Text(
                        _lang.isHindi ? 'वॉल्यूम नॉर्मलाइज़ेशन (ReplayGain)' : 'Volume Normalization (ReplayGain)',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        _lang.isHindi ? 'पुराने 70s-90s और नए गानों की एक समान आवाज़' : 'Balances loudness between retro and modern tracks',
                        style: TextStyle(color: subtextColor, fontSize: 12),
                      ),
                      value: _replayGain,
                      activeColor: const Color(0xFFFF2A6D),
                      onChanged: _toggleReplayGain,
                    ),
                    const Divider(color: Colors.white10),
                    // Streaming Quality Selector
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.high_quality_rounded, color: Colors.amber),
                      title: Text(
                        _lang.isHindi ? 'स्ट्रीमिंग एवं ऑडियो गुणवत्ता' : 'Audio Streaming Quality',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        '$_audioQuality (FLAC/AAC)',
                        style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.tune_rounded, color: Colors.amber),
                        color: const Color(0xFF1F1F1F),
                        onSelected: _saveAudioQuality,
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: '320kbps', child: Text('320 kbps (Ultra Studio HD)', style: TextStyle(color: Colors.white))),
                          const PopupMenuItem(value: '160kbps', child: Text('160 kbps (High Balanced)', style: TextStyle(color: Colors.white))),
                          const PopupMenuItem(value: '96kbps', child: Text('96 kbps (Data Saver)', style: TextStyle(color: Colors.white))),
                        ],
                      ),
                    ),
                    if (widget.audioHandler != null) ...[
                      const Divider(color: Colors.white10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF00E5FF)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.equalizer_rounded, color: Color(0xFF00E5FF)),
                          label: Text(
                            _lang.isHindi ? '10-बैंड इक्वलाइज़र और 3D सराउंड खोलें' : 'Open 10-Band Equalizer & 3D Surround',
                            style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (_) => EqualizerSheet(audioHandler: widget.audioHandler!),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // ================================================================
                // EXPANDABLE SECTION: 👥 पार्टी रूम ("सुनो साथ में" / Listen Together)
                // ================================================================
                PartyRoomCard(audioHandler: widget.audioHandler),

                const SizedBox(height: 18),

                // ================================================================
                // MASTER SECTION: ⚙️ ऐप सेटिंग्स (App Settings Master Section)
                // ================================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00E5FF).withOpacity(0.15),
                        ),
                        child: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF00E5FF), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _lang.isHindi ? 'ऐप सेटिंग्स (Settings)' : 'App Settings',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Master Clickable Card: ⚙️ सभी सेटिंग्स खोलें (Open Full App Settings)
                Tactile3DWrapper(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
                    );
                  },
                  scaleElevation: 1.05,
                  glowColor: const Color(0xFF00E5FF),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00E5FF).withOpacity(0.15),
                          const Color(0xFFFF2A6D).withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4), width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
                            ),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Colors.black, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _lang.isHindi ? 'सभी ऐप सेटिंग्स खोलें' : 'Open All App Settings',
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _lang.isHindi ? 'थीम, भाषा, डाउनलोड, स्टोरेज एवं अन्य' : 'Theme, language, storage, downloads & more',
                                style: TextStyle(color: subtextColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF00E5FF), size: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 1. 🎨 App Theme (Opens in dedicated page)
                Tactile3DWrapper(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ThemeSelectionScreen()),
                    );
                  },
                  scaleElevation: 1.04,
                  glowColor: const Color(0xFF00E5FF),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00E5FF).withOpacity(0.15),
                          ),
                          child: const Icon(Icons.palette_rounded, color: Color(0xFF00E5FF), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _lang.isHindi ? 'ऐप थीम (App Theme)' : 'App Theme',
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                _getThemeName(_theme.currentMode),
                                style: TextStyle(color: subtextColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 2. 🌐 App Language (Opens in dedicated page)
                Tactile3DWrapper(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                    );
                  },
                  scaleElevation: 1.04,
                  glowColor: const Color(0xFF00E676),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00E676).withOpacity(0.15),
                          ),
                          child: const Icon(Icons.translate_rounded, color: Color(0xFF00E676), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _lang.isHindi ? 'ऐप की भाषा (Language)' : 'App Language',
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                _lang.currentLanguageName,
                                style: TextStyle(color: subtextColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 3. 📥 Download Settings (Opens in dedicated page)
                Tactile3DWrapper(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DownloadSettingsScreen()),
                    );
                  },
                  scaleElevation: 1.04,
                  glowColor: const Color(0xFFFF2A6D),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF2A6D).withOpacity(0.15),
                          ),
                          child: const Icon(Icons.download_rounded, color: Color(0xFFFF2A6D), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _lang.isHindi ? 'डाउनलोड सेटिंग्स (Downloads)' : 'Download Settings',
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '$_audioQuality • $_thumbQuality quality',
                                style: TextStyle(color: subtextColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 4. 💾 Storage Management (Opens in dedicated page)
                Tactile3DWrapper(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StorageManagementScreen()),
                    );
                  },
                  scaleElevation: 1.04,
                  glowColor: const Color(0xFFFFB300),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFB300).withOpacity(0.15),
                          ),
                          child: const Icon(Icons.storage_rounded, color: Color(0xFFFFB300), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _lang.isHindi ? 'स्टोरेज प्रबंधन (Storage)' : 'Storage Management',
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '${_tempCacheMB.toStringAsFixed(1)} MB cache • ${_permStorageMB.toStringAsFixed(1)} MB songs',
                                style: TextStyle(color: subtextColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 7. ℹ️ About & Developer
                Tactile3DWrapper(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                  scaleElevation: 1.05,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF007F).withOpacity(0.15),
                          ),
                          child: const Icon(Icons.info_outline_rounded, color: Color(0xFFFF007F), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _lang.t('about_developer'),
                                style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${AppConstants.appName} v$_installedVersion by ${AppConstants.developerName}',
                                style: TextStyle(color: subtextColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFF007F), size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  String _getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return _lang.isHindi ? 'लाइट थीम (Light)' : 'Light';
      case AppThemeMode.dark:
        return _lang.isHindi ? 'डार्क थीम (Dark)' : 'Dark';
      case AppThemeMode.transparent:
        return _lang.isHindi ? 'ट्रांसपेरेंट ग्लास (Transparent)' : 'Transparent';
      case AppThemeMode.defaultMode:
      default:
        return _lang.isHindi ? 'डिफ़ॉल्ट साइबरपंक (Default)' : 'Default (Cyberpunk)';
    }
  }

  Widget _buildThemeOptionChip({
    required AppThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _theme.currentMode == mode;
    return Tactile3DWrapper(
      onTap: () => _theme.setTheme(mode),
      scaleElevation: 1.04,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: (MediaQuery.of(context).size.width - 76) / 2,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.18) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.white60, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? color : Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityChip(String bitrate, String label) {
    final isSelected = _audioQuality == bitrate;
    return Expanded(
      child: Tactile3DWrapper(
        onTap: () => _saveAudioQuality(bitrate),
        scaleElevation: 1.05,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.18) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white12,
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 3),
                const Icon(Icons.check_circle_rounded, color: Color(0xFF00E5FF), size: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbQualityChip(String quality, String label) {
    final isSelected = _thumbQuality == quality;
    return Expanded(
      child: Tactile3DWrapper(
        onTap: () => _saveThumbnailQuality(quality),
        scaleElevation: 1.05,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF9100).withOpacity(0.18) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFFFF9100) : Colors.white12,
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF9100).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFFF9100) : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 3),
                const Icon(Icons.check_circle_rounded, color: Color(0xFFFF9100), size: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccordionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withOpacity(0.15),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          iconColor: accentColor,
          collapsedIconColor: Colors.white54,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: children,
        ),
      ),
    );
  }
}

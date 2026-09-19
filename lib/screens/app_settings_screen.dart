import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/theme_service.dart';
import '../services/language_service.dart';
import '../services/share_helper.dart';
import '../services/update_service.dart';
import '../utils/app_constants.dart';
import '../widgets/tactile_3d_wrapper.dart';
import 'theme_selection_screen.dart';
import 'language_screen.dart';
import 'download_settings_screen.dart';
import 'storage_management_screen.dart';
import 'about_screen.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();
  final UpdateService _updateService = UpdateService();

  bool _isCheckingUpdate = false;
  String _installedVersion = AppConstants.appVersion;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final v = await _updateService.getInstalledVersion();
    if (mounted) setState(() => _installedVersion = v);
  }

  Future<void> _checkForUpdates() async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);

    try {
      final info = await _updateService.checkForUpdate();
      if (!mounted) return;
      setState(() => _isCheckingUpdate = false);

      if (info != null && info.hasUpdate) {
        _showUpdateDialog(info);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00E676),
            content: Text(
              _lang.isHindi
                  ? 'आपका ऐप पहले से ही नवीनतम वर्ज़न (v$_installedVersion) पर है!'
                  : 'Your app is up to date (v$_installedVersion)!',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              _lang.isHindi ? 'अपडेट जांचने में त्रुटि हुई' : 'Failed to check for updates',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: Color(0xFF00E5FF)),
            const SizedBox(width: 10),
            Text(
              _lang.isHindi ? 'नया अपडेट उपलब्ध!' : 'Update Available!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_lang.isHindi ? "नया वर्ज़न" : "Version"}: v${info.latestVersion}',
              style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              info.releaseNotes.isNotEmpty ? info.releaseNotes : (_lang.isHindi ? 'नवीनतम सुधार और नए फीचर्स' : 'Latest features and bug fixes'),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_lang.t('cancel'), style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _downloadAndInstallApk(info);
            },
            child: Text(
              _lang.isHindi ? 'अपडेट करें' : 'Update Now',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadAndInstallApk(UpdateInfo info) {
    final apkUrl = info.apkDownloadUrl;
    if (apkUrl.isEmpty) return;

    final cancelToken = CancelToken();
    final progressNotifier = ValueNotifier<Map<String, dynamic>>({
      'received': 0,
      'total': info.assetSize > 0 ? info.assetSize : 1,
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
          'total': total,
          'percent': percent,
        };
      },
    ).then((apkFile) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (apkFile != null) {
        _updateService.installApk(apkFile.path);
      }
    }).catchError((_) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_theme, _lang]),
      builder: (context, _) {
        final textColor = _theme.textColor;
        final subtextColor = _theme.subtextColor;
        final cardColor = _theme.cardBg;
        final isHindi = _lang.isHindi;

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
              isHindi ? 'ऐप सेटिंग्स' : 'App Settings',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            centerTitle: true,
          ),
          body: Container(
            decoration: _theme.backgroundDecoration,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // 1. App Theme
                _buildSettingTile(
                  icon: Icons.palette_rounded,
                  title: isHindi ? 'ऐप थीम (App Theme)' : 'App Theme',
                  subtitle: isHindi ? 'साइबरपंक, डार्क, लाइट, अमोलेड' : 'Cyberpunk, Dark, Light, AMOLED',
                  accentColor: const Color(0xFF00E5FF),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ThemeSelectionScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 2. Language
                _buildSettingTile(
                  icon: Icons.translate_rounded,
                  title: isHindi ? 'ऐप की भाषा (Language)' : 'App Language',
                  subtitle: isHindi ? 'हिंदी, English एवं अन्य 12+ भाषाएं' : 'Hindi, English & 12+ languages',
                  accentColor: const Color(0xFF00E676),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 3. Download Settings
                _buildSettingTile(
                  icon: Icons.download_rounded,
                  title: isHindi ? 'डाउनलोड सेटिंग्स (Downloads)' : 'Download Settings',
                  subtitle: isHindi ? '320kbps साउंड, थंबनेल क्वालिटी, ऑफलाइन लिरिक्स' : 'Audio fidelity, thumbnail & lyrics options',
                  accentColor: const Color(0xFFFF2A6D),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DownloadSettingsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 4. Storage Management
                _buildSettingTile(
                  icon: Icons.storage_rounded,
                  title: isHindi ? 'स्टोरेज प्रबंधन (Storage)' : 'Storage Management',
                  subtitle: isHindi ? 'कैश साफ़ करें, स्पेस देखें, डाउनलोड फ़ोल्डर' : 'Manage cache, storage space & music folder',
                  accentColor: const Color(0xFFFFB300),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StorageManagementScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 5. About Application
                _buildSettingTile(
                  icon: Icons.info_outline_rounded,
                  title: isHindi ? 'ऐप के बारे में (About App)' : 'About Application',
                  subtitle: isHindi ? 'वर्ज़न v$_installedVersion, डेवलपर एवं लाइसेंस' : 'Version v$_installedVersion, credits & developer',
                  accentColor: const Color(0xFFAB47BC),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // SECTION: Actions (Share & Update)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      // Share App
                      Tactile3DWrapper(
                        onTap: () => ShareHelper.shareApp(),
                        scaleElevation: 1.04,
                        glowColor: const Color(0xFF00E5FF),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00E5FF).withOpacity(0.15),
                              ),
                              child: const Icon(Icons.share_rounded, color: Color(0xFF00E5FF), size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                isHindi ? 'दोस्तों के साथ ऐप शेयर करें' : 'Share App with Friends',
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      // Check for updates
                      Tactile3DWrapper(
                        onTap: _checkForUpdates,
                        scaleElevation: 1.04,
                        glowColor: const Color(0xFF00E676),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00E676).withOpacity(0.15),
                              ),
                              child: _isCheckingUpdate
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E676)),
                                    )
                                  : const Icon(Icons.system_update_rounded, color: Color(0xFF00E676), size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isHindi ? 'ऐप अपडेट चेक करें' : 'Check for Updates',
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    'v$_installedVersion',
                                    style: TextStyle(color: subtextColor, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
  }) {
    return Tactile3DWrapper(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      scaleElevation: 1.05,
      glowColor: accentColor,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.15),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: subtextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }
}

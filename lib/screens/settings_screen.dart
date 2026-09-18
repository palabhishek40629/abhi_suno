import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../services/download_service.dart';
import '../services/music_service.dart';
import '../services/playlist_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeService _themeService = ThemeService();
  final LanguageService _lang = LanguageService();
  final DownloadService _downloadService = DownloadService();
  final MusicService _musicService = MusicService();
  final PlaylistService _playlistService = PlaylistService();

  final TextEditingController _ytLinkController = TextEditingController();
  bool _isImportingYt = false;
  double _cacheSizeMB = 0.0;
  String _audioQuality = '320kbps';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final size = await _downloadService.getVaultSizeInMB();
    final prefs = await SharedPreferences.getInstance();
    final quality = prefs.getString('audio_quality_pref') ?? '320kbps';

    if (mounted) {
      setState(() {
        _cacheSizeMB = size;
        _audioQuality = quality;
      });
    }
  }

  Future<void> _saveAudioQuality(String quality) async {
    setState(() => _audioQuality = quality);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audio_quality_pref', quality);
  }

  Future<void> _importYouTubePlaylist() async {
    final url = _ytLinkController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isImportingYt = true);
    try {
      final songs = await _musicService.importYouTubePlaylist(url);
      if (songs.isNotEmpty) {
        final playlistName = songs.first.album.isNotEmpty ? songs.first.album : 'YouTube Playlist';
        await _playlistService.createPlaylist(playlistName);
        for (final song in songs) {
          await _playlistService.addSongToPlaylist(playlistName, song);
        }

        if (mounted) {
          _ytLinkController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${songs.length} ' + (_lang.isHindi ? 'गाने सफलतापूर्वक जोड़े गए!' : 'songs imported successfully!')),
              backgroundColor: const Color(0xFF05D9E8),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_lang.isHindi ? 'प्लेलिस्ट नहीं मिली। लिंक जांचें।' : 'Playlist not found. Please check URL.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_lang.isHindi ? 'इम्पोर्ट करने में त्रुटि हुई' : 'Error importing playlist'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImportingYt = false);
    }
  }

  Future<void> _clearCache() async {
    await _downloadService.clearVaultCache();
    await _loadSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lang.t('cache_cleared')),
          backgroundColor: const Color(0xFF05D9E8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_themeService, _lang]),
      builder: (context, _) {
        final isDark = _themeService.isDark;
        final isLight = _themeService.isLight;
        final isTrans = _themeService.isTransparent;

        final bgColor = _themeService.scaffoldBg;
        final cardColor = _themeService.cardBg;
        final textColor = _themeService.textColor;
        final subtextColor = _themeService.subtextColor;
        final primaryColor = _themeService.primaryColor;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: isLight ? Colors.white : Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _lang.t('settings'),
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Container(
            decoration: _themeService.backgroundDecoration,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // SECTION: Developer Profile (Abhishek Pal)
                _buildSectionHeader(_lang.t('about_developer'), textColor),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFD700), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.amber),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _lang.t('developer_name'),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _lang.t('developer_role'),
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _lang.t('developer_bio'),
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION: Theme Selection (Dark, Light, Transparent)
                _buildSectionHeader(_lang.t('theme_title'), textColor),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      _buildThemeTile(
                        title: _lang.t('theme_dark'),
                        icon: Icons.dark_mode_rounded,
                        color: const Color(0xFF0A0A0A),
                        isSelected: isDark,
                        textColor: textColor,
                        onTap: () => _themeService.setTheme(AppThemeMode.dark),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      _buildThemeTile(
                        title: _lang.t('theme_light'),
                        icon: Icons.light_mode_rounded,
                        color: Colors.amber,
                        isSelected: isLight,
                        textColor: textColor,
                        onTap: () => _themeService.setTheme(AppThemeMode.light),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      _buildThemeTile(
                        title: _lang.t('theme_transparent'),
                        icon: Icons.blur_on_rounded,
                        color: const Color(0xFF05D9E8),
                        isSelected: isTrans,
                        textColor: textColor,
                        onTap: () => _themeService.setTheme(AppThemeMode.transparent),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION: Language Selection (Pure Hindi / Pure English)
                _buildSectionHeader(_lang.t('language_title'), textColor),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<bool>(
                        value: true,
                        groupValue: _lang.isHindi,
                        activeColor: primaryColor,
                        title: Text('हिन्दी (Hindi)', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                        subtitle: Text('100% शुद्ध हिन्दी भाषा', style: TextStyle(color: subtextColor, fontSize: 12)),
                        onChanged: (val) => _lang.setLanguage(true),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      RadioListTile<bool>(
                        value: false,
                        groupValue: _lang.isHindi,
                        activeColor: primaryColor,
                        title: Text('English', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                        subtitle: Text('100% Pure English localization', style: TextStyle(color: subtextColor, fontSize: 12)),
                        onChanged: (val) => _lang.setLanguage(false),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION: YouTube Sync & Account Playlists
                _buildSectionHeader(_lang.t('youtube_sync_title'), textColor),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.play_circle_filled_rounded, color: Color(0xFFFF0000), size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _lang.t('youtube_sync_desc'),
                              style: TextStyle(color: subtextColor, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _ytLinkController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: _lang.t('yt_link_hint'),
                          hintStyle: TextStyle(color: subtextColor.withOpacity(0.6), fontSize: 12),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF0000),
                            shape: BorderRadius.circular(12),
                          ),
                          onPressed: _isImportingYt ? null : _importYouTubePlaylist,
                          child: _isImportingYt
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  _lang.t('import_button'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION: Audio Quality
                _buildSectionHeader(_lang.t('audio_quality_title'), textColor),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: '320kbps',
                        groupValue: _audioQuality,
                        activeColor: primaryColor,
                        title: Text(_lang.t('quality_high'), style: TextStyle(color: textColor)),
                        onChanged: (val) => _saveAudioQuality(val!),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      RadioListTile<String>(
                        value: '160kbps',
                        groupValue: _audioQuality,
                        activeColor: primaryColor,
                        title: Text(_lang.t('quality_medium'), style: TextStyle(color: textColor)),
                        onChanged: (val) => _saveAudioQuality(val!),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      RadioListTile<String>(
                        value: '96kbps',
                        groupValue: _audioQuality,
                        activeColor: primaryColor,
                        title: Text(_lang.t('quality_low'), style: TextStyle(color: textColor)),
                        onChanged: (val) => _saveAudioQuality(val!),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION: Cache & Storage
                _buildSectionHeader(_lang.t('cache_clear_title'), textColor),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_cacheSizeMB.toStringAsFixed(1)} MB',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _lang.t('offline_vault'),
                            style: TextStyle(color: subtextColor, fontSize: 12),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          shape: BorderRadius.circular(12),
                        ),
                        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
                        label: Text(
                          _lang.t('clear_cache_btn'),
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                        onPressed: _clearCache,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // App Version Footer
                Center(
                  child: Text(
                    _lang.t('app_version'),
                    style: TextStyle(color: subtextColor.withOpacity(0.5), fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
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
      style: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildThemeTile({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF05D9E8))
          : const Icon(Icons.circle_outlined, color: Colors.white24),
      onTap: onTap,
    );
  }
}

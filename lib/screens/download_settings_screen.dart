import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_service.dart';
import '../services/language_service.dart';
import '../widgets/tactile_3d_wrapper.dart';

class DownloadSettingsScreen extends StatefulWidget {
  const DownloadSettingsScreen({Key? key}) : super(key: key);

  @override
  State<DownloadSettingsScreen> createState() => _DownloadSettingsScreenState();
}

class _DownloadSettingsScreenState extends State<DownloadSettingsScreen> {
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();

  String _audioQuality = '320kbps';
  String _thumbQuality = 'low';
  bool _downloadLyrics = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _audioQuality = prefs.getString('audio_download_quality_pref') ??
            prefs.getString('audio_quality_pref') ??
            '320kbps';
        _thumbQuality = prefs.getString('thumbnail_download_quality_pref') ?? 'low';
        _downloadLyrics = prefs.getBool('auto_download_lyrics') ?? true;
      });
    }
  }

  Future<void> _setAudioQuality(String quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audio_download_quality_pref', quality);
    await prefs.setString('audio_quality_pref', quality);
    if (mounted) setState(() => _audioQuality = quality);
  }

  Future<void> _setThumbQuality(String quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('thumbnail_download_quality_pref', quality);
    if (mounted) setState(() => _thumbQuality = quality);
  }

  Future<void> _toggleLyrics(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_download_lyrics', val);
    if (mounted) setState(() => _downloadLyrics = val);
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
              isHindi ? 'डाउनलोड सेटिंग्स' : 'Download Settings',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
          ),
          body: Container(
            decoration: _theme.backgroundDecoration,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // SECTION: Song Audio Quality
                _buildSectionHeader(
                  title: isHindi ? 'गाने की ऑडियो क्वालिटी' : 'Song Audio Quality',
                  icon: Icons.high_quality_rounded,
                  color: const Color(0xFF00E5FF),
                  textColor: textColor,
                ),
                const SizedBox(height: 10),
                _buildOptionCard(
                  title: isHindi ? '320 kbps (अल्ट्रा एचडी लॉसलेस)' : '320 kbps (Ultra HD Lossless)',
                  subtitle: isHindi ? 'उच्चतम स्टूडियो साउंड क्वालिटी • सर्वोत्तम अनुभव' : 'Highest fidelity studio audio',
                  isSelected: _audioQuality == '320kbps',
                  accentColor: const Color(0xFF00E5FF),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () => _setAudioQuality('320kbps'),
                ),
                const SizedBox(height: 8),
                _buildOptionCard(
                  title: isHindi ? '160 kbps (हाई क्वालिटी)' : '160 kbps (High Quality)',
                  subtitle: isHindi ? 'संतुलित साउंड और कम स्टोरेज • तेज डाउनलोड' : 'Balanced audio & storage footprint',
                  isSelected: _audioQuality == '160kbps',
                  accentColor: const Color(0xFF00E5FF),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () => _setAudioQuality('160kbps'),
                ),
                const SizedBox(height: 8),
                _buildOptionCard(
                  title: isHindi ? '96 kbps (डेटा सेवर)' : '96 kbps (Data Saver)',
                  subtitle: isHindi ? 'धीमे नेटवर्क पर तुरंत डाउनलोड • न्यूनतम एमबी' : 'Lightest size for slow connections',
                  isSelected: _audioQuality == '96kbps',
                  accentColor: const Color(0xFF00E5FF),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () => _setAudioQuality('96kbps'),
                ),

                const SizedBox(height: 24),

                // SECTION: Thumbnail Quality
                _buildSectionHeader(
                  title: isHindi ? 'थंबनेल / फोटो डाउनलोड क्वालिटी' : 'Thumbnail Download Quality',
                  icon: Icons.image_rounded,
                  color: const Color(0xFFFF2A6D),
                  textColor: textColor,
                ),
                const SizedBox(height: 10),
                _buildOptionCard(
                  title: isHindi ? 'लो क्वालिटी (Low 150x150 - अनुशंसित)' : 'Low Quality (150x150 - Recommended)',
                  subtitle: isHindi ? 'मात्र 5-10 KB • स्टोरेज बचाएं और ऑफलाइन फोटो देखें' : 'Only 5-10 KB • Saves storage & loads fast',
                  isSelected: _thumbQuality == 'low',
                  accentColor: const Color(0xFFFF2A6D),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () => _setThumbQuality('low'),
                ),
                const SizedBox(height: 8),
                _buildOptionCard(
                  title: isHindi ? 'मीडियम क्वालिटी (Medium 300x300)' : 'Medium Quality (300x300)',
                  subtitle: isHindi ? 'लगभग 20-30 KB • साफ और स्पष्ट कवर आर्ट' : 'Approx 20-30 KB • Crisp & clear artwork',
                  isSelected: _thumbQuality == 'medium',
                  accentColor: const Color(0xFFFF2A6D),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () => _setThumbQuality('medium'),
                ),
                const SizedBox(height: 8),
                _buildOptionCard(
                  title: isHindi ? 'हाई क्वालिटी (High 500x500 HD)' : 'High Quality (500x500 HD)',
                  subtitle: isHindi ? 'लगभग 60-100 KB • ओरिजिनल स्टूडियो आर्ट' : 'Approx 60-100 KB • Full size studio art',
                  isSelected: _thumbQuality == 'high',
                  accentColor: const Color(0xFFFF2A6D),
                  cardColor: cardColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () => _setThumbQuality('high'),
                ),

                const SizedBox(height: 24),

                // SECTION: Offline Lyrics
                _buildSectionHeader(
                  title: isHindi ? 'ऑफलाइन लिरिक्स (Lyrics Download)' : 'Offline Lyrics',
                  icon: Icons.lyrics_rounded,
                  color: const Color(0xFF00E676),
                  textColor: textColor,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        child: const Icon(Icons.description_rounded, color: Color(0xFF00E676), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHindi ? 'गाने के साथ लिरिक्स डाउनलोड करें' : 'Download Lyrics with Song',
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isHindi ? 'JioSaavn / LRCLIB से .lrc फाइल ऑफलाइन सेव होगी' : 'Saves synchronized .lrc file for offline reading',
                              style: TextStyle(color: subtextColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _downloadLyrics,
                        onChanged: _toggleLyrics,
                        activeColor: const Color(0xFF00E676),
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

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
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
      scaleElevation: 1.04,
      glowColor: accentColor,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.12) : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white12,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: subtextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.white38,
                  width: 2.0,
                ),
                color: isSelected ? accentColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, color: Colors.black, size: 14),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

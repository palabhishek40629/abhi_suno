import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal() {
    _loadLanguagePreference();
  }

  bool _isHindi = true; // Default to Hindi as requested by Abhishek
  bool get isHindi => _isHindi;

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isHindi = prefs.getBool('app_language_is_hindi') ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    _isHindi = !_isHindi;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_language_is_hindi', _isHindi);
    } catch (_) {}
  }

  Future<void> setLanguage(bool isHindi) async {
    _isHindi = isHindi;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_language_is_hindi', _isHindi);
    } catch (_) {}
  }

  // Bilingual translation dictionary
  String t(String key) {
    if (_isHindi) {
      return _hindiStrings[key] ?? _englishStrings[key] ?? key;
    } else {
      return _englishStrings[key] ?? key;
    }
  }

  static const Map<String, String> _englishStrings = {
    'app_name': 'Abhi Suno',
    'app_subtitle': 'by Abhishek Pal',
    'home': 'Home',
    'search': 'Search',
    'library': 'Library',
    'downloads': 'Downloads',
    'playlists': 'Playlists',
    'device_music': 'Device Songs',
    'import_device_songs': 'Scan & Import Phone Songs',
    'scanning_device': 'Scanning phone for audio files...',
    'no_device_songs': 'No songs found on phone storage.',
    'create_playlist': 'New Playlist',
    'create_playlist_title': 'Create New Playlist',
    'playlist_name_hint': 'Enter playlist name...',
    'cancel': 'Cancel',
    'create': 'Create',
    'empty_playlist': 'Playlist is empty. Add songs from Home or Search.',
    'now_playing': 'Now Playing',
    'playing_from': 'PLAYING FROM',
    'download': 'Download',
    'downloaded': 'Downloaded',
    'downloading': 'Downloading...',
    'lyrics': 'Lyrics',
    'equalizer': 'Equalizer & Bass',
    'pure_audio': '100% Pure Audio (No Video)',
    'search_hint': 'Search Hindi or international songs, artists...',
    'popular_artists': 'Popular Hindi Artists',
    'trending_hindi': '🔥 Trending Hindi Hits',
    'romantic_hits': '❤️ Romantic Melodies',
    'retro_classics': '📻 90s Retro Classics',
    'punjabi_hits': '⚡ Punjabi Hits',
    'lofi_chill': '🌙 Lo-Fi & Chill Hindi',
    'about_title': 'About Abhi Suno',
    'about_developer': 'Created & Developed by',
    'developer_name': 'Abhishek Pal',
    'developer_role': 'Computer Science & Engineering Student',
    'developer_desc': 'Passionate CSE student and open-source developer creating high-quality, ad-free music software for everyone.',
    'features_heading': 'Key Highlights',
    'youtube_login_title': 'YouTube Account & Playlist Import',
    'import_yt_playlist': 'Import YouTube Playlist',
    'yt_link_hint': 'Paste public YouTube / YT Music playlist link...',
    'import_button': 'Import Playlist',
    'connected_as': 'Connected as YouTube User',
  };

  static const Map<String, String> _hindiStrings = {
    'app_name': 'अभी सुनो',
    'app_subtitle': 'बाय अभिषेक पाल',
    'home': 'होम',
    'search': 'सर्च',
    'library': 'लाइब्रेरी',
    'downloads': 'डाउनलोड्स',
    'playlists': 'प्लेलिस्ट',
    'device_music': 'फोन के गाने',
    'import_device_songs': 'फोन से गाने स्कैन & इम्पोर्ट करें',
    'scanning_device': 'फोन में ऑडियो फाइल्स खोजी जा रही हैं...',
    'no_device_songs': 'फोन स्टोरेज में कोई गाना नहीं मिला।',
    'create_playlist': 'नई प्लेलिस्ट',
    'create_playlist_title': 'नई प्लेलिस्ट बनाएं',
    'playlist_name_hint': 'प्लेलिस्ट का नाम लिखें...',
    'cancel': 'रद्द करें',
    'create': 'बनाएं',
    'empty_playlist': 'प्लेलिस्ट खाली है। होम या सर्च से गाने जोड़ें।',
    'now_playing': 'अब बज रहा है',
    'playing_from': 'बज रहा है',
    'download': 'डाउनलोड',
    'downloaded': 'डाउनलोडेड',
    'downloading': 'डाउनलोड हो रहा है...',
    'lyrics': 'बोल (Lyrics)',
    'equalizer': 'इक्वलाइज़र & बास',
    'pure_audio': '100% प्योर ऑडियो (नो वीडियो)',
    'search_hint': 'हिंदी गाने, बॉलीवुड, कलाकार सर्च करें...',
    'popular_artists': 'लोकप्रिय हिंदी कलाकार',
    'trending_hindi': '🔥 ट्रेंडिंग हिंदी गाने',
    'romantic_hits': '❤️ रोमांटिक हिट्स',
    'retro_classics': '📻 90s रेट्रो पुराने गाने',
    'punjabi_hits': '⚡ पंजाबी धमाकेदार बीट्स',
    'lofi_chill': '🌙 लो-फाई & चिल हिंदी',
    'about_title': 'अभी सुनो के बारे में',
    'about_developer': 'निर्माता व डेवलपर',
    'developer_name': 'अभिषेक पाल',
    'developer_role': 'कंप्यूटर साइंस एंड इंजीनियरिंग के छात्र',
    'developer_desc': 'कंप्यूटर साइंस एंड इंजीनियरिंग (CSE) के उत्साही छात्र और ओपन-सोर्स डेवलपर, जिन्होंने सभी के लिए यह फ्री व ऐड-फ्री म्यूज़िक ऐप बनाया है।',
    'features_heading': 'खास विशेषताएं',
    'youtube_login_title': 'यूट्यूब अकाउंट & प्लेलिस्ट इम्पोर्ट',
    'import_yt_playlist': 'YouTube प्लेलिस्ट इम्पोर्ट करें',
    'yt_link_hint': 'YouTube / YT Music प्लेलिस्ट लिंक यहाँ पेस्ट करें...',
    'import_button': 'प्लेलिस्ट इम्पोर्ट करें',
    'connected_as': 'YouTube यूजर के रूप में कनेक्टेड',
  };
}

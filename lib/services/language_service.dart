import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal() {
    _loadLanguagePreference();
  }

  bool _isHindi = true;
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
    'explore': 'Explore',
    'search': 'Search',
    'library': 'Library',
    'settings': 'Settings',
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
    'playing_from': 'Playing From',
    'download': 'Download',
    'downloaded': 'Downloaded',
    'downloading': 'Downloading...',
    'lyrics': 'Lyrics',
    'equalizer': 'Equalizer & Audio Controls',
    'pure_audio': 'Pure Audio (No Video Lag)',
    'search_hint': 'Search songs, artists, albums...',
    'search_history': 'Recent Search History',
    'clear_all': 'Clear All',
    'no_history': 'No search history yet',
    'theme_title': 'Theme & Appearance',
    'theme_dark': 'Dark Mode (Deep Black)',
    'theme_light': 'Light Mode (Clean White)',
    'theme_transparent': 'Transparent Mode (Glass Effect)',
    'language_title': 'Language Selection',
    'youtube_sync_title': 'YouTube Music & Playlist Sync',
    'youtube_sync_desc': 'Paste public YouTube or YT Music playlist URL to import songs directly',
    'import_yt_playlist': 'Import YouTube Playlist',
    'yt_link_hint': 'Paste YouTube playlist URL here...',
    'import_button': 'Import Playlist',
    'audio_quality_title': 'Audio Streaming Quality',
    'quality_high': 'High Quality (320 kbps)',
    'quality_medium': 'Standard Quality (160 kbps)',
    'quality_low': 'Data Saver (96 kbps)',
    'cache_clear_title': 'Cache & Storage',
    'clear_cache_btn': 'Clear Cache Memory',
    'cache_cleared': 'Cache cleared successfully',
    'about_developer': 'Developer Profile',
    'developer_name': 'Abhishek Pal',
    'developer_role': 'Computer Science & Engineering Student',
    'developer_bio': 'Passionate Computer Science & Engineering student creating high-performance, ad-free music applications for everyone.',
    'app_version': 'Version 3.0.0 Pro',
    'speed': 'Playback Speed',
    'pitch': 'Pitch',
    'volume': 'Volume',
    'mood_categories': 'Moods & Categories',
    'trending': 'Trending Top Hits',
    'romantic': 'Romantic Melodies',
    'retro_classics': '90s Retro Classics',
    'punjabi': 'Punjabi Beats',
    'bhakti': 'Devotional & Bhakti',
    'lofi': 'Lo-Fi Chill',
    'workout': 'Workout & Energy',
    'party': 'Party & Dance',
    'ghazal': 'Ghazals & Soulful',
    'popular_artists': 'Popular Artists',
    'quick_picks': 'Quick Picks for You',
    'offline_vault': 'Offline Private Vault',
    'play_all': 'Play All',
  };

  static const Map<String, String> _hindiStrings = {
    'app_name': 'अभी सुनो',
    'app_subtitle': 'अभिषेक पाल द्वारा',
    'home': 'मुखपृष्ठ',
    'explore': 'अन्वेषण',
    'search': 'खोजें',
    'library': 'संग्रह',
    'settings': 'व्यवस्था',
    'downloads': 'डाउनलोड किए गए गीत',
    'playlists': 'गीत सूचियाँ',
    'device_music': 'फोन के स्थानीय गीत',
    'import_device_songs': 'फोन के गाने खोजें एवं जोड़ें',
    'scanning_device': 'फोन में गीत खोजे जा रहे हैं...',
    'no_device_songs': 'फोन में कोई ऑडियो फाइल नहीं मिली।',
    'create_playlist': 'नई गीत सूची',
    'create_playlist_title': 'नई गीत सूची बनाएं',
    'playlist_name_hint': 'गीत सूची का नाम लिखें...',
    'cancel': 'रद्द करें',
    'create': 'बनाएं',
    'empty_playlist': 'यह सूची अभी खाली है। मुखपृष्ठ या खोज से गीत जोड़ें।',
    'now_playing': 'वर्तमान में बज रहा गीत',
    'playing_from': 'यहाँ से बज रहा है',
    'download': 'डाउनलोड करें',
    'downloaded': 'डाउनलोड पूर्ण',
    'downloading': 'डाउनलोड हो रहा है...',
    'lyrics': 'गीत के बोल',
    'equalizer': 'ध्वनि संतुलन एवं बास',
    'pure_audio': 'शुद्ध संगीत (केवल ऑडियो)',
    'search_hint': 'गीत, कलाकार या एल्बम खोजें...',
    'search_history': 'हालिया खोज इतिहास',
    'clear_all': 'सभी हटाएं',
    'no_history': 'कोई खोज इतिहास नहीं है',
    'theme_title': 'रंग रूप एवं थीम',
    'theme_dark': 'डार्क मोड (गहरा रंग)',
    'theme_light': 'लाइट मोड (हल्का रंग)',
    'theme_transparent': 'पारदर्शी मोड (ग्लास प्रभाव)',
    'language_title': 'भाषा चयन',
    'youtube_sync_title': 'यूट्यूब संगीत एवं गीत सूची जोड़ें',
    'youtube_sync_desc': 'यूट्यूब प्लेलिस्ट का लिंक दर्ज करके सीधे इस ऐप में गाने जोड़ें',
    'import_yt_playlist': 'यूट्यूब प्लेलिस्ट जोड़ें',
    'yt_link_hint': 'यूट्यूब प्लेलिस्ट लिंक यहाँ पेस्ट करें...',
    'import_button': 'प्लेलिस्ट जोड़ें',
    'audio_quality_title': 'ऑडियो गुणवत्ता',
    'quality_high': 'उच्चतम गुणवत्ता (३२० केबीपीएस)',
    'quality_medium': 'मध्यम गुणवत्ता (१६० केबीपीएस)',
    'quality_low': 'डेटा बचत (९६ केबीपीएस)',
    'cache_clear_title': 'कैश एवं स्टोरेज',
    'clear_cache_btn': 'कैश मेमोरी साफ करें',
    'cache_cleared': 'कैश मेमोरी सफलतापूर्वक साफ कर दी गई',
    'about_developer': 'डेवलपर परिचय',
    'developer_name': 'अभिषेक पाल',
    'developer_role': 'कंप्यूटर विज्ञान एवं इंजीनियरिंग के छात्र',
    'developer_bio': 'कंप्यूटर विज्ञान एवं इंजीनियरिंग (CSE) के उत्साही छात्र, जिन्होंने बिना किसी विज्ञापन के तीव्र एवं उच्च गुणवत्ता वाला संगीत अनुभव प्रदान करने हेतु यह ऐप बनाया है।',
    'app_version': 'संस्करण ३.०.० प्रो',
    'speed': 'बजने की गति',
    'pitch': 'ध्वनि का सुर',
    'volume': 'ध्वनि की तीव्रता',
    'mood_categories': 'मूड एवं शैलियाँ',
    'trending': 'लोकप्रिय ट्रेंडिंग गीत',
    'romantic': 'मधुर प्रेम गीत',
    'retro_classics': 'सदाबहार पुराने गीत',
    'punjabi': 'पंजाबी धमाकेदार गीत',
    'bhakti': 'भक्ति एवं प्रार्थना गीत',
    'lofi': 'शांत एवं सुकून भरे धुन',
    'workout': 'ऊर्जावान गीत',
    'party': 'पार्टी एवं नृत्य गीत',
    'ghazal': 'ग़ज़ल एवं सुकून',
    'popular_artists': 'लोकप्रिय कलाकार',
    'quick_picks': 'आपके लिए विशेष चयन',
    'offline_vault': 'सुरक्षित ऑफलाइन संग्रह',
    'play_all': 'सभी चलाएं',
  };
}

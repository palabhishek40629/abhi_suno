import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageInfo {
  final String code;
  final String nativeName;
  final String englishName;
  const LanguageInfo({required this.code, required this.nativeName, required this.englishName});
}

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal() {
    _loadLanguagePreference();
  }

  // 21 Indian Constitutional & Popular Languages
  static const List<LanguageInfo> supportedLanguages = [
    LanguageInfo(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi'),
    LanguageInfo(code: 'en', nativeName: 'English', englishName: 'English'),
    LanguageInfo(code: 'bho', nativeName: 'भोजपुरी', englishName: 'Bhojpuri'),
    LanguageInfo(code: 'pa', nativeName: 'ਪੰਜਾਬੀ', englishName: 'Punjabi'),
    LanguageInfo(code: 'bn', nativeName: 'বাংলা', englishName: 'Bengali'),
    LanguageInfo(code: 'mr', nativeName: 'मराठी', englishName: 'Marathi'),
    LanguageInfo(code: 'gu', nativeName: 'ગુજરાતી', englishName: 'Gujarati'),
    LanguageInfo(code: 'ta', nativeName: 'தமிழ்', englishName: 'Tamil'),
    LanguageInfo(code: 'te', nativeName: 'తెలుగు', englishName: 'Telugu'),
    LanguageInfo(code: 'kn', nativeName: 'ಕನ್ನಡ', englishName: 'Kannada'),
    LanguageInfo(code: 'ml', nativeName: 'മലയാളം', englishName: 'Malayalam'),
    LanguageInfo(code: 'or', nativeName: 'ଓଡ଼ିଆ', englishName: 'Odia'),
    LanguageInfo(code: 'as', nativeName: 'অসমীয়া', englishName: 'Assamese'),
    LanguageInfo(code: 'raj', nativeName: 'राजस्थानी', englishName: 'Rajasthani'),
    LanguageInfo(code: 'har', nativeName: 'हरियाणवी', englishName: 'Haryanvi'),
    LanguageInfo(code: 'mai', nativeName: 'मैथिली', englishName: 'Maithili'),
    LanguageInfo(code: 'ur', nativeName: 'اردو', englishName: 'Urdu'),
    LanguageInfo(code: 'sa', nativeName: 'संस्कृतम्', englishName: 'Sanskrit'),
    LanguageInfo(code: 'sd', nativeName: 'سنڌي', englishName: 'Sindhi'),
    LanguageInfo(code: 'ne', nativeName: 'नेपाली', englishName: 'Nepali'),
    LanguageInfo(code: 'kok', nativeName: 'कोंकणी', englishName: 'Konkani'),
  ];

  String _currentCode = 'hi';
  bool _manualSelected = false;

  String get currentCode => _currentCode;
  bool get isHindi => _currentCode == 'hi' || _currentCode == 'bho' || _currentCode == 'raj' || _currentCode == 'har';

  String get currentLanguageName {
    final match = supportedLanguages.firstWhere(
      (l) => l.code == _currentCode,
      orElse: () => const LanguageInfo(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi'),
    );
    return '${match.nativeName} (${match.englishName})';
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _manualSelected = prefs.getBool('language_manual_selected') ?? false;

      if (_manualSelected) {
        _currentCode = prefs.getString('app_language_code') ?? 'hi';
      } else {
        // Section 6.3: Detect phone system language on first launch
        final systemLocale = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
        final match = supportedLanguages.firstWhere(
          (l) => l.code == systemLocale,
          orElse: () => const LanguageInfo(code: 'en', nativeName: 'English', englishName: 'English'),
        );
        _currentCode = match.code == 'en' ? 'en' : match.code;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLanguageCode(String code) async {
    _currentCode = code;
    _manualSelected = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language_code', code);
      await prefs.setBool('language_manual_selected', true);
      await prefs.setBool('app_language_is_hindi', isHindi);
    } catch (_) {}
  }

  Future<void> setLanguage(bool isHindi) async {
    await setLanguageCode(isHindi ? 'hi' : 'en');
  }

  String t(String key) {
    if (isHindi) {
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
    'profile': 'Profile',
    'settings': 'Settings',
    'downloads': 'Downloads',
    'playlists': 'Playlists',
    'device_music': 'Device Audio',
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
    'remove_search_history': 'Remove search history',
    'remove_search_history_confirm': 'Are you sure you want to remove this search from history?',
    'delete': 'Delete',
    'theme_title': 'Theme & Appearance',
    'theme_default': 'Default (System)',
    'theme_dark': 'Dark Mode (Deep Black)',
    'theme_light': 'Light Mode (Clean White)',
    'theme_transparent': 'Transparent Mode (Glass Effect)',
    'language_title': 'Language Selection',
    'youtube_sync_title': 'Playlist URL Import / Download',
    'youtube_sync_desc': 'Paste public YouTube, Instagram, or media URL to stream or download',
    'import_yt_playlist': 'Import / Download URL',
    'yt_link_hint': 'Paste media URL here...',
    'import_button': 'Import Playlist',
    'download_audio': 'Download Audio',
    'download_video': 'Download Video',
    'audio_quality_title': 'Default Download Quality',
    'quality_high': 'Ultra High (320 kbps)',
    'quality_medium': 'Standard (160 kbps)',
    'quality_low': 'Data Saver (96 kbps)',
    'cache_clear_title': 'Storage Management',
    'total_storage': 'Total Device Storage',
    'available_storage': 'Available Free Space',
    'app_storage': 'App Storage Usage',
    'temporary_cache': 'Temporary Streaming Cache',
    'permanent_downloads': 'Permanent Offline Downloads',
    'delete_all_downloads': 'Delete All Downloaded Songs',
    'delete_all_warning': 'Warning: Deleted downloads cannot be restored without re-downloading. Are you sure?',
    'clear_cache_btn': 'Clear Temporary Cache',
    'clear_cache_note': 'Clearing cache will NEVER delete your permanent offline downloads.',
    'cache_cleared': 'Temporary cache cleared successfully',
    'github_updates_title': 'Check for Updates',
    'current_version': 'Current Version',
    'latest_version': 'Latest Available Version',
    'check_updates': 'Check for Updates',
    'checking_updates': 'Checking for new releases...',
    'up_to_date': 'You have the latest version installed.',
    'update_available': 'New update available on GitHub!',
    'update_now': 'Update Now',
    'about_developer': 'About Application',
    'developer_name': 'Abhishek Pal',
    'developer_role': 'Computer Science & Engineering Student',
    'developer_bio': 'Passionate CSE student creating high-performance, ad-free music applications for everyone.',
    'app_version': 'Version 3.4.0 High Performance Edition',
    'share_app': 'Share Application',
    'share_app_desc': 'Share Abhi Suno APK with friends & family',
    'share_app_text': 'Listen to unlimited ad-free songs with 320 kbps Akamai CDN on Abhi Suno by Abhishek Pal! Download here: https://github.com/palabhishek40629/abhi_suno/releases/latest',
    'offline_title': 'You are offline',
    'offline_desc': 'Please check your internet connection to stream online songs.',
    'go_to_downloads': 'Go to Downloads',
    'sort_by': 'Sort by',
    'sort_name_az': 'Name (A-Z)',
    'sort_name_za': 'Name (Z-A)',
    'sort_newest': 'Newest Downloaded',
    'sort_oldest': 'Oldest Downloaded',
    'continuous_playback': 'Mix / Auto-Play',
    'play_all': 'Play All',
    'shuffle_all': 'Shuffle All',
    'trending': 'Trending Top Hits',
    'bhojpuri': 'Bhojpuri Music',
    'bhojpuri_desc': 'Hit Bhojpuri songs, chaita, and devotional',
    'continue_listening': 'CONTINUE LISTENING',
  };

  static const Map<String, String> _hindiStrings = {
    'app_name': 'अभी सुनो',
    'app_subtitle': 'अभिषेक पाल द्वारा',
    'home': 'मुखपृष्ठ',
    'explore': 'अन्वेषण',
    'search': 'खोजें',
    'library': 'संग्रह',
    'profile': 'प्रोफ़ाइल',
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
    'empty_playlist': 'यह सूची अभी खाली है।',
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
    'remove_search_history': 'खोज इतिहास से हटाएं',
    'remove_search_history_confirm': 'क्या आप वाकई इस खोज को इतिहास से हटाना चाहते हैं?',
    'delete': 'हटाएं',
    'theme_title': 'रंग रूप एवं थीम',
    'theme_default': 'डिफ़ॉल्ट (सिस्टम)',
    'theme_dark': 'डार्क मोड (गहरा रंग)',
    'theme_light': 'लाइट मोड (हल्का रंग)',
    'theme_transparent': 'पारदर्शी मोड (ग्लास प्रभाव)',
    'language_title': 'भाषा चयन',
    'youtube_sync_title': 'प्लेलिस्ट URL इम्पोर्ट / डाउनलोड',
    'youtube_sync_desc': 'YouTube, Instagram या मीडिया लिंक पेस्ट करके ऑनलाइन सुनें या डाउनलोड करें',
    'import_yt_playlist': 'इम्पोर्ट / डाउनलोड URL',
    'yt_link_hint': 'मीडिया लिंक यहाँ पेस्ट करें...',
    'import_button': 'प्लेलिस्ट जोड़ें',
    'download_audio': 'ऑडियो डाउनलोड',
    'download_video': 'वीडियो डाउनलोड',
    'audio_quality_title': 'डिफ़ॉल्ट डाउनलोड गुणवत्ता',
    'quality_high': 'उच्चतम गुणवत्ता (३२० केबीपीएस)',
    'quality_medium': 'मध्यम गुणवत्ता (१६० केबीपीएस)',
    'quality_low': 'डेटा बचत (९६ केबीपीएस)',
    'cache_clear_title': 'स्टोरेज प्रबंधन',
    'total_storage': 'कुल फोन स्टोरेज',
    'available_storage': 'उपलब्ध खाली स्पेस',
    'app_storage': 'ऐप द्वारा प्रयुक्त स्पेस',
    'temporary_cache': 'अस्थायी स्ट्रीमिंग कैश',
    'permanent_downloads': 'स्थायी ऑफलाइन डाउनलोड्स',
    'delete_all_downloads': 'सभी डाउनलोड किए गए गीत हटाएं',
    'delete_all_warning': 'चेतावनी: हटाए गए गाने पुनः डाउनलोड किए बिना वापस नहीं आएंगे। क्या आप निश्चित हैं?',
    'clear_cache_btn': 'कैश मेमोरी साफ करें',
    'clear_cache_note': 'कैश साफ करने से आपके डाउनलोड किए गए ऑफलाइन गाने कभी नहीं हटेंगे।',
    'cache_cleared': 'अस्थायी कैश मेमोरी सफलतापूर्वक साफ कर दी गई',
    'github_updates_title': 'अपडेट जांचें',
    'current_version': 'वर्तमान स्थापित संस्करण',
    'latest_version': 'नवीनतम उपलब्ध संस्करण',
    'check_updates': 'अपडेट जांचें',
    'checking_updates': 'नए संस्करण की जांच हो रही है...',
    'up_to_date': 'आपके पास पहले से ही नवीनतम संस्करण है।',
    'update_available': 'नया अपडेट उपलब्ध है!',
    'update_now': 'अभी अपडेट करें',
    'about_developer': 'ऐप परिचय',
    'developer_name': 'अभिषेक पाल',
    'developer_role': 'कंप्यूटर विज्ञान एवं इंजीनियरिंग के छात्र',
    'developer_bio': 'कंप्यूटर विज्ञान एवं इंजीनियरिंग (CSE) के उत्साही छात्र, जिन्होंने बिना किसी विज्ञापन के तीव्र एवं उच्च गुणवत्ता वाला संगीत अनुभव प्रदान करने हेतु यह ऐप बनाया है।',
    'app_version': 'संस्करण ३.४.० उच्च प्रदर्शन संस्करण',
    'share_app': 'ऐप शेयर करें',
    'share_app_desc': 'अभिषेक पाल का अभी सुनो ऐप मित्रों को शेयर करें',
    'share_app_text': 'अभिषेक पाल द्वारा निर्मित अभी सुनो ऐप पर 320 kbps Akamai CDN से असीमित विज्ञापन-मुक्त संगीत सुनें! डाउनलोड लिंक: https://github.com/palabhishek40629/abhi_suno/releases/latest',
    'offline_title': 'आप ऑफ़लाइन हैं',
    'offline_desc': 'ऑनलाइन संगीत सुनने के लिए कृपया अपना इंटरनेट कनेक्शन जांचें।',
    'go_to_downloads': 'डाउनलोड्स पर जाएं',
    'sort_by': 'क्रमबद्ध करें',
    'sort_name_az': 'नाम (A-Z)',
    'sort_name_za': 'नाम (Z-A)',
    'sort_newest': 'नया डाउनलोड पहले',
    'sort_oldest': 'पुराना डाउनलोड पहले',
    'continuous_playback': 'मिक्स / निरंतर प्लेबैक',
    'play_all': 'सभी चलाएं',
    'shuffle_all': 'शफ़ल प्ले',
    'trending': 'लोकप्रिय ट्रेंडिंग गीत',
    'bhojpuri': 'भोजपुरी संगीत',
    'bhojpuri_desc': 'हिट भोजपुरी गाने, चैता, और भक्ति गीत',
    'continue_listening': 'सुनना जारी रखें',
  };
}

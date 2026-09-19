import 'now_playing_screen.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/download_service.dart';
import '../services/language_service.dart';
import '../services/music_service.dart';
import '../services/performance_guard.dart';
import '../services/theme_service.dart';
import '../widgets/tactile_3d_wrapper.dart';

class ExploreScreen extends StatefulWidget {
  final AbhiAudioHandler audioHandler;

  const ExploreScreen({Key? key, required this.audioHandler}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();

  String _selectedSection = 'all'; // 'all', 'bhojpuri', 'bollywood', 'punjabi', 'devotional', 'mood', 'regional'
  String _selectedEra = 'all'; // 'all', 'new', 'classic'

  static final List<Map<String, dynamic>> allCategories = [
    // ----------------- BHOJPURI SUBCATEGORIES -----------------
    {
      'key': 'bhojpuri_birha',
      'section': 'bhojpuri',
      'era': 'classic',
      'labelEn': 'Bhojpuri Birha',
      'labelHi': 'भोजपुरी पारंपरिक बिरहा',
      'desc': 'Traditional storytelling ballads & heroic folk tales',
      'query': 'Bhojpuri Birha hits',
      'icon': Icons.record_voice_over_rounded,
      'gradient': [Color(0xFFE65100), Color(0xFFFF9800)],
    },
    {
      'key': 'bhojpuri_lokgeet',
      'section': 'bhojpuri',
      'era': 'classic',
      'labelEn': 'Bhojpuri Lokgeet & Purvanchal',
      'labelHi': 'पारंपरिक भोजपुरी लोकगीत',
      'desc': 'Soulful folk melodies of UP & Bihar',
      'query': 'Bhojpuri Lokgeet Purvanchal hits',
      'icon': Icons.audiotrack_rounded,
      'gradient': [Color(0xFFBF360C), Color(0xFFFF5722)],
    },
    {
      'key': 'bhojpuri_chhath',
      'section': 'bhojpuri',
      'era': 'classic',
      'labelEn': 'Chhath Puja Geet',
      'labelHi': 'छठी मईया के पावन गीत',
      'desc': 'Sacred Chhath festival hymns by Sharda Sinha',
      'query': 'Chhath Puja Geet Sharda Sinha hits',
      'icon': Icons.wb_sunny_rounded,
      'gradient': [Color(0xFFF57F17), Color(0xFFFFD54F)],
    },
    {
      'key': 'bhojpuri_devi',
      'section': 'bhojpuri',
      'era': 'all',
      'labelEn': 'Bhojpuri Devi Geet & Pachra',
      'labelHi': 'मईया के पचरा एवं देवी गीत',
      'desc': 'Navratri devotion and temple aartis',
      'query': 'Bhojpuri Devi Geet Pachra Pawan Singh',
      'icon': Icons.flare_rounded,
      'gradient': [Color(0xFFC2185B), Color(0xFFFF4081)],
    },
    {
      'key': 'bhojpuri_dj',
      'section': 'bhojpuri',
      'era': 'new',
      'labelEn': 'Bhojpuri DJ Remix & Dhamaka',
      'labelHi': 'धमाकेदार भोजपुरी डीजे रीमिक्स',
      'desc': 'High-bass party beats & dancefloor bangers',
      'query': 'Bhojpuri DJ Remix nonstop hits',
      'icon': Icons.speaker_group_rounded,
      'gradient': [Color(0xFF6A1B9A), Color(0xFFBA68C8)],
    },
    {
      'key': 'bhojpuri_vivah',
      'section': 'bhojpuri',
      'era': 'classic',
      'labelEn': 'Bhojpuri Vivah & Shadi Geet',
      'labelHi': 'विवाह एवं शादी के गीत',
      'desc': 'Traditional Purvanchali wedding ceremony songs',
      'query': 'Bhojpuri Vivah Shadi Geet hits',
      'icon': Icons.celebration_rounded,
      'gradient': [Color(0xFFAD1457), Color(0xFFFF80AB)],
    },
    {
      'key': 'bhojpuri_bolbam',
      'section': 'bhojpuri',
      'era': 'all',
      'labelEn': 'Bol Bam & Sawan Kanwar',
      'labelHi': 'सावन कांवड़ एवं बोल बम',
      'desc': 'Lord Shiva Sawan bhajans & Kanwariya anthems',
      'query': 'Bhojpuri Bol Bam Sawan Shiv Bhajan',
      'icon': Icons.waves_rounded,
      'gradient': [Color(0xFF00695C), Color(0xFF26A69A)],
    },
    {
      'key': 'bhojpuri_sohar',
      'section': 'bhojpuri',
      'era': 'classic',
      'labelEn': 'Sohar & Badhai Geet',
      'labelHi': 'सोहर एवं बधाई लोकगीत',
      'desc': 'Celebratory songs of birth and auspicious beginnings',
      'query': 'Bhojpuri Sohar Badhai Geet traditional',
      'icon': Icons.child_care_rounded,
      'gradient': [Color(0xFF0277BD), Color(0xFF4FC3F7)],
    },
    {
      'key': 'bhojpuri_nirgun',
      'section': 'bhojpuri',
      'era': 'classic',
      'labelEn': 'Bhojpuri Kabir Nirgun',
      'labelHi': 'भोजपुरी कबीर निर्गुण',
      'desc': 'Philosophical spiritual songs of consciousness',
      'query': 'Bhojpuri Nirgun Kabir Bhajan',
      'icon': Icons.self_improvement_rounded,
      'gradient': [Color(0xFF37474F), Color(0xFF78909C)],
    },
    {
      'key': 'bhojpuri_ropani',
      'section': 'bhojpuri',
      'era': 'classic',
      'labelEn': 'Ropani & Khetihar Geet',
      'labelHi': 'रोपाई एवं खेती लोकगीत',
      'desc': 'Songs of lush fields, monsoons, and harvest',
      'query': 'Bhojpuri Ropani Khetihar Geet traditional',
      'icon': Icons.agriculture_rounded,
      'gradient': [Color(0xFF2E7D32), Color(0xFF81C784)],
    },
    {
      'key': 'bhojpuri_romantic',
      'section': 'bhojpuri',
      'era': 'new',
      'labelEn': 'Bhojpuri Romantic Hits',
      'labelHi': 'मधुर भोजपुरी प्रेम गीत',
      'desc': 'Melodious modern love songs & duets',
      'query': 'Bhojpuri Romantic Love Songs hits',
      'icon': Icons.favorite_rounded,
      'gradient': [Color(0xFFD81B60), Color(0xFFFF4081)],
    },
    {
      'key': 'bhojpuri_sad',
      'section': 'bhojpuri',
      'era': 'new',
      'labelEn': 'Bhojpuri Sad & Bewafai',
      'labelHi': 'दर्द भरे भोजपुरी गीत',
      'desc': 'Heart-touching melancholic ballads',
      'query': 'Bhojpuri Sad Song bewafai hits',
      'icon': Icons.heart_broken_rounded,
      'gradient': [Color(0xFF424242), Color(0xFF616161)],
    },

    // ----------------- BOLLYWOOD & RETRO -----------------
    {
      'key': 'trending_hindi',
      'section': 'bollywood',
      'era': 'new',
      'labelEn': 'Trending Chartbusters',
      'labelHi': 'लोकप्रिय ट्रेंडिंग हिट्स',
      'desc': 'The hottest hits ruling all Indian music charts',
      'query': 'Trending Hindi Bollywood hits 2026',
      'icon': Icons.local_fire_department_rounded,
      'gradient': [Color(0xFFFF416C), Color(0xFFFF4B2B)],
    },
    {
      'key': 'bollywood_romantic',
      'section': 'bollywood',
      'era': 'new',
      'labelEn': 'Bollywood Romantic',
      'labelHi': 'बॉलीवुड रोमांटिक मेलोडी',
      'desc': 'Soul-stirring romantic anthems & duets',
      'query': 'Bollywood romantic love songs hits',
      'icon': Icons.favorite_border_rounded,
      'gradient': [Color(0xFFEC008C), Color(0xFFFC6767)],
    },
    {
      'key': 'retro_90s',
      'section': 'bollywood',
      'era': 'classic',
      'labelEn': '90s Golden Bollywood',
      'labelHi': '90s के सदाबहार नगमे',
      'desc': 'Kumar Sanu, Udit Narayan, Alka Yagnik magic',
      'query': '90s Hindi Evergreen Superhit Songs',
      'icon': Icons.album_rounded,
      'gradient': [Color(0xFFF7971E), Color(0xFFFFD200)],
    },
    {
      'key': 'retro_70s80s',
      'section': 'bollywood',
      'era': 'classic',
      'labelEn': '70s-80s Timeless Classics',
      'labelHi': 'सत्तर-अस्सी का स्वर्ण युग',
      'desc': 'Kishore Kumar, Lata Mangeshkar, R.D. Burman',
      'query': '70s 80s Kishore Lata RD Burman classics',
      'icon': Icons.radio_rounded,
      'gradient': [Color(0xFFE65C00), Color(0xFFF9D423)],
    },
    {
      'key': 'heartbreak_sad',
      'section': 'bollywood',
      'era': 'all',
      'labelEn': 'Sad & Heartbreak',
      'labelHi': 'टूटे दिल के तराने',
      'desc': 'Emotional solace for quiet lonely evenings',
      'query': 'Bollywood sad heartbreak songs Arijit Singh',
      'icon': Icons.water_drop_rounded,
      'gradient': [Color(0xFF141E30), Color(0xFF243B55)],
    },
    {
      'key': 'acoustic_unplugged',
      'section': 'bollywood',
      'era': 'new',
      'labelEn': 'Acoustic & Unplugged',
      'labelHi': 'एकॉस्टिक अनप्लग्ड मेलोडी',
      'desc': 'Raw, intimate guitar & piano arrangements',
      'query': 'Bollywood acoustic unplugged guitar hits',
      'icon': Icons.music_note_rounded,
      'gradient': [Color(0xFF4B6CB7), Color(0xFF182848)],
    },
    {
      'key': 'monsoon_rain',
      'section': 'bollywood',
      'era': 'all',
      'labelEn': 'Monsoon Rain Melodies',
      'labelHi': 'बरसात एवं रिमझिम धुनें',
      'desc': 'Rain songs and cozy petrichor moods',
      'query': 'Bollywood rain monsoon hit songs',
      'icon': Icons.umbrella_rounded,
      'gradient': [Color(0xFF005AA7), Color(0xFFFFFDE4)],
    },
    {
      'key': 'party_dance',
      'section': 'bollywood',
      'era': 'new',
      'labelEn': 'Party & Dance Anthems',
      'labelHi': 'धमाकेदार पार्टी सॉन्ग्स',
      'desc': 'Electrifying club numbers to set dancefloors on fire',
      'query': 'Bollywood dance party club hits',
      'icon': Icons.nightlife_rounded,
      'gradient': [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    },
    {
      'key': 'wedding_sangeet',
      'section': 'bollywood',
      'era': 'all',
      'labelEn': 'Wedding & Sangeet',
      'labelHi': 'शादी एवं संगीत स्पेशल',
      'desc': 'Celebratory bridal and baraat anthems',
      'query': 'Bollywood wedding sangeet songs',
      'icon': Icons.wine_bar_rounded,
      'gradient': [Color(0xFFFF0844), Color(0xFFFFB199)],
    },
    {
      'key': 'hindi_ghazals',
      'section': 'bollywood',
      'era': 'classic',
      'labelEn': 'Soulful Hindi Ghazals',
      'labelHi': 'रूहानी ग़ज़लें एवं नज़्म',
      'desc': 'Jagjit Singh, Ghulam Ali, Mehdi Hassan',
      'query': 'Jagjit Singh Ghazals timeless hits',
      'icon': Icons.auto_stories_rounded,
      'gradient': [Color(0xFF434343), Color(0xFF000000)],
    },
    {
      'key': 'indie_pop',
      'section': 'bollywood',
      'era': 'new',
      'labelEn': 'Indian Indie Pop',
      'labelHi': 'इंडी पॉप एवं स्वतंत्र संगीत',
      'desc': 'Fresh indie vibes: Prateek Kuhad, Anuv Jain, Jasleen',
      'query': 'Indian Indie Pop hits Anuv Jain Prateek Kuhad',
      'icon': Icons.mic_external_on_rounded,
      'gradient': [Color(0xFF00C9FF), Color(0xFF92FE9D)],
    },
    {
      'key': 'desi_hiphop',
      'section': 'bollywood',
      'era': 'new',
      'labelEn': 'Desi Hip-Hop & Rap',
      'labelHi': 'देसी हिप-हॉप एवं रैप',
      'desc': 'DIVINE, MC Stan, Seedhe Maut, Raftaar',
      'query': 'Desi Hip Hop Hindi Rap hits DIVINE',
      'icon': Icons.electric_bolt_rounded,
      'gradient': [Color(0xFFF12711), Color(0xFFF5AF19)],
    },

    // ----------------- PUNJABI -----------------
    {
      'key': 'punjabi_top',
      'section': 'punjabi',
      'era': 'new',
      'labelEn': 'Punjabi Top Hits',
      'labelHi': 'पंजाबी सुपरहिट्स',
      'desc': 'Sidhu Moose Wala, Karan Aujla, Diljit Dosanjh',
      'query': 'Punjabi Top Hits Karan Aujla Diljit Sidhu',
      'icon': Icons.bolt_rounded,
      'gradient': [Color(0xFF8A2387), Color(0xFFE94057)],
    },
    {
      'key': 'punjabi_bhangra',
      'section': 'punjabi',
      'era': 'all',
      'labelEn': 'Bhangra Beats & Dhol',
      'labelHi': 'धड़कते भांगड़ा बीट्स',
      'desc': 'Traditional folk dhol and pure energy',
      'query': 'Punjabi Bhangra beats dhol hits',
      'icon': Icons.music_note_rounded,
      'gradient': [Color(0xFFFF512F), Color(0xFFDD2476)],
    },
    {
      'key': 'punjabi_romantic',
      'section': 'punjabi',
      'era': 'new',
      'labelEn': 'Romantic Punjabi Melodies',
      'labelHi': 'मधुर पंजाबी प्यार भरे गीत',
      'desc': 'Heartwarming Punjabi love ballads',
      'query': 'Romantic Punjabi love songs hits',
      'icon': Icons.favorite_rounded,
      'gradient': [Color(0xFFFF6A00), Color(0xFFEE0979)],
    },
    {
      'key': 'punjabi_folk',
      'section': 'punjabi',
      'era': 'classic',
      'labelEn': 'Punjabi Folk & Virsa',
      'labelHi': 'विरासत एवं लोकगीत',
      'desc': 'Kuldeep Manak, Gurdas Maan, Surinder Kaur',
      'query': 'Gurdas Maan Punjabi folk virsa classics',
      'icon': Icons.landscape_rounded,
      'gradient': [Color(0xFFB993D6), Color(0xFF8CA6DB)],
    },

    // ----------------- DEVOTIONAL & SPIRITUAL -----------------
    {
      'key': 'devotional_shiv',
      'section': 'devotional',
      'era': 'all',
      'labelEn': 'Shiv Tandav & Mahadev',
      'labelHi': 'महाकाल एवं शिव भजन',
      'desc': 'Powerful Shiva stotram, tandav, and bhajans',
      'query': 'Shiv Tandav Mahadev Shiv Bhajan hits',
      'icon': Icons.brightness_7_rounded,
      'gradient': [Color(0xFF0F2027), Color(0xFF2C5364)],
    },
    {
      'key': 'devotional_krishna',
      'section': 'devotional',
      'era': 'all',
      'labelEn': 'Krishna Bhakti & Bhajan',
      'labelHi': 'राधे-कृष्ण मधुर भजन',
      'desc': 'Soul-soothing Vrindavan bhajans & kirtans',
      'query': 'Radha Krishna Bhakti Bhajan hits',
      'icon': Icons.park_rounded,
      'gradient': [Color(0xFF134E5E), Color(0xFF71B280)],
    },
    {
      'key': 'devotional_hanuman',
      'section': 'devotional',
      'era': 'all',
      'labelEn': 'Hanuman Chalisa & Aarti',
      'labelHi': 'श्री हनुमान चालीसा एवं संकटमोचन',
      'desc': 'Gulshan Kumar Hanuman Chalisa & Sundarkand',
      'query': 'Hanuman Chalisa Gulshan Kumar original',
      'icon': Icons.security_rounded,
      'gradient': [Color(0xFFFF8008), Color(0xFFFFC837)],
    },
    {
      'key': 'devotional_mata',
      'section': 'devotional',
      'era': 'all',
      'labelEn': 'Durga Mata Ki Bhetein',
      'labelHi': 'माता रानी की आरती व भेंटें',
      'desc': 'Vaishno Devi bhajans & Narendra Chanchal',
      'query': 'Mata Ki Bhetein Narendra Chanchal Gulshan Kumar',
      'icon': Icons.wb_twilight_rounded,
      'gradient': [Color(0xFFED213A), Color(0xFF93291E)],
    },
    {
      'key': 'devotional_sai',
      'section': 'devotional',
      'era': 'all',
      'labelEn': 'Sai Sandhya & Bhajans',
      'labelHi': 'साईं नाथ की कृपा एवं भजन',
      'desc': 'Peaceful Shirdi Sai Baba devotional songs',
      'query': 'Sai Baba Bhajan Shirdi Sandhya',
      'icon': Icons.wb_incandescent_rounded,
      'gradient': [Color(0xFFF3904F), Color(0xFF3B4371)],
    },
    {
      'key': 'devotional_gurbani',
      'section': 'devotional',
      'era': 'all',
      'labelEn': 'Sacred Gurbani Kirtan',
      'labelHi': 'पवित्र गुरबाणी कीर्तन',
      'desc': 'Golden Temple live shabad and simran',
      'query': 'Gurbani Kirtan Golden Temple Shabad',
      'icon': Icons.temple_hindu_rounded,
      'gradient': [Color(0xFFF09819), Color(0xFFEDDE5D)],
    },
    {
      'key': 'devotional_sufi',
      'section': 'devotional',
      'era': 'all',
      'labelEn': 'Sufi Qawwali & Kalam',
      'labelHi': 'सूफ़ी कव्वाली एवं कलाम',
      'desc': 'Nusrat Fateh Ali Khan, Sabri Brothers, Rahat',
      'query': 'Nusrat Fateh Ali Khan Sufi Qawwali hits',
      'icon': Icons.all_inclusive_rounded,
      'gradient': [Color(0xFF434343), Color(0xFF000000)],
    },
    {
      'key': 'devotional_ganesh',
      'section': 'devotional',
      'era': 'all',
      'labelEn': 'Ganesh Vandana & Aarti',
      'labelHi': 'गणपति बाप्पा मोरया आरती',
      'desc': 'Auspicious Ganpati aartis & stutis',
      'query': 'Ganesh Vandana Aarti Sukhkarta Dukhharta',
      'icon': Icons.spa_rounded,
      'gradient': [Color(0xFFFF4E50), Color(0xFFF9D423)],
    },

    // ----------------- MOODS & LIFESTYLE -----------------
    {
      'key': 'mood_lofi',
      'section': 'mood',
      'era': 'new',
      'labelEn': 'Lo-Fi Chill & Aesthetics',
      'labelHi': 'शांत एवं सुकून भरे लो-फाई धुन',
      'desc': 'Slowed & reverb aesthetic midnight sounds',
      'query': 'Hindi lofi chill slowed and reverb hits',
      'icon': Icons.nightlight_round,
      'gradient': [Color(0xFF2B5876), Color(0xFF4E4376)],
    },
    {
      'key': 'mood_latenight',
      'section': 'mood',
      'era': 'new',
      'labelEn': 'Late Night Long Drive',
      'labelHi': 'देर रात की सुहानी यात्रा',
      'desc': 'Atmospheric, breezy soundtracks for night roads',
      'query': 'Late night drive Hindi chill songs',
      'icon': Icons.directions_car_rounded,
      'gradient': [Color(0xFF0F2027), Color(0xFF203A43)],
    },
    {
      'key': 'mood_gym',
      'section': 'mood',
      'era': 'new',
      'labelEn': 'Gym & Workout Motivation',
      'labelHi': 'ऊर्जावान जिम एवं वर्कआउट',
      'desc': 'Adrenaline-pumping beats for breaking limits',
      'query': 'Gym workout motivation high bass songs',
      'icon': Icons.fitness_center_rounded,
      'gradient': [Color(0xFF11998E), Color(0xFF38EF7D)],
    },
    {
      'key': 'mood_meditation',
      'section': 'mood',
      'era': 'all',
      'labelEn': 'Meditation 432Hz & Peace',
      'labelHi': 'ध्यान एवं मानसिक शांति 432Hz',
      'desc': 'Flute, sitar, nature sounds, and healing frequencies',
      'query': 'Indian Flute Meditation peaceful relaxation',
      'icon': Icons.self_improvement_rounded,
      'gradient': [Color(0xFF1D976C), Color(0xFF93F9B9)],
    },
    {
      'key': 'mood_study',
      'section': 'mood',
      'era': 'new',
      'labelEn': 'Study & Deep Concentration',
      'labelHi': 'पढ़ाई एवं एकाग्रता संगीत',
      'desc': 'Calm, unobtrusive background music for productivity',
      'query': 'Study focus concentration instrumental Hindi',
      'icon': Icons.menu_book_rounded,
      'gradient': [Color(0xFF3A6073), Color(0xFF3A7BD5)],
    },
    {
      'key': 'mood_bass',
      'section': 'mood',
      'era': 'new',
      'labelEn': 'Bass Boosted Car Audio',
      'labelHi': 'अल्ट्रा बेस बूस्टेड कार मिक्स',
      'desc': 'Subwoofer-testing deep bass frequencies',
      'query': 'Bass boosted car audio remix Indian',
      'icon': Icons.volume_up_rounded,
      'gradient': [Color(0xFFD31027), Color(0xFFEA384D)],
    },

    // ----------------- REGIONAL FOLK & LANGUAGES -----------------
    {
      'key': 'regional_haryanvi',
      'section': 'regional',
      'era': 'all',
      'labelEn': 'Haryanvi Ragni & Hits',
      'labelHi': 'हरियाणवी रागनी एवं गाने',
      'desc': 'High-power Haryanvi chartbusters & folk ragnis',
      'query': 'Haryanvi top superhit songs',
      'icon': Icons.campaign_rounded,
      'gradient': [Color(0xFFE53935), Color(0xFFFFB74D)],
    },
    {
      'key': 'regional_rajasthani',
      'section': 'regional',
      'era': 'classic',
      'labelEn': 'Rajasthani Folk & Ghoomar',
      'labelHi': 'राजस्थानी घूमर एवं लोकगीत',
      'desc': 'Vibrant desert melodies and royal folk songs',
      'query': 'Rajasthani Folk Ghoomar hits',
      'icon': Icons.landscape_rounded,
      'gradient': [Color(0xFFFF8F00), Color(0xFFFFD54F)],
    },
    {
      'key': 'regional_gujarati',
      'section': 'regional',
      'era': 'all',
      'labelEn': 'Gujarati Garba & Raas',
      'labelHi': 'गुजराती गरबा एवं डांडिया रास',
      'desc': 'Nonstop Navratri garba and Gujarati folk',
      'query': 'Gujarati Garba nonstop hits Dandiya',
      'icon': Icons.festival_rounded,
      'gradient': [Color(0xFF8E24AA), Color(0xFFBA68C8)],
    },
    {
      'key': 'regional_marathi',
      'section': 'regional',
      'era': 'all',
      'labelEn': 'Marathi Lavani & Bhavgeet',
      'labelHi': 'मराठी लावणी एवं भावगीत',
      'desc': 'Culturally rich Marathi folk, lavani, and natyageet',
      'query': 'Marathi Superhit Songs Lavani Bhavgeet',
      'icon': Icons.theater_comedy_rounded,
      'gradient': [Color(0xFFD81B60), Color(0xFFFF4081)],
    },
    {
      'key': 'regional_bengali',
      'section': 'regional',
      'era': 'classic',
      'labelEn': 'Bengali Rabindra Sangeet',
      'labelHi': 'रवींद्र संगीत एवं बांग्ला गान',
      'desc': 'Timeless poems of Tagore and modern Bengali hits',
      'query': 'Rabindra Sangeet timeless Bengali hits',
      'icon': Icons.book_rounded,
      'gradient': [Color(0xFF00897B), Color(0xFF4DB6AC)],
    },
    {
      'key': 'regional_south',
      'section': 'regional',
      'era': 'new',
      'labelEn': 'South Superhits (Tamil/Telugu/Malayalam)',
      'labelHi': 'साउथ सुपरहिट्स (तमिल/तेलुगू/मलयालम)',
      'desc': 'Anirudh, AR Rahman, DSP, Thaman blockbuster hits',
      'query': 'South Indian Superhit songs Tamil Telugu Malayalam',
      'icon': Icons.star_rounded,
      'gradient': [Color(0xFF1E88E5), Color(0xFF64B5F6)],
    },
    {
      'key': 'regional_maithili',
      'section': 'regional',
      'era': 'classic',
      'labelEn': 'Maithili Vidyapati & Folk',
      'labelHi': 'मैथिली विद्यापति एवं लोकगीत',
      'desc': 'Melodious Mithila culture and festive folk',
      'query': 'Maithili Lokgeet Vidyapati songs hits',
      'icon': Icons.temple_buddhist_rounded,
      'gradient': [Color(0xFFF4511E), Color(0xFFFF8A65)],
    },
    {
      'key': 'regional_odia',
      'section': 'regional',
      'era': 'all',
      'labelEn': 'Odia Sambalpuri Hits',
      'labelHi': 'ओड़िया संबलपुरी धुनें',
      'desc': 'Catchy rhythms of Sambalpuri and Odia melodies',
      'query': 'Odia Sambalpuri superhit songs',
      'icon': Icons.music_video_rounded,
      'gradient': [Color(0xFF43A047), Color(0xFFAED581)],
    },
    {
      'key': 'regional_assamese',
      'section': 'regional',
      'era': 'all',
      'labelEn': 'Assamese Bihu Geet',
      'labelHi': 'असमिया बिहू संगीत',
      'desc': 'Joyous spring festival rhythms of Assam',
      'query': 'Assamese Bihu songs hits',
      'icon': Icons.eco_rounded,
      'gradient': [Color(0xFF5E35B1), Color(0xFF9575CD)],
    },
  ];

  List<Map<String, dynamic>> get _filteredCategories {
    return allCategories.where((c) {
      if (_selectedSection != 'all' && c['section'] != _selectedSection) {
        return false;
      }
      if (_selectedEra != 'all' && c['era'] != 'all' && c['era'] != _selectedEra) {
        return false;
      }
      return true;
    }).toList();
  }

  void _openCategory(BuildContext context, Map<String, dynamic> cat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryDetailScreen(
          category: cat,
          audioHandler: widget.audioHandler,
        ),
      ),
    );
  }


  String _getCategoryImageUrl(Map<String, dynamic> cat) {
    final key = (cat['key'] ?? '').toString().toLowerCase();
    final section = (cat['section'] ?? '').toString().toLowerCase();

    if (key.contains('chhath')) return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&q=80';
    if (key.contains('dj') || key.contains('party') || key.contains('club')) return 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&q=80';
    if (key.contains('bolbam') || key.contains('devi') || section == 'devotional' || key.contains('bhakti') || key.contains('aarti')) return 'https://images.unsplash.com/photo-1609342122563-a43ac8917a3a?w=500&q=80';
    if (key.contains('romantic') || key.contains('love')) return 'https://images.unsplash.com/photo-1518495973542-4542c06a5843?w=500&q=80';
    if (key.contains('lofi') || key.contains('chill')) return 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=500&q=80';
    if (key.contains('retro') || key.contains('90s') || key.contains('classic') || key.contains('birha')) return 'https://images.unsplash.com/photo-1539375665275-f9de415ef9ac?w=500&q=80';
    if (key.contains('gym') || key.contains('workout')) return 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=500&q=80';
    if (section == 'punjabi') return 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=500&q=80';
    if (section == 'bollywood') return 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&q=80';

    return 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_theme, _lang]),
      builder: (context, _) {
        final textColor = _theme.textColor;
        final subtextColor = _theme.subtextColor;
        final primaryColor = _theme.primaryColor;
        final isHindi = _lang.isHindi;

        final sections = [
          {'key': 'all', 'label': isHindi ? 'सभी श्रेणियां' : 'All Categories'},
          {'key': 'bhojpuri', 'label': isHindi ? 'भोजपुरी स्पेशल' : 'Bhojpuri Special'},
          {'key': 'bollywood', 'label': isHindi ? 'बॉलीवुड एवं रेट्रो' : 'Bollywood & Retro'},
          {'key': 'punjabi', 'label': isHindi ? 'पंजाबी' : 'Punjabi'},
          {'key': 'devotional', 'label': isHindi ? 'भक्ति एवं भजन' : 'Devotional'},
          {'key': 'mood', 'label': isHindi ? 'मूड एवं सुकून' : 'Mood & Vibe'},
          {'key': 'regional', 'label': isHindi ? 'क्षेत्रीय लोकगीत' : 'Regional Folk'},
        ];

        final eras = [
          {'key': 'all', 'label': isHindi ? 'सभी' : 'All Eras'},
          {'key': 'new', 'label': isHindi ? 'नए गाने (New Hits)' : 'New Hits'},
          {'key': 'classic', 'label': isHindi ? 'सदाबहार पुराने (Classics)' : 'Classics'},
        ];

        final categories = _filteredCategories;

        return Column(
          children: [
            // Section Category Filter Pills Row
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: sections.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final s = sections[i];
                  final isSelected = s['key'] == _selectedSection;

                  return FilterChip(
                    label: Text(s['label']!),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? primaryColor : Colors.white12),
                    ),
                    onSelected: (val) {
                      setState(() => _selectedSection = s['key']!);
                    },
                  );
                },
              ),
            ),

            // Era Filter Pills (All / New Hits / Classics)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.filter_list_rounded, size: 16, color: subtextColor),
                  const SizedBox(width: 6),
                  Text(
                    isHindi ? 'फिल्टर:' : 'Filter:',
                    style: TextStyle(color: subtextColor, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: eras.map((e) {
                          final isSelected = e['key'] == _selectedEra;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () => setState(() => _selectedEra = e['key']!),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSelected ? const Color(0xFF00E5FF) : Colors.white12),
                                ),
                                child: Text(
                                  e['label']!,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF00E5FF) : subtextColor,
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Text(
                    '${categories.length} ${isHindi ? "श्रेणियां" : "Genres"}',
                    style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // 3D Frosted Glass Category Cards Grid
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final List<Color> gradient = cat['gradient'] as List<Color>;

                  return Tactile3DWrapper(
                    onTap: () => _openCategory(context, cat),
                    scaleElevation: 1.06,
                    borderRadius: BorderRadius.circular(16),
                    glowColor: gradient[0],
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 1. Related Genre Background Image
                            Image.network(
                              _getCategoryImageUrl(cat),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: gradient[0].withOpacity(0.6),
                              ),
                            ),
                            // 2. Legibility Dark Gradient Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    gradient[0].withOpacity(0.85),
                                    Colors.black.withOpacity(0.88),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            // 3. Category Content (Icon, Label, Description)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white24, width: 0.8),
                                        ),
                                        child: Icon(cat['icon'] as IconData, color: Colors.white, size: 20),
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 12),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isHindi ? (cat['labelHi'] as String) : (cat['labelEn'] as String),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.2,
                                          shadows: [
                                            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        cat['desc'] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 10,
                                          shadows: const [
                                            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==============================================================================
// CATEGORY DETAIL SCREEN (Instant playback, Play All, Shuffle, Downloads)
// ==============================================================================
class CategoryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> category;
  final AbhiAudioHandler audioHandler;

  const CategoryDetailScreen({
    Key? key,
    required this.category,
    required this.audioHandler,
  }) : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final MusicService _musicService = MusicService();
  final DownloadService _downloadService = DownloadService();
  final LanguageService _lang = LanguageService();
  final ThemeService _theme = ThemeService();

  List<SongModel> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategorySongs();
  }

  Future<void> _loadCategorySongs() async {
    final query = widget.category['query'] as String;
    try {
      final res = await PerformanceGuard.safeAsync<List<SongModel>>(
        _musicService.searchSongs(query),
        timeout: const Duration(seconds: 7),
        fallback: <SongModel>[],
      );
      if (mounted) {
        setState(() {
          _songs = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _playSongOnly(SongModel song) {
    final currentId = widget.audioHandler.mediaItem.value?.id;
    if (currentId == song.id) {
      final isPlaying = widget.audioHandler.playbackState.value.playing;
      isPlaying ? widget.audioHandler.pause() : widget.audioHandler.play();
    } else {
      widget.audioHandler.playSong(song, queue: _songs);
    }
  }

  void _playSong(SongModel song) {
    final currentId = widget.audioHandler.mediaItem.value?.id;
    if (currentId != song.id) {
      widget.audioHandler.playSong(song, queue: _songs);
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NowPlayingScreen(audioHandler: widget.audioHandler),
      ),
    );
  }

  void _playAll() {
    if (_songs.isNotEmpty) {
      widget.audioHandler.playSong(_songs.first, queue: _songs);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NowPlayingScreen(audioHandler: widget.audioHandler),
        ),
      );
    }
  }

  void _shuffleAll() {
    if (_songs.isNotEmpty) {
      final copy = List<SongModel>.from(_songs)..shuffle();
      widget.audioHandler.playSong(copy.first, queue: copy);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NowPlayingScreen(audioHandler: widget.audioHandler),
        ),
      );
    }
  }

  void _downloadSong(SongModel song) async {
    final success = await _downloadService.downloadSong(song);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? const Color(0xFF00E676) : Colors.redAccent,
          content: Text(
            success
                ? (_lang.isHindi ? '"${song.title}" डाउनलोड हो गया!' : '"${song.title}" downloaded!')
                : (_lang.isHindi ? 'डाउनलोड विफल रहा।' : 'Download failed.'),
          ),
        ),
      );
    }
  }


  String _getCategoryImageUrl(Map<String, dynamic> cat) {
    final key = (cat['key'] ?? '').toString().toLowerCase();
    final section = (cat['section'] ?? '').toString().toLowerCase();

    if (key.contains('chhath')) return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&q=80';
    if (key.contains('dj') || key.contains('party') || key.contains('club')) return 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&q=80';
    if (key.contains('bolbam') || key.contains('devi') || section == 'devotional' || key.contains('bhakti') || key.contains('aarti')) return 'https://images.unsplash.com/photo-1609342122563-a43ac8917a3a?w=500&q=80';
    if (key.contains('romantic') || key.contains('love')) return 'https://images.unsplash.com/photo-1518495973542-4542c06a5843?w=500&q=80';
    if (key.contains('lofi') || key.contains('chill')) return 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=500&q=80';
    if (key.contains('retro') || key.contains('90s') || key.contains('classic') || key.contains('birha')) return 'https://images.unsplash.com/photo-1539375665275-f9de415ef9ac?w=500&q=80';
    if (key.contains('gym') || key.contains('workout')) return 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=500&q=80';
    if (section == 'punjabi') return 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=500&q=80';
    if (section == 'bollywood') return 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&q=80';

    return 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80';
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = _lang.isHindi;
    final title = isHindi ? (widget.category['labelHi'] as String) : (widget.category['labelEn'] as String);
    final desc = widget.category['desc'] as String;
    final List<Color> gradient = widget.category['gradient'] as List<Color>;
    final primaryColor = _theme.primaryColor;
    final textColor = _theme.textColor;
    final subtextColor = _theme.subtextColor;

    return Scaffold(
      backgroundColor: _theme.scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            pinned: true,
            backgroundColor: gradient[0].withOpacity(0.9),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      desc,
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_songs.length} ${isHindi ? "गाने उपलब्ध" : "songs available"}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action Buttons Bar (Play All / Shuffle All)
          if (!_isLoading && _songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: Text(
                          isHindi ? 'सभी बजाएं' : 'Play All',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: _playAll,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: Icon(Icons.shuffle_rounded, size: 20, color: primaryColor),
                        label: Text(
                          isHindi ? 'शफ़ल प्ले' : 'Shuffle',
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: _shuffleAll,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                ),
              ),
            )
          else if (_songs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  isHindi ? 'गाने लोड नहीं हो सके। पुनः प्रयास करें।' : 'No songs available.',
                  style: TextStyle(color: subtextColor),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 90),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = _songs[index];
                    return StreamBuilder<MediaItem?>(
                      stream: widget.audioHandler.mediaItem,
                      builder: (context, mediaSnap) {
                        final isCurrentTrack = mediaSnap.data?.id == song.id;
                        final isPlaying = isCurrentTrack && widget.audioHandler.playbackState.value.playing;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isCurrentTrack ? primaryColor : subtextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.network(
                                      song.thumbnailUrl,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 48,
                                        height: 48,
                                        color: Colors.grey.shade900,
                                        child: const Icon(Icons.music_note_rounded, color: Colors.white54),
                                      ),
                                    ),
                                    if (isCurrentTrack)
                                      Container(
                                        width: 48,
                                        height: 48,
                                        color: Colors.black.withOpacity(0.4),
                                        child: Icon(Icons.equalizer_rounded, color: primaryColor, size: 24),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrentTrack ? primaryColor : textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: subtextColor, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.download_rounded, size: 22),
                                color: subtextColor,
                                tooltip: _lang.t('download'),
                                onPressed: () => _downloadSong(song),
                              ),
                              IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_fill_rounded,
                                  color: isCurrentTrack ? primaryColor : primaryColor,
                                  size: 32,
                                ),
                                onPressed: () => _playSongOnly(song),
                              ),
                            ],
                          ),
                          onTap: () => _playSong(song),
                        );
                      },
                    );
                  },
                  childCount: _songs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

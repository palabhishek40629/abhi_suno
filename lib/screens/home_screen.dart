import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/download_service.dart';
import '../services/language_service.dart';
import '../services/music_service.dart';
import '../services/performance_guard.dart';
import '../services/playback_history_service.dart';
import '../services/theme_service.dart';
import '../services/favorites_service.dart';
import '../widgets/screen_bubble_celebration.dart';
import 'now_playing_screen.dart';
import '../widgets/tactile_3d_wrapper.dart';

class HomeScreen extends StatefulWidget {
  final AbhiAudioHandler audioHandler;

  const HomeScreen({Key? key, required this.audioHandler}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MusicService _musicService = MusicService();
  final DownloadService _downloadService = DownloadService();
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();
  final PlaybackHistoryService _historyService = PlaybackHistoryService();
  final FavoritesService _favoritesService = FavoritesService();
  final ScrollController _scrollController = ScrollController();

  List<SongModel> _trendingHindi = [];
  List<SongModel> _bollywoodRomantic = [];
  List<SongModel> _retroClassics = [];
  List<SongModel> _punjabiHits = [];
  List<SongModel> _hindiLofi = [];
  List<SongModel> _artistSongs = [];
  
  // Infinite Feed Pool
  final List<SongModel> _infiniteFeedSongs = [];
  final Set<String> _seenSongIds = {};
  int _feedQueryIndex = 0;
  bool _isLoadingMore = false;
  bool _isOfflineDetected = false;
  String _userName = 'Abhishek Pal';
  String _activeChip = 'all';
  bool _isContinueDismissed = false;
  String _cachedArtistQuery = '';

  // Rich Discovery Queries for Endless Fast Scroll (100% Verified against JioSaavn Index)
  static const List<String> _infiniteQueryPool = [
    'Top Bollywood Songs',
    'Arijit Singh Melodies',
    'Atif Aslam Romance',
    'Top Punjabi Songs',
    '90s Hindi Hits',
    'Shreya Ghoshal Pure Vocals',
    'Hindi Indie Hits',
    'Coke Studio Hits',
    'Sidhu Moose Wala Bangers',
    'Pritam Mega Hits',
    'A.R. Rahman Soulful',
    'Bhakti Devotional Essentials',
    'EDM Bollywood Remix',
    'Unplugged Hindi Covers',
    'Kishore Kumar Evergreen Classics',
    'Lata Mangeshkar Masterpieces',
    'Mohammed Rafi Superhits',
    'Sonu Nigam Heartfelt Melodies',
    'Anuv Jain Songs',
    'Darshan Raval Love Ballads',
    'Jubin Nautiyal Peaceful Beats',
    'King Desi Hip Hop',
    'Honey Singh Hits',
  ];

  @override
  void initState() {
    super.initState();
    _loadInstantStarterTracks();
    _refreshLiveTrending();
    _loadUserProfile();
    _historyService.addListener(_onHistoryUpdated);
    _loadMoreByArtist();

    // Preload first batch of infinite dynamic feed
    _loadNextInfiniteFeedBatch();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
        _loadNextInfiniteFeedBatch();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _historyService.removeListener(_onHistoryUpdated);
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_custom_profile_name');
      if (mounted && name != null && name.trim().isNotEmpty) {
        setState(() => _userName = name.trim());
      }
    } catch (_) {}
  }

  void _onHistoryUpdated() {
    if (mounted) {
      setState(() {});
      _loadMoreByArtist();
    }
  }

  Future<void> _loadMoreByArtist() async {
    final lastSong = _historyService.lastPlayedSong;
    if (lastSong == null) return;
    final primaryArtist = lastSong.artist.split(',').first.split('&').first.trim();
    if (primaryArtist.isEmpty || primaryArtist == _cachedArtistQuery) return;

    _cachedArtistQuery = primaryArtist;
    try {
      final songs = await PerformanceGuard.safeAsync<List<SongModel>>(
        _musicService.searchSongs(primaryArtist),
        timeout: const Duration(seconds: 5),
        fallback: <SongModel>[],
      );
      if (mounted) {
        setState(() {
          _artistSongs = songs.where((s) => s.id != lastSong.id).take(10).toList();
        });
      }
    } catch (_) {}
  }

  // Infinite Seamless Continuous Feed Loader
  Future<void> _loadNextInfiniteFeedBatch() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final query = _infiniteQueryPool[_feedQueryIndex % _infiniteQueryPool.length];
      _feedQueryIndex++;

      final songs = await PerformanceGuard.safeAsync<List<SongModel>>(
        _musicService.searchSongs(query),
        timeout: const Duration(seconds: 5),
        fallback: <SongModel>[],
      );

      if (mounted) {
        final newTracks = <SongModel>[];
        for (final s in songs) {
          if (!_seenSongIds.contains(s.id)) {
            _seenSongIds.add(s.id);
            newTracks.add(s);
          }
        }
        setState(() {
          _infiniteFeedSongs.addAll(newTracks);
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _loadInstantStarterTracks() {
    setState(() {
      _trendingHindi = [
        SongModel(
          id: 'rjkrTnma',
          title: 'Kesariya',
          artist: 'Pritam, Arijit Singh, Amitabh Bhattacharya',
          album: 'Brahmastra',
          duration: const Duration(minutes: 4, seconds: 28),
          thumbnailUrl: 'https://c.saavncdn.com/871/Brahmastra-Original-Motion-Picture-Soundtrack-Hindi-2022-20221006155213-500x500.jpg',
        ),
        SongModel(
          id: 'qZtKBMZ_',
          title: 'Apna Bana Le',
          artist: 'Sachin-Jigar, Arijit Singh',
          album: 'Bhediya',
          duration: const Duration(minutes: 4, seconds: 21),
          thumbnailUrl: 'https://c.saavncdn.com/815/Bhediya-Hindi-2023-20230927155213-500x500.jpg',
        ),
        SongModel(
          id: 'NIidiD9g',
          title: 'Heeriye',
          artist: 'Jasleen Royal, Arijit Singh',
          album: 'Heeriye',
          duration: const Duration(minutes: 3, seconds: 14),
          thumbnailUrl: 'https://c.saavncdn.com/022/Heeriye-feat-Arijit-Singh-Hindi-2023-20230928050405-500x500.jpg',
        ),
        SongModel(
          id: 'faloMmjX',
          title: 'Chaleya',
          artist: 'Anirudh Ravichander, Arijit Singh, Shilpa Rao',
          album: 'Jawan',
          duration: const Duration(minutes: 3, seconds: 20),
          thumbnailUrl: 'https://c.saavncdn.com/047/Jawan-Hindi-2023-20230921190854-500x500.jpg',
        ),
        SongModel(
          id: 'wcsDiSsA',
          title: 'O Maahi',
          artist: 'Pritam, Arijit Singh, Irshad Kamil',
          album: 'Dunki',
          duration: const Duration(minutes: 3, seconds: 53),
          thumbnailUrl: 'https://c.saavncdn.com/139/Dunki-Hindi-2023-20231220211003-500x500.jpg',
        ),
      ];

      for (final s in _trendingHindi) {
        _seenSongIds.add(s.id);
      }

      _bollywoodRomantic = [
        SongModel(
          id: 'aRZbUYD7',
          title: 'Tum Hi Ho',
          artist: 'Mithoon, Arijit Singh',
          album: 'Aashiqui 2',
          duration: const Duration(minutes: 4, seconds: 22),
          thumbnailUrl: 'https://c.saavncdn.com/430/Aashiqui-2-Hindi-2013-500x500.jpg',
        ),
        SongModel(
          id: 'mPTrDSun',
          title: 'Raataan Lambiyan',
          artist: 'Tanishk Bagchi, Jubin Nautiyal, Asees Kaur',
          album: 'Shershaah',
          duration: const Duration(minutes: 3, seconds: 50),
          thumbnailUrl: 'https://c.saavncdn.com/238/Shershaah-Original-Motion-Picture-Soundtrack--Hindi-2021-20210815181610-500x500.jpg',
        ),
        SongModel(
          id: '1e0En7YX',
          title: 'Pehle Bhi Main',
          artist: 'Vishal Mishra, Raj Shekhar',
          album: 'ANIMAL',
          duration: const Duration(minutes: 4, seconds: 10),
          thumbnailUrl: 'https://c.saavncdn.com/092/ANIMAL-Hindi-2023-20260724191152-500x500.jpg',
        ),
        SongModel(
          id: 'Ni6noMmw',
          title: 'Agar Tum Saath Ho',
          artist: 'Alka Yagnik, Arijit Singh',
          album: 'Tamasha',
          duration: const Duration(minutes: 5, seconds: 41),
          thumbnailUrl: 'https://c.saavncdn.com/994/Tamasha-Hindi-2015-500x500.jpg',
        ),
      ];

      _retroClassics = [
        SongModel(
          id: 'IK_LkHAT',
          title: 'Yeh Sham Mastani',
          artist: 'Kishore Kumar, R.D. Burman',
          album: 'Kati Patang',
          duration: const Duration(minutes: 4, seconds: 35),
          thumbnailUrl: 'https://c.saavncdn.com/715/Kati-Patang-Hindi-1970-500x500.jpg',
        ),
        SongModel(
          id: 'HAhzpmwM',
          title: 'Mere Sapnon Ki Rani',
          artist: 'Kishore Kumar',
          album: 'Aradhana',
          duration: const Duration(minutes: 5, seconds: 0),
          thumbnailUrl: 'https://c.saavncdn.com/951/Aradhana-Hindi-1969-500x500.jpg',
        ),
        SongModel(
          id: 'CPg5xoka',
          title: 'Lag Ja Gale Se Phir',
          artist: 'Lata Mangeshkar, Madan Mohan',
          album: 'Woh Kaun Thi',
          duration: const Duration(minutes: 4, seconds: 18),
          thumbnailUrl: 'https://c.saavncdn.com/834/Woh-Kaun-Thi-Hindi-1964-20251103094113-500x500.jpg',
        ),
      ];

      _punjabiHits = [
        SongModel(
          id: 'H2r9PnvA',
          title: '295',
          artist: 'Sidhu Moose Wala',
          album: 'Moosetape',
          duration: const Duration(minutes: 4, seconds: 30),
          thumbnailUrl: 'https://c.saavncdn.com/609/Moosetape-Punjabi-2021-20260626155141-500x500.jpg',
        ),
        SongModel(
          id: 'iMzGQX6_',
          title: 'Softly',
          artist: 'Karan Aujla, IKKY',
          album: 'Making Memories',
          duration: const Duration(minutes: 2, seconds: 35),
          thumbnailUrl: 'https://c.saavncdn.com/538/Making-Memories-English-2023-20230818075015-500x500.jpg',
        ),
      ];

      _hindiLofi = [
        SongModel(
          id: '3Be_U0qz',
          title: 'Iktara',
          artist: 'Amit Trivedi, Kavita Seth',
          album: 'Wake Up Sid',
          duration: const Duration(minutes: 4, seconds: 13),
          thumbnailUrl: 'https://c.saavncdn.com/910/Wake-Up-Sid-Hindi-2009-20190617160255-500x500.jpg',
        ),
        SongModel(
          id: 'Cyu6QA-C',
          title: 'Kabira',
          artist: 'Pritam, Tochi Raina, Rekha Bhardwaj',
          album: 'Yeh Jawaani Hai Deewani',
          duration: const Duration(minutes: 4, seconds: 29),
          thumbnailUrl: 'https://c.saavncdn.com/440/Yeh-Jawaani-Hai-Deewani-2013-500x500.jpg',
        ),
      ];
    });
  }

  Future<void> _refreshLiveTrending() async {
    try {
      final results = await Future.wait([
        PerformanceGuard.safeAsync<List<SongModel>>(_musicService.getTrendingHindi(), timeout: const Duration(seconds: 5), fallback: <SongModel>[]),
        PerformanceGuard.safeAsync<List<SongModel>>(_musicService.getBollywoodRomantic(), timeout: const Duration(seconds: 5), fallback: <SongModel>[]),
        PerformanceGuard.safeAsync<List<SongModel>>(_musicService.getRetroClassics(), timeout: const Duration(seconds: 5), fallback: <SongModel>[]),
        PerformanceGuard.safeAsync<List<SongModel>>(_musicService.getPunjabiHits(), timeout: const Duration(seconds: 5), fallback: <SongModel>[]),
        PerformanceGuard.safeAsync<List<SongModel>>(_musicService.getHindiLofi(), timeout: const Duration(seconds: 5), fallback: <SongModel>[]),
      ]);

      if (mounted) {
        setState(() {
          if (results[0].isNotEmpty) _trendingHindi = results[0];
          if (results[1].isNotEmpty) _bollywoodRomantic = results[1];
          if (results[2].isNotEmpty) _retroClassics = results[2];
          if (results[3].isNotEmpty) _punjabiHits = results[3];
          if (results[4].isNotEmpty) _hindiLofi = results[4];
          _isOfflineDetected = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isOfflineDetected = true);
      }
    }
  }

  // Play song without opening Now Playing screen (Play Button tap)
  void _playSongOnly(SongModel song, List<SongModel> queue) {
    final currentId = widget.audioHandler.mediaItem.value?.id;
    if (currentId == song.id) {
      final isPlaying = widget.audioHandler.playbackState.value.playing;
      isPlaying ? widget.audioHandler.pause() : widget.audioHandler.play();
    } else {
      widget.audioHandler.playSong(song, queue: queue);
    }
  }

  // Instant Play & Automatic Fullscreen Player Open (Song Tile tap)
  void _playTrack(SongModel song, List<SongModel> queue) {
    final currentId = widget.audioHandler.mediaItem.value?.id;
    if (currentId != song.id) {
      widget.audioHandler.playSong(song, queue: queue);
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NowPlayingScreen(audioHandler: widget.audioHandler),
      ),
    );
  }

  // Time-of-Day AI Smart Playlist Metadata
  Map<String, String> _getTimeOfDayMixInfo() {
    final hour = DateTime.now().hour;
    final isHindi = _lang.isHindi;

    if (hour >= 5 && hour < 12) {
      return {
        'greeting': isHindi ? 'सुप्रभात, $_userName!' : 'Good Morning, $_userName!',
        'title': isHindi ? 'मॉर्निंग एनर्जी एवं फ्रेश वाइब्स' : 'Morning Energy & Fresh Vibes',
        'subtitle': isHindi ? 'दिन की शानदार शुरुआत के लिए ऊर्जावान गीत' : 'Upbeat melodies to kickstart your day',
        'icon': '🌅',
        'badge': 'MORNING AI MIX',
      };
    } else if (hour >= 12 && hour < 17) {
      return {
        'greeting': isHindi ? 'शुभ दोपहर, $_userName!' : 'Good Afternoon, $_userName!',
        'title': isHindi ? 'आफ्टरनून फोकस एवं एकॉस्टिक चिल' : 'Afternoon Focus & Acoustic Chill',
        'subtitle': isHindi ? 'काम और पढ़ाई के बीच सुकून भरे सुरीले गीत' : 'Peaceful acoustic tunes to keep you focused',
        'icon': '☀️',
        'badge': 'FOCUS AI MIX',
      };
    } else if (hour >= 17 && hour < 21) {
      return {
        'greeting': isHindi ? 'शुभ संध्या, $_userName!' : 'Good Evening, $_userName!',
        'title': isHindi ? 'सनसेट अनप्लग्ड एवं गोल्डन क्लासिक्स' : 'Sunset Unplugged & Golden Classics',
        'subtitle': isHindi ? 'शाम की चाय और यादों के संग सदाबहार धुनें' : 'Golden melodies to unwind and reflect',
        'icon': '🌆',
        'badge': 'SUNSET AI MIX',
      };
    } else {
      return {
        'greeting': isHindi ? 'शुभ रात्रि, $_userName!' : 'Night Vibes, $_userName!',
        'title': isHindi ? 'मिडनाइट लो-फाई एवं सुकून भरी रात' : 'Midnight Lo-Fi & Soulful Dreams',
        'subtitle': isHindi ? 'गहरी नींद और सुकून के लिए धीमा संगीत' : 'Slowed & reverbed lo-fi for sweet dreams',
        'icon': '🌙',
        'badge': 'MIDNIGHT AI MIX',
      };
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
        const primaryCyan = Color(0xFF00E5FF);
        const primaryPink = Color(0xFFFF2A6D);
        final isHindi = _lang.isHindi;

        final chips = [
          {'key': 'all', 'label': isHindi ? 'सभी' : 'All'},
          {'key': 'trending', 'label': _lang.t('trending')},
          {'key': 'romantic', 'label': _lang.t('romantic')},
          {'key': 'retro', 'label': _lang.t('retro_classics')},
          {'key': 'punjabi', 'label': _lang.t('punjabi')},
          {'key': 'lofi', 'label': _lang.t('lofi')},
        ];

        final timeMix = _getTimeOfDayMixInfo();

        return RefreshIndicator(
          onRefresh: _refreshLiveTrending,
          color: primaryCyan,
          backgroundColor: cardColor,
          child: ListView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 90),
            children: [
              // Offline Notice Banner
              if (_isOfflineDetected)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isHindi ? 'ऑफलाइन मोड: इंटरनेट उपलब्ध नहीं है।' : 'Offline Mode: You are offline.',
                          style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              // Filter Chips Row
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: chips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final chip = chips[i];
                    final isSelected = chip['key'] == _activeChip;

                    return FilterChip(
                      label: Text(chip['label']!),
                      selected: isSelected,
                      selectedColor: primaryCyan,
                      backgroundColor: cardColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSelected ? primaryCyan : Colors.white12),
                      ),
                      onSelected: (val) {
                        setState(() => _activeChip = chip['key']!);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // TIME-OF-DAY AI SMART PLAYLIST HERO CARD
              if (_activeChip == 'all')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1F1128),
                          Color(0xFF0F172A),
                        ],
                      ),
                      border: Border.all(color: primaryCyan.withOpacity(0.4), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: primaryCyan.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(colors: [primaryCyan, primaryPink]),
                          ),
                          child: Center(
                            child: Text(timeMix['icon']!, style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryCyan.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  timeMix['badge']!,
                                  style: const TextStyle(color: primaryCyan, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeMix['title']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                timeMix['subtitle']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Radiant Play Mix Button
                        GestureDetector(
                          onTap: () {
                            if (_trendingHindi.isNotEmpty) {
                              _playTrack(_trendingHindi.first, _trendingHindi);
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [primaryCyan, primaryPink]),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryCyan.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Recently Played Section
              if (_activeChip == 'all' && _historyService.recentHistory.isNotEmpty)
                _buildSongSection(
                  isHindi ? 'हाल ही में बजाए गए' : 'Recently Played',
                  _historyService.recentHistory,
                  textColor,
                  subtextColor,
                  primaryCyan,
                ),

              // More by Artist Section
              if (_activeChip == 'all' && _artistSongs.isNotEmpty && _historyService.lastPlayedSong != null)
                _buildSongSection(
                  isHindi ? 'कलाकार के अन्य लोकप्रिय गीत' : 'More by ${_historyService.lastPlayedSong!.artist.split(',').first.trim()}',
                  _artistSongs,
                  textColor,
                  subtextColor,
                  primaryCyan,
                ),

              // Trending Hindi Section
              if (_activeChip == 'all' || _activeChip == 'trending')
                _buildSongSection(_lang.t('trending'), _trendingHindi, textColor, subtextColor, primaryCyan),

              // Romantic Section
              if (_activeChip == 'all' || _activeChip == 'romantic')
                _buildSongSection(_lang.t('romantic'), _bollywoodRomantic, textColor, subtextColor, primaryCyan),

              // Retro Classics Section
              if (_activeChip == 'all' || _activeChip == 'retro')
                _buildSongSection(_lang.t('retro_classics'), _retroClassics, textColor, subtextColor, primaryCyan),

              // Punjabi Section
              if (_activeChip == 'all' || _activeChip == 'punjabi')
                _buildSongSection(_lang.t('punjabi'), _punjabiHits, textColor, subtextColor, primaryCyan),

              // Lo-Fi Section
              if (_activeChip == 'all' || _activeChip == 'lofi')
                _buildSongSection(_lang.t('lofi'), _hindiLofi, textColor, subtextColor, primaryCyan),

              // ====================================================================
              // CONTINUOUS INFINITE DISCOVERY FEED (Loads endlessly as user scrolls!)
              // ====================================================================
              if (_activeChip == 'all' && _infiniteFeedSongs.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [primaryCyan, primaryPink]),
                        ),
                        child: const Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isHindi ? 'असीमित संगीत स्ट्रीम (Never-Ending Feed)' : 'Infinite Music Stream',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _infiniteFeedSongs.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 12),
                  itemBuilder: (context, index) {
                    final song = _infiniteFeedSongs[index];
                    return StreamBuilder<PlaybackState>(
                      stream: widget.audioHandler.playbackState,
                      builder: (context, playStateSnap) {
                        return StreamBuilder<MediaItem?>(
                          stream: widget.audioHandler.mediaItem,
                          builder: (context, mediaSnap) {
                            final isCurrentTrack = mediaSnap.data?.id == song.id;
                            final isPlaying = isCurrentTrack && (playStateSnap.data?.playing ?? widget.audioHandler.isPlaying);

                            return InkWell(
                              onTap: () => _playTrack(song, _infiniteFeedSongs),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Image.network(
                                            song.thumbnailUrl,
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 52,
                                              height: 52,
                                              color: Colors.white10,
                                              child: const Icon(Icons.music_note, color: Colors.white54),
                                            ),
                                          ),
                                          if (isCurrentTrack)
                                            Container(
                                              width: 52,
                                              height: 52,
                                              color: Colors.black.withOpacity(0.35),
                                              child: const Icon(Icons.equalizer_rounded, color: primaryCyan, size: 24),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            song.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isCurrentTrack ? primaryCyan : textColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            song.artist,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: subtextColor, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Quick Like Button
                                    AnimatedBuilder(
                                      animation: _favoritesService,
                                      builder: (context, _) {
                                        final isFav = _favoritesService.isFavorite(song.id);
                                        return IconButton(
                                          icon: Icon(
                                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                            color: isFav ? const Color(0xFFFF2A6D) : Colors.white38,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            final added = await _favoritesService.toggleFavorite(song);
                                            if (added) {
                                              ScreenBubbleCelebration.show(context);
                                            }
                                          },
                                        );
                                      },
                                    ),
                                    // Quick Download Button
                                    AnimatedBuilder(
                                      animation: _downloadService,
                                      builder: (context, _) {
                                        final isDownloaded = _downloadService.isSongDownloaded(song.id);
                                        final isQueued = _downloadService.isSongInQueue(song.id);
                                        return IconButton(
                                          icon: Icon(
                                            isDownloaded
                                                ? Icons.download_done_rounded
                                                : (isQueued ? Icons.hourglass_top_rounded : Icons.download_rounded),
                                            color: isDownloaded
                                                ? const Color(0xFF00E676)
                                                : (isQueued ? const Color(0xFF00E5FF) : Colors.white60),
                                            size: 20,
                                          ),
                                          tooltip: isHindi ? 'डाउनलोड करें' : 'Download',
                                          onPressed: () {
                                            if (isDownloaded) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  backgroundColor: const Color(0xFF00E676),
                                                  duration: const Duration(seconds: 2),
                                                  content: Text(
                                                    isHindi ? 'यह गाना पहले से डाउनलोड है!' : 'Song already downloaded!',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                backgroundColor: const Color(0xFF00E5FF),
                                                duration: const Duration(seconds: 2),
                                                content: Text(
                                                  isHindi ? '"${song.title}" डाउनलोड में जोड़ा गया!' : '"${song.title}" added to downloads!',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                              ),
                                            );
                                            _downloadService.downloadSong(song);
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    // Radiant Play Button (Always shows Play Logo with active playing aura)
                                    GestureDetector(
                                      onTap: () => _playSongOnly(song, _infiniteFeedSongs),
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: isPlaying
                                                ? [const Color(0xFF00E5FF), const Color(0xFF00E676)]
                                                : isCurrentTrack
                                                    ? [const Color(0xFF00E5FF), const Color(0xFFFF2A6D)]
                                                    : [primaryCyan, primaryPink],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isPlaying
                                                      ? const Color(0xFF00E676)
                                                      : (isCurrentTrack ? const Color(0xFF00E5FF) : primaryCyan))
                                                  .withOpacity(0.45),
                                              blurRadius: isPlaying ? 14 : 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Icon(
                                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],

              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryCyan),
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildSongSection(
    String title,
    List<SongModel> songs,
    Color textColor,
    Color subtextColor,
    Color primaryColor,
  ) {
    if (songs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: subtextColor.withOpacity(0.4), size: 14),
            ],
          ),
        ),
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: songs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final song = songs[i];
              return StreamBuilder<PlaybackState>(
                stream: widget.audioHandler.playbackState,
                builder: (context, playStateSnap) {
                  return StreamBuilder<MediaItem?>(
                    stream: widget.audioHandler.mediaItem,
                    builder: (context, mediaSnap) {
                      final isCurrentTrack = mediaSnap.data?.id == song.id;
                      final isPlaying = isCurrentTrack && (playStateSnap.data?.playing ?? widget.audioHandler.isPlaying);

                      return Tactile3DWrapper(
                        onTap: () => _playTrack(song, songs),
                        scaleElevation: 1.06,
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 135,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AspectRatio(
                                      aspectRatio: 1.0,
                                      child: Image.network(
                                        song.thumbnailUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade900,
                                          child: const Icon(Icons.music_note, color: Colors.white54),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isCurrentTrack)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: Colors.black.withOpacity(0.35),
                                        ),
                                        child: Center(
                                          child: Icon(Icons.equalizer_rounded, color: primaryColor, size: 28),
                                        ),
                                      ),
                                    ),
                                  // Top-Right Download Button
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: AnimatedBuilder(
                                      animation: _downloadService,
                                      builder: (context, _) {
                                        final isDownloaded = _downloadService.isSongDownloaded(song.id);
                                        final isQueued = _downloadService.isSongInQueue(song.id);
                                        return GestureDetector(
                                          onTap: () {
                                            if (isDownloaded) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                backgroundColor: const Color(0xFF00E5FF),
                                                duration: const Duration(seconds: 2),
                                                content: Text(
                                                  _lang.isHindi
                                                      ? '"${song.title}" डाउनलोड में जोड़ा गया!'
                                                      : '"${song.title}" queued for download!',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                                ),
                                              ),
                                            );
                                            _downloadService.downloadSong(song);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black.withOpacity(0.65),
                                              border: Border.all(
                                                color: isDownloaded
                                                    ? const Color(0xFF00E676)
                                                    : (isQueued ? const Color(0xFF00E5FF) : Colors.white30),
                                              ),
                                            ),
                                            child: Icon(
                                              isDownloaded
                                                  ? Icons.download_done_rounded
                                                  : (isQueued ? Icons.hourglass_top_rounded : Icons.download_rounded),
                                              color: isDownloaded
                                                  ? const Color(0xFF00E676)
                                                  : (isQueued ? const Color(0xFF00E5FF) : Colors.white70),
                                              size: 14,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // Corner Play Button (Shows Play Logo with active aura)
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () => _playSongOnly(song, songs),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: isPlaying
                                                ? [const Color(0xFF00E5FF), const Color(0xFF00E676)]
                                                : isCurrentTrack
                                                    ? [const Color(0xFF00E5FF), const Color(0xFFFF2A6D)]
                                                    : [const Color(0xFF00E5FF), const Color(0xFFFF2A6D)],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isPlaying
                                                      ? const Color(0xFF00E676)
                                                      : (isCurrentTrack ? const Color(0xFF00E5FF) : const Color(0xFF00E5FF)))
                                                  .withOpacity(0.45),
                                              blurRadius: isPlaying ? 12 : 8,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          const SizedBox(height: 8),
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrentTrack ? primaryColor : textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    ),
  ],
);
  }
}

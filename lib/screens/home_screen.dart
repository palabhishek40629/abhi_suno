import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/language_service.dart';
import '../services/music_service.dart';
import '../services/performance_guard.dart';
import '../services/playback_history_service.dart';
import '../services/theme_service.dart';
import 'now_playing_screen.dart';

class HomeScreen extends StatefulWidget {
  final AbhiAudioHandler audioHandler;

  const HomeScreen({Key? key, required this.audioHandler}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MusicService _musicService = MusicService();
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();
  final PlaybackHistoryService _historyService = PlaybackHistoryService();
  final ScrollController _scrollController = ScrollController();

  List<SongModel> _trendingHindi = [];
  List<SongModel> _bollywoodRomantic = [];
  List<SongModel> _retroClassics = [];
  List<SongModel> _punjabiHits = [];
  List<SongModel> _hindiLofi = [];
  List<SongModel> _artistSongs = [];
  List<SongModel> _dynamicFeedSongs = [];
  String _cachedArtistQuery = '';

  String _activeChip = 'all';
  bool _isContinueDismissed = false;
  bool _isLoadingMore = false;
  bool _isOfflineDetected = false;
  String _userName = 'Abhishek Pal';

  @override
  void initState() {
    super.initState();
    _loadInstantStarterTracks();
    _refreshLiveTrending();
    _loadUserProfile();
    _historyService.addListener(_onHistoryUpdated);
    _loadMoreByArtist();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        _loadDynamicFeedPage();
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

  Future<void> _loadDynamicFeedPage() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final additional = await PerformanceGuard.safeAsync<List<SongModel>>(
        _musicService.searchSongs('Hindi acoustic romantic chartbusters'),
        timeout: const Duration(seconds: 6),
        fallback: <SongModel>[],
      );
      if (mounted) {
        setState(() {
          _dynamicFeedSongs.addAll(additional.take(8));
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
          id: 'BddP6PY427U',
          title: 'Kesariya',
          artist: 'Arijit Singh, Pritam',
          duration: const Duration(minutes: 4, seconds: 28),
          thumbnailUrl: 'https://i.ytimg.com/vi/BddP6PY427U/hqdefault.jpg',
        ),
        SongModel(
          id: 'ElZfdU54Cp8',
          title: 'Apna Bana Le',
          artist: 'Arijit Singh, Sachin-Jigar',
          duration: const Duration(minutes: 3, seconds: 42),
          thumbnailUrl: 'https://i.ytimg.com/vi/ElZfdU54Cp8/hqdefault.jpg',
        ),
        SongModel(
          id: 'RLzC55ai0eo',
          title: 'Heeriye',
          artist: 'Jasleen Royal, Arijit Singh',
          duration: const Duration(minutes: 3, seconds: 15),
          thumbnailUrl: 'https://i.ytimg.com/vi/RLzC55ai0eo/hqdefault.jpg',
        ),
        SongModel(
          id: 'VAdGW7QDJUI',
          title: 'Chaleya',
          artist: 'Arijit Singh, Shilpa Rao',
          duration: const Duration(minutes: 3, seconds: 20),
          thumbnailUrl: 'https://i.ytimg.com/vi/VAdGW7QDJUI/hqdefault.jpg',
        ),
        SongModel(
          id: '8vt2W_F13eI',
          title: 'O Maahi',
          artist: 'Arijit Singh, Pritam',
          duration: const Duration(minutes: 3, seconds: 53),
          thumbnailUrl: 'https://i.ytimg.com/vi/8vt2W_F13eI/hqdefault.jpg',
        ),
      ];

      _bollywoodRomantic = [
        SongModel(
          id: 'IJq0yyWug1k',
          title: 'Tum Hi Ho',
          artist: 'Arijit Singh',
          duration: const Duration(minutes: 4, seconds: 22),
          thumbnailUrl: 'https://i.ytimg.com/vi/IJq0yyWug1k/hqdefault.jpg',
        ),
        SongModel(
          id: 'gvyUuxdRdR4',
          title: 'Raataan Lambiyan',
          artist: 'Jubin Nautiyal, Asees Kaur',
          duration: const Duration(minutes: 3, seconds: 50),
          thumbnailUrl: 'https://i.ytimg.com/vi/gvyUuxdRdR4/hqdefault.jpg',
        ),
        SongModel(
          id: '2mDCVzruYzQ',
          title: 'Pehle Bhi Main',
          artist: 'Vishal Mishra, Raj Shekhar',
          duration: const Duration(minutes: 4, seconds: 10),
          thumbnailUrl: 'https://i.ytimg.com/vi/2mDCVzruYzQ/hqdefault.jpg',
        ),
        SongModel(
          id: 'sK7riqg2mr4',
          title: 'Agar Tum Saath Ho',
          artist: 'Alka Yagnik, Arijit Singh',
          duration: const Duration(minutes: 5, seconds: 41),
          thumbnailUrl: 'https://i.ytimg.com/vi/sK7riqg2mr4/hqdefault.jpg',
        ),
      ];

      _retroClassics = [
        SongModel(
          id: '_sZgA133Sc0',
          title: 'Yeh Shaam Mastani',
          artist: 'Kishore Kumar, R.D. Burman',
          duration: const Duration(minutes: 4, seconds: 35),
          thumbnailUrl: 'https://i.ytimg.com/vi/_sZgA133Sc0/hqdefault.jpg',
        ),
        SongModel(
          id: 'vo1My403Psk',
          title: 'Mere Sapno Ki Rani',
          artist: 'Kishore Kumar, S.D. Burman',
          duration: const Duration(minutes: 5, seconds: 0),
          thumbnailUrl: 'https://i.ytimg.com/vi/vo1My403Psk/hqdefault.jpg',
        ),
        SongModel(
          id: 'TFr6G5zveS8',
          title: 'Lag Ja Gale',
          artist: 'Lata Mangeshkar, Madan Mohan',
          duration: const Duration(minutes: 4, seconds: 18),
          thumbnailUrl: 'https://i.ytimg.com/vi/TFr6G5zveS8/hqdefault.jpg',
        ),
      ];

      _punjabiHits = [
        SongModel(
          id: 'cl0a3i2wFcc',
          title: '295',
          artist: 'Sidhu Moose Wala',
          duration: const Duration(minutes: 4, seconds: 30),
          thumbnailUrl: 'https://i.ytimg.com/vi/cl0a3i2wFcc/hqdefault.jpg',
        ),
        SongModel(
          id: 'cWMxCE2HTag',
          title: 'Softly',
          artist: 'Karan Aujla, Ikky',
          duration: const Duration(minutes: 2, seconds: 35),
          thumbnailUrl: 'https://i.ytimg.com/vi/cWMxCE2HTag/hqdefault.jpg',
        ),
      ];

      _hindiLofi = [
        SongModel(
          id: 'e-ORhEE9VVg',
          title: 'Iktara (Lo-Fi Chill)',
          artist: 'Amit Trivedi, Kavita Seth',
          duration: const Duration(minutes: 4, seconds: 12),
          thumbnailUrl: 'https://i.ytimg.com/vi/e-ORhEE9VVg/hqdefault.jpg',
        ),
        SongModel(
          id: 'jHNNMj5bNQw',
          title: 'Kabira (Slowed & Reverb)',
          artist: 'Tochi Raina, Rekha Bhardwaj',
          duration: const Duration(minutes: 4, seconds: 29),
          thumbnailUrl: 'https://i.ytimg.com/vi/jHNNMj5bNQw/hqdefault.jpg',
        ),
      ];
    });
  }

  Future<void> _refreshLiveTrending() async {
    try {
      final results = await Future.wait([
        PerformanceGuard.safeAsync<List<SongModel>>(_musicService.getTrendingHindi(), timeout: const Duration(seconds: 5), fallback: []),
        PerformanceGuard.safeAsync<List<SongModel>>(_musicService.getBollywoodRomantic(), timeout: const Duration(seconds: 5), fallback: []),
        PerformanceGuard.safeAsync<List<SongModel>>(_musicService.getRetroClassics(), timeout: const Duration(seconds: 5), fallback: []),
        PerformanceGuard.safeAsync<List<SongModel>>(_musicService.getPunjabiHits(), timeout: const Duration(seconds: 5), fallback: []),
        PerformanceGuard.safeAsync<List<SongModel>>(_musicService.getHindiLofi(), timeout: const Duration(seconds: 5), fallback: []),
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

  void _playTrack(SongModel song, List<SongModel> queue) {
    widget.audioHandler.playSong(song, queue: queue);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NowPlayingScreen(audioHandler: widget.audioHandler),
      ),
    );
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
        final isHindi = _lang.isHindi;

        final chips = [
          {'key': 'all', 'label': isHindi ? 'सभी' : 'All'},
          {'key': 'trending', 'label': _lang.t('trending')},
          {'key': 'romantic', 'label': _lang.t('romantic')},
          {'key': 'retro', 'label': _lang.t('retro_classics')},
          {'key': 'punjabi', 'label': _lang.t('punjabi')},
          {'key': 'lofi', 'label': _lang.t('lofi')},
        ];

        return RefreshIndicator(
          onRefresh: _refreshLiveTrending,
          color: primaryColor,
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
                      selectedColor: primaryColor,
                      backgroundColor: cardColor,
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
                        setState(() => _activeChip = chip['key']!);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Continue Listening Hero Card (with close dismiss button)
              if (_activeChip == 'all' && !_isContinueDismissed && _historyService.lastPlayedSong != null)
                _buildContinueListeningCard(
                  _historyService.lastPlayedSong!,
                  _historyService.lastPosition,
                  textColor,
                  subtextColor,
                  primaryColor,
                  cardColor,
                  isHindi,
                ),

              // Recently Played Section
              if (_activeChip == 'all' && _historyService.recentHistory.isNotEmpty)
                _buildSongSection(
                  isHindi ? 'हाल ही में बजाए गए' : 'Recently Played',
                  _historyService.recentHistory,
                  textColor,
                  subtextColor,
                  primaryColor,
                ),

              // More by Artist Section
              if (_activeChip == 'all' && _artistSongs.isNotEmpty && _historyService.lastPlayedSong != null)
                _buildSongSection(
                  isHindi ? 'कलाकार के अन्य लोकप्रिय गीत' : 'More by ${_historyService.lastPlayedSong!.artist.split(',').first.trim()}',
                  _artistSongs,
                  textColor,
                  subtextColor,
                  primaryColor,
                ),

              // Trending Hindi Section
              if (_activeChip == 'all' || _activeChip == 'trending')
                _buildSongSection(_lang.t('trending'), _trendingHindi, textColor, subtextColor, primaryColor),

              // Romantic Section
              if (_activeChip == 'all' || _activeChip == 'romantic')
                _buildSongSection(_lang.t('romantic'), _bollywoodRomantic, textColor, subtextColor, primaryColor),

              // Retro Classics Section
              if (_activeChip == 'all' || _activeChip == 'retro')
                _buildSongSection(_lang.t('retro_classics'), _retroClassics, textColor, subtextColor, primaryColor),

              // Punjabi Section
              if (_activeChip == 'all' || _activeChip == 'punjabi')
                _buildSongSection(_lang.t('punjabi'), _punjabiHits, textColor, subtextColor, primaryColor),

              // Lo-Fi Section
              if (_activeChip == 'all' || _activeChip == 'lofi')
                _buildSongSection(_lang.t('lofi'), _hindiLofi, textColor, subtextColor, primaryColor),

              // Dynamic Pagination Feed
              if (_dynamicFeedSongs.isNotEmpty)
                _buildSongSection(
                  isHindi ? 'आपके लिए विशेष सुझाव' : 'Recommended for You',
                  _dynamicFeedSongs,
                  textColor,
                  subtextColor,
                  primaryColor,
                ),

              if (_isLoadingMore)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
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

  Widget _buildContinueListeningCard(
    SongModel song,
    Duration position,
    Color textColor,
    Color subtextColor,
    Color primaryColor,
    Color cardColor,
    bool isHindi,
  ) {
    final durSec = song.duration.inSeconds > 0 ? song.duration.inSeconds : 1;
    final posSec = position.inSeconds.clamp(0, durSec);
    final double progress = (posSec / durSec).clamp(0.0, 1.0);

    String formatDur(int s) {
      final m = s ~/ 60;
      final sec = s % 60;
      return '$m:${sec.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF221A0C), // Warm golden dark
              Color(0xFF141414), // Dark obsidian
            ],
          ),
          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history_rounded, size: 14, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      isHindi ? 'सुनना जारी रखें' : 'CONTINUE LISTENING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                // Close / Dismiss Button
                InkWell(
                  onTap: () => setState(() => _isContinueDismissed = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: subtextColor.withOpacity(0.6)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _playTrack(song, [song]),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      song.thumbnailUrl,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 58,
                        height: 58,
                        color: Colors.black45,
                        child: const Icon(Icons.music_note, color: Colors.white54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subtextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    iconSize: 42,
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.play_circle_fill_rounded, color: primaryColor),
                    onPressed: () => _playTrack(song, [song]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                minHeight: 3.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDur(posSec),
                  style: TextStyle(color: subtextColor, fontSize: 10),
                ),
                Text(
                  formatDur(durSec),
                  style: TextStyle(color: subtextColor, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
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
              return GestureDetector(
                onTap: () => _playTrack(song, songs),
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
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.7),
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
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
                          color: textColor,
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
          ),
        ),
      ],
    );
  }
}

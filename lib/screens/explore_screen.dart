import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/download_service.dart';
import '../services/language_service.dart';
import '../services/music_service.dart';
import '../services/theme_service.dart';

class ExploreScreen extends StatelessWidget {
  final AbhiAudioHandler audioHandler;

  const ExploreScreen({Key? key, required this.audioHandler}) : super(key: key);

  static final List<Map<String, dynamic>> categories = [
    {
      'key': 'trending',
      'labelEn': 'Trending Hits',
      'labelHi': 'लोकप्रिय ट्रेंडिंग',
      'desc': 'Top chartbusters ruling across India',
      'icon': Icons.local_fire_department_rounded,
      'gradient': [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
    },
    {
      'key': 'romantic',
      'labelEn': 'Romantic Melodies',
      'labelHi': 'मधुर प्रेम गीत',
      'desc': 'Heartwarming love ballads and duets',
      'icon': Icons.favorite_rounded,
      'gradient': [const Color(0xFFE91E63), const Color(0xFFFF6090)],
    },
    {
      'key': 'retro_classics',
      'labelEn': '90s Retro Classics',
      'labelHi': 'सदाबहार पुराने गीत',
      'desc': 'Timeless golden melodies of Kishore & Lata',
      'icon': Icons.radio_rounded,
      'gradient': [const Color(0xFFF7971E), const Color(0xFFFFD200)],
    },
    {
      'key': 'punjabi',
      'labelEn': 'Punjabi Beats',
      'labelHi': 'पंजाबी धमाकेदार गीत',
      'desc': 'High-energy Punjabi hits & club anthems',
      'icon': Icons.bolt_rounded,
      'gradient': [const Color(0xFF8A2387), const Color(0xFFE94057)],
    },
    {
      'key': 'bhakti',
      'labelEn': 'Devotional & Bhakti',
      'labelHi': 'भक्ति एवं प्रार्थना गीत',
      'desc': 'Soulful bhajans, aartis, and mantras',
      'icon': Icons.self_improvement_rounded,
      'gradient': [const Color(0xFFFF8008), const Color(0xFFFFC837)],
    },
    {
      'key': 'lofi',
      'labelEn': 'Lo-Fi Chill Beats',
      'labelHi': 'शांत एवं सुकून भरे धुन',
      'desc': 'Slowed & reverb aesthetic Hindi lo-fi',
      'icon': Icons.nightlight_round,
      'gradient': [const Color(0xFF2B5876), const Color(0xFF4E4376)],
    },
    {
      'key': 'workout',
      'labelEn': 'Workout Energy',
      'labelHi': 'ऊर्जावान वर्कआउट धुनें',
      'desc': 'Pumping gym motivation & fast-paced beats',
      'icon': Icons.fitness_center_rounded,
      'gradient': [const Color(0xFF11998E), const Color(0xFF38EF7D)],
    },
    {
      'key': 'party',
      'labelEn': 'Party & Dance',
      'labelHi': 'पार्टी एवं नृत्य गीत',
      'desc': 'DJ remixes, bass boosters, and dance tracks',
      'icon': Icons.celebration_rounded,
      'gradient': [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
    },
    {
      'key': 'ghazal',
      'labelEn': 'Ghazals & Soulful',
      'labelHi': 'ग़ज़ल एवं सुकून',
      'desc': 'Poetic expressions and classical ghazals',
      'icon': Icons.queue_music_rounded,
      'gradient': [const Color(0xFF2C3E50), const Color(0xFF3498DB)],
    },
    {
      'key': 'acoustic',
      'labelEn': 'Acoustic & Unplugged',
      'labelHi': 'अनप्लग्ड धुनें',
      'desc': 'Raw acoustic guitars and soothing vocals',
      'icon': Icons.music_note_rounded,
      'gradient': [const Color(0xFF4568DC), const Color(0xFFB06AB3)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService();
    final lang = LanguageService();

    return AnimatedBuilder(
      animation: Listenable.merge([theme, lang]),
      builder: (context, _) {
        final textColor = theme.textColor;
        final subtextColor = theme.subtextColor;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          children: [
            // Header
            Text(
              lang.isHindi ? 'गीत और श्रेणियां खोजें' : 'Explore Categories',
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lang.isHindi
                  ? 'अपनी पसंद और मूड के अनुसार संगीत चुनें'
                  : 'Browse songs by mood, genre, and popular Indian sounds',
              style: TextStyle(
                color: subtextColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),

            // 2-Column Category Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.35,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final List<Color> gradColors = cat['gradient'] as List<Color>;
                final String title = lang.isHindi ? (cat['labelHi'] as String) : (cat['labelEn'] as String);
                final String subtitle = lang.isHindi ? (cat['labelEn'] as String) : (cat['labelHi'] as String);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CategoryDetailScreen(
                            category: cat,
                            audioHandler: audioHandler,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradColors,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gradColors.first.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

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
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();

  List<SongModel> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    setState(() => _isLoading = true);

    final key = widget.category['key'] as String;
    List<SongModel> result = [];

    try {
      switch (key) {
        case 'trending':
          result = await _musicService.getTrendingHindi();
          break;
        case 'romantic':
          result = await _musicService.getBollywoodRomantic();
          break;
        case 'retro_classics':
          result = await _musicService.getRetroClassics();
          break;
        case 'punjabi':
          result = await _musicService.getPunjabiHits();
          break;
        case 'bhakti':
          result = await _musicService.getBhaktiSongs();
          break;
        case 'lofi':
          result = await _musicService.getHindiLofi();
          break;
        case 'workout':
          result = await _musicService.getWorkoutSongs();
          break;
        case 'party':
          result = await _musicService.getPartySongs();
          break;
        case 'ghazal':
          result = await _musicService.getGhazals();
          break;
        case 'acoustic':
          result = await _musicService.searchSongs('Hindi Acoustic Unplugged');
          break;
        default:
          result = await _musicService.getTrendingHindi();
          break;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _songs = result;
        _isLoading = false;
      });
    }
  }

  void _playSong(SongModel song) {
    widget.audioHandler.playSong(song, queue: _songs);
  }

  void _playAll() {
    if (_songs.isNotEmpty) {
      widget.audioHandler.playSong(_songs.first, queue: _songs);
    }
  }

  void _shuffleAll() {
    if (_songs.isNotEmpty) {
      final shuffled = List<SongModel>.from(_songs)..shuffle();
      widget.audioHandler.playSong(shuffled.first, queue: shuffled);
    }
  }

  void _downloadSong(SongModel song) async {
    final success = await _downloadService.downloadSong(song);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (_lang.isHindi ? 'गाना डाउनलोड हो गया!' : 'Song downloaded successfully!')
                : (_lang.isHindi ? 'डाउनलोड विफल हुआ' : 'Download failed'),
          ),
          backgroundColor: success ? const Color(0xFF05D9E8) : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> gradColors = widget.category['gradient'] as List<Color>;
    final String title = _lang.isHindi
        ? (widget.category['labelHi'] as String)
        : (widget.category['labelEn'] as String);
    final String desc = widget.category['desc'] as String;

    return AnimatedBuilder(
      animation: Listenable.merge([_theme, _lang]),
      builder: (context, _) {
        final textColor = _theme.textColor;
        final subtextColor = _theme.subtextColor;
        final primaryColor = _theme.primaryColor;
        final bgColor = _theme.scaffoldBg;

        return Scaffold(
          backgroundColor: bgColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Vibrant Category Hero Header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                elevation: 0,
                backgroundColor: gradColors.first,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradColors,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.category['icon'] as IconData,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_songs.length} ${_lang.isHindi ? "गाने" : "Songs"}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Action Buttons Bar (Play All / Shuffle)
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, size: 22),
                            label: Text(
                              _lang.t('play_all'),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: Icon(Icons.shuffle_rounded, size: 20, color: primaryColor),
                            label: Text(
                              _lang.isHindi ? 'शफ़ल प्ले' : 'Shuffle',
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: _shuffleAll,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Loading State
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF05D9E8)),
                    ),
                  ),
                )
              // Empty State
              else if (_songs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      _lang.isHindi ? 'गाने लोड नहीं हो सके। पुनः प्रयास करें।' : 'No songs available.',
                      style: TextStyle(color: subtextColor),
                    ),
                  ),
                )
              // Song List
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = _songs[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 22,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: subtextColor.withOpacity(0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
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
                              ),
                            ],
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
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
                                icon: Icon(Icons.play_circle_fill_rounded, color: primaryColor, size: 32),
                                onPressed: () => _playSong(song),
                              ),
                            ],
                          ),
                          onTap: () => _playSong(song),
                        );
                      },
                      childCount: _songs.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

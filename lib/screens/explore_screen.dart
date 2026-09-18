import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/download_service.dart';
import '../services/language_service.dart';
import '../services/music_service.dart';
import '../services/theme_service.dart';

class ExploreScreen extends StatefulWidget {
  final AbhiAudioHandler audioHandler;

  const ExploreScreen({Key? key, required this.audioHandler}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final MusicService _musicService = MusicService();
  final DownloadService _downloadService = DownloadService();
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();

  String _selectedCategoryKey = 'trending';
  List<SongModel> _categorySongs = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {
      'key': 'trending',
      'labelEn': 'Trending Hits',
      'labelHi': 'लोकप्रिय ट्रेंडिंग गीत',
      'icon': Icons.local_fire_department_rounded,
      'gradient': [Color(0xFFFF416C), Color(0xFFFF4B2B)],
    },
    {
      'key': 'romantic',
      'labelEn': 'Romantic Melodies',
      'labelHi': 'मधुर प्रेम गीत',
      'icon': Icons.favorite_rounded,
      'gradient': [Color(0xFFE91E63), Color(0xFFFF6090)],
    },
    {
      'key': 'retro_classics',
      'labelEn': '90s Retro Classics',
      'labelHi': 'सदाबहार पुराने गीत',
      'icon': Icons.radio_rounded,
      'gradient': [Color(0xFFF7971E), Color(0xFFFFD200)],
    },
    {
      'key': 'punjabi',
      'labelEn': 'Punjabi Beats',
      'labelHi': 'पंजाबी धमाकेदार गीत',
      'icon': Icons.bolt_rounded,
      'gradient': [Color(0xFF8A2387), Color(0xFFE94057)],
    },
    {
      'key': 'bhakti',
      'labelEn': 'Devotional & Bhakti',
      'labelHi': 'भक्ति एवं प्रार्थना गीत',
      'icon': Icons.self_improvement_rounded,
      'gradient': [Color(0xFFFF8008), Color(0xFFFFC837)],
    },
    {
      'key': 'lofi',
      'labelEn': 'Lo-Fi Chill Beats',
      'labelHi': 'शांत एवं सुकून भरे धुन',
      'icon': Icons.nightlight_round,
      'gradient': [Color(0xFF2B5876), Color(0xFF4E4376)],
    },
    {
      'key': 'workout',
      'labelEn': 'Workout Energy',
      'labelHi': 'ऊर्जावान वर्कआउट धुनें',
      'icon': Icons.fitness_center_rounded,
      'gradient': [Color(0xFF11998E), Color(0xFF38EF7D)],
    },
    {
      'key': 'party',
      'labelEn': 'Party & Dance',
      'labelHi': 'पार्टी एवं नृत्य गीत',
      'icon': Icons.celebration_rounded,
      'gradient': [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    },
    {
      'key': 'ghazal',
      'labelEn': 'Ghazals & Soulful',
      'labelHi': 'ग़ज़ल एवं सुकून',
      'icon': Icons.queue_music_rounded,
      'gradient': [Color(0xFF2C3E50), Color(0xFF3498DB)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCategory('trending');
  }

  Future<void> _loadCategory(String key) async {
    setState(() {
      _selectedCategoryKey = key;
      _isLoading = true;
    });

    List<SongModel> songs = [];
    switch (key) {
      case 'trending':
        songs = await _musicService.getTrendingHindi();
        break;
      case 'romantic':
        songs = await _musicService.getBollywoodRomantic();
        break;
      case 'retro_classics':
        songs = await _musicService.getRetroClassics();
        break;
      case 'punjabi':
        songs = await _musicService.getPunjabiHits();
        break;
      case 'bhakti':
        songs = await _musicService.getBhaktiSongs();
        break;
      case 'lofi':
        songs = await _musicService.getHindiLofi();
        break;
      case 'workout':
        songs = await _musicService.getWorkoutSongs();
        break;
      case 'party':
        songs = await _musicService.getPartySongs();
        break;
      case 'ghazal':
        songs = await _musicService.getGhazals();
        break;
    }

    if (mounted) {
      setState(() {
        _categorySongs = songs;
        _isLoading = false;
      });
    }
  }

  void _playSong(SongModel song) {
    widget.audioHandler.playSong(song, queue: _categorySongs);
  }

  void _playAll() {
    if (_categorySongs.isNotEmpty) {
      widget.audioHandler.playSong(_categorySongs.first, queue: _categorySongs);
    }
  }

  void _downloadSong(SongModel song) async {
    final success = await _downloadService.downloadSong(song);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? (_lang.isHindi ? 'गाना डाउनलोड हो गया!' : 'Song downloaded successfully!') : (_lang.isHindi ? 'डाउनलोड विफल हुआ' : 'Download failed')),
          backgroundColor: success ? const Color(0xFF05D9E8) : Colors.redAccent,
        ),
      );
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
        final primaryColor = _theme.primaryColor;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 90),
          children: [
            // YouTube Music Style Category Grid
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                _lang.t('mood_categories'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Horizontal Mood Category Chips
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat['key'] == _selectedCategoryKey;
                  final title = _lang.isHindi ? cat['labelHi'] : cat['labelEn'];

                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat['icon'] as IconData, size: 16, color: isSelected ? Colors.black : textColor),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: TextStyle(
                            color: isSelected ? Colors.black : textColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: cardColor,
                    side: BorderSide(
                      color: isSelected ? primaryColor : Colors.white12,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        _loadCategory(cat['key'] as String);
                      }
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Selected Category Header & Play All Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _lang.isHindi
                          ? (_categories.firstWhere((c) => c['key'] == _selectedCategoryKey)['labelHi'] as String)
                          : (_categories.firstWhere((c) => c['key'] == _selectedCategoryKey)['labelEn'] as String),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!_isLoading && _categorySongs.isNotEmpty)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: Text(
                        _lang.t('play_all'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: _playAll,
                    ),
                ],
              ),
            ),

            // Song List for Category
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF05D9E8)),
                  ),
                ),
              )
            else if (_categorySongs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    _lang.isHindi ? 'गाने लोड नहीं हो सके। पुनः प्रयास करें।' : 'Could not load songs. Please retry.',
                    style: TextStyle(color: subtextColor),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categorySongs.length,
                itemBuilder: (context, index) {
                  final song = _categorySongs[index];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        song.thumbnailUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 52,
                          height: 52,
                          color: Colors.grey.shade900,
                          child: const Icon(Icons.music_note_rounded, color: Colors.white54),
                        ),
                      ),
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
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
              ),
          ],
        );
      },
    );
  }
}

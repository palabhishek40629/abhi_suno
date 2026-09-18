import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/music_service.dart';
import '../services/download_service.dart';

class HomeScreen extends StatefulWidget {
  final AbhiAudioHandler audioHandler;

  const HomeScreen({Key? key, required this.audioHandler}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MusicService _musicService = MusicService();
  final DownloadService _downloadService = DownloadService();

  List<SongModel> _trendingHindi = [];
  List<SongModel> _bollywoodRomantic = [];
  List<SongModel> _retroClassics = [];
  List<SongModel> _punjabiHits = [];
  List<SongModel> _hindiLofi = [];

  bool _isLoading = true;
  String _activeChip = 'All';

  final List<String> _chips = [
    'All',
    'Trending Hindi',
    'Romantic',
    'Old Classics 90s',
    'Punjabi Hits',
    'Lo-Fi Beats',
  ];

  @override
  void initState() {
    super.initState();
    _fetchMusicData();
  }

  Future<void> _fetchMusicData() async {
    setState(() => _isLoading = true);
    try {
      final trending = await _musicService.getTrendingHindi();
      final romantic = await _musicService.getBollywoodRomantic();
      final retro = await _musicService.getRetroClassics();
      final punjabi = await _musicService.getPunjabiHits();
      final lofi = await _musicService.getHindiLofi();

      if (mounted) {
        setState(() {
          _trendingHindi = trending;
          _bollywoodRomantic = romantic;
          _retroClassics = retro;
          _punjabiHits = punjabi;
          _hindiLofi = lofi;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _playTrack(SongModel song, List<SongModel> queue) {
    widget.audioHandler.playSong(song, queue: queue);
  }

  void _downloadTrack(SongModel song) async {
    final success = await _downloadService.downloadSong(song);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Gaana app me download ho gaya!' : 'Download nahi ho paya'),
          backgroundColor: success ? const Color(0xFF05D9E8) : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF05D9E8))),
            SizedBox(height: 16),
            Text('Hindi gaane load ho rahe hain...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMusicData,
      color: const Color(0xFF05D9E8),
      backgroundColor: const Color(0xFF1E1E1E),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          // Filter Chips Row
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final chip = _chips[i];
                final isSelected = chip == _activeChip;
                return FilterChip(
                  label: Text(chip),
                  selected: isSelected,
                  selectedColor: Colors.white,
                  backgroundColor: const Color(0xFF222222),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? Colors.white : Colors.transparent),
                  ),
                  onSelected: (val) {
                    setState(() => _activeChip = chip);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Trending Hindi Section
          if (_activeChip == 'All' || _activeChip == 'Trending Hindi')
            _buildSongSection('🔥 Trending Hindi (अभी ट्रेंडिंग)', _trendingHindi),

          // Romantic Section
          if (_activeChip == 'All' || _activeChip == 'Romantic')
            _buildSongSection('❤️ Bollywood Romantic (रोमांटिक हिट्स)', _bollywoodRomantic),

          // Retro Classics Section
          if (_activeChip == 'All' || _activeChip == 'Old Classics 90s')
            _buildSongSection('📻 Retro Classics (सदाबहार 90s & पुराने)', _retroClassics),

          // Punjabi Section
          if (_activeChip == 'All' || _activeChip == 'Punjabi Hits')
            _buildSongSection('⚡ Punjabi Hits (धमाकेदार बीट्स)', _punjabiHits),

          // Lo-Fi Section
          if (_activeChip == 'All' || _activeChip == 'Lo-Fi Beats')
            _buildSongSection('🌙 Hindi Lo-Fi (रिलैक्स & चिल)', _hindiLofi),
        ],
      ),
    );
  }

  Widget _buildSongSection(String title, List<SongModel> songs) {
    if (songs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
            ],
          ),
        ),
        SizedBox(
          height: 200,
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
                      // Thumbnail Card with Play Overlay
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
                      // Song Title
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Artist
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
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

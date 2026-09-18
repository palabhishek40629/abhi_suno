import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/music_service.dart';
import '../services/download_service.dart';

class SearchScreen extends StatefulWidget {
  final AbhiAudioHandler audioHandler;

  const SearchScreen({Key? key, required this.audioHandler}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final MusicService _musicService = MusicService();
  final DownloadService _downloadService = DownloadService();

  List<SongModel> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  final List<String> _suggestedArtists = [
    'Arijit Singh',
    'Shreya Ghoshal',
    'Kishore Kumar',
    'Sidhu Moosewala',
    'Atif Aslam',
    'Neha Kakkar',
    'Lata Mangeshkar',
    'Sonu Nigam',
    'Bollywood 90s',
    'Jubin Nautiyal',
  ];

  void _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final res = await _musicService.searchSongs(query);
    if (mounted) {
      setState(() {
        _results = res;
        _isSearching = false;
      });
    }
  }

  void _playSong(SongModel song) {
    widget.audioHandler.playSong(song, queue: _results);
  }

  void _downloadSong(SongModel song) async {
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
    return Column(
      children: [
        // Search Input Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Hindi gana ya kalakar search karein...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF05D9E8)),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white70),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _results = [];
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // Quick Artist Chips
        if (!_hasSearched)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Lokpriya Kalakar (Popular Hindi Artists)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestedArtists.map((artist) {
                    return ActionChip(
                      label: Text(artist),
                      backgroundColor: const Color(0xFF1E1E1E),
                      labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
                      avatar: const CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(0xFF05D9E8),
                        child: Icon(Icons.music_note, size: 12, color: Colors.black),
                      ),
                      side: const BorderSide(color: Colors.white12),
                      onPressed: () {
                        _controller.text = artist;
                        _search(artist);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        // Search Results List
        if (_hasSearched)
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF05D9E8)),
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          'Koi gana nahi mila. Dusra naam daal kar dekhein.',
                          style: TextStyle(color: Colors.white.withOpacity(0.6)),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 90),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final song = _results[index];
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
                                  child: const Icon(Icons.music_note, color: Colors.white54),
                                ),
                              ),
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.download_rounded, color: Colors.white70, size: 22),
                                  tooltip: 'Download',
                                  onPressed: () => _downloadSong(song),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF05D9E8), size: 32),
                                  onPressed: () => _playSong(song),
                                ),
                              ],
                            ),
                            onTap: () => _playSong(song),
                          );
                        },
                      ),
          ),
      ],
    );
  }
}

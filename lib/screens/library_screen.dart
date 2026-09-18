import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/download_service.dart';

class LibraryScreen extends StatefulWidget {
  final AbhiAudioHandler audioHandler;

  const LibraryScreen({Key? key, required this.audioHandler}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DownloadService _downloadService = DownloadService();
  List<SongModel> _downloadedSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    final songs = await _downloadService.getDownloadedSongs();
    if (mounted) {
      setState(() {
        _downloadedSongs = songs;
        _isLoading = false;
      });
    }
  }

  void _playSong(SongModel song) {
    widget.audioHandler.playSong(song, queue: _downloadedSongs);
  }

  void _deleteSong(String songId) async {
    await _downloadService.deleteDownloadedSong(songId);
    _loadDownloads();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gaana app se hata diya gaya.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Offline Vault Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B2A47), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF05D9E8).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF05D9E8).withOpacity(0.15),
                ),
                child: const Icon(Icons.offline_pin_rounded, color: Color(0xFF05D9E8), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Offline Vault',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_downloadedSongs.length} Gaane download hain (Bina internet sunne ke liye)',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (_downloadedSongs.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF05D9E8), size: 36),
                  onPressed: () => _playSong(_downloadedSongs.first),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // List Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Downloaded Gaane (In-App)',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                onPressed: _loadDownloads,
              ),
            ],
          ),
        ),

        // Downloaded List
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF05D9E8))),
                )
              : _downloadedSongs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.downloading_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          const Text(
                            'Abhi koi gaana download nahi hai.',
                            style: TextStyle(color: Colors.white70, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Kisi bhi gaane par Download button dabayein!',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: _downloadedSongs.length,
                      itemBuilder: (context, index) {
                        final song = _downloadedSongs[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              song.thumbnailUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 50,
                                height: 50,
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
                            '${song.artist} • In-App Storage',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 20),
                                tooltip: 'Delete Karein',
                                onPressed: () => _deleteSong(song.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF05D9E8), size: 28),
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

import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../services/language_service.dart';
import '../services/favorites_service.dart';
import '../services/share_helper.dart';
import '../widgets/equalizer_sheet.dart';
import '../widgets/lyrics_sheet.dart';

class NowPlayingScreen extends StatefulWidget {
  final AbhiAudioHandler audioHandler;

  const NowPlayingScreen({Key? key, required this.audioHandler}) : super(key: key);

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final DownloadService _downloadService = DownloadService();
  final FavoritesService _favoritesService = FavoritesService();
  bool _isDownloading = false;
  double _downloadPercent = 0.0;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    final song = widget.audioHandler.currentSong;
    if (song != null) {
      final downloaded = await _downloadService.isSongDownloaded(song.id);
      if (mounted) {
        setState(() => _isDownloaded = downloaded);
      }
    }
  }

  void _triggerDownload(SongModel song) async {
    if (_isDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeh gaana pehle se hi app me downloaded hai!')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadPercent = 0.0;
    });

    final success = await _downloadService.downloadSong(
      song,
      onProgress: (progress) {
        if (mounted) {
          setState(() => _downloadPercent = progress);
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _isDownloaded = success;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Gaana app me download ho gaya! Offline sun sakte hain.'
                : 'Download nahi ho paya, kripya dobara koshish karein.',
          ),
          backgroundColor: success ? const Color(0xFF05D9E8) : Colors.redAccent,
        ),
      );
    }
  }

  void _showAddToPlaylistSheet(SongModel song) {
    final playlistService = PlaylistService();
    final isHindi = LanguageService().isHindi;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return AnimatedBuilder(
          animation: playlistService,
          builder: (context, _) {
            final playlists = playlistService.playlists;
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isHindi ? 'प्लेलिस्ट में जोड़ें' : 'Add to Playlist',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, color: Color(0xFF05D9E8), size: 18),
                        label: Text(
                          isHindi ? 'नई प्लेलिस्ट' : 'New',
                          style: const TextStyle(color: Color(0xFF05D9E8)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showCreatePlaylistDialog(song);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (playlists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          isHindi ? 'कोई प्लेलिस्ट नहीं है। ऊपर "नई प्लेलिस्ट" पर टैप करें।' : 'No playlists yet. Tap "New" above.',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...playlists.map((p) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.queue_music_rounded, color: Color(0xFF05D9E8), size: 20),
                          ),
                          title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text('${p.songs.length} ${isHindi ? "गाने" : "songs"}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          trailing: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF05D9E8)),
                          onTap: () async {
                            await playlistService.addSongToPlaylist(p.id, song);
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF05D9E8),
                                  content: Text(isHindi ? '"${p.name}" में गाना जुड़ गया!' : 'Added to "${p.name}"!'),
                                ),
                              );
                            }
                          },
                        )),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreatePlaylistDialog(SongModel song) {
    final controller = TextEditingController();
    final isHindi = LanguageService().isHindi;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(isHindi ? 'नई प्लेलिस्ट बनाएं' : 'Create New Playlist', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: isHindi ? 'प्लेलिस्ट का नाम...' : 'Playlist name...',
            hintStyle: const TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            child: Text(isHindi ? 'रद्द करें' : 'Cancel', style: const TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF05D9E8)),
            child: Text(isHindi ? 'बनाएं' : 'Create', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await PlaylistService().createPlaylist(name);
                final created = PlaylistService().playlists.first;
                await PlaylistService().addSongToPlaylist(created.id, song);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF05D9E8),
                      content: Text(isHindi ? '"$name" बन गई और गाना जुड़ गया!' : 'Created "$name" and added song!'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration? d) {
    if (d == null) return "0:00";
    final minutes = d.inMinutes.remainder(60).toString();
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SongModel?>(
      stream: widget.audioHandler.currentSongStream,
      builder: (context, snapshot) {
        final song = snapshot.data ?? widget.audioHandler.currentSong;
        if (song == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D0D),
            body: Center(child: Text('Koi gana play nahi ho raha', style: TextStyle(color: Colors.white70))),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.2,
                colors: [
                  Color(0xFF23173D), // Soft atmospheric deep purple
                  Color(0xFF0D0D0D), // True black
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top Navigation & Action Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 36),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Column(
                          children: [
                            Text(
                              LanguageService().t('playing_from'),
                              style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5),
                            ),
                            Text(
                              song.album,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.playlist_add_rounded, color: Color(0xFF05D9E8), size: 28),
                          tooltip: 'Add to Playlist',
                          onPressed: () => _showAddToPlaylistSheet(song),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Album Artwork with 3D Shadow & Border
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF05D9E8).withOpacity(0.25),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          song.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade900,
                            child: const Icon(Icons.music_note, color: Colors.white, size: 80),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Title, Artist, In-App Download Button, Favorite & Share
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Like / Favorite Button
                        AnimatedBuilder(
                          animation: _favoritesService,
                          builder: (context, _) {
                            final isFav = _favoritesService.isFavorite(song.id);
                            return IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFav ? const Color(0xFFFF2A6D) : Colors.white70,
                                size: 28,
                              ),
                              tooltip: isFav ? 'Remove Favorite' : 'Add to Favorites',
                              onPressed: () async {
                                final added = await _favoritesService.toggleFavorite(song);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: added ? const Color(0xFFFF2A6D) : Colors.grey.shade800,
                                      content: Text(
                                        added
                                            ? (LanguageService().isHindi ? 'पसंदीदा में जोड़ा गया!' : 'Added to Favorites!')
                                            : (LanguageService().isHindi ? 'पसंदीदा से हटाया गया!' : 'Removed from Favorites!'),
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),

                        // In-App Download Button
                        _isDownloading
                            ? SizedBox(
                                width: 34,
                                height: 34,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: _downloadPercent,
                                      strokeWidth: 3,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF05D9E8)),
                                    ),
                                    Text(
                                      '${(_downloadPercent * 100).toInt()}%',
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            : IconButton(
                                icon: Icon(
                                  _isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                                  color: _isDownloaded ? const Color(0xFF05D9E8) : Colors.white70,
                                  size: 26,
                                ),
                                tooltip: 'App me Download Karein',
                                onPressed: () => _triggerDownload(song),
                              ),

                        // Share Button
                        IconButton(
                          icon: const Icon(Icons.share_rounded, color: Colors.white70, size: 24),
                          tooltip: 'Share Song',
                          onPressed: () {
                            ShareHelper.shareSong(
                              title: song.title,
                              artist: song.artist,
                              streamUrl: song.streamUrl,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress Scrubber (Seekbar)
                  StreamBuilder<Duration>(
                    stream: widget.audioHandler.player.positionStream,
                    builder: (context, posSnapshot) {
                      final pos = posSnapshot.data ?? Duration.zero;
                      final total = song.duration.inMilliseconds > 0
                          ? song.duration
                          : const Duration(minutes: 3);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.5,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                activeTrackColor: const Color(0xFF05D9E8),
                                inactiveTrackColor: Colors.white12,
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: pos.inMilliseconds.toDouble().clamp(0.0, total.inMilliseconds.toDouble()),
                                min: 0.0,
                                max: total.inMilliseconds.toDouble(),
                                onChanged: (val) {
                                  widget.audioHandler.seek(Duration(milliseconds: val.toInt()));
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(pos),
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                  Text(
                                    _formatDuration(total),
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Main Controls: Shuffle, Previous, Big Play/Pause, Next, Loop
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shuffle_rounded, color: Colors.white54, size: 24),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40),
                          onPressed: () => widget.audioHandler.skipToPrevious(),
                        ),
                        // Big Play / Pause Button
                        StreamBuilder<bool>(
                          stream: widget.audioHandler.player.playingStream,
                          builder: (context, playSnapshot) {
                            final isPlaying = playSnapshot.data ?? widget.audioHandler.player.playing;
                            return Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF05D9E8), Color(0xFFFF2A6D)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF05D9E8).withOpacity(0.4),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 38,
                                ),
                                onPressed: () {
                                  if (isPlaying) {
                                    widget.audioHandler.pause();
                                  } else {
                                    widget.audioHandler.play();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 40),
                          onPressed: () => widget.audioHandler.skipToNext(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.repeat_rounded, color: Colors.white54, size: 24),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom Action Utilities (Lyrics, Equalizer & Queue)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Lyrics Toggle Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          icon: const Icon(Icons.lyrics_rounded, size: 18, color: Color(0xFF05D9E8)),
                          label: Text(LanguageService().t('lyrics'), style: const TextStyle(fontSize: 13)),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => LyricsSheet(song: song),
                            );
                          },
                        ),
                        // Equalizer & Sound Effects
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          icon: const Icon(Icons.equalizer_rounded, size: 18, color: Color(0xFFFF2A6D)),
                          label: Text(LanguageService().t('equalizer'), style: const TextStyle(fontSize: 13)),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (_) => EqualizerSheet(audioHandler: widget.audioHandler),
                            );
                          },
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
    );
  }
}

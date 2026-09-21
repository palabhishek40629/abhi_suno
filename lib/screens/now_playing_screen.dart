import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../services/language_service.dart';
import '../services/favorites_service.dart';
import '../services/share_helper.dart';
import '../widgets/equalizer_sheet.dart';
import '../widgets/lyrics_sheet.dart';
import '../widgets/screen_bubble_celebration.dart';
import '../widgets/tactile_3d_wrapper.dart';

class NowPlayingScreen extends StatefulWidget {
  final AbhiAudioHandler audioHandler;

  const NowPlayingScreen({Key? key, required this.audioHandler}) : super(key: key);

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> with SingleTickerProviderStateMixin {
  final DownloadService _downloadService = DownloadService();
  final FavoritesService _favoritesService = FavoritesService();
  static const MethodChannel _nativeChannel = MethodChannel('com.abhishekpal.abhisuno/native');

  bool _isDownloading = false;
  double _downloadPercent = 0.0;
  bool _isDownloaded = false;

  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();

    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    final song = widget.audioHandler.currentSong;
    if (song != null && _favoritesService.isFavorite(song.id)) {
      _lottieController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
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

  Future<void> _enterPictureInPicture() async {
    try {
      final bool? entered = await _nativeChannel.invokeMethod<bool>('enterPip');
      if (entered != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LanguageService().isHindi ? 'पिक्चर-इन-पिक्चर शुरू हुआ' : 'Floating Player active'),
            backgroundColor: const Color(0xFF00E5FF),
          ),
        );
      }
    } catch (_) {}
  }

  void _triggerDownload(SongModel song) async {
    final isHindi = LanguageService().isHindi;
    if (_isDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHindi ? 'यह गाना पहले से ही डाउनलोड है।' : 'This song is already downloaded!'),
          backgroundColor: const Color(0xFF00E5FF),
        ),
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
                ? (isHindi ? 'गाना डाउनलोड हो गया! ऑफ़लाइन सुन सकते हैं।' : 'Song downloaded! You can now listen offline.')
                : (isHindi ? 'डाउनलोड विफल रहा, कृपया पुनः प्रयास करें।' : 'Download failed, please try again.'),
          ),
          backgroundColor: success ? const Color(0xFF00E5FF) : Colors.redAccent,
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
                        icon: const Icon(Icons.add, color: Color(0xFF00E5FF), size: 18),
                        label: Text(
                          isHindi ? 'नई प्लेलिस्ट' : 'New',
                          style: const TextStyle(color: Color(0xFF00E5FF)),
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
                            child: const Icon(Icons.queue_music_rounded, color: Color(0xFF00E5FF), size: 20),
                          ),
                          title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text('${p.songs.length} ${isHindi ? "गाने" : "songs"}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          trailing: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF00E5FF)),
                          onTap: () async {
                            await playlistService.addSongToPlaylist(p.id, song);
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF00E5FF),
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

  void _showQueueSheet(BuildContext context) {
    final isHindi = LanguageService().isHindi;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return StreamBuilder<List<SongModel>>(
              stream: widget.audioHandler.playlistStream,
              initialData: widget.audioHandler.playlist,
              builder: (context, snapshot) {
                final queue = snapshot.data ?? [];
                final currentSong = widget.audioHandler.currentSong;

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFB300).withOpacity(0.15),
                            ),
                            child: const Icon(Icons.queue_music_rounded, color: Color(0xFFFFB300), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHindi ? 'प्लेलिस्ट कतार (Queue)' : 'Up Next / Queue',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isHindi
                                      ? '${queue.length} गाने • पकड़ कर ऊपर-नीचे बदलें'
                                      : '${queue.length} songs • Drag to reorder',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    if (queue.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            isHindi ? 'कतार खाली है' : 'Queue is empty',
                            style: const TextStyle(color: Colors.white38),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ReorderableListView.builder(
                          scrollController: scrollController,
                          itemCount: queue.length,
                          onReorder: (oldIndex, newIndex) {
                            widget.audioHandler.reorderQueue(oldIndex, newIndex);
                          },
                          itemBuilder: (context, index) {
                            final s = queue[index];
                            final isPlaying = currentSong?.id == s.id;
                            return Container(
                              key: ValueKey('queue_${s.id}_$index'),
                              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPlaying
                                    ? const Color(0xFF00E5FF).withOpacity(0.12)
                                    : Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isPlaying
                                      ? const Color(0xFF00E5FF).withOpacity(0.4)
                                      : Colors.transparent,
                                ),
                              ),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: (s.localThumbnailPath != null &&
                                          File(s.localThumbnailPath!).existsSync())
                                      ? Image.file(
                                          File(s.localThumbnailPath!),
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          s.thumbnailUrl,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 44,
                                            height: 44,
                                            color: Colors.white12,
                                            child: const Icon(Icons.music_note, color: Colors.white54),
                                          ),
                                        ),
                                ),
                                title: Text(
                                  s.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isPlaying ? const Color(0xFF00E5FF) : Colors.white,
                                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  s.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isPlaying
                                        ? const Color(0xFF00E5FF).withOpacity(0.8)
                                        : Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isPlaying)
                                      const Icon(Icons.volume_up_rounded, color: Color(0xFF00E5FF), size: 20)
                                    else
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                                        onPressed: () {
                                          widget.audioHandler.removeFromQueue(index);
                                        },
                                      ),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                        child: Icon(Icons.drag_handle_rounded, color: Colors.white54, size: 22),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  widget.audioHandler.playSong(s);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCreatePlaylistDialog(SongModel song) {
    final controller = TextEditingController();
    final playlistService = PlaylistService();
    final isHindi = LanguageService().isHindi;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          isHindi ? 'नई प्लेलिस्ट बनाएं' : 'Create Playlist',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: isHindi ? 'प्लेलिस्ट का नाम' : 'Playlist name',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00E5FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isHindi ? 'रद्द करें' : 'Cancel', style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newPlaylist = await playlistService.createPlaylist(name);
                await playlistService.addSongToPlaylist(newPlaylist.id, song);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF00E5FF),
                      content: Text(isHindi ? '"$name" बन गई और गाना जुड़ गया!' : 'Playlist "$name" created!'),
                    ),
                  );
                }
              }
            },
            child: Text(isHindi ? 'बनाएं' : 'Create'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const primaryCyan = Color(0xFF00E5FF);
    const primaryPink = Color(0xFFFF2A6D);

    return StreamBuilder<SongModel?>(
      stream: widget.audioHandler.currentSongStream,
      initialData: widget.audioHandler.currentSong,
      builder: (context, snapshot) {
        final song = snapshot.data;
        if (song == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F0F),
            body: Center(
              child: Text(
                'Koi gaana nahi baj raha hai',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1B0E23), // Deep radiant obsidian magenta
                  Color(0xFF0B0D13), // Pure obsidian black
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top App Bar with PiP Floating Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Tactile3DWrapper(
                          onTap: () => Navigator.pop(context),
                          scaleElevation: 1.15,
                          isCircle: true,
                          glowColor: Colors.white,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Center(
                              child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              LanguageService().isHindi ? 'अब बज रहा है' : 'PLAYING FROM QUEUE',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.album.isNotEmpty ? song.album : 'Abhi Suno Master HD',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // FLOATING PICTURE-IN-PICTURE (PiP) BUTTON
                            Tactile3DWrapper(
                              onTap: _enterPictureInPicture,
                              scaleElevation: 1.15,
                              isCircle: true,
                              glowColor: primaryCyan,
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryCyan.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.picture_in_picture_alt_rounded, color: Colors.black, size: 20),
                                ),
                              ),
                            ),
                            Tactile3DWrapper(
                              onTap: () => _showAddToPlaylistSheet(song),
                              scaleElevation: 1.15,
                              isCircle: true,
                              glowColor: primaryPink,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF2A6D), Color(0xFFFF7597)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryPink.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.playlist_add_rounded, color: Colors.white, size: 22),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Album Artwork with 3D Shadow & Radiant Border
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: primaryCyan.withOpacity(0.25),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                          BoxShadow(
                            color: primaryPink.withOpacity(0.18),
                            blurRadius: 28,
                            offset: const Offset(0, -6),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.85),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: (song.localThumbnailPath != null &&
                                File(song.localThumbnailPath!).existsSync())
                            ? Image.file(
                                File(song.localThumbnailPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade900,
                                  child: const Icon(Icons.music_note, color: Colors.white, size: 80),
                                ),
                              )
                            : Image.network(
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

                  // Middle Row: Title, Artist, Lottie Like Button & In-App Download (Share moved to bottom!)
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

                        // ROCK-SOLID ANIMATED LIKE BUTTON (Elastic Bounce + 3 Rising Clones)
                        AnimatedBuilder(
                          animation: _favoritesService,
                          builder: (context, _) {
                            final isFav = _favoritesService.isFavorite(song.id);
                            return Tactile3DWrapper(
                              onTap: () async {
                                final added = await _favoritesService.toggleFavorite(song);
                                if (added) {
                                  ScreenBubbleCelebration.show(context);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: added ? primaryPink : Colors.grey.shade900,
                                      content: Text(
                                        added
                                            ? (LanguageService().isHindi ? 'पसंदीदा में जोड़ा गया!' : 'Added to Favorites!')
                                            : (LanguageService().isHindi ? 'पसंदीदा से हटाया गया!' : 'Removed from Favorites!'),
                                      ),
                                    ),
                                  );
                                }
                              },
                              scaleElevation: 1.15,
                              isCircle: true,
                              glowColor: primaryPink,
                              child: Container(
                                width: 46,
                                height: 46,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isFav
                                        ? [primaryPink, const Color(0xFFFF007F)]
                                        : [const Color(0xFFFF2A6D).withOpacity(0.35), Colors.white.withOpacity(0.08)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: isFav ? primaryPink : const Color(0xFFFF2A6D).withOpacity(0.6),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isFav ? primaryPink : const Color(0xFFFF2A6D)).withOpacity(0.4),
                                      blurRadius: 14,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isFav ? Colors.white : const Color(0xFFFF2A6D),
                                    size: 24,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // RESTORED RADIANT SONG SHARE BUTTON
                        Tactile3DWrapper(
                          onTap: () {
                            ShareHelper.shareSong(
                              title: song.title,
                              artist: song.artist,
                              streamUrl: song.streamUrl,
                              permaUrl: song.permaUrl,
                            );
                          },
                          scaleElevation: 1.15,
                          isCircle: true,
                          glowColor: const Color(0xFFFF9100),
                          child: Container(
                            width: 46,
                            height: 46,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF9100),
                                  Color(0xFFFF5252),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9100).withOpacity(0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.share_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ),

                        // RADIANT IN-APP DOWNLOAD BUTTON
                        _isDownloading
                            ? SizedBox(
                                width: 46,
                                height: 46,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: _downloadPercent,
                                      strokeWidth: 3,
                                      valueColor: const AlwaysStoppedAnimation<Color>(primaryCyan),
                                    ),
                                    Text(
                                      '${(_downloadPercent * 100).toInt()}%',
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            : Tactile3DWrapper(
                                onTap: () => _triggerDownload(song),
                                scaleElevation: 1.15,
                                isCircle: true,
                                glowColor: const Color(0xFF00E676),
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: _isDownloaded
                                          ? [const Color(0xFF00E676), const Color(0xFF00B0FF)]
                                          : [const Color(0xFF00E676).withOpacity(0.35), Colors.white.withOpacity(0.08)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: _isDownloaded ? const Color(0xFF00E676) : const Color(0xFF00E676).withOpacity(0.6),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E676).withOpacity(0.4),
                                        blurRadius: 14,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                                      color: _isDownloaded ? Colors.black : const Color(0xFF00E676),
                                      size: 23,
                                    ),
                                  ),
                                ),
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
                                activeTrackColor: primaryCyan,
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

                  const SizedBox(height: 8),

                  // Main Controls: Shuffle, Previous, Big Radiant Play/Pause, Next, Loop
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Radiant Shuffle Button
                        StreamBuilder<bool>(
                          stream: widget.audioHandler.shuffleStream,
                          initialData: widget.audioHandler.isShuffle,
                          builder: (context, snapshot) {
                            final isShuffle = snapshot.data ?? widget.audioHandler.isShuffle;
                            return Tactile3DWrapper(
                              onTap: () => widget.audioHandler.toggleShuffle(),
                              scaleElevation: 1.15,
                              isCircle: true,
                              glowColor: primaryCyan,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isShuffle
                                        ? [const Color(0xFF00E5FF), const Color(0xFF00B0FF)]
                                        : [const Color(0xFF00E5FF).withOpacity(0.2), Colors.white.withOpacity(0.06)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: isShuffle ? const Color(0xFF00E5FF) : Colors.white24,
                                    width: 1.4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withOpacity(isShuffle ? 0.45 : 0.15),
                                      blurRadius: 14,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.shuffle_rounded,
                                    color: isShuffle ? Colors.black : Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Radiant Previous Button
                        Tactile3DWrapper(
                          onTap: () => widget.audioHandler.skipToPrevious(),
                          scaleElevation: 1.15,
                          isCircle: true,
                          glowColor: const Color(0xFF7C4DFF),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C4DFF).withOpacity(0.45),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.skip_previous_rounded, color: Colors.white, size: 30),
                            ),
                          ),
                        ),
                        // Big Play / Pause Button with Radiant Cyan & Magenta Gradient & Weak Network Buffering Neon Ring
                        StreamBuilder<PlaybackState>(
                          stream: widget.audioHandler.playbackState,
                          builder: (context, pbSnapshot) {
                            final pb = pbSnapshot.data;
                            final isBuffering = pb?.processingState == AudioProcessingState.buffering ||
                                pb?.processingState == AudioProcessingState.loading;
                            final isPlaying = pb?.playing ?? widget.audioHandler.player.playing;

                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                if (isBuffering)
                                  Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2FC0DB).withOpacity(0.6),
                                          blurRadius: 20,
                                          spreadRadius: 3,
                                        ),
                                        BoxShadow(
                                          color: const Color(0xFFD34C8C).withOpacity(0.4),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 3.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2FC0DB)),
                                    ),
                                  ),
                                Tactile3DWrapper(
                                  scaleElevation: 1.18,
                                  isCircle: true,
                                  glowColor: const Color(0xFF00E5FF),
                                  onTap: () {
                                    if (isPlaying) {
                                      widget.audioHandler.pause();
                                    } else {
                                      widget.audioHandler.play();
                                    }
                                  },
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF00E5FF), Color(0xFFFF2A6D)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00E5FF).withOpacity(0.55),
                                          blurRadius: 24,
                                          spreadRadius: 2.0,
                                          offset: const Offset(0, 6),
                                        ),
                                        BoxShadow(
                                          color: const Color(0xFFFF2A6D).withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: isBuffering
                                          ? const SizedBox(
                                              width: 32,
                                              height: 32,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : Icon(
                                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        // Radiant Next Button
                        Tactile3DWrapper(
                          onTap: () => widget.audioHandler.skipToNext(),
                          scaleElevation: 1.15,
                          isCircle: true,
                          glowColor: const Color(0xFFFF2A6D),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF2A6D), Color(0xFFFF7597)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF2A6D).withOpacity(0.45),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.skip_next_rounded, color: Colors.white, size: 30),
                            ),
                          ),
                        ),
                        // Radiant Repeat Button
                        StreamBuilder<bool>(
                          stream: widget.audioHandler.repeatStream,
                          initialData: widget.audioHandler.isRepeat,
                          builder: (context, snapshot) {
                            final isRepeat = snapshot.data ?? widget.audioHandler.isRepeat;
                            return Tactile3DWrapper(
                              onTap: () => widget.audioHandler.toggleRepeat(),
                              scaleElevation: 1.15,
                              isCircle: true,
                              glowColor: primaryPink,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isRepeat
                                        ? [const Color(0xFFFF2A6D), const Color(0xFFFF7597)]
                                        : [const Color(0xFFFF2A6D).withOpacity(0.2), Colors.white.withOpacity(0.06)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),

                                  border: Border.all(
                                    color: isRepeat ? const Color(0xFFFF2A6D) : Colors.white24,
                                    width: 1.4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF2A6D).withOpacity(isRepeat ? 0.45 : 0.15),
                                      blurRadius: 14,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    isRepeat ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                                    color: isRepeat ? Colors.white : Colors.white70,
                                    size: 22,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ================================================================
                  // DEDICATED BOTTOM SECTION: Lyrics, 10-Band EQ & Share Song!
                  // ================================================================
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        // 1. Synchronized Karaoke Lyrics
                        Expanded(
                          child: Tactile3DWrapper(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => LyricsSheet(song: song, audioHandler: widget.audioHandler),
                              );
                            },
                            scaleElevation: 1.10,
                            glowColor: primaryCyan,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryCyan.withOpacity(0.25), const Color(0xFF00B0FF).withOpacity(0.12)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: primaryCyan.withOpacity(0.6), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryCyan.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lyrics_rounded, size: 15, color: primaryCyan),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      LanguageService().t('lyrics'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: primaryCyan, fontSize: 11.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 2. 10-Band Equalizer & 3D Surround
                        Expanded(
                          child: Tactile3DWrapper(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => EqualizerSheet(audioHandler: widget.audioHandler),
                              );
                            },
                            scaleElevation: 1.10,
                            glowColor: primaryPink,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryPink.withOpacity(0.25), const Color(0xFFFF007F).withOpacity(0.12)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: primaryPink.withOpacity(0.6), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryPink.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.equalizer_rounded, size: 15, color: primaryPink),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      LanguageService().t('equalizer'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: primaryPink, fontSize: 11.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 3. Spotify Reorderable Queue
                        Expanded(
                          child: Tactile3DWrapper(
                            onTap: () => _showQueueSheet(context),
                            scaleElevation: 1.10,
                            glowColor: const Color(0xFFFFB300),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [const Color(0xFFFFB300).withOpacity(0.25), const Color(0xFFFF8F00).withOpacity(0.12)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.6), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFB300).withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.queue_music_rounded, size: 15, color: Color(0xFFFFB300)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      LanguageService().isHindi ? 'कतार' : 'Queue',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Color(0xFFFFB300), fontSize: 11.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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

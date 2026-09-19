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
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                          onPressed: () => Navigator.pop(context),
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
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    primaryCyan.withOpacity(0.25),
                                    primaryPink.withOpacity(0.15),
                                  ],
                                ),
                                border: Border.all(color: primaryCyan.withOpacity(0.4)),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.picture_in_picture_alt_rounded, color: primaryCyan, size: 20),
                                tooltip: 'Floating Mini Player (PiP)',
                                onPressed: _enterPictureInPicture,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.playlist_add_rounded, color: Colors.white, size: 28),
                              tooltip: 'Add to Playlist',
                              onPressed: () => _showAddToPlaylistSheet(song),
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

                        // LOTTIE LIKE BUTTON (Using User's exact LottieFiles Animation + Rising 3-Clone Animation)
                        AnimatedBuilder(
                          animation: _favoritesService,
                          builder: (context, _) {
                            final isFav = _favoritesService.isFavorite(song.id);
                            return GestureDetector(
                              onTap: () async {
                                final added = await _favoritesService.toggleFavorite(song);
                                if (added) {
                                  _lottieController.animateTo(0.5, curve: Curves.easeOut);
                                  ScreenBubbleCelebration.show(context);
                                } else {
                                  _lottieController.animateTo(1.0, curve: Curves.easeIn).then((_) {
                                    if (mounted) _lottieController.reset();
                                  });
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
                              child: Container(
                                width: 48,
                                height: 48,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isFav
                                        ? [primaryPink, const Color(0xFFFF007F)]
                                        : [primaryCyan, const Color(0xFF0077FE)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isFav ? primaryPink : primaryCyan).withOpacity(0.45),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Center(
                                    child: Lottie.asset(
                                      'assets/animations/like_heart.json',
                                      controller: _lottieController,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Icon(
                                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // RADIANT IN-APP DOWNLOAD BUTTON
                        _isDownloading
                            ? SizedBox(
                                width: 38,
                                height: 38,
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
                            : Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: _isDownloaded
                                        ? [const Color(0xFF00E676), const Color(0xFF00B0FF)]
                                        : [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.04)],
                                  ),
                                  border: Border.all(
                                    color: _isDownloaded ? const Color(0xFF00E676) : Colors.white24,
                                  ),
                                  boxShadow: [
                                    if (_isDownloaded)
                                      BoxShadow(
                                        color: const Color(0xFF00E676).withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                  ],
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    _isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                                    color: _isDownloaded ? Colors.black : Colors.white,
                                    size: 22,
                                  ),
                                  tooltip: 'App me Download Karein',
                                  onPressed: () => _triggerDownload(song),
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
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isShuffle ? primaryCyan.withOpacity(0.2) : Colors.transparent,
                                border: Border.all(
                                  color: isShuffle ? primaryCyan : Colors.transparent,
                                  width: 1.2,
                                ),
                                boxShadow: isShuffle
                                    ? [
                                        BoxShadow(
                                          color: primaryCyan.withOpacity(0.3),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.shuffle_rounded,
                                  color: isShuffle ? primaryCyan : Colors.white54,
                                  size: 24,
                                ),
                                tooltip: isShuffle ? 'Shuffle On' : 'Shuffle Off',
                                onPressed: () => widget.audioHandler.toggleShuffle(),
                              ),
                            );
                          },
                        ),
                        // Radiant Previous Button
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 30),
                            onPressed: () => widget.audioHandler.skipToPrevious(),
                          ),
                        ),
                        // Big Play / Pause Button with Radiant Cyan & Magenta Gradient
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
                                  colors: [Color(0xFF00E5FF), Color(0xFFFF2A6D)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withOpacity(0.4),
                                    blurRadius: 20,
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
                        // Radiant Next Button
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 30),
                            onPressed: () => widget.audioHandler.skipToNext(),
                          ),
                        ),
                        // Radiant Repeat Button
                        StreamBuilder<bool>(
                          stream: widget.audioHandler.repeatStream,
                          initialData: widget.audioHandler.isRepeat,
                          builder: (context, snapshot) {
                            final isRepeat = snapshot.data ?? widget.audioHandler.isRepeat;
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isRepeat ? primaryCyan.withOpacity(0.2) : Colors.transparent,
                                border: Border.all(
                                  color: isRepeat ? primaryCyan : Colors.transparent,
                                  width: 1.2,
                                ),
                                boxShadow: isRepeat
                                    ? [
                                        BoxShadow(
                                          color: primaryCyan.withOpacity(0.3),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isRepeat ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                                  color: isRepeat ? primaryCyan : Colors.white54,
                                  size: 24,
                                ),
                                tooltip: isRepeat ? 'Repeat On' : 'Repeat Off',
                                onPressed: () => widget.audioHandler.toggleRepeat(),
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
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Synchronized Karaoke Lyrics
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => LyricsSheet(song: song, audioHandler: widget.audioHandler),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: primaryCyan.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: primaryCyan.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lyrics_rounded, size: 16, color: primaryCyan),
                                const SizedBox(width: 6),
                                Text(
                                  LanguageService().t('lyrics'),
                                  style: const TextStyle(color: primaryCyan, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 10-Band Equalizer & 3D Surround
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => EqualizerSheet(audioHandler: widget.audioHandler),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: primaryPink.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: primaryPink.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.equalizer_rounded, size: 16, color: primaryPink),
                                const SizedBox(width: 6),
                                Text(
                                  LanguageService().t('equalizer'),
                                  style: const TextStyle(color: primaryPink, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // DEDICATED RADIANT SHARE BUTTON IN BOTTOM SECTION!
                        InkWell(
                          onTap: () {
                            ShareHelper.shareSong(
                              title: song.title,
                              artist: song.artist,
                              streamUrl: song.streamUrl,
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9100), Color(0xFFFF5252)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9100).withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  LanguageService().isHindi ? 'शेयर करें' : 'Share',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
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

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/download_service.dart';
import '../services/language_service.dart';
import '../services/music_service.dart';
import '../services/theme_service.dart';
import '../widgets/tactile_3d_wrapper.dart';
import 'now_playing_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  final String playlistTitle;
  final String? playlistSubtitle;
  final String? playlistImageUrl;
  final AbhiAudioHandler audioHandler;
  final List<SongModel>? preloadedSongs;

  const PlaylistDetailScreen({
    Key? key,
    required this.playlistId,
    required this.playlistTitle,
    this.playlistSubtitle,
    this.playlistImageUrl,
    required this.audioHandler,
    this.preloadedSongs,
  }) : super(key: key);

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final MusicService _musicService = MusicService();
  final DownloadService _downloadService = DownloadService();
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();

  List<SongModel> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedSongs != null && widget.preloadedSongs!.isNotEmpty) {
      _songs = widget.preloadedSongs!;
      _isLoading = false;
    } else {
      _loadPlaylistSongs();
    }
  }

  Future<void> _loadPlaylistSongs() async {
    setState(() => _isLoading = true);
    try {
      final songs = await _musicService.getPlaylistSongs(widget.playlistId);
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _playSong(SongModel song) {
    widget.audioHandler.playSong(song, queue: _songs);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NowPlayingScreen(audioHandler: widget.audioHandler),
      ),
    );
  }

  void _playAll() {
    if (_songs.isNotEmpty) {
      widget.audioHandler.playSong(_songs.first, queue: _songs);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NowPlayingScreen(audioHandler: widget.audioHandler),
        ),
      );
    }
  }

  void _shuffleAll() {
    if (_songs.isNotEmpty) {
      final copy = List<SongModel>.from(_songs)..shuffle();
      widget.audioHandler.playSong(copy.first, queue: copy);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NowPlayingScreen(audioHandler: widget.audioHandler),
        ),
      );
    }
  }

  void _downloadAll() {
    final isHindi = _lang.isHindi;
    final toDownload = _songs.where((s) => !_downloadService.isSongDownloaded(s.id)).toList();
    if (toDownload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF00E676),
          content: Text(isHindi ? 'सभी गाने पहले से डाउनलोड हैं!' : 'All songs are already downloaded!'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2FC0DB),
        content: Text(isHindi
            ? '${toDownload.length} गाने डाउनलोड कतार में जोड़े गए (एक-एक करके डाउनलोड होंगे)'
            : '${toDownload.length} songs added to download queue (sequential download)'),
      ),
    );
    _downloadService.downloadSongsSequentially(toDownload);
  }

  void _downloadSong(SongModel song) async {
    final isHindi = _lang.isHindi;
    final isDownloaded = _downloadService.isSongDownloaded(song.id);
    if (isDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF00E676),
          content: Text(isHindi ? 'यह गाना पहले से डाउनलोड है!' : 'This song is already downloaded!'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2FC0DB),
        content: Text(isHindi ? 'डाउनलोड शुरू हुआ: ${song.title}' : 'Download started: ${song.title}'),
      ),
    );
    await _downloadService.downloadSong(song);
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = _lang.isHindi;
    final textColor = _theme.textColor;
    final subtextColor = _theme.subtextColor;
    const cyanNeon = Color(0xFF2FC0DB);
    const pinkNeon = Color(0xFFD34C8C);

    return Scaffold(
      backgroundColor: _theme.scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sliver App Bar with Artwork and Back Button
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF070913),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.playlistImageUrl != null && widget.playlistImageUrl!.isNotEmpty)
                    Image.network(
                      widget.playlistImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF131726)),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cyanNeon, pinkNeon],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  // Gradient Vignette
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.3),
                          const Color(0xFF070913).withOpacity(0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Title & Details
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.playlistTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.playlistSubtitle != null && widget.playlistSubtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.playlistSubtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          '${_songs.length} ${isHindi ? "गाने उपलब्ध" : "tracks available"}',
                          style: const TextStyle(color: cyanNeon, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Play All, Shuffle & Download All Buttons
          if (!_isLoading && _songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Tactile3DWrapper(
                        onTap: _playAll,
                        scaleElevation: 1.05,
                        glowColor: cyanNeon,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [cyanNeon, Color(0xFF00A2C7)]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: cyanNeon.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                isHindi ? 'सभी बजाएं' : 'Play All',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Tactile3DWrapper(
                        onTap: _shuffleAll,
                        scaleElevation: 1.05,
                        glowColor: pinkNeon,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131726),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: pinkNeon.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shuffle_rounded, color: pinkNeon, size: 17),
                              const SizedBox(width: 4),
                              Text(
                                isHindi ? 'शफ़ल' : 'Shuffle',
                                style: const TextStyle(color: pinkNeon, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Tactile3DWrapper(
                        onTap: _downloadAll,
                        scaleElevation: 1.05,
                        glowColor: const Color(0xFF00E676),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131726),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.file_download_outlined, color: Color(0xFF00E676), size: 17),
                              const SizedBox(width: 4),
                              Text(
                                isHindi ? 'सब डाउनलोड' : 'Download All',
                                style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
                  ],
                ),
              ),
            ),

          // Loading Indicator
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(cyanNeon)),
              ),
            )
          else if (_songs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  isHindi ? 'प्लेलिस्ट में कोई गाना नहीं मिला।' : 'No songs found in this playlist.',
                  style: TextStyle(color: subtextColor),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 90),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = _songs[index];
                    return StreamBuilder<MediaItem?>(
                      stream: widget.audioHandler.mediaItem,
                      builder: (context, mediaSnap) {
                        return StreamBuilder<PlaybackState>(
                          stream: widget.audioHandler.playbackState,
                          builder: (context, playSnap) {
                            final isCurrentTrack = mediaSnap.data?.id == song.id;
                            final isPlaying = isCurrentTrack &&
                                (playSnap.data?.playing ?? widget.audioHandler.playbackState.value.playing);

                            return Tactile3DWrapper(
                              scaleElevation: 1.03,
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _playSong(song),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: isCurrentTrack ? cyanNeon : subtextColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Image.network(
                                            song.thumbnailUrl,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 48,
                                              height: 48,
                                              color: Colors.grey.shade900,
                                              child: const Icon(Icons.music_note, color: Colors.white54),
                                            ),
                                          ),
                                          if (isCurrentTrack)
                                            Container(
                                              width: 48,
                                              height: 48,
                                              color: Colors.black.withOpacity(0.4),
                                              child: Icon(
                                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                                color: cyanNeon,
                                                size: 26,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isCurrentTrack ? cyanNeon : textColor,
                                    fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.w600,
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
                                      onPressed: () => _downloadSong(song),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                        color: isCurrentTrack ? cyanNeon : Colors.white70,
                                        size: 30,
                                      ),
                                      onPressed: () {
                                        if (isCurrentTrack) {
                                          isPlaying ? widget.audioHandler.pause() : widget.audioHandler.play();
                                        } else {
                                          _playSong(song);
                                        }
                                      },
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
                  childCount: _songs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

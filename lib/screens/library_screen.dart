import 'now_playing_screen.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../services/device_audio_service.dart';
import '../services/favorites_service.dart';
import '../services/language_service.dart';

class LibraryScreen extends StatefulWidget {
  final AbhiAudioHandler audioHandler;

  const LibraryScreen({Key? key, required this.audioHandler}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DownloadService _downloadService = DownloadService();
  final PlaylistService _playlistService = PlaylistService();
  final DeviceAudioService _deviceAudioService = DeviceAudioService();
  final FavoritesService _favoritesService = FavoritesService();
  final LanguageService _lang = LanguageService();

  List<SongModel> _deviceSongs = [];
  bool _isScanningDevice = false;

  // Sorting state for offline downloads: 'newest', 'a-z', 'z-a', 'oldest'
  String _downloadSortOrder = 'newest';

  @override
  void initState() {
    super.initState();
    // 4 Tabs: 0: Downloads (FIRST), 1: Liked, 2: Playlists, 3: Device Storage
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _scanDeviceMusic() async {
    setState(() => _isScanningDevice = true);
    final songs = await _deviceAudioService.scanDeviceAudioFiles();
    if (mounted) {
      setState(() {
        _deviceSongs = songs;
        _isScanningDevice = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF00E676),
          content: Text(
            _lang.isHindi
                ? '${songs.length} गाने फोन से इम्पोर्ट हो गए!'
                : '${songs.length} songs imported from phone storage!',
          ),
        ),
      );
    }
  }

  void _playSongOnly(SongModel song, List<SongModel> queue) {
    final currentId = widget.audioHandler.mediaItem.value?.id;
    if (currentId == song.id) {
      final isPlaying = widget.audioHandler.playbackState.value.playing;
      isPlaying ? widget.audioHandler.pause() : widget.audioHandler.play();
    } else {
      widget.audioHandler.playSong(song, queue: queue);
    }
  }

  void _playSong(SongModel song, List<SongModel> queue) {
    final currentId = widget.audioHandler.mediaItem.value?.id;
    if (currentId != song.id) {
      widget.audioHandler.playSong(song, queue: queue);
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NowPlayingScreen(audioHandler: widget.audioHandler),
      ),
    );
  }

  List<SongModel> _getSortedDownloads(List<SongModel> raw) {
    final list = List<SongModel>.from(raw);
    switch (_downloadSortOrder) {
      case 'a-z':
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'z-a':
        list.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case 'oldest':
        // list in natural stored order
        break;
      case 'newest':
      default:
        // reversed order
        return list.reversed.toList();
    }
    return list;
  }

  double _calculateDownloadsSizeMb(List<SongModel> songs) {
    int totalBytes = 0;
    for (final s in songs) {
      if (s.localFilePath != null) {
        final f = File(s.localFilePath!);
        if (f.existsSync()) {
          totalBytes += f.lengthSync();
        }
      }
    }
    return totalBytes / (1024 * 1024);
  }

  void _showCreatePlaylistDialog({SongModel? initialSong}) {
    final controller = TextEditingController();
    final isHindi = _lang.isHindi;

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
                await _playlistService.createPlaylist(name);
                if (initialSong != null && _playlistService.playlists.isNotEmpty) {
                  await _playlistService.addSongToPlaylist(_playlistService.playlists.first.id, initialSong);
                }
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF05D9E8),
                      content: Text(isHindi ? 'प्लेलिस्ट "$name" बन गई!' : 'Playlist "$name" created!'),
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

  void _showAddToPlaylistDialog(SongModel song, bool isHindi) {
    final playlists = _playlistService.playlists;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isHindi ? 'प्लेलिस्ट में जोड़ें' : 'Add to Playlist',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18, color: Color(0xFF05D9E8)),
                      label: Text(isHindi ? 'नई' : 'New', style: const TextStyle(color: Color(0xFF05D9E8))),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCreatePlaylistDialog(initialSong: song);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              if (playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      isHindi ? 'कोई प्लेलिस्ट नहीं है। ऊपर "नई" पर टैप करें।' : 'No playlists yet. Tap "New" above.',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                )
              else
                ...playlists.map(
                  (p) => ListTile(
                    leading: const Icon(Icons.queue_music_rounded, color: Color(0xFF05D9E8)),
                    title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text('${p.songs.length} ${isHindi ? "गाने" : "songs"}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    onTap: () async {
                      await _playlistService.addSongToPlaylist(p.id, song);
                      Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF05D9E8),
                            content: Text(isHindi ? '"${p.name}" में गाना जुड़ गया!' : 'Added to "${p.name}"!'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showRenamePlaylistDialog(UserPlaylist playlist, StateSetter setModalState, bool isHindi) {
    final controller = TextEditingController(text: playlist.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(isHindi ? 'प्लेलिस्ट का नाम बदलें' : 'Rename Playlist', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: isHindi ? 'नया नाम दर्ज करें...' : 'Enter new name...',
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
            child: Text(isHindi ? 'सहेजें' : 'Save', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await _playlistService.renamePlaylist(playlist.id, newName);
                setModalState(() {});
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF05D9E8),
                      content: Text(isHindi ? 'प्लेलिस्ट का नाम बदल दिया गया!' : 'Playlist renamed!'),
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

  void _openPlaylistDetails(UserPlaylist playlist) {
    final isHindi = _lang.isHindi;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDownloading = _playlistService.playlistDownloadProgress.containsKey(playlist.id);
            final downloadProgress = _playlistService.playlistDownloadProgress[playlist.id] ?? 0.0;

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.4,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        playlist.name,
                                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: Colors.white54, size: 18),
                                      tooltip: isHindi ? 'नाम बदलें' : 'Rename',
                                      onPressed: () => _showRenamePlaylistDialog(playlist, setModalState, isHindi),
                                    ),
                                  ],
                                ),
                                Text('${playlist.songs.length} ${isHindi ? "गाने" : "tracks"}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),
                          if (playlist.songs.isNotEmpty) ...[
                            IconButton(
                              icon: const Icon(Icons.shuffle_rounded, color: Color(0xFF05D9E8), size: 24),
                              tooltip: isHindi ? 'शफ़ल करके बजाएं' : 'Shuffle Play',
                              onPressed: () {
                                final songsCopy = List<SongModel>.from(playlist.songs)..shuffle();
                                _playSong(songsCopy.first, songsCopy);
                                Navigator.pop(ctx);
                              },
                            ),
                            isDownloading
                                ? SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      value: downloadProgress,
                                      strokeWidth: 2.5,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF05D9E8)),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.download_for_offline_rounded, color: Color(0xFF05D9E8), size: 28),
                                    tooltip: isHindi ? 'पूरी प्लेलिस्ट डाउनलोड करें' : 'Download Playlist',
                                    onPressed: () async {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: const Color(0xFF05D9E8),
                                          content: Text(isHindi ? 'प्लेलिस्ट डाउनलोड हो रही है...' : 'Downloading playlist...'),
                                        ),
                                      );
                                      final res = await _playlistService.downloadEntirePlaylist(
                                        playlist.id,
                                        onProgress: (done, total, p) => setModalState(() {}),
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: const Color(0xFF00E676),
                                            content: Text(
                                              isHindi
                                                  ? '${res["downloaded"]} गाने सफलतापूर्वक डाउनलोड हो गए!'
                                                  : '${res["downloaded"]} songs downloaded successfully!',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                            IconButton(
                              icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF05D9E8), size: 36),
                              onPressed: () {
                                _playSong(playlist.songs.first, playlist.songs);
                                Navigator.pop(ctx);
                              },
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                            tooltip: isHindi ? 'प्लेलिस्ट डिलीट करें' : 'Delete Playlist',
                            onPressed: () async {
                              await _playlistService.deletePlaylist(playlist.id);
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    ),
                    if (isDownloading)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: LinearProgressIndicator(
                          value: downloadProgress,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF05D9E8)),
                        ),
                      ),
                    const Divider(color: Colors.white10),
                    Expanded(
                      child: playlist.songs.isEmpty
                          ? Center(
                              child: Text(
                                isHindi ? 'प्लेलिस्ट खाली है। गाने जोड़ें।' : 'Playlist is empty. Add songs from player.',
                                style: const TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: playlist.songs.length,
                              itemBuilder: (context, i) {
                                final song = playlist.songs[i];
                                return ListTile(
                                  leading: const Icon(Icons.music_note, color: Color(0xFF05D9E8)),
                                  title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                                  subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white38),
                                    onPressed: () async {
                                      await _playlistService.removeSongFromPlaylist(playlist.id, song.id);
                                      setModalState(() {});
                                    },
                                  ),
                                  onTap: () {
                                    _playSong(song, playlist.songs);
                                    Navigator.pop(ctx);
                                  },
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

  void _showSongActionMenu(SongModel song, bool isHindi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: song.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          song.thumbnailUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 44, height: 44, color: Colors.white10, child: const Icon(Icons.music_note, color: Colors.white54)),
                        )
                      : Container(width: 44, height: 44, color: Colors.white10, child: const Icon(Icons.music_note, color: Colors.white54)),
                ),
                title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded, color: Color(0xFF05D9E8)),
                title: Text(isHindi ? 'बजाएं' : 'Play', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _playSong(song, _downloadService.downloadedSongs);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded, color: Colors.white70),
                title: Text(isHindi ? 'प्लेलिस्ट में जोड़ें' : 'Add to Playlist', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddToPlaylistDialog(song, isHindi);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.white70),
                title: Text(isHindi ? 'शेयर करें' : 'Share', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _downloadService.shareAudioFile(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined, color: Colors.white70),
                title: Text(isHindi ? 'फोन मेमोरी में एक्सपोर्ट करें' : 'Save/Export Outside App', style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final exportPath = await _downloadService.exportSongToPublic(song);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: exportPath != null ? const Color(0xFF05D9E8) : Colors.redAccent,
                        content: Text(
                          exportPath != null
                              ? (isHindi ? 'गाना फोन के Music फोल्डर में सुरक्षित हो गया!' : 'Song exported to public Music folder!')
                              : (isHindi ? 'एक्सपोर्ट विफल रहा।' : 'Export failed.'),
                        ),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: Colors.white70),
                title: Text(isHindi ? 'गीत विवरण (Song Info)' : 'Song Information', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSongInfoDialog(song, isHindi);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                title: Text(isHindi ? 'डाउनलोड से हटाएं' : 'Delete Song', style: const TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteSong(song, isHindi);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteSong(SongModel song, bool isHindi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(isHindi ? 'गाना हटाएं?' : 'Delete Song?', style: const TextStyle(color: Colors.white)),
        content: Text(
          isHindi
              ? 'क्या आप वाकई "${song.title}" को ऑफलाइन वॉल्ट से हटाना चाहते हैं?'
              : 'Are you sure you want to delete "${song.title}" from offline downloads?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isHindi ? 'रद्द करें' : 'Cancel', style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _downloadService.deleteDownloadedSong(song.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isHindi ? 'गाना हटा दिया गया।' : 'Song deleted from offline storage.'),
                  ),
                );
              }
            },
            child: Text(isHindi ? 'हटाएं' : 'Delete', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSongInfoDialog(SongModel song, bool isHindi) {
    int fileSize = 0;
    if (song.localFilePath != null && File(song.localFilePath!).existsSync()) {
      fileSize = File(song.localFilePath!).lengthSync();
    }
    final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(isHindi ? 'गीत विवरण' : 'Song Information', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(isHindi ? 'शीर्षक:' : 'Title:', song.title),
            _infoRow(isHindi ? 'कलाकार:' : 'Artist:', song.artist),
            _infoRow(isHindi ? 'एल्बम:' : 'Album:', song.album),
            _infoRow(isHindi ? 'अवधि:' : 'Duration:', '${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}'),
            _infoRow(isHindi ? 'फ़ाइल साइज़:' : 'File Size:', '$sizeMb MB'),
            _infoRow(isHindi ? 'फॉर्मेट:' : 'Format:', 'M4A / AAC (320 kbps)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isHindi ? 'ठीक है' : 'Close', style: const TextStyle(color: const Color(0xFF05D9E8))),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _lang,
      builder: (context, _) {
        final isHindi = _lang.isHindi;

        return Column(
          children: [
            // 4-Tab Header: Downloads (FIRST), Liked Songs, Playlists, Device Songs
            Container(
              color: const Color(0xFF0F0F0F),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF05D9E8),
                labelColor: const Color(0xFF05D9E8),
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(icon: const Icon(Icons.download_done_rounded), text: _lang.t('downloads')),
                  Tab(icon: const Icon(Icons.favorite_rounded), text: _lang.t('liked_songs')),
                  Tab(icon: const Icon(Icons.queue_music_rounded), text: _lang.t('playlists')),
                  Tab(icon: const Icon(Icons.phone_android_rounded), text: isHindi ? 'फ़ोन स्टोरेज' : 'Device Storage'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDownloadsTab(isHindi),
                  _buildLikedSongsTab(isHindi),
                  _buildPlaylistsTab(isHindi),
                  _buildDeviceSongsTab(isHindi),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // TAB 1 (INDEX 0): OFFLINE DOWNLOADS (FIRST PRIORITY, SORTING & CONTINUOUS PLAY)
  // ============================================================================
  Widget _buildDownloadsTab(bool isHindi) {
    return AnimatedBuilder(
      animation: _downloadService,
      builder: (context, _) {
        final rawDownloads = _downloadService.downloadedSongs;
        final sortedDownloads = _getSortedDownloads(rawDownloads);
        final totalMb = _calculateDownloadsSizeMb(rawDownloads).toStringAsFixed(1);

        return Column(
          children: [
            // Storage Meter & Action Bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF05D9E8).withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF05D9E8).withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF05D9E8).withOpacity(0.2),
                            ),
                            child: const Icon(Icons.offline_pin_rounded, color: Color(0xFF05D9E8), size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHindi ? 'ऑफलाइन वॉल्ट' : 'Offline Vault',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                '${rawDownloads.length} ${isHindi ? "सुरक्षित गाने" : "songs"} • $totalMb MB',
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (sortedDownloads.isNotEmpty)
                        Row(
                          children: [
                            // Play All
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF05D9E8),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 18),
                              label: Text(
                                isHindi ? 'सभी बजाएं' : 'Play All',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              onPressed: () => _playSong(sortedDownloads.first, sortedDownloads),
                            ),
                            const SizedBox(width: 6),
                            // Shuffle
                            IconButton(
                              icon: const Icon(Icons.shuffle_rounded, color: Color(0xFF05D9E8), size: 22),
                              tooltip: isHindi ? 'शफ़ल मिक्स' : 'Shuffle Mix',
                              onPressed: () {
                                final shuffled = List<SongModel>.from(sortedDownloads)..shuffle();
                                _playSong(shuffled.first, shuffled);
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Sort Options Bar
                  Row(
                    children: [
                      Text(
                        isHindi ? 'क्रमबद्ध:' : 'Sort:',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildSortPill('newest', isHindi ? 'हाल के (Newest)' : 'Newest'),
                              const SizedBox(width: 6),
                              _buildSortPill('a-z', 'A - Z'),
                              const SizedBox(width: 6),
                              _buildSortPill('z-a', 'Z - A'),
                              const SizedBox(width: 6),
                              _buildSortPill('oldest', isHindi ? 'पुराने (Oldest)' : 'Oldest'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Downloads List
            Expanded(
              child: sortedDownloads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_download_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(
                            isHindi ? 'कोई डाउनलोड किया गया गाना नहीं है' : 'No downloaded songs yet',
                            style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              isHindi
                                  ? 'ऑनलाइन होने पर किसी भी गाने पर डाउनलोड आइकन दबाएं और कभी भी बिना इंटरनेट के सुनें।'
                                  : 'Tap download on any track to listen offline anytime without internet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: sortedDownloads.length,
                      itemBuilder: (context, index) {
                        final song = sortedDownloads[index];
                        return StreamBuilder<MediaItem?>(
                          stream: widget.audioHandler.mediaItem,
                          builder: (context, mediaSnap) {
                            final isCurrentTrack = mediaSnap.data?.id == song.id;
                            final isPlaying = isCurrentTrack && widget.audioHandler.playbackState.value.playing;

                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    song.localThumbnailPath != null && File(song.localThumbnailPath!).existsSync()
                                        ? Image.file(
                                            File(song.localThumbnailPath!),
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: 48,
                                              height: 48,
                                              color: Colors.white10,
                                              child: const Icon(Icons.music_note, color: Colors.white54),
                                            ),
                                          )
                                        : song.thumbnailUrl.isNotEmpty
                                            ? Image.network(
                                                song.thumbnailUrl,
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  width: 48,
                                                  height: 48,
                                                  color: Colors.white10,
                                                  child: const Icon(Icons.music_note, color: Colors.white54),
                                                ),
                                              )
                                            : Container(
                                                width: 48,
                                                height: 48,
                                                color: Colors.white10,
                                                child: const Icon(Icons.music_note, color: Colors.white54),
                                              ),
                                    if (isCurrentTrack)
                                      Container(
                                        width: 48,
                                        height: 48,
                                        color: Colors.black.withOpacity(0.4),
                                        child: const Icon(Icons.equalizer_rounded, color: Color(0xFF00E5FF), size: 24),
                                      ),
                                  ],
                                ),
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrentTrack ? const Color(0xFF00E5FF) : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 12),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${song.artist} • 320 kbps',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
                                    tooltip: isHindi ? 'अधिक विकल्प' : 'Options',
                                    onPressed: () => _showSongActionMenu(song, isHindi),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_filled_rounded,
                                      color: isCurrentTrack ? const Color(0xFF00E5FF) : const Color(0xFF05D9E8),
                                      size: 30,
                                    ),
                                    onPressed: () => _playSongOnly(song, sortedDownloads),
                                  ),
                                ],
                              ),
                              onTap: () => _playSong(song, sortedDownloads),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSortPill(String key, String label) {
    final isSelected = _downloadSortOrder == key;
    return InkWell(
      onTap: () => setState(() => _downloadSortOrder = key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF05D9E8) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF05D9E8) : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // TAB 2 (INDEX 1): LIKED SONGS
  // ============================================================================
  Widget _buildLikedSongsTab(bool isHindi) {
    return AnimatedBuilder(
      animation: _favoritesService,
      builder: (context, _) {
        final likedSongs = _favoritesService.favoriteSongs;

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B1528), Color(0xFF1E0E18)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF2A6D).withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF2A6D).withOpacity(0.18),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Color(0xFFFF2A6D), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHindi ? 'पसंदीदा गीत' : 'Liked Songs',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${likedSongs.length} ${isHindi ? "पसंदीदा गाने" : "favorite tracks"}',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (likedSongs.isNotEmpty)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2A6D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(isHindi ? 'बजाएं' : 'Play All', style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _playSong(likedSongs.first, likedSongs),
                    ),
                ],
              ),
            ),
            Expanded(
              child: likedSongs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_border_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(
                            isHindi ? 'कोई पसंदीदा गाना नहीं है' : 'No liked songs yet',
                            style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isHindi
                                ? 'किसी भी गाने के दिल वाले आइकन पर टैप करें।'
                                : 'Tap the heart icon on any song to add here.',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: likedSongs.length,
                      itemBuilder: (context, index) {
                        final song = likedSongs[index];
                        return StreamBuilder<MediaItem?>(
                          stream: widget.audioHandler.mediaItem,
                          builder: (context, mediaSnap) {
                            final isCurrentTrack = mediaSnap.data?.id == song.id;
                            final isPlaying = isCurrentTrack && widget.audioHandler.playbackState.value.playing;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: ClipRRect(
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
                                        color: Colors.white10,
                                        child: const Icon(Icons.music_note, color: Colors.white54),
                                      ),
                                    ),
                                    if (isCurrentTrack)
                                      Container(
                                        width: 48,
                                        height: 48,
                                        color: Colors.black.withOpacity(0.4),
                                        child: const Icon(Icons.equalizer_rounded, color: Color(0xFF00E5FF), size: 24),
                                      ),
                                  ],
                                ),
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrentTrack ? const Color(0xFF00E5FF) : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.favorite_rounded, color: Color(0xFFFF2A6D), size: 22),
                                    onPressed: () => _favoritesService.toggleFavorite(song),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_filled_rounded,
                                      color: isCurrentTrack ? const Color(0xFF00E5FF) : const Color(0xFF05D9E8),
                                      size: 28,
                                    ),
                                    onPressed: () => _playSongOnly(song, likedSongs),
                                  ),
                                ],
                              ),
                              onTap: () => _playSong(song, likedSongs),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // TAB 3 (INDEX 2): PLAYLISTS
  // ============================================================================
  Widget _buildPlaylistsTab(bool isHindi) {
    return AnimatedBuilder(
      animation: _playlistService,
      builder: (context, _) {
        final playlists = _playlistService.playlists;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF05D9E8),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.playlist_add_rounded),
                label: Text(
                  isHindi ? 'नई प्लेलिस्ट बनाएं' : 'Create New Playlist',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () => _showCreatePlaylistDialog(),
              ),
            ),
            Expanded(
              child: playlists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.queue_music_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(
                            isHindi ? 'कोई प्लेलिस्ट नहीं बनाई गई' : 'No playlists created yet',
                            style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isHindi ? 'अपनी पसंदीदा धुनों की लिस्ट बनाने के लिए ऊपर टैप करें।' : 'Tap above to organize your music.',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final p = playlists[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF05D9E8).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.queue_music_rounded, color: Color(0xFF05D9E8)),
                          ),
                          title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text('${p.songs.length} ${isHindi ? "गाने" : "tracks"}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
                          onTap: () => _openPlaylistDetails(p),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // TAB 4 (INDEX 3): DEVICE AUDIO FILES
  // ============================================================================
  Widget _buildDeviceSongsTab(bool isHindi) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF05D9E8)),
              ),
            ),
            icon: _isScanningDevice
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF05D9E8)))
                : const Icon(Icons.refresh_rounded, color: Color(0xFF05D9E8)),
            label: Text(
              _isScanningDevice
                  ? (isHindi ? 'फ़ोन स्टोरेज स्कैन हो रहा है...' : 'Scanning device storage...')
                  : (isHindi ? 'फ़ोन के गाने स्कैन करें (Scan Device)' : 'Scan Phone Storage'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: _isScanningDevice ? null : _scanDeviceMusic,
          ),
        ),
        Expanded(
          child: _deviceSongs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sd_storage_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        isHindi ? 'कोई स्थानीय गाना नहीं मिला' : 'No local audio files found',
                        style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isHindi ? 'अपने फोन मेमोरी के गानों को लोड करने के लिए ऊपर स्कैन करें।' : 'Tap scan above to discover audio files on your phone.',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: _deviceSongs.length,
                  itemBuilder: (context, index) {
                    final song = _deviceSongs[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.audiotrack_rounded, color: Color(0xFF05D9E8)),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Phone Storage • Local Audio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                      ),
                      trailing: const Icon(Icons.play_arrow_rounded, color: Color(0xFF05D9E8), size: 28),
                      onTap: () => _playSong(song, _deviceSongs),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

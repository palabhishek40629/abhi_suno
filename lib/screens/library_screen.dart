import 'dart:io';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
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

  void _playSong(SongModel song, List<SongModel> queue) {
    widget.audioHandler.playSong(song, queue: queue);
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
                            // Shuffle Play
                            IconButton(
                              icon: const Icon(Icons.shuffle_rounded, color: Color(0xFF05D9E8), size: 24),
                              tooltip: isHindi ? 'शफ़ल करके बजाएं' : 'Shuffle Play',
                              onPressed: () {
                                final songsCopy = List<SongModel>.from(playlist.songs)..shuffle();
                                _playSong(songsCopy.first, songsCopy);
                                Navigator.pop(ctx);
                              },
                            ),
                            // Download Playlist
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
                            // Play All
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
            // 4-Tab Header (Liked Songs, Downloads, Playlists, Device Songs)
            Container(
              color: const Color(0xFF0F0F0F),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFFF2A6D),
                indicatorWeight: 3,
                labelColor: const Color(0xFFFF2A6D),
                unselectedLabelColor: Colors.white54,
                isScrollable: true,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.favorite_rounded, size: 20),
                    text: isHindi ? 'पसंदीदा' : 'Liked',
                  ),
                  Tab(
                    icon: const Icon(Icons.download_done_rounded, size: 20),
                    text: isHindi ? 'डाउनलोड्स' : 'Downloads',
                  ),
                  Tab(
                    icon: const Icon(Icons.playlist_play_rounded, size: 20),
                    text: isHindi ? 'प्लेलिस्ट' : 'Playlists',
                  ),
                  Tab(
                    icon: const Icon(Icons.phone_android_rounded, size: 20),
                    text: isHindi ? 'फोन गाने' : 'Device',
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: Liked Songs (Favorites)
                  _buildLikedSongsTab(isHindi),

                  // TAB 2: In-App Downloads (Instant reactive updates!)
                  _buildDownloadsTab(isHindi),

                  // TAB 3: Custom Playlists
                  _buildPlaylistsTab(isHindi),

                  // TAB 4: Device Music
                  _buildDeviceSongsTab(isHindi),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDownloadsTab(bool isHindi) {
    return AnimatedBuilder(
      animation: _downloadService,
      builder: (context, _) {
        final downloadedSongs = _downloadService.downloadedSongs;

        return Column(
          children: [
            // Offline Vault Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        Text(
                          isHindi ? 'ऐप ऑफलाइन वॉल्ट' : 'App Offline Vault',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${downloadedSongs.length} ${isHindi ? "गाने डाउनलोडेड हैं (बिना इंटरनेट सुनिए)" : "songs downloaded (play offline anytime)"}',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (downloadedSongs.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF05D9E8), size: 36),
                      onPressed: () => _playSong(downloadedSongs.first, downloadedSongs),
                    ),
                ],
              ),
            ),

            Expanded(
              child: downloadedSongs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.downloading_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          Text(
                            isHindi ? 'अभी कोई गाना डाउनलोड नहीं है।' : 'No songs downloaded yet.',
                            style: const TextStyle(color: Colors.white70, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isHindi ? 'किसी भी गाने पर Download बटन दबाएं!' : 'Tap Download on any song!',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: downloadedSongs.length,
                      itemBuilder: (context, index) {
                        final song = downloadedSongs[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: song.thumbnailUrl.isNotEmpty
                                ? Image.network(
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
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey.shade900,
                                    child: const Icon(Icons.music_note, color: Colors.white54),
                                  ),
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${song.artist} • In-App Vault',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
                                tooltip: 'Options',
                                onPressed: () => _showSongActionMenu(song, isHindi),
                              ),
                              IconButton(
                                icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF05D9E8), size: 28),
                                onPressed: () => _playSong(song, downloadedSongs),
                              ),
                            ],
                          ),
                          onTap: () => _playSong(song, downloadedSongs),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaylistsTab(bool isHindi) {
    return AnimatedBuilder(
      animation: _playlistService,
      builder: (context, _) {
        final playlists = _playlistService.playlists;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isHindi ? 'मेरी प्लेलिस्ट्स' : 'My Playlists',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF05D9E8),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(isHindi ? 'नई प्लेलिस्ट' : 'New Playlist', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showCreatePlaylistDialog(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: playlists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.queue_music_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          Text(
                            isHindi ? 'कोई प्लेलिस्ट नहीं है।' : 'No custom playlists yet.',
                            style: const TextStyle(color: Colors.white70, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isHindi ? 'अपनी पसंद के गानों की सूची बनाएं!' : 'Create one to organize your favorites!',
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
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.playlist_play_rounded, color: Color(0xFF05D9E8), size: 30),
                          ),
                          title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text('${p.songs.length} ${isHindi ? "गाने" : "songs"}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
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

  Widget _buildDeviceSongsTab(bool isHindi) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHindi ? 'फोन के गाने' : 'Device Audio',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: _isScanningDevice
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(isHindi ? 'स्कैन करें' : 'Rescan', style: const TextStyle(fontSize: 12)),
                onPressed: _isScanningDevice ? null : _scanDeviceMusic,
              ),
            ],
          ),
        ),
        Expanded(
          child: _deviceSongs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_android_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      Text(
                        isHindi ? 'कोई स्थानीय गाना नहीं मिला।' : 'No device songs scanned yet.',
                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isHindi ? 'ऊपर "स्कैन करें" बटन दबाएं।' : 'Tap "Rescan" above to import songs from phone.',
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.audio_file_rounded, color: Color(0xFF05D9E8), size: 24),
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

  Widget _buildLikedSongsTab(bool isHindi) {
    return AnimatedBuilder(
      animation: _favoritesService,
      builder: (context, _) {
        final likedSongs = _favoritesService.favoriteSongs;

        return Column(
          children: [
            // Liked Songs Header Banner
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
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
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
                                icon: const Icon(Icons.play_circle_filled_rounded, color: Color(0xFF05D9E8), size: 28),
                                onPressed: () => _playSong(song, likedSongs),
                              ),
                            ],
                          ),
                          onTap: () => _playSong(song, likedSongs),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

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

  List<SongModel> _downloadedSongs = [];
  List<SongModel> _deviceSongs = [];
  bool _isLoading = true;
  bool _isScanningDevice = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDownloads();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  void _deleteSong(String songId) async {
    await _downloadService.deleteDownloadedSong(songId);
    _loadDownloads();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lang.isHindi ? 'गाना हटा दिया गया।' : 'Song deleted from offline storage.'),
        ),
      );
    }
  }

  void _showCreatePlaylistDialog() {
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
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
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
                                Text(playlist.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                Text('${playlist.songs.length} ${isHindi ? "गाने" : "tracks"}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),
                          if (playlist.songs.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF05D9E8), size: 36),
                              onPressed: () {
                                _playSong(playlist.songs.first, playlist.songs);
                                Navigator.pop(ctx);
                              },
                            ),
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

                  // TAB 2: In-App Downloads
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
                      '${_downloadedSongs.length} ${isHindi ? "गाने डाउनलोडेड हैं (बिना इंटरनेट सुनिए)" : "songs downloaded (play offline anytime)"}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (_downloadedSongs.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF05D9E8), size: 36),
                  onPressed: () => _playSong(_downloadedSongs.first, _downloadedSongs),
                ),
            ],
          ),
        ),

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
                      itemCount: _downloadedSongs.length,
                      itemBuilder: (context, index) {
                        final song = _downloadedSongs[index];
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
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 20),
                                tooltip: 'Delete',
                                onPressed: () => _deleteSong(song.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF05D9E8), size: 28),
                                onPressed: () => _playSong(song, _downloadedSongs),
                              ),
                            ],
                          ),
                          onTap: () => _playSong(song, _downloadedSongs),
                        );
                      },
                    ),
        ),
      ],
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
                    isHindi ? 'आपकी प्लेलिस्ट्स' : 'Your Playlists',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF05D9E8),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      isHindi ? 'नई प्लेलिस्ट' : 'New Playlist',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: _showCreatePlaylistDialog,
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
                          Icon(Icons.playlist_add_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          Text(
                            isHindi ? 'कोई प्लेलिस्ट नहीं बनाई गई।' : 'No playlists created yet.',
                            style: const TextStyle(color: Colors.white70, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isHindi ? 'अपनी पसंदीदा गानों की प्लेलिस्ट बनाएं!' : 'Create playlists of your favorite songs!',
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
                        final pl = playlists[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF05D9E8), Color(0xFFFF2A6D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.queue_music_rounded, color: Colors.white, size: 28),
                          ),
                          title: Text(
                            pl.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            '${pl.songs.length} ${isHindi ? "गाने" : "tracks"}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                          onTap: () => _openPlaylistDetails(pl),
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
        // Scan Button Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Icon(Icons.audio_file_rounded, color: Color(0xFF05D9E8), size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? 'फोन के गाने इम्पोर्ट करें' : 'Import Phone Songs',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isHindi ? 'MP3, M4A, WAV फाइल्स को सीधे बजाएं' : 'Play MP3, M4A, WAV from storage',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF05D9E8),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isScanningDevice ? null : _scanDeviceMusic,
                child: _isScanningDevice
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
                      )
                    : Text(
                        isHindi ? 'स्कैन करें' : 'Scan',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
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
                      Icon(Icons.speaker_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      Text(
                        isHindi ? 'अभी कोई फोन का गाना लोड नहीं हुआ।' : 'No device songs scanned yet.',
                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isHindi ? 'ऊपर "स्कैन करें" बटन दबाएं।' : 'Tap "Scan" above to search phone storage.',
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

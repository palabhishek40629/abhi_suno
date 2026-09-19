import 'now_playing_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/download_service.dart';
import '../services/language_service.dart';
import '../services/music_service.dart';
import '../services/performance_guard.dart';
import '../services/theme_service.dart';
import '../services/audio_providers/jiosaavn_adapter.dart';
import '../widgets/tactile_3d_wrapper.dart';

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
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();

  List<SongModel> _results = [];
  List<JioSaavnPlaylist> _playlistResults = [];
  List<String> _history = [];
  List<String> _liveSuggestions = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _activeFilter = 'all'; // 'all', 'songs', 'playlists', 'artists'

  Timer? _debounceTimer;
  static const String _historyKey = 'abhi_suno_search_history';


  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_historyKey) ?? [];
      if (mounted) {
        setState(() => _history = list);
      }
    } catch (_) {}
  }

  Future<void> _addToHistory(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    _history.remove(clean);
    _history.insert(0, clean);
    if (_history.length > 25) _history = _history.sublist(0, 25);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_historyKey, _history);
    } catch (_) {}
  }

  Future<void> _removeFromHistory(String query) async {
    setState(() {
      _history.remove(query);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_historyKey, _history);
    } catch (_) {}
  }

  Future<void> _clearAllHistory() async {
    setState(() {
      _history.clear();
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (_) {}
  }

  void _onQueryChanged(String val) {
    _debounceTimer?.cancel();
    final query = val.trim();
    if (query.length < 2) {
      if (mounted) {
        setState(() => _liveSuggestions = []);
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 120), () async {
      try {
        final suggestions = await _musicService.getAutocompleteSuggestions(query);
        if (mounted) {
          setState(() {
            _liveSuggestions = suggestions;
          });
        }
      } catch (_) {}
    });
  }

  void _search(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    _debounceTimer?.cancel();
    _addToHistory(clean);

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _liveSuggestions = [];
    });

    try {
      final futures = await Future.wait([
        PerformanceGuard.safeAsync<List<SongModel>>(
          _musicService.searchSongs(clean),
          timeout: const Duration(seconds: 7),
          fallback: <SongModel>[],
        ),
        PerformanceGuard.safeAsync<List<JioSaavnPlaylist>>(
          _musicService.searchPlaylists(clean),
          timeout: const Duration(seconds: 7),
          fallback: <JioSaavnPlaylist>[],
        ),
      ]);

      if (mounted) {
        setState(() {
          _results = futures[0] as List<SongModel>;
          _playlistResults = futures[1] as List<JioSaavnPlaylist>;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _playPlaylist(JioSaavnPlaylist pl) async {
    final isHindi = _lang.isHindi;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF00E5FF),
        content: Text(
          isHindi ? '"${pl.title}" के गाने लोड हो रहे हैं...' : 'Loading "${pl.title}" playlist...',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );

    try {
      final songs = await _musicService.getPlaylistSongs(pl.id);
      if (songs.isNotEmpty) {
        widget.audioHandler.playSong(songs.first, queue: songs);
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NowPlayingScreen(audioHandler: widget.audioHandler),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text(isHindi ? 'प्लेलिस्ट में कोई गाना नहीं मिला।' : 'No tracks found in this playlist.'),
            ),
          );
        }
      }
    } catch (_) {}
  }


  void _confirmDeleteHistory(String query) {
    final isHindi = _lang.isHindi;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          isHindi ? 'खोज इतिहास से हटाएं?' : 'Remove from search history?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isHindi
              ? 'क्या आप वाकई "$query" को खोज इतिहास से हटाना चाहते हैं?'
              : 'Are you sure you want to remove "$query" from history?',
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
              _removeFromHistory(query);
            },
            child: Text(isHindi ? 'हटाएं' : 'Remove', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _playSongOnly(SongModel song) {
    final currentId = widget.audioHandler.mediaItem.value?.id;
    if (currentId == song.id) {
      final isPlaying = widget.audioHandler.playbackState.value.playing;
      isPlaying ? widget.audioHandler.pause() : widget.audioHandler.play();
    } else {
      widget.audioHandler.playSong(song, queue: _results);
    }
  }

  void _playSong(SongModel song) {
    final currentId = widget.audioHandler.mediaItem.value?.id;
    if (currentId != song.id) {
      widget.audioHandler.playSong(song, queue: _results);
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NowPlayingScreen(audioHandler: widget.audioHandler),
      ),
    );
  }

  void _downloadSong(SongModel song) async {
    final success = await _downloadService.downloadSong(song);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? const Color(0xFF00E676) : Colors.redAccent,
          content: Text(
            success
                ? (_lang.isHindi ? '"${song.title}" डाउनलोड हो गया!' : '"${song.title}" downloaded!')
                : (_lang.isHindi ? 'डाउनलोड विफल रहा।' : 'Download failed.'),
          ),
        ),
      );
    }
  }

  List<SongModel> get _filteredResults {
    if (_activeFilter == 'all' || _activeFilter == 'songs') return _results;
    if (_activeFilter == 'artists') {
      final query = _controller.text.toLowerCase().trim();
      return _results.where((s) => s.artist.toLowerCase().contains(query)).toList();
    }
    return _results;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_theme, _lang]),
      builder: (context, _) {
        final textColor = _theme.textColor;
        final subtextColor = _theme.subtextColor;
        final cardColor = _theme.cardBg;
        final primaryColor = _theme.primaryColor;
        final isHindi = _lang.isHindi;

        final displayResults = _filteredResults;

        return Column(
          children: [
            // Search Input Field Bar with Circular History Quick Action
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryColor.withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: textColor, fontSize: 14),
                  textInputAction: TextInputAction.search,
                  onChanged: _onQueryChanged,
                  onSubmitted: _search,
                  decoration: InputDecoration(
                    hintText: isHindi ? 'गाना, कलाकार, एल्बम या प्लेलिस्ट खोजें...' : 'Search songs, artists, playlists...',
                    hintStyle: TextStyle(color: subtextColor.withOpacity(0.6), fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_history.isNotEmpty && _controller.text.isEmpty)
                          IconButton(
                            icon: const Icon(Icons.history_rounded, size: 20),
                            color: primaryColor,
                            tooltip: isHindi ? 'हालिया खोज' : 'Recent Search',
                            onPressed: () {
                              if (_history.isNotEmpty) {
                                _controller.text = _history.first;
                                _search(_history.first);
                              }
                            },
                          ),
                        if (_controller.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear_rounded, color: subtextColor),
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _results = [];
                                _liveSuggestions = [];
                                _hasSearched = false;
                              });
                            },
                          ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Filter Pills (All / Songs / Playlists / Artists)
            if (_hasSearched)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', isHindi ? 'सभी' : 'All', primaryColor, textColor, cardColor),
                      const SizedBox(width: 8),
                      _buildFilterChip('songs', isHindi ? 'गाने' : 'Songs', primaryColor, textColor, cardColor),
                      const SizedBox(width: 8),
                      _buildFilterChip('playlists', isHindi ? 'प्लेलिस्ट' : 'Playlists', primaryColor, textColor, cardColor),
                      const SizedBox(width: 8),
                      _buildFilterChip('artists', isHindi ? 'कलाकार' : 'Artists', primaryColor, textColor, cardColor),
                    ],
                  ),
                ),
              ),

            // Live Suggestions Dropdown (Appears while typing)
            if (_liveSuggestions.isNotEmpty && !_hasSearched)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: _liveSuggestions.map((sug) {
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.search_rounded, color: subtextColor, size: 18),
                      title: Text(sug, style: TextStyle(color: textColor, fontSize: 13)),
                      trailing: Icon(Icons.north_west_rounded, color: subtextColor, size: 14),
                      onTap: () {
                        _controller.text = sug;
                        _search(sug);
                      },
                    );
                  }).toList(),
                ),
              ),

            // When user has not searched: SHOW PERSISTENT SEARCH HISTORY
            if (!_hasSearched)
              Expanded(
                child: _history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 52, color: subtextColor.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text(
                              _lang.t('no_history'),
                              style: TextStyle(color: subtextColor.withOpacity(0.6), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _lang.t('search_history'),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _clearAllHistory,
                                icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.redAccent),
                                label: Text(
                                  _lang.t('clear_all'),
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Horizontal Circular History Chips
                          SizedBox(
                            height: 38,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _history.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, i) {
                                final h = _history[i];
                                return InkWell(
                                  onTap: () {
                                    _controller.text = h;
                                    _search(h);
                                  },
                                  onLongPress: () => _confirmDeleteHistory(h),
                                  borderRadius: BorderRadius.circular(19),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(19),
                                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.history_rounded, size: 14, color: primaryColor),
                                        const SizedBox(width: 6),
                                        Text(h, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white10),
                          ..._history.map((query) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              leading: Icon(Icons.history_rounded, color: subtextColor, size: 20),
                              title: Text(
                                query,
                                style: TextStyle(color: textColor, fontSize: 14),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.close_rounded, color: subtextColor, size: 18),
                                onPressed: () => _removeFromHistory(query),
                              ),
                              onTap: () {
                                _controller.text = query;
                                _search(query);
                              },
                              onLongPress: () => _confirmDeleteHistory(query),
                            );
                          }).toList(),
                        ],
                      ),
              ),

            // Search Results View
            if (_hasSearched)
              Expanded(
                child: _isSearching
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      )
                    : (_activeFilter == 'playlists'
                        ? (_playlistResults.isEmpty
                            ? Center(
                                child: Text(
                                  isHindi ? 'कोई प्लेलिस्ट नहीं मिली।' : 'No playlists found.',
                                  style: TextStyle(color: subtextColor),
                                ),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90, top: 8),
                                itemCount: _playlistResults.length,
                                itemBuilder: (context, index) {
                                  final pl = _playlistResults[index];
                                  return Tactile3DWrapper(
                                    onTap: () => _playPlaylist(pl),
                                    scaleElevation: 1.06,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white10),
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              pl.imageUrl,
                                              width: 58,
                                              height: 58,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 58,
                                                height: 58,
                                                color: Colors.grey.shade900,
                                                child: const Icon(Icons.album_rounded, color: Colors.white54),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  pl.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${pl.subtitle} • ${pl.songCount > 0 ? "${pl.songCount} ${isHindi ? 'गाने' : 'songs'}" : (isHindi ? 'प्लेलिस्ट' : 'Playlist')}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: subtextColor, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.play_circle_fill_rounded, color: primaryColor, size: 34),
                                            onPressed: () => _playPlaylist(pl),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ))
                        : (displayResults.isEmpty && _playlistResults.isEmpty
                            ? Center(
                                child: Text(
                                  isHindi
                                      ? 'कोई परिणाम नहीं मिला। कृपया दूसरा नाम खोजें।'
                                      : 'No results found. Try a different query.',
                                  style: TextStyle(color: subtextColor),
                                ),
                              )
                            : ListView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 90),
                                children: [
                                  // Playlists Section (Shown on 'all' tab when playlists exist)
                                  if (_activeFilter == 'all' && _playlistResults.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.queue_music_rounded, color: primaryColor, size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                isHindi ? 'प्लेलिस्ट और एल्बम' : 'Playlists & Albums',
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: () => setState(() => _activeFilter = 'playlists'),
                                            child: Text(
                                              isHindi ? 'सभी देखें' : 'See all',
                                              style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 180,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        itemCount: _playlistResults.length,
                                        itemBuilder: (context, idx) {
                                          final pl = _playlistResults[idx];
                                          return Tactile3DWrapper(
                                            onTap: () => _playPlaylist(pl),
                                            scaleElevation: 1.10,
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              width: 132,
                                              margin: const EdgeInsets.only(right: 12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Stack(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius: BorderRadius.circular(14),
                                                        child: Image.network(
                                                          pl.imageUrl,
                                                          width: 132,
                                                          height: 120,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => Container(
                                                            width: 132,
                                                            height: 120,
                                                            color: Colors.grey.shade900,
                                                            child: const Icon(Icons.album_rounded, color: Colors.white54, size: 40),
                                                          ),
                                                        ),
                                                      ),
                                                      if (pl.songCount > 0)
                                                        Positioned(
                                                          bottom: 6,
                                                          right: 6,
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: Colors.black.withOpacity(0.75),
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: Text(
                                                              '${pl.songCount}',
                                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    pl.title,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
                                                  ),
                                                  Text(
                                                    pl.subtitle,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(color: subtextColor, fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],

                                  // Songs Section Header
                                  if (displayResults.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                      child: Row(
                                        children: [
                                          Icon(Icons.music_note_rounded, color: primaryColor, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            isHindi ? 'गाने' : 'Songs',
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            ' (${displayResults.length})',
                                            style: TextStyle(color: subtextColor, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                     ...displayResults.map((song) {
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
                                                     width: 52,
                                                     height: 52,
                                                     fit: BoxFit.cover,
                                                     errorBuilder: (_, __, ___) => Container(
                                                       width: 52,
                                                       height: 52,
                                                       color: Colors.grey.shade900,
                                                       child: const Icon(Icons.music_note_rounded, color: Colors.white54),
                                                     ),
                                                   ),
                                                   if (isCurrentTrack)
                                                     Container(
                                                       width: 52,
                                                       height: 52,
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
                                                 color: isCurrentTrack ? const Color(0xFF00E5FF) : textColor,
                                                 fontWeight: FontWeight.w600,
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
                                                   icon: Icon(Icons.download_rounded, color: subtextColor, size: 22),
                                                   tooltip: _lang.t('download'),
                                                   onPressed: () => _downloadSong(song),
                                                 ),
                                                 IconButton(
                                                   icon: Icon(
                                                     isPlaying
                                                         ? Icons.pause_circle_filled_rounded
                                                         : Icons.play_circle_fill_rounded,
                                                     color: isCurrentTrack ? const Color(0xFF00E5FF) : primaryColor,
                                                     size: 32,
                                                   ),
                                                   onPressed: () => _playSongOnly(song),
                                                 ),
                                               ],
                                             ),
                                             onTap: () => _playSong(song),
                                           );
                                         },
                                       );
                                     }).toList(),
                                  ],
                                ],
                              ))),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label, Color primary, Color text, Color card) {
    final isSelected = _activeFilter == key;
    return InkWell(
      onTap: () => setState(() => _activeFilter = key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primary : card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? primary : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : text,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

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
  List<String> _history = [];
  List<String> _liveSuggestions = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _activeFilter = 'all'; // 'all', 'songs', 'artists', 'playlists'

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

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final songs = await PerformanceGuard.safeAsync<List<SongModel>>(
          _musicService.searchSongs(query),
          timeout: const Duration(seconds: 4),
          fallback: <SongModel>[],
        );
        if (mounted) {
          final titles = songs.map((s) => s.title).take(5).toList();
          setState(() {
            _liveSuggestions = titles;
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
      final res = await PerformanceGuard.safeAsync<List<SongModel>>(
        _musicService.searchSongs(clean),
        timeout: const Duration(seconds: 7),
        fallback: <SongModel>[],
      );
      if (mounted) {
        setState(() {
          _results = res;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
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

  void _playSong(SongModel song) {
    widget.audioHandler.playSong(song, queue: _results);
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

            // Filter Pills (All / Songs / Artists / Playlists)
            if (_hasSearched)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip('all', isHindi ? 'सभी' : 'All', primaryColor, textColor, cardColor),
                    const SizedBox(width: 8),
                    _buildFilterChip('songs', isHindi ? 'गाने' : 'Songs', primaryColor, textColor, cardColor),
                    const SizedBox(width: 8),
                    _buildFilterChip('artists', isHindi ? 'कलाकार' : 'Artists', primaryColor, textColor, cardColor),
                  ],
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

            // Search Results List
            if (_hasSearched)
              Expanded(
                child: _isSearching
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      )
                    : displayResults.isEmpty
                        ? Center(
                            child: Text(
                              isHindi
                                  ? 'कोई गाना नहीं मिला। कृपया दूसरा नाम खोजें।'
                                  : 'No songs found. Try a different query.',
                              style: TextStyle(color: subtextColor),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 90),
                            itemCount: displayResults.length,
                            itemBuilder: (context, index) {
                              final song = displayResults[index];
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
                                      child: const Icon(Icons.music_note_rounded, color: Colors.white54),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
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
                                      icon: Icon(Icons.play_circle_fill_rounded, color: primaryColor, size: 32),
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

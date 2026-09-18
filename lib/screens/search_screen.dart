import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/download_service.dart';
import '../services/language_service.dart';
import '../services/music_service.dart';
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
  bool _isSearching = false;
  bool _hasSearched = false;

  static const String _historyKey = 'abhi_suno_search_history';

  @override
  void initState() {
    super.initState();
    _loadHistory();
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

  void _search(String query) async {
    if (query.trim().isEmpty) return;
    _addToHistory(query);

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final res = await _musicService.searchSongs(query);
    if (mounted) {
      setState(() {
        _results = res;
        _isSearching = false;
      });
    }
  }

  void _playSong(SongModel song) {
    widget.audioHandler.playSong(song, queue: _results);
  }

  void _downloadSong(SongModel song) async {
    final success = await _downloadService.downloadSong(song);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (_lang.isHindi ? 'गाना डाउनलोड हो गया!' : 'Song downloaded successfully!')
              : (_lang.isHindi ? 'डाउनलोड विफल हुआ' : 'Download failed')),
          backgroundColor: success ? const Color(0xFF05D9E8) : Colors.redAccent,
        ),
      );
    }
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

        return Column(
          children: [
            // Search Input Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: textColor),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _search,
                  decoration: InputDecoration(
                    hintText: _lang.t('search_hint'),
                    hintStyle: TextStyle(color: subtextColor.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: subtextColor),
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _results = [];
                                _hasSearched = false;
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // When user has not searched: SHOW PERSISTENT SEARCH HISTORY ONLY (NO SUGGESTIONS)
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
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              _lang.isHindi
                                  ? 'कोई गाना नहीं मिला। कृपया दूसरा नाम खोजें।'
                                  : 'No songs found. Try a different query.',
                              style: TextStyle(color: subtextColor),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 90),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final song = _results[index];
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
}

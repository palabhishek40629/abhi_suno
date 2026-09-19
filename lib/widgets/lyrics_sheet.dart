import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/language_service.dart';
import '../services/music_service.dart';
import '../services/theme_service.dart';

class LyricsSheet extends StatefulWidget {
  final SongModel song;
  final AbhiAudioHandler? audioHandler;

  const LyricsSheet({Key? key, required this.song, this.audioHandler}) : super(key: key);

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> {
  final MusicService _musicService = MusicService();
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();
  final ScrollController _scrollController = ScrollController();

  List<_KaraokeLine> _karaokeLines = [];
  String _plainLyrics = '';
  bool _isKaraoke = false;
  bool _isLoading = true;
  int _activeLineIndex = -1;
  StreamSubscription? _posSub;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLyrics() async {
    final rawLyrics = await _musicService.fetchLyrics(widget.song.title, widget.song.artist);
    _parseLyrics(rawLyrics);

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (widget.audioHandler != null && _isKaraoke) {
      _posSub = widget.audioHandler!.player.positionStream.listen((pos) {
        _syncActiveLine(pos);
      });
    }
  }

  void _parseLyrics(String raw) {
    final lines = raw.split('\n');
    final regExp = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');
    final List<_KaraokeLine> parsed = [];

    for (final line in lines) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final m = int.parse(match.group(1)!);
        final s = int.parse(match.group(2)!);
        final ms = int.parse(match.group(3)!.padRight(3, '0').substring(0, 3));
        final time = Duration(minutes: m, seconds: s, milliseconds: ms);
        final text = line.replaceAll(regExp, '').trim();
        if (text.isNotEmpty) {
          parsed.add(_KaraokeLine(time: time, text: text));
        }
      }
    }

    if (parsed.isNotEmpty) {
      _isKaraoke = true;
      _karaokeLines = parsed;
    } else {
      _isKaraoke = false;
      _plainLyrics = raw.replaceAll(regExp, '').trim();
    }
  }

  void _syncActiveLine(Duration currentPos) {
    if (_karaokeLines.isEmpty) return;

    int activeIdx = -1;
    for (int i = 0; i < _karaokeLines.length; i++) {
      if (currentPos >= _karaokeLines[i].time) {
        activeIdx = i;
      } else {
        break;
      }
    }

    if (activeIdx != _activeLineIndex && mounted) {
      setState(() => _activeLineIndex = activeIdx);

      // Auto-scroll active line to center smoothly
      if (activeIdx >= 0 && _scrollController.hasClients) {
        final targetOffset = (activeIdx * 52.0) - 150.0;
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_theme, _lang]),
      builder: (context, _) {
        final textColor = _theme.textColor;
        final subtextColor = _theme.subtextColor;
        const primaryCyan = Color(0xFF00E5FF);
        const neonGold = Color(0xFFFFD700);

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xEB0A1329), // Deep midnight navy frosted glass
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: primaryCyan.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: primaryCyan.withOpacity(0.15),
                    blurRadius: 28,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: primaryCyan.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header with Song Info and Karaoke Indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryCyan.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic_external_on_rounded, color: primaryCyan, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                if (_isKaraoke)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: neonGold.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: neonGold.withOpacity(0.5)),
                                    ),
                                    child: const Text(
                                      'LIVE KARAOKE',
                                      style: TextStyle(color: neonGold, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    widget.song.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: subtextColor, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 20),

                  // Lyrics Content View
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(primaryCyan),
                            ),
                          )
                        : _isKaraoke
                            ? ListView.builder(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                itemCount: _karaokeLines.length,
                                itemBuilder: (context, i) {
                                  final line = _karaokeLines[i];
                                  final isActive = i == _activeLineIndex;

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: isActive ? primaryCyan.withOpacity(0.12) : Colors.transparent,
                                    ),
                                    child: Text(
                                      line.text,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isActive
                                            ? neonGold
                                            : textColor.withOpacity(i < _activeLineIndex ? 0.4 : 0.75),
                                        fontSize: isActive ? 20 : 16,
                                        fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
                                        letterSpacing: isActive ? 0.6 : 0.2,
                                        shadows: isActive
                                            ? [
                                                BoxShadow(
                                                  color: neonGold.withOpacity(0.6),
                                                  blurRadius: 16,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  _plainLyrics.isEmpty
                                      ? (_lang.isHindi ? 'गीत के बोल उपलब्ध नहीं हैं।' : 'Lyrics not available.')
                                      : _plainLyrics,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    height: 2.2,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
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

class _KaraokeLine {
  final Duration time;
  final String text;
  _KaraokeLine({required this.time, required this.text});
}

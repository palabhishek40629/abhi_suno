import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/audio_handler.dart';
import '../services/language_service.dart';
import '../services/music_service.dart';
import '../services/theme_service.dart';
import '../utils/devanagari_converter.dart';

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
    String rawLyrics = '';

    // 1. Check local offline lyrics file
    if (widget.song.localLyricsPath != null) {
      try {
        final lrcFile = File(widget.song.localLyricsPath!);
        if (lrcFile.existsSync()) {
          rawLyrics = await lrcFile.readAsString();
        }
      } catch (_) {}
    }

    // 2. Check song.lyrics property
    if (rawLyrics.isEmpty && widget.song.lyrics != null && widget.song.lyrics!.isNotEmpty) {
      rawLyrics = widget.song.lyrics!;
    }

    // 3. Fallback to online multi-source query (JioSaavn + LRCLIB)
    if (rawLyrics.isEmpty) {
      rawLyrics = await _musicService.fetchLyrics(
        widget.song.title,
        widget.song.artist,
        songId: widget.song.id,
      );
    }

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
          final devanagariText = DevanagariConverter.toDevanagari(text);
          parsed.add(_KaraokeLine(time: time, text: devanagariText));
        }
      }
    }

    if (parsed.isNotEmpty) {
      _isKaraoke = true;
      _karaokeLines = parsed;
    } else {
      _isKaraoke = false;
      final cleaned = raw.replaceAll(regExp, '').trim();
      _plainLyrics = DevanagariConverter.toDevanagari(cleaned);
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

                                  return GestureDetector(
                                    onTap: () {
                                      widget.audioHandler?.seek(line.time);
                                    },
                                    child: AnimatedScale(
                                      scale: isActive ? 1.16 : 1.0,
                                      duration: const Duration(milliseconds: 260),
                                      curve: Curves.easeOutBack,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(14),
                                          color: isActive ? const Color(0xFF2FC0DB).withOpacity(0.12) : Colors.transparent,
                                          border: isActive ? Border.all(color: const Color(0xFF2FC0DB).withOpacity(0.35)) : null,
                                        ),
                                        child: isActive
                                            ? ShaderMask(
                                                shaderCallback: (bounds) => const LinearGradient(
                                                  colors: [Color(0xFF2FC0DB), Color(0xFFD34C8C)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ).createShader(bounds),
                                                child: Text(
                                                  line.text,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontFamily: 'AmsSudha',
                                                    color: Colors.white,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 0.6,
                                                    shadows: [
                                                      Shadow(color: Color(0xFF2FC0DB), blurRadius: 18),
                                                      Shadow(color: Color(0xFFD34C8C), blurRadius: 18),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                line.text,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: 'AmsSudha',
                                                  color: textColor.withOpacity(i < _activeLineIndex ? 0.35 : 0.72),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
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
                                    fontFamily: 'AmsSudha',
                                    color: Colors.white,
                                    fontSize: 19,
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

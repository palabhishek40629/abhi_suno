import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _rawLyrics = '';
  bool _isKaraoke = false;
  bool _isLoading = true;
  int _activeLineIndex = -1;
  StreamSubscription? _posSub;

  static const Color cyanNeon = Color(0xFF2FC0DB);
  static const Color pinkNeon = Color(0xFFD34C8C);
  static const Color neonGold = Color(0xFFFFD700);

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
    _rawLyrics = raw;
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
          final devanagariText = DevanagariConverter.cleanLyricsText(text);
          if (devanagariText.isNotEmpty) {
            parsed.add(_KaraokeLine(time: time, text: devanagariText));
          }
        }
      }
    }

    if (parsed.isNotEmpty) {
      parsed.sort((a, b) => a.time.compareTo(b.time));
      _isKaraoke = true;
      _karaokeLines = parsed;
    } else {
      _isKaraoke = false;
      _plainLyrics = DevanagariConverter.cleanLyricsText(raw);
    }
  }

  /// High-Precision Millisecond Voice Detection (Never Glitches / Lag-Free)
  void _syncActiveLine(Duration currentPos) {
    if (_karaokeLines.isEmpty) return;

    int activeIdx = -1;
    for (int i = _karaokeLines.length - 1; i >= 0; i--) {
      if (currentPos >= _karaokeLines[i].time) {
        activeIdx = i;
        break;
      }
    }

    if (activeIdx != -1 && activeIdx != _activeLineIndex && mounted) {
      setState(() => _activeLineIndex = activeIdx);

      // Auto-scroll active line to center smoothly without jitter
      if (_scrollController.hasClients) {
        const itemEstimatedHeight = 72.0;
        final viewportHeight = MediaQuery.of(context).size.height * 0.58;
        final targetOffset = (activeIdx * itemEstimatedHeight) - (viewportHeight / 2) + (itemEstimatedHeight / 2);
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  /// Export & Download Clean Lyrics directly as a .txt file to public Downloads/AbhiSuno
  Future<void> _downloadLyricsAsTextFile() async {
    final isHindi = _lang.isHindi;
    final sourceToClean = _rawLyrics.isNotEmpty ? _rawLyrics : _plainLyrics;
    final cleanLyrics = DevanagariConverter.cleanLyricsText(sourceToClean);

    if (cleanLyrics.trim().isEmpty ||
        cleanLyrics.contains('गीत के बोल उपलब्ध नहीं हैं') ||
        cleanLyrics.contains('Lyrics not available')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(
            isHindi ? 'डाउनलोड करने के लिए लिरिक्स उपलब्ध नहीं हैं।' : 'Lyrics are not available to download.',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      );
      return;
    }

    try {
      final cleanTitle = widget.song.title.replaceAll(RegExp(r'[^\w\s]+'), '').trim().replaceAll(RegExp(r'\s+'), '_');
      final fileName = '${cleanTitle}_Lyrics.txt';
      const channel = MethodChannel('com.abhishekpal.abhisuno/native');

      await channel.invokeMethod('saveTextToDownloads', {
        'fileName': fileName,
        'content': '🎧 ${widget.song.title} - ${widget.song.artist}\n'
            '━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n'
            '$cleanLyrics\n\n'
            '━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
            'Abhi Suno Music App • Developed by Abhishek Pal\n',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: cyanNeon,
            content: Text(
              isHindi ? 'लिरिक्स टेक्स्ट फाइल सफलतापूर्वक डाउनलोड हो गई! ($fileName)' : 'Lyrics text file downloaded successfully! ($fileName)',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              isHindi ? 'लिरिक्स डाउनलोड विफल रहा।' : 'Failed to download lyrics file.',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
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
        final isHindi = _lang.isHindi;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xEB070B18), // Deep midnight navy frosted glass
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: cyanNeon.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: cyanNeon.withOpacity(0.15),
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
                      color: cyanNeon.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header with Song Info, Download Lyrics Button, and Close Button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cyanNeon.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic_external_on_rounded, color: cyanNeon, size: 22),
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

                      // Dedicated Download Lyrics (.txt) Button
                      IconButton(
                        tooltip: isHindi ? 'लिरिक्स डाउनलोड करें (.txt)' : 'Download Lyrics (.txt)',
                        icon: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cyanNeon.withOpacity(0.15),
                            border: Border.all(color: cyanNeon.withOpacity(0.6)),
                            boxShadow: [
                              BoxShadow(color: cyanNeon.withOpacity(0.35), blurRadius: 8),
                            ],
                          ),
                          child: const Icon(Icons.file_download_outlined, color: cyanNeon, size: 19),
                        ),
                        onPressed: _downloadLyricsAsTextFile,
                      ),

                      // Close Button
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
                              valueColor: AlwaysStoppedAnimation<Color>(cyanNeon),
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
                                      scale: isActive ? 1.18 : 1.0,
                                      duration: const Duration(milliseconds: 280),
                                      curve: Curves.easeOutBack,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 260),
                                        margin: EdgeInsets.symmetric(
                                          vertical: isActive ? 8 : 4,
                                          horizontal: isActive ? 4 : 8,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: isActive ? 14 : 9,
                                          horizontal: isActive ? 18 : 12,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(22),
                                          gradient: isActive
                                              ? const LinearGradient(
                                                  colors: [Color(0xFF0F1B33), Color(0xFF1E102E)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : null,
                                          color: isActive ? null : Colors.transparent,
                                          border: isActive
                                              ? Border.all(
                                                  color: cyanNeon.withOpacity(0.9),
                                                  width: 1.8,
                                                )
                                              : null,
                                          boxShadow: isActive
                                              ? [
                                                  BoxShadow(
                                                    color: cyanNeon.withOpacity(0.40),
                                                    blurRadius: 22,
                                                    spreadRadius: 1,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                  BoxShadow(
                                                    color: pinkNeon.withOpacity(0.22),
                                                    blurRadius: 16,
                                                    offset: const Offset(0, -2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: isActive
                                            ? ShaderMask(
                                                shaderCallback: (bounds) => const LinearGradient(
                                                  colors: [
                                                    Color(0xFF2FC0DB),
                                                    Color(0xFF00E5FF),
                                                    Colors.white,
                                                    Color(0xFFD34C8C),
                                                  ],
                                                  stops: [0.0, 0.35, 0.70, 1.0],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ).createShader(bounds),
                                                child: Text(
                                                  line.text,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontFamily: 'AmsSudha',
                                                    color: Colors.white,
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 0.8,
                                                    shadows: [
                                                      Shadow(color: cyanNeon, blurRadius: 24),
                                                      Shadow(color: Color(0xFF00E5FF), blurRadius: 12),
                                                      Shadow(color: pinkNeon, blurRadius: 20),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                line.text,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: 'AmsSudha',
                                                  color: textColor.withOpacity(i < _activeLineIndex ? 0.35 : 0.70),
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                                child: Text(
                                  _plainLyrics.isEmpty
                                      ? (isHindi ? 'गीत के बोल उपलब्ध नहीं हैं।' : 'Lyrics not available.')
                                      : _plainLyrics,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'AmsSudha',
                                    color: Colors.white,
                                    fontSize: 20,
                                    height: 2.2,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
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

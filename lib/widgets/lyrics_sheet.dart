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

  late SongModel _currentSong;
  List<_KaraokeLine> _karaokeLines = [];
  List<GlobalKey> _lineKeys = [];
  String _plainLyrics = '';
  String _rawLyrics = '';
  bool _isKaraoke = false;
  bool _isLoading = true;
  int _activeLineIndex = -1;

  StreamSubscription? _posSub;
  StreamSubscription? _songSub;

  static const Color cyanNeon = Color(0xFF2FC0DB);
  static const Color pinkNeon = Color(0xFFD34C8C);
  static const Color neonGold = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    _loadLyricsForSong(_currentSong);

    // Dynamically react to track changes (Next / Previous / Autoplay) while lyrics sheet is open
    if (widget.audioHandler != null) {
      _songSub = widget.audioHandler!.currentSongStream.listen((newSong) {
        if (newSong != null && newSong.id != _currentSong.id && mounted) {
          setState(() {
            _currentSong = newSong;
            _isLoading = true;
            _karaokeLines.clear();
            _lineKeys.clear();
            _plainLyrics = '';
            _rawLyrics = '';
            _activeLineIndex = -1;
          });
          _posSub?.cancel();
          _loadLyricsForSong(newSong);
        }
      });
    }
  }

  @override
  void dispose() {
    _songSub?.cancel();
    _posSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLyricsForSong(SongModel song) async {
    String rawLyrics = '';

    // 1. Check local offline lyrics file
    if (song.localLyricsPath != null) {
      try {
        final lrcFile = File(song.localLyricsPath!);
        if (lrcFile.existsSync()) {
          rawLyrics = await lrcFile.readAsString();
        }
      } catch (_) {}
    }

    // 2. Check song.lyrics property
    if (rawLyrics.isEmpty && song.lyrics != null && song.lyrics!.isNotEmpty) {
      rawLyrics = song.lyrics!;
    }

    // 3. Fallback to online multi-source query (LRCLIB synced first, then JioSaavn)
    if (rawLyrics.isEmpty) {
      rawLyrics = await _musicService.fetchLyrics(
        song.title,
        song.artist,
        songId: song.id,
      );
    }

    _parseLyrics(rawLyrics);

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (widget.audioHandler != null && _isKaraoke) {
      _posSub?.cancel();
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
      _lineKeys = List.generate(parsed.length, (_) => GlobalKey());
    } else {
      final clean = DevanagariConverter.cleanLyricsText(raw);
      _plainLyrics = clean;
      final rawLines = clean
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (rawLines.isNotEmpty &&
          !clean.contains('गीत के बोल उपलब्ध नहीं हैं') &&
          !clean.contains('Lyrics not available')) {
        final totalSec = _currentSong.duration.inSeconds > 30 ? _currentSong.duration.inSeconds : 180;
        final startSec = 10.0;
        final endSec = (totalSec - 12.0).clamp(startSec + 15.0, totalSec.toDouble());
        final step = (endSec - startSec) / rawLines.length;

        for (int i = 0; i < rawLines.length; i++) {
          final lineTimeMs = ((startSec + (i * step)) * 1000).toInt();
          parsed.add(_KaraokeLine(time: Duration(milliseconds: lineTimeMs), text: rawLines[i]));
        }

        _isKaraoke = true;
        _karaokeLines = parsed;
        _lineKeys = List.generate(parsed.length, (_) => GlobalKey());
      } else {
        _isKaraoke = false;
        _lineKeys.clear();
      }
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

    if (activeIdx != _activeLineIndex && mounted) {
      setState(() => _activeLineIndex = activeIdx);

      // Smooth center scrolling with zero drift using Scrollable.ensureVisible
      if (activeIdx >= 0 && activeIdx < _lineKeys.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final keyContext = _lineKeys[activeIdx].currentContext;
          if (keyContext != null) {
            Scrollable.ensureVisible(
              keyContext,
              alignment: 0.5,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            );
          }
        });

        // Broadcast active lyrics line to home screen widgets
        try {
          const MethodChannel('com.abhishekpal.abhisuno/native').invokeMethod('updateWidgets', {
            'lyricsLine': _karaokeLines[activeIdx].text,
          });
        } catch (_) {}
      } else if (activeIdx < 0 && _scrollController.hasClients) {
        // Seeking before first line (intro instrumental): smoothly scroll to top
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
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
      final safeSongTitle = _currentSong.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = '${safeSongTitle}_लिरिक्स.txt';

      const channel = MethodChannel('com.abhishekpal.abhisuno/native');
      final success = await channel.invokeMethod<bool>('saveTextToDownloads', {
        'fileName': fileName,
        'content': '=== ${_currentSong.title} (${_currentSong.artist}) ===\n\n$cleanLyrics\n\n--- Abhi Suno Music Player ---',
      });

      if (mounted) {
        if (success == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00E676),
              duration: const Duration(seconds: 4),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.black, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isHindi
                          ? 'लिरिक्स डाउनलोड फोल्डर (AbhiSuno) में सेव हो गए!'
                          : 'Lyrics saved to Downloads/AbhiSuno folder!',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: isHindi ? 'खोलें' : 'OPEN',
                textColor: Colors.black,
                onPressed: () {
                  try {
                    channel.invokeMethod('openDownloadsFolder');
                  } catch (_) {}
                },
              ),
            ),
          );
        } else {
          throw Exception('File write failed');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              isHindi ? 'लिरिक्स डाउनलोड करने में विफल: $e' : 'Failed to save lyrics: $e',
              style: const TextStyle(color: Colors.white),
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
                              _currentSong.title,
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
                                    _currentSong.artist,
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
                          child: const Icon(Icons.file_download_outlined, color: cyanNeon, size: 18),
                        ),
                        onPressed: _downloadLyricsAsTextFile,
                      ),

                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),

                  // Lyrics Content Body
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(cyanNeon),
                            ),
                          )
                        : _isKaraoke
                            ? LayoutBuilder(
                                builder: (context, constraints) {
                                  final viewportHeight = constraints.maxHeight;
                                  final verticalPadding = (viewportHeight / 2).clamp(40.0, 450.0);

                                  return ListView.builder(
                                    controller: _scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    padding: EdgeInsets.symmetric(vertical: verticalPadding),
                                    itemCount: _karaokeLines.length,
                                    itemBuilder: (context, i) {
                                      final line = _karaokeLines[i];
                                      final isActive = i == _activeLineIndex;

                                      return GestureDetector(
                                        key: i < _lineKeys.length ? _lineKeys[i] : null,
                                        onTap: () {
                                          widget.audioHandler?.seek(line.time);
                                        },
                                        child: AnimatedScale(
                                          scale: isActive ? 1.02 : 1.0, // Sleek, non-jarring 1.02 scale
                                          duration: const Duration(milliseconds: 260),
                                          curve: Curves.easeOutCubic,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 240),
                                            margin: EdgeInsets.symmetric(
                                              vertical: isActive ? 4 : 2,
                                              horizontal: isActive ? 4 : 8,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: isActive ? 10 : 6,
                                              horizontal: isActive ? 14 : 10,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(22),
                                              gradient: isActive
                                                  ? const LinearGradient(
                                                      colors: [
                                                        Color(0xFF131D36),
                                                        Color(0xFF1B112D),
                                                        Color(0xFF0E1626),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    )
                                                  : null,
                                              color: isActive ? null : Colors.transparent,
                                              border: isActive
                                                  ? Border.all(
                                                      color: cyanNeon.withOpacity(0.85),
                                                      width: 1.0, // Sleek, thinner 1.0 border
                                                    )
                                                  : null,
                                              boxShadow: isActive
                                                  ? [
                                                      // 3D Top-left light reflection highlight
                                                      BoxShadow(
                                                        color: Colors.white.withOpacity(0.10),
                                                        blurRadius: 5,
                                                        offset: const Offset(-2, -2),
                                                      ),
                                                      // 3D Bottom-right deep ambient drop shadow
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.60),
                                                        blurRadius: 10,
                                                        offset: const Offset(2, 4),
                                                      ),
                                                      // Neon cyan glow
                                                      BoxShadow(
                                                        color: cyanNeon.withOpacity(0.30),
                                                        blurRadius: 16,
                                                        spreadRadius: 0.5,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                      // Neon pink subtle secondary glow
                                                      BoxShadow(
                                                        color: pinkNeon.withOpacity(0.18),
                                                        blurRadius: 12,
                                                        offset: const Offset(0, -1),
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
                                                        fontSize: 19, // Crisp, centered & balanced
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: 0.5,
                                                        shadows: [
                                                          Shadow(color: cyanNeon, blurRadius: 16),
                                                          Shadow(color: Color(0xFF00E5FF), blurRadius: 8),
                                                          Shadow(color: pinkNeon, blurRadius: 12),
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
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 0.4,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      );
                                    },
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
                                    fontSize: 19,
                                    height: 2.1,
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

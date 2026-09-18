import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/audio_handler.dart';
import 'services/language_service.dart';
import 'services/theme_service.dart';
import 'widgets/app_header.dart';
import 'widgets/mini_player.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/search_screen.dart';
import 'screens/library_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style immediately
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const AbhiSunoApp());
}

class AbhiSunoApp extends StatelessWidget {
  const AbhiSunoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return AnimatedBuilder(
      animation: themeService,
      builder: (context, _) {
        return MaterialApp(
          title: 'Abhi Suno',
          debugShowCheckedModeBanner: false,
          theme: themeService.themeData,
          home: const AppBootstrapScreen(),
        );
      },
    );
  }
}

class AppBootstrapScreen extends StatefulWidget {
  const AppBootstrapScreen({Key? key}) : super(key: key);

  @override
  State<AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends State<AppBootstrapScreen> {
  AbhiAudioHandler? _audioHandler;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final handler = await AudioService.init(
        builder: () => AbhiAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.abhishekpal.abhisuno.audio',
          androidNotificationChannelName: 'Abhi Suno Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () => AbhiAudioHandler(),
      );

      if (mounted) {
        setState(() => _audioHandler = handler);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _audioHandler = AbhiAudioHandler());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_audioHandler != null) {
      return MainNavigationScaffold(audioHandler: _audioHandler!);
    }

    // Instant Fast Splash Screen with the 3D Golden Crown Emblem
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.music_note_rounded, size: 48, color: Colors.amber),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Abhi Suno',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'by Abhishek Pal',
              style: TextStyle(
                color: Color(0xFF05D9E8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF05D9E8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainNavigationScaffold extends StatefulWidget {
  final AbhiAudioHandler audioHandler;

  const MainNavigationScaffold({Key? key, required this.audioHandler}) : super(key: key);

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(audioHandler: widget.audioHandler),
      ExploreScreen(audioHandler: widget.audioHandler),
      SearchScreen(audioHandler: widget.audioHandler),
      LibraryScreen(audioHandler: widget.audioHandler),
    ];

    return AnimatedBuilder(
      animation: Listenable.merge([_theme, _lang]),
      builder: (context, _) {
        final isLight = _theme.isLight;
        final textColor = _theme.textColor;
        final primaryColor = _theme.primaryColor;

        return Scaffold(
          backgroundColor: _theme.scaffoldBg,
          body: Container(
            decoration: _theme.backgroundDecoration,
            child: SafeArea(
              child: Column(
                children: [
                  // Top 3D Golden Logo & App Header
                  AppHeader(
                    onSearchTap: () => setState(() => _currentIndex = 2),
                  ),

                  // Tab View
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: screens,
                    ),
                  ),

                  // Floating Mini-Player
                  MiniPlayer(audioHandler: widget.audioHandler),
                ],
              ),
            ),
          ),
          bottomNavigationBar: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: isLight ? Colors.white : const Color(0xFF0D0D0D),
              indicatorColor: primaryColor.withOpacity(0.2),
              labelTextStyle: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 11);
                }
                return TextStyle(color: textColor.withOpacity(0.5), fontSize: 11);
              }),
              iconTheme: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return IconThemeData(color: primaryColor);
                }
                return IconThemeData(color: textColor.withOpacity(0.5));
              }),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: _lang.t('home'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.explore_outlined),
                  selectedIcon: const Icon(Icons.explore_rounded),
                  label: _lang.t('explore'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.search_outlined),
                  selectedIcon: const Icon(Icons.search_rounded),
                  label: _lang.t('search'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.library_music_outlined),
                  selectedIcon: const Icon(Icons.library_music_rounded),
                  label: _lang.t('library'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

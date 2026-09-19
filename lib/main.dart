import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/audio_handler.dart';
import 'services/language_service.dart';
import 'services/performance_guard.dart';
import 'services/theme_service.dart';
import 'widgets/app_header.dart';
import 'widgets/mini_player.dart';
import 'widgets/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/search_screen.dart';
import 'screens/library_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Anti-Hang Watchdog & Image Cache Throttling
  PerformanceGuard.initialize();

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
          theme: themeService.themeData.copyWith(
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
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
  bool _splashCompleted = false;

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
    } catch (_) {
      if (mounted) {
        setState(() => _audioHandler = AbhiAudioHandler());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isReady = _audioHandler != null && _splashCompleted;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: isReady
          ? MainNavigationScaffold(
              key: const ValueKey('main_nav'),
              audioHandler: _audioHandler!,
            )
          : AnimatedSplashScreen(
              key: const ValueKey('splash_screen'),
              onFinish: () {
                if (mounted) {
                  setState(() => _splashCompleted = true);
                }
              },
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

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();
  static const MethodChannel _nativeChannel = MethodChannel('com.abhishekpal.abhisuno/native');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkExternalShareIntent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkExternalShareIntent();
    }
  }

  Future<void> _checkExternalShareIntent() async {
    try {
      final sharedLink = await _nativeChannel.invokeMethod<String>('getSharedLink');
      if (sharedLink != null && sharedLink.trim().isNotEmpty) {
        // Switch to Search tab immediately to discover the shared track
        setState(() => _currentIndex = 2);
      }
    } catch (_) {}
  }

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
                  // Top 3D Logo & App Header
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

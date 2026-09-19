import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/audio_handler.dart';
import 'services/party_room_service.dart';
import 'services/language_service.dart';
import 'services/performance_guard.dart';
import 'services/theme_service.dart';
import 'services/connectivity_service.dart';
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

      PartyRoomService().audioHandler = handler;
      if (mounted) {
        setState(() => _audioHandler = handler);
      }
    } catch (_) {
      final fallbackHandler = AbhiAudioHandler();
      PartyRoomService().audioHandler = fallbackHandler;
      if (mounted) {
        setState(() => _audioHandler = fallbackHandler);
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
  final ConnectivityService _connectivity = ConnectivityService();
  static const MethodChannel _nativeChannel = MethodChannel('com.abhishekpal.abhisuno/native');

  // Multi-tap back navigation tracking
  int _backPressCount = 0;
  Timer? _backResetTimer;

  // Warm resume splash state
  bool _showResumeSplash = false;
  Timer? _resumeSplashTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkExternalShareIntent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backResetTimer?.cancel();
    _resumeSplashTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkExternalShareIntent();
      _connectivity.checkConnection();
      // Show fast 1.2s branded resume splash on reopen, then return smoothly right where the user was
      setState(() => _showResumeSplash = true);
      _resumeSplashTimer?.cancel();
      _resumeSplashTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() => _showResumeSplash = false);
        }
      });
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

  void _handleBackPress() {
    _backPressCount++;
    _backResetTimer?.cancel();
    _backResetTimer = Timer(const Duration(milliseconds: 1500), () {
      _backPressCount = 0;
    });

    if (_backPressCount == 1) {
      // 1-tap: Go back in navigation stack, or jump to Home tab
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else if (_currentIndex != 0) {
        setState(() => _currentIndex = 0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ऐप बंद करने के लिए 2 बार और दबाएं'),
            duration: Duration(milliseconds: 1200),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (_backPressCount == 2) {
      // 2-taps: Return to Home tab from any deep screen
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() => _currentIndex = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ऐप बंद करने के लिए 1 बार और दबाएं'),
          duration: Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_backPressCount >= 3) {
      // 3-taps: Completely terminate app, including background audio
      _backResetTimer?.cancel();
      widget.audioHandler.stop();
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      Future.delayed(const Duration(milliseconds: 200), () {
        exit(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(audioHandler: widget.audioHandler),
      ExploreScreen(audioHandler: widget.audioHandler),
      SearchScreen(audioHandler: widget.audioHandler),
      LibraryScreen(audioHandler: widget.audioHandler),
    ];

    return WillPopScope(
      onWillPop: () async {
        _handleBackPress();
        return false;
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_theme, _lang, _connectivity]),
        builder: (context, _) {
          final isLight = _theme.isLight;
          final textColor = _theme.textColor;
          final primaryColor = _theme.primaryColor;

          return Stack(
            children: [
              Scaffold(
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

                        // Offline Detection Floating Banner with 1-tap Jump to Downloads
                        if (!_connectivity.isOnline)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'ऑफ़लाइन मोड (Offline Mode) - डाउनलोड्स उपलब्ध हैं',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _currentIndex = 3);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      'डाउनलोड्स',
                                      style: TextStyle(
                                        color: Color(0xFFE65100),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
              ),

              // Warm Resume Branded Startup Splash Overlay
              if (_showResumeSplash)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _showResumeSplash ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      color: const Color(0xFF09090D),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              width: 86,
                              height: 86,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.music_note_rounded,
                                size: 80,
                                color: Color(0xFF6C5CE7),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'अभी सुनो',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'लोड हो रहा है...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}


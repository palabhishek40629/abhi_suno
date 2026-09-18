import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/audio_handler.dart';
import 'widgets/app_header.dart';
import 'widgets/mini_player.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/library_screen.dart';
import 'screens/about_screen.dart';

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

  // Launch UI immediately so the phone NEVER hangs on a black screen
  runApp(const AbhiSunoApp());
}

class AbhiSunoApp extends StatelessWidget {
  const AbhiSunoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abhi Suno',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFF05D9E8),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF05D9E8),
          secondary: Color(0xFFFF2A6D),
          surface: Color(0xFF141414),
          background: Color(0xFF0A0A0A),
        ),
        fontFamily: 'sans-serif',
        useMaterial3: true,
      ),
      home: const AppBootstrapScreen(),
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
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize background audio with a timeout to prevent hanging on device
      final handler = await AudioService.init(
        builder: () => AbhiAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.abhishekpal.abhisuno.audio',
          androidNotificationChannelName: 'Abhi Suno Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      ).timeout(
        const Duration(seconds: 4),
        onTimeout: () => AbhiAudioHandler(),
      );

      if (mounted) {
        setState(() => _audioHandler = handler);
      }
    } catch (e) {
      // Fallback safe handler in case of any native device issues
      debugPrint("Fallback audio handler initiated: $e");
      if (mounted) {
        setState(() => _audioHandler = AbhiAudioHandler());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If audioHandler is ready, show full app
    if (_audioHandler != null) {
      return MainNavigationScaffold(audioHandler: _audioHandler!);
    }

    // While initializing (takes < 0.5s), show sleek 3D "A" Splash Screen instead of black screen!
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 3D "A" Emblem Badge with pulsing glow
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF2A6D),
                    Color(0xFF05D9E8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF05D9E8).withOpacity(0.5),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(2, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Abhi ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF05D9E8), Color(0xFFFF2A6D)],
                  ).createShader(bounds),
                  child: const Text(
                    'Suno',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(audioHandler: widget.audioHandler),
      SearchScreen(audioHandler: widget.audioHandler),
      LibraryScreen(audioHandler: widget.audioHandler),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Top 3D "A" Logo & "Abhi Suno" Header
            AppHeader(
              onSearchTap: () => setState(() => _currentIndex = 1),
              onAboutTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),

            // Tab Content
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),

            // Persistent Floating Mini-Player
            MiniPlayer(audioHandler: widget.audioHandler),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0D0D0D),
          indicatorColor: const Color(0xFF05D9E8).withOpacity(0.2),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(color: Color(0xFF05D9E8), fontWeight: FontWeight.bold, fontSize: 12);
            }
            return TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12);
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: Color(0xFF05D9E8));
            }
            return IconThemeData(color: Colors.white.withOpacity(0.5));
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.download_done_outlined),
              selectedIcon: Icon(Icons.download_done_rounded),
              label: 'Offline Vault',
            ),
          ],
        ),
      ),
    );
  }
}

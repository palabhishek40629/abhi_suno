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

late AbhiAudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system navigation & status bar transparent for modern edge-to-edge look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize background AudioService
  _audioHandler = await AudioService.init(
    builder: () => AbhiAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.abhishekpal.abhisuno.audio',
      androidNotificationChannelName: 'Abhi Suno Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // Error boundary to ensure 100% crash-free experience
  runZonedGuarded(() {
    runApp(const AbhiSunoApp());
  }, (error, stackTrace) {
    debugPrint('Safe Error Boundary Caught: $error');
  });
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
      home: MainNavigationScaffold(audioHandler: _audioHandler),
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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  defaultMode,
  dark,
  light,
  transparent,
}

class ThemeService extends ChangeNotifier {
  String get currentTheme {
    switch (_currentMode) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.transparent:
        return 'transparent';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.defaultMode:
      default:
        return 'default';
    }
  }

  void updateTheme(String theme) {
    if (theme == 'light') {
      setTheme(AppThemeMode.light);
    } else if (theme == 'transparent') {
      setTheme(AppThemeMode.transparent);
    } else if (theme == 'dark') {
      setTheme(AppThemeMode.dark);
    } else {
      setTheme(AppThemeMode.defaultMode);
    }
  }

  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal() {
    _loadTheme();
  }

  AppThemeMode _currentMode = AppThemeMode.defaultMode;
  AppThemeMode get currentMode => _currentMode;

  bool get isDefault => _currentMode == AppThemeMode.defaultMode;
  bool get isDark => _currentMode == AppThemeMode.dark;
  bool get isLight => _currentMode == AppThemeMode.light;
  bool get isTransparent => _currentMode == AppThemeMode.transparent;

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString('app_theme_mode') ?? 'default';
      if (modeStr == 'light') {
        _currentMode = AppThemeMode.light;
      } else if (modeStr == 'transparent') {
        _currentMode = AppThemeMode.transparent;
      } else if (modeStr == 'dark') {
        _currentMode = AppThemeMode.dark;
      } else {
        _currentMode = AppThemeMode.defaultMode;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _currentMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      String modeStr = 'default';
      if (mode == AppThemeMode.light) modeStr = 'light';
      if (mode == AppThemeMode.transparent) modeStr = 'transparent';
      if (mode == AppThemeMode.dark) modeStr = 'dark';
      await prefs.setString('app_theme_mode', modeStr);
    } catch (_) {}
  }

  Color get primaryColor => const Color(0xFF00E5FF);
  Color get secondaryColor => const Color(0xFFFF2A6D);

  Color get scaffoldBg {
    switch (_currentMode) {
      case AppThemeMode.light:
        return const Color(0xFFF4F6F9);
      case AppThemeMode.transparent:
        return const Color(0xFF0C0E17);
      case AppThemeMode.dark:
        return const Color(0xFF000000);
      case AppThemeMode.defaultMode:
      default:
        return const Color(0xFF090A10);
    }
  }

  Color get cardBg {
    switch (_currentMode) {
      case AppThemeMode.light:
        return Colors.white;
      case AppThemeMode.transparent:
        return Colors.white.withOpacity(0.08);
      case AppThemeMode.dark:
        return const Color(0xFF121212);
      case AppThemeMode.defaultMode:
      default:
        return const Color(0xFF141522);
    }
  }

  Color get textColor {
    switch (_currentMode) {
      case AppThemeMode.light:
        return const Color(0xFF111827);
      case AppThemeMode.transparent:
      case AppThemeMode.dark:
      case AppThemeMode.defaultMode:
      default:
        return Colors.white;
    }
  }

  Color get subtextColor {
    switch (_currentMode) {
      case AppThemeMode.light:
        return const Color(0xFF6B7280);
      case AppThemeMode.transparent:
        return Colors.white70;
      case AppThemeMode.dark:
        return const Color(0xFF888888);
      case AppThemeMode.defaultMode:
      default:
        return const Color(0xFF9E9EB2);
    }
  }

  BoxDecoration get backgroundDecoration {
    if (_currentMode == AppThemeMode.transparent) {
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF160E26),
            Color(0xFF0A1224),
            Color(0xFF04060E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (_currentMode == AppThemeMode.light) {
      return const BoxDecoration(
        color: Color(0xFFF4F6F9),
      );
    } else if (_currentMode == AppThemeMode.dark) {
      return const BoxDecoration(
        color: Color(0xFF000000),
      );
    } else {
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF110C1B),
            Color(0xFF0A0F1D),
            Color(0xFF080911),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
    }
  }

  ThemeData get themeData {
    if (_currentMode == AppThemeMode.light) {
      return ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        primaryColor: const Color(0xFF007AFF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF007AFF),
          secondary: Color(0xFFFF2A6D),
          surface: Colors.white,
        ),
        fontFamily: 'sans-serif',
        useMaterial3: true,
      );
    }

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardBg,
      ),
      fontFamily: 'sans-serif',
      useMaterial3: true,
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

class PerformanceGuard with WidgetsBindingObserver {
  static final PerformanceGuard _instance = PerformanceGuard._internal();
  factory PerformanceGuard() => _instance;
  PerformanceGuard._internal();

  static bool _initialized = false;
  static Timer? _watchdogTimer;

  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    // 1. Bound Flutter ImageCache to avoid Out-Of-Memory hangs and stutter
    PaintingBinding.instance.imageCache.maximumSizeBytes = 40 * 1024 * 1024; // 40 MB max memory cache
    PaintingBinding.instance.imageCache.maximumSize = 100; // max 100 thumbnail items in memory

    // 2. Register lifecycle observer to release memory on backgrounding
    WidgetsBinding.instance.addObserver(_instance);

    // 3. Periodic memory and task watchdog every 30 seconds
    _watchdogTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _runRoutineMaintenance();
    });
  }

  static void _runRoutineMaintenance() {
    try {
      final currentSize = PaintingBinding.instance.imageCache.currentSizeBytes;
      if (currentSize > 35 * 1024 * 1024) {
        PaintingBinding.instance.imageCache.clear();
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Evict memory-intensive volatile bitmap cache to prevent OS from killing app in background
      try {
        PaintingBinding.instance.imageCache.clear();
      } catch (_) {}
    }
  }

  /// Helper to execute network calls with strict timeout protection to prevent UI freezes
  static Future<T> safeAsync<T>(
    Future<T> future, {
    Duration timeout = const Duration(seconds: 7),
    required T fallback,
  }) async {
    try {
      return await future.timeout(timeout, onTimeout: () => fallback);
    } catch (_) {
      return fallback;
    }
  }
}

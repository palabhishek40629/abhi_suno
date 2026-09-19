import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class PerformanceGuard with WidgetsBindingObserver {
  static final PerformanceGuard _instance = PerformanceGuard._internal();
  factory PerformanceGuard() => _instance;
  PerformanceGuard._internal();

  bool _initialized = false;
  Timer? _watchdogTimer;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // 1. Bound Flutter ImageCache to avoid Out-Of-Memory hangs and stutter
    PaintingBinding.instance.imageCache.maximumSizeBytes = 40 * 1024 * 1024; // 40 MB max memory cache
    PaintingBinding.instance.imageCache.maximumSize = 100; // max 100 thumbnail items in memory

    // 2. Register lifecycle observer to release memory on backgrounding
    WidgetsBinding.instance.addObserver(this);

    // 3. Periodic memory and task watchdog every 30 seconds
    _watchdogTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _runRoutineMaintenance();
    });
  }

  void _runRoutineMaintenance() {
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
  static Future<T?> safeAsync<T>(
    Future<T> Function() action, {
    Duration timeout = const Duration(seconds: 7),
    T? fallback,
  }) async {
    try {
      return await action().timeout(timeout, onTimeout: () => fallback as T);
    } catch (_) {
      return fallback;
    }
  }

  void dispose() {
    _watchdogTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}

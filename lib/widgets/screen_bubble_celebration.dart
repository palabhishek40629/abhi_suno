import 'dart:math';
import 'package:flutter/material.dart';

class ScreenBubbleCelebration extends StatefulWidget {
  final VoidCallback onComplete;

  const ScreenBubbleCelebration({Key? key, required this.onComplete}) : super(key: key);

  /// Helper to trigger the full-screen celebration from any context
  static void show(BuildContext context) {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (ctx) => ScreenBubbleCelebration(
        onComplete: () {
          entry?.remove();
          entry = null;
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  State<ScreenBubbleCelebration> createState() => _ScreenBubbleCelebrationState();
}

class _ScreenBubbleCelebrationState extends State<ScreenBubbleCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Bubble> _bubbles = [];
  final Random _random = Random();

  final List<Color> _bubbleColors = const [
    Color(0xFFFF2A6D), // Neon Pink
    Color(0xFFFF0055), // Radiant Crimson
    Color(0xFFFFD700), // Amber Gold
    Color(0xFF00E5FF), // Electric Cyan
    Color(0xFFFF758C), // Rose Pink
    Color(0xFFBA68C8), // Violet Glow
  ];

  @override
  void initState() {
    super.initState();

    // Generate 36 colorful glowing bubbles dispersed across the entire screen
    for (int i = 0; i < 36; i++) {
      _bubbles.add(_Bubble(
        startXRatio: _random.nextDouble(),
        startYRatio: 0.6 + _random.nextDouble() * 0.45,
        driftX: (_random.nextDouble() - 0.5) * 160.0,
        floatDistance: 250.0 + _random.nextDouble() * 450.0,
        size: 14.0 + _random.nextDouble() * 26.0,
        color: _bubbleColors[_random.nextInt(_bubbleColors.length)],
        delayRatio: _random.nextDouble() * 0.25,
        isHeart: i % 3 == 0,
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _controller.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;

          return SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              children: _bubbles.map((b) {
                if (t < b.delayRatio) return const SizedBox.shrink();

                final localT = ((t - b.delayRatio) / (1.0 - b.delayRatio)).clamp(0.0, 1.0);
                final curved = Curves.easeOutCubic.transform(localT);

                final x = (b.startXRatio * size.width) + (b.driftX * curved);
                final y = (b.startYRatio * size.height) - (b.floatDistance * curved);
                final opacity = sin(localT * pi).clamp(0.0, 1.0);
                final scale = 0.5 + (sin(localT * pi * 0.8) * 0.7);

                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: b.size,
                        height: b.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.9),
                              b.color.withOpacity(0.8),
                              b.color.withOpacity(0.2),
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: b.color.withOpacity(0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: b.isHeart
                            ? Icon(
                                Icons.favorite_rounded,
                                size: b.size * 0.55,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _Bubble {
  final double startXRatio;
  final double startYRatio;
  final double driftX;
  final double floatDistance;
  final double size;
  final Color color;
  final double delayRatio;
  final bool isHeart;

  _Bubble({
    required this.startXRatio,
    required this.startYRatio,
    required this.driftX,
    required this.floatDistance,
    required this.size,
    required this.color,
    required this.delayRatio,
    required this.isHeart,
  });
}

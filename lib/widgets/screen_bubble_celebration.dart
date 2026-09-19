import 'dart:math';
import 'package:flutter/material.dart';

class ScreenBubbleCelebration extends StatefulWidget {
  final VoidCallback onComplete;

  const ScreenBubbleCelebration({Key? key, required this.onComplete}) : super(key: key);

  /// Helper to trigger the floating like-button clone celebration
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
    Overlay.of(context).insert(entry!);
  }

  @override
  State<ScreenBubbleCelebration> createState() => _ScreenBubbleCelebrationState();
}

class _ScreenBubbleCelebrationState extends State<ScreenBubbleCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_FloatingHeartClone> _clones = [];

  @override
  void initState() {
    super.initState();

    // Exactly 3 elegant floating replicas of the like button!
    _clones.add(_FloatingHeartClone(driftX: -18, speedFactor: 1.0, scale: 0.95, delayRatio: 0.0));
    _clones.add(_FloatingHeartClone(driftX: 12, speedFactor: 1.15, scale: 1.1, delayRatio: 0.12));
    _clones.add(_FloatingHeartClone(driftX: -6, speedFactor: 0.85, scale: 0.85, delayRatio: 0.22));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete();
      }
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
    final startX = size.width * 0.72;
    final startY = size.height * 0.52;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;

          return Stack(
            children: _clones.map((clone) {
              final progress = ((t - clone.delayRatio) / (1.0 - clone.delayRatio)).clamp(0.0, 1.0);
              if (progress <= 0.0) return const SizedBox.shrink();

              // Smooth rise upwards
              final currentY = startY - (progress * 160.0 * clone.speedFactor);
              // Subtle sine-wave wobble
              final currentX = startX + clone.driftX + (sin(progress * pi * 2.5) * 14.0);
              final opacity = (1.0 - progress).clamp(0.0, 1.0);
              final scale = (clone.scale * (0.8 + 0.4 * progress));

              return Positioned(
                left: currentX,
                top: currentY,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2A6D), Color(0xFFFF007F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2A6D).withOpacity(0.6 * opacity),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _FloatingHeartClone {
  final double driftX;
  final double speedFactor;
  final double scale;
  final double delayRatio;

  _FloatingHeartClone({
    required this.driftX,
    required this.speedFactor,
    required this.scale,
    required this.delayRatio,
  });
}

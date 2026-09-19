import 'dart:math';
import 'package:flutter/material.dart';

class LikeParticleOverlay extends StatefulWidget {
  final Offset origin;
  final Color particleColor;
  final VoidCallback onComplete;

  const LikeParticleOverlay({
    Key? key,
    required this.origin,
    required this.particleColor,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<LikeParticleOverlay> createState() => _LikeParticleOverlayState();
}

class _LikeParticleOverlayState extends State<LikeParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // 12 glowing particles that burst upward and outward
    for (int i = 0; i < 12; i++) {
      final angle = -pi / 2 + (_random.nextDouble() - 0.5) * pi * 0.9;
      final distance = 40.0 + _random.nextDouble() * 50.0;
      final size = 4.0 + _random.nextDouble() * 5.0;
      _particles.add(_Particle(
        dx: cos(angle) * distance,
        dy: sin(angle) * distance,
        size: size,
        color: widget.particleColor.withOpacity(0.7 + _random.nextDouble() * 0.3),
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final opacity = (1.0 - progress).clamp(0.0, 1.0);

        return Stack(
          children: _particles.map((p) {
            final x = widget.origin.dx + p.dx * progress;
            final y = widget.origin.dy + p.dy * progress;

            return Positioned(
              left: x - p.size / 2,
              top: y - p.size / 2,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: p.size,
                  height: p.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.color,
                    boxShadow: [
                      BoxShadow(
                        color: p.color.withOpacity(0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Particle {
  final double dx;
  final double dy;
  final double size;
  final Color color;
  _Particle({required this.dx, required this.dy, required this.size, required this.color});
}

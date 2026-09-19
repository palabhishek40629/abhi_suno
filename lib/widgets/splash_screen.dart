import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const AnimatedSplashScreen({Key? key, required this.onFinish}) : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fast, clean startup presentation per Section 1:
    // Remove old startup animation page and separately rendered text completely.
    // Display supplied STARTUP / OPENING IMAGE with zero extra assistant text.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Fast transition (~0.7s total) to Home screen
    Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        widget.onFinish();
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
    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Image.asset(
            AppConstants.startupSquareAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.asset(
              AppConstants.logoAsset,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

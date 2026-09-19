import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Tactile3DWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleElevation;
  final Color? glowColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const Tactile3DWrapper({
    Key? key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleElevation = 1.05,
    this.glowColor,
    this.borderRadius,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  State<Tactile3DWrapper> createState() => _Tactile3DWrapperState();
}

class _Tactile3DWrapperState extends State<Tactile3DWrapper> {
  bool _isPressed = false;

  void _onPointerDown() {
    if (mounted) {
      setState(() => _isPressed = true);
      HapticFeedback.selectionClick();
    }
  }

  void _onPointerUp() {
    if (mounted && _isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? const Color(0xFF00E5FF);
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    return Container(
      margin: widget.margin,
      child: Listener(
        onPointerDown: (_) => _onPointerDown(),
        onPointerUp: (_) => _onPointerUp(),
        onPointerCancel: (_) => _onPointerUp(),
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: _isPressed ? widget.scaleElevation : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: glow.withOpacity(0.55),
                          blurRadius: 22,
                          spreadRadius: 1.5,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

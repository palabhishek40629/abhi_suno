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
  final bool isCircle;

  const Tactile3DWrapper({
    Key? key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleElevation = 1.15,
    this.glowColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.isCircle = false,
  }) : super(key: key);

  @override
  State<Tactile3DWrapper> createState() => _Tactile3DWrapperState();
}

class _Tactile3DWrapperState extends State<Tactile3DWrapper> {
  bool _isPressed = false;
  Offset _downPos = Offset.zero;

  void _onPointerDown(PointerDownEvent e) {
    _downPos = e.position;
    if (mounted) {
      setState(() => _isPressed = true);
      HapticFeedback.selectionClick();
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_isPressed && (e.position - _downPos).distance > 10) {
      if (mounted) {
        setState(() => _isPressed = false);
      }
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
    final radius = widget.isCircle ? null : (widget.borderRadius ?? BorderRadius.circular(16));

    return Container(
      margin: widget.margin,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: (_) => _onPointerUp(),
        onPointerCancel: (_) => _onPointerUp(),
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: _isPressed ? widget.scaleElevation : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              padding: widget.padding,
              decoration: BoxDecoration(
                shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: radius,
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: glow.withOpacity(0.65),
                          blurRadius: 28,
                          spreadRadius: 3.0,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
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


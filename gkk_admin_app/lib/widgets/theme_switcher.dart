import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../utils/theme_constants.dart';

/// A Telegram-style theme switcher with circular reveal animation.
///
/// Wrap your MaterialApp with this widget and call
/// `ThemeSwitcher.of(context).toggleTheme(buttonPosition)` to trigger animation.
class ThemeSwitcher extends StatefulWidget {
  final Widget child;

  const ThemeSwitcher({super.key, required this.child});

  static ThemeSwitcherState of(BuildContext context) {
    return context.findAncestorStateOfType<ThemeSwitcherState>()!;
  }

  @override
  State<ThemeSwitcher> createState() => ThemeSwitcherState();
}

class ThemeSwitcherState extends State<ThemeSwitcher>
    with SingleTickerProviderStateMixin {
  final _boundaryKey = GlobalKey();
  ui.Image? _capturedImage;
  Offset? _animationOrigin;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _isAnimating = false;
        _capturedImage?.dispose();
        _capturedImage = null;
        _animationOrigin = null;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    _capturedImage?.dispose();
    super.dispose();
  }

  /// Triggers the theme toggle with circular reveal animation.
  /// [buttonPosition] is the global position of the toggle button center.
  Future<void> toggleTheme(Offset buttonPosition) async {
    if (_isAnimating) return;

    // Capture current screen
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      // Fallback: just toggle without animation
      context.read<ThemeService>().toggleTheme();
      return;
    }

    try {
      final image = await boundary.toImage(pixelRatio: 1.5);

      setState(() {
        _capturedImage = image;
        _animationOrigin = buttonPosition;
        _isAnimating = true;
      });

      // Toggle the actual theme
      if (mounted) {
        context.read<ThemeService>().toggleTheme();
      }

      // Start reveal animation
      _controller.forward(from: 0);
    } catch (e) {
      // Fallback on error
      if (mounted) {
        context.read<ThemeService>().toggleTheme();
      }
    }
  }

  double _calculateMaxRadius(Size size, Offset origin) {
    // Calculate the maximum distance from origin to any corner
    final topLeft = (origin - Offset.zero).distance;
    final topRight = (origin - Offset(size.width, 0)).distance;
    final bottomLeft = (origin - Offset(0, size.height)).distance;
    final bottomRight = (origin - Offset(size.width, size.height)).distance;
    return [
      topLeft,
      topRight,
      bottomLeft,
      bottomRight,
    ].reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: _boundaryKey,
        child: Stack(
          children: [
            // New theme (underneath)
            widget.child,

            // Old theme snapshot with circular clip (on top, being revealed away)
            if (_isAnimating &&
                _capturedImage != null &&
                _animationOrigin != null)
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Positioned.fill(
                    child: ClipPath(
                      clipper: _CircularRevealClipper(
                        center: _animationOrigin!,
                        progress: _animation.value,
                        maxRadius: _calculateMaxRadius(
                          MediaQuery.of(context).size,
                          _animationOrigin!,
                        ),
                      ),
                      child: IgnorePointer(
                        child: RawImage(
                          image: _capturedImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom clipper that creates a circular hole that grows from center.
/// As progress goes from 0→1, the circle grows, revealing new content.
class _CircularRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double progress;
  final double maxRadius;

  _CircularRevealClipper({
    required this.center,
    required this.progress,
    required this.maxRadius,
  });

  @override
  Path getClip(Size size) {
    final radius = maxRadius * progress;

    // Create a path that covers everything EXCEPT the growing circle
    // This reveals the new theme underneath
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(_CircularRevealClipper oldClipper) {
    return oldClipper.progress != progress ||
        oldClipper.center != center ||
        oldClipper.maxRadius != maxRadius;
  }
}

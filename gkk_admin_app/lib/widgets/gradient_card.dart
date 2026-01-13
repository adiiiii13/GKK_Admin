import 'package:flutter/material.dart';

/// Beautiful gradient card with hover animations and shadows
class GradientCard extends StatefulWidget {
  final Widget child;
  final Gradient? gradient;
  final Color? color;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool enableHoverEffect;
  final double? height;
  final double? width;

  const GradientCard({
    Key? key,
    required this.child,
    this.gradient,
    this.color,
    this.borderRadius = 16,
    this.padding,
    this.onTap,
    this.enableHoverEffect = true,
    this.height,
    this.width,
  }) : super(key: key);

  @override
  State<GradientCard> createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _shadowAnimation = Tween<double>(
      begin: 8.0,
      end: 16.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableHoverEffect && widget.onTap != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableHoverEffect && widget.onTap != null) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enableHoverEffect && widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: widget.gradient,
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: _shadowAnimation.value,
                    offset: Offset(0, _shadowAnimation.value / 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  child: Padding(
                    padding: widget.padding ?? const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

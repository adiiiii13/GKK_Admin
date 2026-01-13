import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme_constants.dart';

/// Modern animated button with ripple effect, elevation, and loading states
class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Gradient? gradient;
  final IconData? icon;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;

  const AnimatedButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.gradient,
    this.icon,
    this.textColor,
    this.width,
    this.height = 56,
    this.borderRadius = 16,
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  // Brand colors
  final LinearGradient _greenGradient = AppTheme.greenGradient;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? _greenGradient;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.isOutlined || isDisabled ? null : gradient,
            color: isDisabled
                ? Colors.grey.shade300
                : widget.isOutlined
                ? Colors.transparent
                : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.isOutlined
                ? Border.all(color: const Color(0xFFc2941b), width: 2)
                : null,
            boxShadow: !widget.isOutlined && !isDisabled
                ? [
                    BoxShadow(
                      color: _isPressed
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.15),
                      blurRadius: _isPressed ? 8 : 12,
                      offset: Offset(0, _isPressed ? 2 : 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              splashColor: Colors.white.withValues(alpha: 0.3),
              highlightColor: Colors.white.withValues(alpha: 0.1),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color:
                                  widget.textColor ??
                                  (widget.isOutlined
                                      ? const Color(0xFFc2941b)
                                      : Colors.white),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              color:
                                  widget.textColor ??
                                  (widget.isOutlined
                                      ? const Color(0xFFc2941b)
                                      : Colors.white),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

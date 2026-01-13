import 'package:flutter/material.dart';

/// Shimmer loading placeholder widget
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final ShimmerShape shape;
  final double borderRadius;

  const ShimmerLoading({
    Key? key,
    required this.width,
    required this.height,
    this.shape = ShimmerShape.rectangle,
    this.borderRadius = 8,
  }) : super(key: key);

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                Color(0xFFF5F0E8),
                Color(0xFFFFFFFF),
                Color(0xFFF5F0E8),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: widget.shape == ShimmerShape.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.shape == ShimmerShape.circle
                ? BoxShape.circle
                : BoxShape.rectangle,
          ),
        );
      },
    );
  }
}

enum ShimmerShape { rectangle, circle }

/// Shimmer loading card placeholder
class ShimmerCard extends StatelessWidget {
  final double? height;

  const ShimmerCard({Key? key, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 120,
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerLoading(width: 50, height: 50, shape: ShimmerShape.circle),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                      width: double.infinity,
                      height: 16,
                      borderRadius: 4,
                    ),
                    SizedBox(height: 8),
                    ShimmerLoading(width: 200, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          Spacer(),
          ShimmerLoading(width: double.infinity, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

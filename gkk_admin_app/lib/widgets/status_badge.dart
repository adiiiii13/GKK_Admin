import 'package:flutter/material.dart';

/// Status badge chip with brand colors and optional pulse animation
class StatusBadge extends StatefulWidget {
  final String label;
  final StatusType type;
  final bool showPulse;
  final IconData? icon;

  const StatusBadge({
    Key? key,
    required this.label,
    required this.type,
    this.showPulse = false,
    this.icon,
  }) : super(key: key);

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.showPulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
          ],
          Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    if (widget.showPulse) {
      badge = ScaleTransition(scale: _pulseAnimation, child: badge);
    }

    return badge;
  }

  List<Color> _getColors() {
    switch (widget.type) {
      case StatusType.verified:
      case StatusType.approved:
      case StatusType.delivered:
        return [const Color(0xFF2da832), const Color(0xFF4DBF55)];

      case StatusType.pending:
      case StatusType.inProgress:
        return [const Color(0xFFc2941b), const Color(0xFFE5B84B)];

      case StatusType.rejected:
      case StatusType.failed:
        return [const Color(0xFFE63946), const Color(0xFFFF5A5F)];

      case StatusType.inactive:
      case StatusType.cancelled:
        return [const Color(0xFF6C757D), const Color(0xFF868E96)];
    }
  }
}

enum StatusType {
  // Success states (green)
  verified,
  approved,
  delivered,

  // Warning states (gold)
  pending,
  inProgress,

  // Error states (red)
  rejected,
  failed,

  // Neutral states (grey)
  inactive,
  cancelled,
}

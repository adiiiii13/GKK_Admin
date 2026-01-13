import 'package:flutter/material.dart';

/// Animated Splash Screen with GKK Logo
class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const AnimatedSplashScreen({Key? key, required this.onAnimationComplete})
    : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Brand Colors
  static const Color _greenColor = Color(0xFF2da832);
  static const Color _goldColor = Color(0xFFc2941b);
  static const Color _creamColor = Color(0xFFFAF6ED);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Fade in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Scale animation (slight bounce)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Start animation
    _controller.forward();

    // Complete after animation
    Future.delayed(const Duration(milliseconds: 2500), () {
      widget.onAnimationComplete();
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
      backgroundColor: _creamColor,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  _creamColor,
                  _creamColor.withValues(alpha: 0.95),
                  const Color(0xFFF5F0E8),
                ],
              ),
            ),
            child: Center(
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with golden glow
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _goldColor.withValues(alpha: 0.3),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: _greenColor.withValues(alpha: 0.2),
                              blurRadius: 60,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 180,
                          height: 180,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // App Name with gradient
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [_greenColor, _goldColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'GKK Admin',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        'Ghar Ka Khana',
                        style: TextStyle(
                          fontSize: 16,
                          color: _greenColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Loading indicator
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _greenColor,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

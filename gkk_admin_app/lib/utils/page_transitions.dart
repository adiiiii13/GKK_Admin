import 'package:flutter/material.dart';

/// Slide from right page transition
class SlideRightRoute extends PageRouteBuilder {
  final Widget page;

  SlideRightRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      );
}

/// Fade through page transition
class FadeRoute extends PageRouteBuilder {
  final Widget page;

  FadeRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
}

/// Scale from center page transition
class ScaleRoute extends PageRouteBuilder {
  final Widget page;

  ScaleRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeInOutCubic;
          var scaleTween = Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).chain(CurveTween(curve: curve));
          var fadeTween = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: curve));

          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: ScaleTransition(
              scale: animation.drive(scaleTween),
              child: child,
            ),
          );
        },
      );
}

/// Slide up from bottom page transition (for modals)
class SlideUpRoute extends PageRouteBuilder {
  final Widget page;

  SlideUpRoute({required this.page, bool fullscreenDialog = false})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 300),
        fullscreenDialog: fullscreenDialog,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      );
}

/// Helper class for easy navigation with custom transitions
class PageTransitions {
  /// Navigate with slide from right
  static Future<T?> pushSlide<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(context, SlideRightRoute(page: page) as Route<T>);
  }

  /// Navigate with fade
  static Future<T?> pushFade<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(context, FadeRoute(page: page) as Route<T>);
  }

  /// Navigate with scale
  static Future<T?> pushScale<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(context, ScaleRoute(page: page) as Route<T>);
  }

  /// Navigate with slide up (modal style)
  static Future<T?> pushModal<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      SlideUpRoute(page: page, fullscreenDialog: true) as Route<T>,
    );
  }

  /// Replace current route with slide
  static Future<T?> replaceSlide<T, TO>(BuildContext context, Widget page) {
    return Navigator.pushReplacement<T, TO>(
      context,
      SlideRightRoute(page: page) as Route<T>,
    );
  }

  /// Replace current route with fade
  static Future<T?> replaceFade<T, TO>(BuildContext context, Widget page) {
    return Navigator.pushReplacement<T, TO>(
      context,
      FadeRoute(page: page) as Route<T>,
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';

/// Enhanced avatar widget with golden glow and hero animation support
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? imagePath;
  final double size;
  final String heroTag;
  final bool showGlow;
  final bool showStatusIndicator;
  final Color? statusColor;
  final VoidCallback? onTap;
  final IconData fallbackIcon;

  const ProfileAvatar({
    Key? key,
    this.imageUrl,
    this.imagePath,
    this.size = 100,
    this.heroTag = 'avatar',
    this.showGlow = true,
    this.showStatusIndicator = false,
    this.statusColor,
    this.onTap,
    this.fallbackIcon = Icons.person,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: const Color(0xFFc2941b).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: const Color(0xFF2da832).withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipOval(child: _buildImage()),
    );

    if (showStatusIndicator) {
      avatarWidget = Stack(
        children: [
          avatarWidget,
          Positioned(
            bottom: 0,
            right: size * 0.05,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: statusColor ?? const Color(0xFF2da832),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    Widget finalWidget = Hero(tag: heroTag, child: avatarWidget);

    if (onTap != null) {
      finalWidget = GestureDetector(onTap: onTap, child: finalWidget);
    }

    return finalWidget;
  }

  Widget _buildImage() {
    // Check if imagePath is actually a URL (Google profile or other network image)
    if (imagePath != null && imagePath!.isNotEmpty) {
      if (imagePath!.startsWith('http://') ||
          imagePath!.startsWith('https://')) {
        // It's a URL, treat as network image
        return Image.network(
          imagePath!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } else {
        // It's a file path, check if file exists
        final file = File(imagePath!);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover, width: size, height: size);
        }
      }
    }

    // Network image from imageUrl parameter
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    // Placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2da832), Color(0xFFc2941b)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(fallbackIcon, size: size * 0.5, color: Colors.white),
    );
  }
}

import 'package:flutter/material.dart';

/// 對齊原型 `.cover.c1` … `.c6` 漸層
abstract final class BookCoverDecoration {
  static BoxDecoration c(int n) {
    switch (n) {
      case 2:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A5D6B), Color(0xFF2C3840)],
          ),
        );
      case 3:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5B4A6B), Color(0xFF352D40)],
          ),
        );
      case 4:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A6B5C), Color(0xFF2D4038)],
          ),
        );
      case 5:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B5A4A), Color(0xFF403529)],
          ),
        );
      case 6:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5C4A6B), Color(0xFF352940)],
          ),
        );
      case 1:
      default:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B5344), Color(0xFF3D3229)],
          ),
        );
    }
  }
}

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.variant,
    this.aspectRatio = 3 / 4,
    this.borderRadius = 10,
    this.child,
  });

  final int variant;
  final double aspectRatio;
  final double borderRadius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BookCoverDecoration.c(variant).copyWith(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x141A1A1A),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x52000000), Color(0x00000000)],
                  stops: [0, 0.42],
                ),
              ),
            ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

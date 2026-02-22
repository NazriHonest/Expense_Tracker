import 'dart:ui';
import 'package:flutter/material.dart';

class GlassBox extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const GlassBox({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.borderRadius = 28,
    this.blur = 12,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      width: width,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
        // Subtle gradient makes the glass look more realistic
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            (isDark ? Colors.white : Colors.black).withOpacity(0.02),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 45,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassBox(
        height: size,
        width: size,
        borderRadius: size / 2, // Perfect circle
        margin: EdgeInsets.zero,
        child: Center(
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: size * 0.45,
          ),
        ),
      ),
    );
  }
}

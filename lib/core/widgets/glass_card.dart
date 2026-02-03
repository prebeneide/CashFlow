import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(20);
    final defaultPadding = padding ?? const EdgeInsets.all(24);
    final defaultMargin = margin ?? EdgeInsets.zero;
    
    // Glassmorphism-effekt
    final backgroundColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.7);
    
    final defaultBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    
    final defaultShadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: 0,
              offset: const Offset(0, 16),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 40,
              spreadRadius: 0,
              offset: const Offset(0, 16),
            ),
          ];

    return Container(
      width: width,
      height: height,
      margin: defaultMargin,
      decoration: BoxDecoration(
        borderRadius: defaultBorderRadius,
        color: backgroundColor,
        border: Border.all(
          color: borderColor ?? defaultBorderColor,
          width: borderWidth,
        ),
        boxShadow: boxShadow ?? defaultShadow,
      ),
      child: ClipRRect(
        borderRadius: defaultBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: defaultPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}


import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final LinearGradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.borderRadius = 24,
    this.blur = 15,
    this.borderColor,
    this.shadows,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Stack(
        children: [
          // Shadows
          if (shadows != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: shadows,
                ),
              ),
            ),
          
          // Blur Layer
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: borderColor ?? (isDark 
                      ? Colors.white.withValues(alpha: 0.1) 
                      : Colors.white.withValues(alpha: 0.4)),
                    width: 1.5,
                  ),
                  gradient: gradient ?? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.03),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.7),
                          Colors.white.withValues(alpha: 0.4),
                        ],
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

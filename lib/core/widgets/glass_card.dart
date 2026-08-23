import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Frosted, bordered card used across the app.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.radius = 20,
    this.borderColor,
    this.gradientColors,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;
  final Color? borderColor;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ??
              [
                AppColors.surface.withOpacity(0.94),
                AppColors.surfaceHigh.withOpacity(0.84),
              ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? AppColors.border.withOpacity(0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
    return card;
  }
}

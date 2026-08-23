import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: compact ? 34 : 42,
      height: compact ? 34 : 42,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(compact ? 10 : 13),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.download_rounded, color: Colors.white),
    );

    if (compact) return icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Media Hub',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
            ),
            Text(
              'Grab · Stitch · Play',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.6,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

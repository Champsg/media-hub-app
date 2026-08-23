import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class FloatingDownloadButton extends StatelessWidget {
  const FloatingDownloadButton({
    super.key,
    required this.count,
    required this.onTap,
    this.visible = true,
  });

  final int count;
  final VoidCallback onTap;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 220),
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.5),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Material(
          color: AppColors.primary,
          elevation: 12,
          shadowColor: AppColors.primary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.download_done_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count media',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

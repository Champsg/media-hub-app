import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../logic/clipboard_controller.dart';
import '../../logic/extract_controller.dart';
import '../../logic/providers.dart';

/// One-tap banner shown when the clipboard contains a media link.
class ClipboardBanner extends ConsumerWidget {
  const ClipboardBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = ref.watch(
      clipboardControllerProvider.select((controller) => controller.suggestion),
    );
    if (suggestion == null) return const SizedBox.shrink();

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(12),
      gradientColors: [
        AppColors.primary.withOpacity(0.18),
        AppColors.surfaceHigh.withOpacity(0.9),
      ],
      borderColor: AppColors.primary.withOpacity(0.45),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.clipboardFound,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  suggestion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(extractControllerProvider).extract(suggestion),
            child: const Text('Use'),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () =>
                ref.read(clipboardControllerProvider).dismiss(),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/library_item.dart';

class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
  });

  final LibraryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      radius: 18,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surfaceHigh.withOpacity(0.9),
                    AppColors.primary.withOpacity(0.22),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                _iconFor(item.kind),
                size: 42,
                color: _colorFor(item.kind),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${Formatters.bytes(item.size)} · '
            '${item.modified.day}/${item.modified.month}/${item.modified.year}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(MediaKind kind) {
    switch (kind) {
      case MediaKind.video:
        return Icons.play_circle_fill_rounded;
      case MediaKind.audio:
        return Icons.music_note_rounded;
      case MediaKind.image:
        return Icons.image_rounded;
      case MediaKind.other:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _colorFor(MediaKind kind) {
    switch (kind) {
      case MediaKind.video:
        return AppColors.primary;
      case MediaKind.audio:
        return AppColors.accent;
      case MediaKind.image:
        return AppColors.secondary;
      case MediaKind.other:
        return AppColors.textSecondary;
    }
  }
}

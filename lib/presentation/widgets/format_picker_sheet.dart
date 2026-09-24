import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/extract_result.dart';

/// What the user picked in the format sheet: an individual format, a
/// server-merged video, or a server-extracted audio track.
class FormatSelection {
  const FormatSelection.format(MediaFormat this.format)
      : merged = false,
        audioOnly = false;

  const FormatSelection.merged()
      : format = null,
        merged = true,
        audioOnly = false;

  const FormatSelection.audioOnly()
      : format = null,
        merged = false,
        audioOnly = true;

  final MediaFormat? format;
  final bool merged;
  final bool audioOnly;
}

/// Bottom sheet that lets the user pick a format from an extracted media.
Future<FormatSelection?> showFormatPickerSheet(
  BuildContext context,
  ExtractResult result,
) {
  return showModalBottomSheet<FormatSelection>(
    context: context,
    builder: (context) => _FormatSheet(result: result),
  );
}

class _FormatSheet extends StatelessWidget {
  const _FormatSheet({required this.result});

  final ExtractResult result;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select download format',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.movie_rounded,
                  title: 'Best Video (Merged)',
                  subtitle: 'Highest quality video with sound',
                  color: AppColors.primary,
                  onTap: () =>
                      Navigator.of(context).pop(const FormatSelection.merged()),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.music_note_rounded,
                  title: 'Audio Only',
                  subtitle: 'Best track as .m4a / .mp3',
                  color: AppColors.secondary,
                  onTap: () =>
                      Navigator.of(context).pop(const FormatSelection.audioOnly()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textFaint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

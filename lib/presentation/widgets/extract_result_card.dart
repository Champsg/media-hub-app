import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/extract_result.dart';
import '../../logic/providers.dart';
import 'format_picker_sheet.dart';

class ExtractResultCard extends ConsumerWidget {
  const ExtractResultCard({super.key, required this.result});

  final ExtractResult result;

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final format = await showFormatPickerSheet(context, result);
    if (format == null) return;
    final fileName =
        result.suggestedFilename ?? '${result.title}.${format.ext}';
    await ref
        .read(downloadControllerProvider)
        .start(url: format.url, fileName: fileName, isHls: format.isHls);
    ref.read(libraryControllerProvider).refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download started')),
      );
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: result.url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = <String>[
      if (result.uploader != null) result.uploader!,
      if (result.durationLabel != null) result.durationLabel!,
      if (result.viewCount != null)
        '${Formatters.compactCount(result.viewCount)} views',
    ].join(' · ');

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumbnail(result: result),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (result.isLive)
                      const _Badge(
                        label: 'LIVE',
                        color: AppColors.danger,
                        icon: Icons.circle,
                      ),
                    if (result.isHls)
                      const _Badge(
                        label: 'HLS',
                        color: AppColors.secondary,
                        icon: Icons.hls_rounded,
                      ),
                    if (result.isDirect)
                      const _Badge(
                        label: 'Direct',
                        color: AppColors.success,
                        icon: Icons.link_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  result.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    meta,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (result.recommendationReason != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Recommended: ${result.recommendationReason}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _download(context, ref),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text(
                          'Download',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Copy link',
                      onPressed: () => _copyLink(context),
                      icon: const Icon(Icons.link_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.result});

  final ExtractResult result;

  @override
  Widget build(BuildContext context) {
    final thumb = result.thumbnail;
    return SizedBox(
      height: 170,
      width: double.infinity,
      child: (thumb == null || thumb.isEmpty)
          ? _placeholder()
          : CachedNetworkImage(
              imageUrl: thumb,
              fit: BoxFit.cover,
              placeholder: (context, url) => _placeholder(),
              errorWidget: (context, url, error) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceHigh,
            AppColors.primary.withOpacity(0.32),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.movie_creation_outlined,
          size: 46,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

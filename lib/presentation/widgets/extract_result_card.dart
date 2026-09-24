import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/ad_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/extract_result.dart';
import '../../logic/providers.dart';
import 'format_picker_sheet.dart';

class ExtractResultCard extends ConsumerWidget {
  const ExtractResultCard({super.key, required this.result});

  final ExtractResult result;

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final selection = await showFormatPickerSheet(context, result);
    if (selection == null) return;

    // Show an interstitial ad before starting the download.
    final adService = ref.read(adServiceProvider);
    final adShown = await adService.showAd();
    if (!adShown && AdConfig.diagnosticsToUi && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ad not shown — ${adService.status}'),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    final downloads = ref.read(downloadControllerProvider);
    final suggested = result.suggestedFilename;
    final base = suggested == null
        ? result.title
        : suggested.replaceAll(RegExp(r'\.[^.]*$'), '');

    if (selection.merged) {
      final bestVideo = result.bestVideoFormat;
      final bestAudio = result.bestAudioFormat;
      if (bestVideo != null) {
        if (!bestVideo.hasAudio && bestAudio != null) {
          await downloads.start(
            url: bestVideo.url,
            audioUrl: bestAudio.url,
            fileName: '$base.mp4',
          );
        } else {
          await downloads.start(
            url: bestVideo.url,
            fileName: '$base.mp4',
            isHls: bestVideo.isHls,
          );
        }
      }
    } else if (selection.audioOnly) {
      final bestAudio = result.bestAudioFormat;
      if (bestAudio != null) {
        await downloads.start(
          url: bestAudio.url,
          fileName: '$base.m4a',
        );
      }
    } else if (selection.format != null) {
      final format = selection.format!;
      final fileName = _fileNameFor(result, format);
      if (format.hasVideo && !format.hasAudio && result.bestAudioFormat != null) {
        await downloads.start(
          url: format.url,
          audioUrl: result.bestAudioFormat!.url,
          fileName: fileName,
        );
      } else {
        await downloads.start(
          url: format.url,
          fileName: fileName,
          isHls: format.isHls,
        );
      }
    }

    ref.read(libraryControllerProvider).refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download started')),
      );
    }
  }

  String _fileNameFor(ExtractResult result, MediaFormat format) {
    final suggested = result.suggestedFilename;
    final base = suggested == null
        ? result.title
        : suggested.replaceAll(RegExp(r'\.[^.]*$'), '');
    var ext = format.ext;
    if (!format.hasVideo &&
        format.hasAudio &&
        (ext == 'ogg' || ext == 'opus' || ext == 'webm')) {
      ext = 'm4a';
    }
    return '$base.$ext';
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

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _download(context, ref),
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text('Download'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigher,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: IconButton(
                        tooltip: 'Copy link',
                        onPressed: () => _copyLink(context),
                        icon: const Icon(
                          Icons.link_rounded,
                          color: AppColors.primary,
                        ),
                      ),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
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
      height: 180,
      width: double.infinity,
      child: (thumb == null || thumb.isEmpty)
          ? _placeholder()
          : Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: thumb,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _placeholder(),
                  errorWidget: (context, url, error) => _placeholder(),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.surfaceHigh.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceHigher,
      child: Center(
        child: Icon(
          Icons.movie_creation_outlined,
          size: 48,
          color: AppColors.border,
        ),
      ),
    );
  }
}

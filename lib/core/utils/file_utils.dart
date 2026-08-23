import 'dart:math';

import '../constants/app_strings.dart';

/// Filesystem helpers shared by the downloader, stitcher and vault.
class FileUtils {
  FileUtils._();

  static final RegExp _disallowed = RegExp(r'[\\/:*?"<>|\x00-\x1f]');

  static String sanitizeFileName(String name, {String fallback = 'media'}) {
    var cleaned = name
        .replaceAll(_disallowed, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    cleaned = cleaned.substring(0, min(cleaned.length, 120));
    if (cleaned.isEmpty || cleaned == '.' || cleaned == '..') {
      cleaned = fallback;
    }
    if (cleaned.startsWith('.')) {
      cleaned = '$fallback$cleaned';
    }
    return cleaned;
  }

  static bool hasExtension(String name) {
    final trimmed = name.trim();
    return trimmed.contains('.') &&
        trimmed.lastIndexOf('.') < trimmed.length - 1;
  }

  /// Forces a sensible extension for HLS stitches, which produce TS segments.
  static String hlsFileName(String baseName) {
    final sanitized = sanitizeFileName(baseName);
    if (sanitized.toLowerCase().endsWith('.ts')) return sanitized;
    if (sanitized.toLowerCase().endsWith('.mp4')) {
      return sanitized.substring(0, sanitized.length - 4) + '.ts';
    }
    return '$sanitized.ts';
  }

  static String mediaBadgeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.m3u8')) return AppStrings.hlsBadge;
    if (_videoExt.hasMatch(lower)) return 'Video';
    if (_audioExt.hasMatch(lower)) return AppStrings.audioBadge;
    if (_imageExt.hasMatch(lower)) return 'Image';
    return 'File';
  }

  static final RegExp _videoExt = RegExp(r'\.(mp4|webm|mkv|mov|avi|ts|m4v|3gp)$');
  static final RegExp _audioExt = RegExp(r'\.(mp3|m4a|aac|wav|flac|ogg|opus|amr)$');
  static final RegExp _imageExt = RegExp(r'\.(jpg|jpeg|png|webp|gif|bmp)$');

  static bool isVideo(String path) => _videoExt.hasMatch(path.toLowerCase());
  static bool isAudio(String path) => _audioExt.hasMatch(path.toLowerCase());
  static bool isImage(String path) => _imageExt.hasMatch(path.toLowerCase());
  static bool isPlayable(String path) =>
      isVideo(path) || isAudio(path);
}

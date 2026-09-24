import 'package:flutter/services.dart';

/// Bridges to ``MediaScannerConnection`` on Android for immediate gallery
/// indexing of downloaded / saved media.
class MediaScanner {
  MediaScanner._();

  static final MediaScanner instance = MediaScanner._();

  static const MethodChannel _channel = MethodChannel('media_hub/media_scanner');

  Future<bool> scanFile(String path) async {
    try {
      final result =
          await _channel.invokeMethod<bool>('scanFile', {'path': path});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<int> scanDirectory(String path) async {
    try {
      final result =
          await _channel.invokeMethod<int>('scanDir', {'path': path});
      return result ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Exports a file into the public media collections so gallery apps can see
  /// it. Returns the MediaStore URI, or null if the export failed.
  Future<String?> saveToGallery(String path) async {
    try {
      return await _channel.invokeMethod<String>(
        'saveToGallery',
        {'path': path},
      );
    } catch (_) {
      return null;
    }
  }
}

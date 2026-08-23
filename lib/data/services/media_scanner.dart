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
}

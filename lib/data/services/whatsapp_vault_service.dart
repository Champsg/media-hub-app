import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/utils/file_utils.dart';
import '../models/status_item.dart';
import 'media_scanner.dart';
import 'storage_service.dart';

class VaultException implements Exception {
  VaultException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Storage Access Framework integration for the WhatsApp Status Vault.
/// The native side (MainActivity) handles tree picking, listing and copying;
/// this service adds discovery + media filtering on top.
class WhatsAppVaultService {
  static const MethodChannel _channel = MethodChannel('media_hub/saf');

  Future<String?> pickDirectory() async {
    try {
      return await _channel.invokeMethod<String>('pickDirectory');
    } on PlatformException catch (e) {
      if (e.code == 'CANCELLED') return null;
      throw VaultException(e.message ?? 'Folder picker failed.');
    }
  }

  /// Recursively walks the picked tree and returns status-style media files.
  Future<List<VaultStatusItem>> scanStatuses(String treeUri) async {
    final items = <VaultStatusItem>[];
    await _walk(treeUri, items, depth: 0);
    return items;
  }

  Future<void> _walk(
    String uri,
    List<VaultStatusItem> out, {
    required int depth,
  }) async {
    if (depth > 8) return;
    final children = await _list(uri);
    for (final child in children) {
      if (child.isDirectory) {
        await _walk(child.uri, out, depth: depth + 1);
      } else if (_isStatusMedia(child)) {
        out.add(child);
      }
    }
  }

  Future<List<VaultStatusItem>> _list(String uri) async {
    final raw = await _channel.invokeMethod<List<dynamic>>(
      'listTree',
      {'uri': uri},
    );
    final result = <VaultStatusItem>[];
    for (final entry in raw ?? const []) {
      if (entry is Map) {
        final map = Map<String, dynamic>.from(entry);
        result.add(
          VaultStatusItem(
            name: map['name'] as String? ?? 'Untitled',
            uri: map['uri'] as String? ?? '',
            mimeType: map['mimeType'] as String? ?? '',
            isDirectory: map['isDirectory'] as bool? ?? false,
            size: (map['size'] as num?)?.toInt() ?? -1,
          ),
        );
      }
    }
    return result;
  }

  bool _isStatusMedia(VaultStatusItem item) {
    final mime = item.mimeType.toLowerCase();
    final name = item.name.toLowerCase();
    return mime.startsWith('image/') ||
        mime.startsWith('video/') ||
        mime.startsWith('audio/') ||
        RegExp(r'\.(jpg|jpeg|png|webp|gif|mp4|3gp|mkv|webm|mov)$')
            .hasMatch(name);
  }

  Future<String> save({
    required String uri,
    required String fileName,
    required String directory,
  }) async {
    final directoryHandle = Directory(directory);
    final destPath = await StorageService.instance.uniquePath(
      directoryHandle,
      FileUtils.sanitizeFileName(fileName),
    );
    final result = await _channel.invokeMethod<String>(
      'copyTo',
      {'srcUri': uri, 'destPath': destPath},
    );
    if (result == null) throw VaultException('Copy failed.');
    await MediaScanner.instance.scanFile(result);
    return result;
  }

  /// Copies a remote SAF file into Temp so Flutter can render/preview it.
  Future<String> copyToTemp({
    required String uri,
    required String fileName,
  }) async {
    final tempDir = await StorageService.instance.tempDir();
    final destPath = await StorageService.instance.uniquePath(
      tempDir,
      FileUtils.sanitizeFileName(fileName),
    );
    final result = await _channel.invokeMethod<String>(
      'copyTo',
      {'srcUri': uri, 'destPath': destPath},
    );
    if (result == null) throw VaultException('Copy failed.');
    return result;
  }
}

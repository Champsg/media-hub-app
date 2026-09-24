import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/utils/file_utils.dart';

/// Owns the app-private media directories (Downloads, Vault, Temp).
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  Future<Directory> _root() async {
    final base = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final root = Directory(p.join(base.path, 'VidKwaii'));
    return root.create(recursive: true);
  }

  Future<Directory> downloadsDir() => _subDir('Downloads');

  Future<Directory> vaultDir() => _subDir('Vault');

  Future<Directory> tempDir() => _subDir('Temp');

  Future<Directory> _subDir(String name) async {
    final dir = Directory(p.join((await _root()).path, name));
    return dir.create(recursive: true);
  }

  /// Returns a path in [directory] that does not yet exist, appending
  /// `` (1)``, `` (2)`` … on collision.
  Future<String> uniquePath(Directory directory, String fileName) async {
    final candidate = p.join(directory.path, fileName);
    if (!await File(candidate).exists()) return candidate;
    final dot = fileName.lastIndexOf('.');
    final stem = dot > 0 ? fileName.substring(0, dot) : fileName;
    final ext = dot > 0 ? fileName.substring(dot) : '';
    for (var i = 1; i < 1000; i++) {
      final next = p.join(directory.path, '$stem ($i)$ext');
      if (!await File(next).exists()) return next;
    }
    return candidate;
  }

  String sanitizeForSave(String name) => FileUtils.sanitizeFileName(name);
}

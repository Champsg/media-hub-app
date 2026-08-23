import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/library_item.dart';
import '../data/services/storage_service.dart';

/// Scans the app's Downloads and Vault folders into a playable library.
class LibraryController extends ChangeNotifier {
  List<LibraryItem> items = const [];
  bool loading = false;
  String? error;

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final downloads = await StorageService.instance.downloadsDir();
      final vault = await StorageService.instance.vaultDir();
      final collected = <LibraryItem>[];
      await _collect(downloads, collected);
      await _collect(vault, collected);
      collected.sort((a, b) => b.modified.compareTo(a.modified));
      items = collected;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _collect(Directory directory, List<LibraryItem> out) async {
    if (!await directory.exists()) return;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File && !entity.path.contains('.part')) {
        try {
          out.add(LibraryItem.fromFile(entity));
        } catch (_) {
          // Skip files that vanish mid-scan.
        }
      }
    }
  }

  Future<void> delete(LibraryItem item) async {
    final file = File(item.path);
    if (await file.exists()) await file.delete();
    await refresh();
  }

  Future<void> share(LibraryItem item) async {
    await Share.shareXFiles([XFile(item.path)], text: item.name);
  }
}

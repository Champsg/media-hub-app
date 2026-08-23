import 'package:flutter/foundation.dart';

import '../data/models/status_item.dart';
import '../data/services/storage_service.dart';
import '../data/services/whatsapp_vault_service.dart';

/// Drives the WhatsApp Status Vault: SAF tree picking, scanning, saving.
class VaultController extends ChangeNotifier {
  VaultController(this._service);

  final WhatsAppVaultService _service;

  String? _treeUri;
  List<VaultStatusItem> _items = const [];
  bool _scanning = false;
  String? _error;
  final Set<String> _saving = {};
  String? _previewPath;
  VaultStatusItem? _previewItem;

  String? get treeUri => _treeUri;
  List<VaultStatusItem> get items => _items;
  bool get scanning => _scanning;
  String? get error => _error;
  Set<String> get saving => _saving;
  String? get previewPath => _previewPath;
  VaultStatusItem? get previewItem => _previewItem;

  Future<void> pickAndScan() async {
    _error = null;
    try {
      final uri = await _service.pickDirectory();
      if (uri == null) return;
      _treeUri = uri;
      _scanning = true;
      _items = const [];
      notifyListeners();
      _items = await _service.scanStatuses(uri);
    } catch (e) {
      _error = '$e';
    } finally {
      _scanning = false;
      notifyListeners();
    }
  }

  Future<String?> save(VaultStatusItem item) async {
    _saving.add(item.uri);
    notifyListeners();
    try {
      final dir = await StorageService.instance.vaultDir();
      return await _service.save(
        uri: item.uri,
        fileName: item.name,
        directory: dir.path,
      );
    } catch (e) {
      _error = '$e';
      return null;
    } finally {
      _saving.remove(item.uri);
      notifyListeners();
    }
  }

  Future<void> saveAll() async {
    final targets = _items.where((item) => !item.isDirectory).toList();
    for (final item in targets) {
      await save(item);
    }
  }

  Future<void> preview(VaultStatusItem item) async {
    try {
      final path =
          await _service.copyToTemp(uri: item.uri, fileName: item.name);
      _previewItem = item;
      _previewPath = path;
      notifyListeners();
    } catch (e) {
      _error = '$e';
      notifyListeners();
    }
  }

  void clearPreview() {
    _previewItem = null;
    _previewPath = null;
    notifyListeners();
  }

  Future<void> disconnect() async {
    _treeUri = null;
    _items = const [];
    notifyListeners();
  }
}

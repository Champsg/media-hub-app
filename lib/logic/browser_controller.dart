import 'package:flutter/foundation.dart';

import '../data/models/download_task.dart';
import '../data/services/web_sniffer.dart';

/// Tracks the in-app browser's URL and sniffed media candidates.
class BrowserController extends ChangeNotifier {
  final List<SniffedMedia> _media = [];
  String? _currentUrl;
  bool _snifferActive = false;

  List<SniffedMedia> get media => List.unmodifiable(_media);
  String? get currentUrl => _currentUrl;
  bool get snifferActive => _snifferActive;

  void setUrl(String? url) {
    _currentUrl = url;
    notifyListeners();
  }

  void handleJsMessage(String payload) {
    final parsed = WebSniffer.parse(payload);
    var added = false;
    for (final item in parsed) {
      if (item.url.isEmpty) continue;
      final exists = _media.any((m) => m.url == item.url);
      if (!exists) {
        _media.add(item);
        added = true;
      }
    }
    if (added) notifyListeners();
  }

  void setSnifferActive(bool active) {
    _snifferActive = active;
    notifyListeners();
  }

  void clearMedia() {
    _media.clear();
    notifyListeners();
  }
}

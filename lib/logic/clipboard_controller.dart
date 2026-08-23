import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/utils/url_utils.dart';

/// Polls the clipboard and surfaces media links as one-tap suggestions.
class ClipboardController extends ChangeNotifier {
  Timer? _timer;
  String? _lastSeen;
  String? _suggestion;

  String? get suggestion => _suggestion;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text == _lastSeen) return;
      _lastSeen = text;
      _suggestion = UrlUtils.isLikelyMediaUrl(text) ? text : null;
      notifyListeners();
    } on PlatformException {
      // Clipboard unavailable — ignore.
    }
  }

  void dismiss() {
    if (_suggestion == null) return;
    _suggestion = null;
    _lastSeen = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/extract_result.dart';
import '../data/repositories/media_repository.dart';

/// Drives metadata extraction and exposes the result as an AsyncValue.
class ExtractController extends ChangeNotifier {
  ExtractController(this._repository);

  final MediaRepository _repository;

  AsyncValue<ExtractResult?> state = const AsyncValue.data(null);
  String? lastUrl;

  Future<void> extract(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    lastUrl = trimmed;
    state = const AsyncValue.loading();
    notifyListeners();
    try {
      final result = await _repository.extract(trimmed);
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
    notifyListeners();
  }

  void clear() {
    lastUrl = null;
    state = const AsyncValue.data(null);
    notifyListeners();
  }
}

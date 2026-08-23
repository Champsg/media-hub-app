import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config/api_config.dart';
import '../data/models/download_task.dart';
import '../data/repositories/media_repository.dart';
import '../data/services/downloader_service.dart';

/// Listens to the downloader's progress stream and re-exposes tasks to UI.
class DownloadController extends ChangeNotifier {
  DownloadController({
    required MediaRepository repository,
    required DownloaderService downloader,
    required ApiConfig config,
  })  : _repository = repository,
        _downloader = downloader,
        _config = config {
    _subscription = _downloader.progressStream.listen((_) => notifyListeners());
  }

  final MediaRepository _repository;
  final DownloaderService _downloader;
  final ApiConfig _config;
  late final StreamSubscription<DownloadProgress> _subscription;

  List<DownloadTask> get tasks => _downloader.tasks;

  List<DownloadTask> get activeTasks => _downloader.tasks
      .where(
        (t) =>
            t.status == DownloadStatus.queued ||
            t.status == DownloadStatus.running ||
            t.status == DownloadStatus.paused,
      )
      .toList(growable: false);

  Future<DownloadTask> start({
    required String url,
    required String fileName,
    bool isHls = false,
  }) {
    return _repository.download(
      url: url,
      fileName: fileName,
      isHls: isHls,
      parallelChunks: _config.parallelChunks,
    );
  }

  Future<void> pause(String id) => _downloader.pause(id);

  Future<void> resume(String id) => _downloader.resume(id);

  Future<void> cancel(String id) => _downloader.cancel(id);

  Future<void> retry(String id) => _downloader.retry(id);

  void remove(String id) {
    _downloader.remove(id);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

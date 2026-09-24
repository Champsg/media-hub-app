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
    VoidCallback? onTaskCompleted,
  })  : _repository = repository,
        _downloader = downloader,
        _config = config,
        _onTaskCompleted = onTaskCompleted {
    _subscription = _downloader.progressStream.listen(_onProgress);
  }

  final MediaRepository _repository;
  final DownloaderService _downloader;
  final ApiConfig _config;
  final VoidCallback? _onTaskCompleted;
  late final StreamSubscription<DownloadProgress> _subscription;
  final Map<String, DownloadStatus> _lastStatus = {};

  void _onProgress(DownloadProgress progress) {
    final task = _downloader.taskById(progress.taskId);
    if (task != null) {
      final previous = _lastStatus[task.id];
      if (previous != task.status) {
        if (task.status == DownloadStatus.completed) {
          _onTaskCompleted?.call();
        }
        _lastStatus[task.id] = task.status;
      }
    }
    notifyListeners();
  }

  List<DownloadTask> get tasks => _downloader.tasks;

  List<DownloadTask> get activeTasks => _downloader.tasks
      .where(
        (t) =>
            t.status == DownloadStatus.queued ||
            t.status == DownloadStatus.running ||
            t.status == DownloadStatus.merging ||
            t.status == DownloadStatus.paused,
      )
      .toList(growable: false);

  Future<DownloadTask> start({
    required String url,
    required String fileName,
    String? audioUrl,
    Map<String, String>? headers,
    Map<String, String>? audioHeaders,
    bool isHls = false,
  }) {
    return _repository.download(
      url: url,
      audioUrl: audioUrl,
      headers: headers,
      audioHeaders: audioHeaders,
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
